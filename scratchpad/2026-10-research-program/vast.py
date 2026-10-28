#!/usr/bin/env python3
"""Vast.ai helper for the nice research program (budget-guarded rentals).

Rules it enforces (PROPOSAL.md section 3):
  * every instance is labelled nice-research-<name>; the fleet ignores that prefix
  * hard cap CAP_USD per calendar month, measured from `vastai show invoices-v1`
    (dated, per instance, includes disk); RESERVE_USD held back in the last 7 days
  * no rental when account credit is below CREDIT_FLOOR
  * every instance self-destroys after its TTL (onstart background timer); `reconcile`
    destroys anything past TTL + grace, and any research-labelled instance the ledger
    does not know

Commands:
  credit                      account credit
  offers [--gpu X] [--max-dph D] [--bid] [--query EXTRA] [-n N]
  create [OFFER | --gpu NAME [--max-dph D]] --name NAME [--ttl-hours H] [--image IMG]
                              [--disk GB] [--onstart-cmd CMD] [--bid PRICE] [--purpose TEXT]
                              (offer ids go stale in minutes; --gpu picks the cheapest live offer)
  list                        research instances with age and running cost
  ssh ID                      print the ssh command
  destroy ID|all              destroy (research-labelled only)
  reconcile                   TTL sweep, orphan sweep, ledger close-out, budget summary
  month [YYYY-MM]             invoiced research charges for a month (and fleet, for context)
Uses the `vastai` CLI (key in ~/.config/vastai/vast_api_key). Stdlib only.
"""
import argparse, csv, datetime as dt, json, os, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
LEDGER = os.path.join(HERE, "vast-ledger.csv")
PREFIX = "nice-research-"
CAP_USD = 30.0
RESERVE_USD = 5.0          # untouchable in the last 7 days of the month
CREDIT_FLOOR = 10.0        # protects the fleet, which shares the account
DEFAULT_TTL_H = 2.0
GRACE_MIN = 15
DEFAULT_IMAGE = "nvidia/cuda:12.8.1-devel-ubuntu24.04"
DEFAULT_QUERY = ("reliability>0.95 num_gpus=1 gpu_ram>=8 cuda_vers>=12.8 rentable=true "
                 "inet_down>100 disk_space>=12")
FIELDS = ["created_utc", "instance_id", "label", "offer_id", "gpu", "dph", "ttl_h",
          "purpose", "status", "closed_utc", "est_usd", "note"]
SELF_DESTROY = ('curl -s -X DELETE -H "Authorization: Bearer $CONTAINER_API_KEY" '
                '-H "Content-Type: application/json" -d "{}" '
                '"https://console.vast.ai/api/v0/instances/$CONTAINER_ID/"')


def vast(*args, raw=True, timeout=120):
    cmd = ["vastai", *args] + (["--raw"] if raw else [])
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    if p.returncode != 0:
        sys.exit(f"vastai {' '.join(args)} failed: {p.stderr.strip() or p.stdout.strip()}")
    if not raw:
        return p.stdout
    try:
        return json.loads(p.stdout)
    except json.JSONDecodeError:
        sys.exit(f"vastai {' '.join(args)}: not JSON: {p.stdout[:300]}")


def now():
    return dt.datetime.now(dt.timezone.utc)


def credit():
    u = vast("show", "user")
    return float(u.get("credit") or 0.0)


def read_ledger():
    if not os.path.exists(LEDGER):
        return []
    with open(LEDGER, newline="") as f:
        return list(csv.DictReader(f))


def write_ledger(rows):
    with open(LEDGER, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        w.writeheader()
        w.writerows(rows)


def research_instances():
    return [i for i in vast("show", "instances") if str(i.get("label") or "").startswith(PREFIX)]


def month_bounds(ym=None):
    t = now()
    y, m = (int(ym[:4]), int(ym[5:7])) if ym else (t.year, t.month)
    start = dt.date(y, m, 1)
    end = dt.date(y + (m == 12), (m % 12) + 1, 1)
    return start, end


def charges(start, end):
    """All invoices-v1 charge records of type instance between two dates (paginated)."""
    out, token = [], None
    for _ in range(50):
        args = ["show", "invoices-v1", "-c", "-s", start.isoformat(), "-e", end.isoformat(), "-l", "100"]
        if token:
            args += ["-t", token]
        page = vast(*args)
        out += [r for r in page.get("results", []) if r.get("type") == "instance"]
        token = page.get("next_token")
        if not token or not page.get("results"):
            break
    return out


def month_spend(ym=None):
    start, end = month_bounds(ym)
    recs = charges(start, end)
    res = fleet = 0.0
    by_type = {}
    for r in recs:
        label = str((r.get("metadata") or {}).get("label") or "")
        amt = float(r.get("amount") or 0)
        if label.startswith(PREFIX):
            res += amt
            for it in r.get("items", []):
                by_type[it.get("type")] = by_type.get(it.get("type"), 0.0) + float(it.get("amount") or 0)
        elif label.startswith("nice-fleet"):
            fleet += amt
    return start, end, res, fleet, by_type


def open_estimate(rows, live):
    """Ledger estimate of this month's research spend: closed rows + running ones."""
    start, _ = month_bounds()
    total = 0.0
    live_by_id = {str(i["id"]): i for i in live}
    for r in rows:
        if r["created_utc"][:7] != start.isoformat()[:7]:
            continue
        if r["status"] == "closed":
            total += float(r["est_usd"] or 0)
        else:
            i = live_by_id.get(r["instance_id"])
            if i:
                hours = max(0.0, time.time() - float(i.get("start_date") or time.time())) / 3600
                total += hours * float(i.get("dph_total") or r["dph"] or 0)
    return total


def budget_check(projected_usd):
    c = credit()
    if c < CREDIT_FLOOR:
        sys.exit(f"REFUSED: account credit ${c:.2f} is below the ${CREDIT_FLOOR:.0f} floor (the fleet shares it).")
    _, end, invoiced, _, _ = month_spend()
    est = open_estimate(read_ledger(), research_instances())
    mtd = max(invoiced, est)
    days_left = (end - now().date()).days
    ceiling = CAP_USD - (RESERVE_USD if days_left <= 7 else 0.0)
    if mtd + projected_usd > ceiling:
        sys.exit(f"REFUSED: month-to-date ${mtd:.2f} + projected ${projected_usd:.2f} exceeds "
                 f"${ceiling:.2f} (cap ${CAP_USD:.0f}, reserve ${RESERVE_USD:.0f} in the last 7 days).")
    print(f"budget ok: credit ${c:.2f}, month-to-date ${mtd:.2f} (invoiced ${invoiced:.2f}), "
          f"projected +${projected_usd:.2f}, ceiling ${ceiling:.2f}")


def cmd_credit(a):
    print(f"credit ${credit():.2f}")


def cmd_offers(a):
    q = DEFAULT_QUERY
    if a.gpu:
        q += f' gpu_name="{a.gpu}"'
    if a.max_dph:
        q += f" dph_total<{a.max_dph}"
    if a.query:
        q += " " + a.query
    args = ["search", "offers", "-o", "dph_total", q]
    if a.bid:
        args += ["--type", "bid"]
    else:
        args += ["--type", "on-demand"]
    offers = vast(*args)[: a.n]
    print(f"{'id':>10} {'gpu':<22} {'$/h':>6} {'cuda':>5} {'rel':>5} {'down':>6} {'cores':>5}  cpu / geo")
    for o in offers:
        print(f"{o['id']:>10} {o.get('gpu_name',''):<22} {o.get('dph_total',0):>6.3f} {o.get('cuda_max_good',0):>5} "
              f"{o.get('reliability2',o.get('reliability',0)):>5.2f} {o.get('inet_down',0):>6.0f} {o.get('cpu_cores_effective',0):>5.0f}  "
              f"{str(o.get('cpu_name',''))[:28]} / {o.get('geolocation','')}")


def find_offers(a):
    """Candidate offers, cheapest first: a given id (looked up client-side, since the
    API has no id filter) or the cheapest offers for --gpu under --max-dph."""
    q = DEFAULT_QUERY
    if a.gpu:
        q += f' gpu_name="{a.gpu}"'
    if a.max_dph:
        q += f" dph_total<{a.max_dph}"
    if getattr(a, "query", ""):
        q += " " + a.query
    typ = "bid" if a.bid else "on-demand"
    offers = vast("search", "offers", "-o", "dph_total", q, "--type", typ)
    if a.offer:
        return [o for o in offers if str(o["id"]) == str(a.offer)]
    return offers[:5]


def cmd_create(a):
    if not a.offer and not a.gpu:
        sys.exit("give an offer id or --gpu NAME")
    label = PREFIX + a.name
    cands = find_offers(a)
    if not cands:
        sys.exit("no matching offer (ids go stale within minutes; prefer --gpu NAME --max-dph D)")
    ttl_s = int(a.ttl_hours * 3600)
    body = a.onstart_cmd or "sleep infinity"
    onstart = f"( sleep {ttl_s}; {SELF_DESTROY} ) & {body}"
    last_err = None
    for offer in cands[:3]:
        dph = float(a.bid) if a.bid else float(offer["dph_total"])
        budget_check(dph * a.ttl_hours * 1.25)   # 25 % headroom for disk and bandwidth
        args = ["create", "instance", str(offer["id"]), "--image", a.image, "--disk", str(a.disk),
                "--label", label, "--ssh", "--cancel-unavail", "--onstart-cmd", onstart]
        if a.bid:
            args += ["--bid_price", str(a.bid)]
        p = subprocess.run(["vastai", *args, "--raw"], capture_output=True, text=True, timeout=120)
        try:
            r = json.loads(p.stdout) if p.stdout.strip() else {}
        except json.JSONDecodeError:
            r = {}
        iid = r.get("new_contract") or r.get("id")
        if p.returncode != 0 or not iid:
            last_err = (p.stderr.strip() or p.stdout.strip())[:300]
            print(f"offer {offer['id']} failed ({last_err}); trying the next")
            continue
        rows = read_ledger()
        rows.append({"created_utc": now().strftime("%Y-%m-%dT%H:%M:%SZ"), "instance_id": str(iid), "label": label,
                     "offer_id": str(offer["id"]), "gpu": offer.get("gpu_name", ""), "dph": f"{dph:.4f}",
                     "ttl_h": f"{a.ttl_hours:g}", "purpose": a.purpose or "", "status": "open",
                     "closed_utc": "", "est_usd": "", "note": ""})
        write_ledger(rows)
        print(f"created instance {iid} ({label}, {offer.get('gpu_name')}, ${dph:.3f}/h, TTL {a.ttl_hours:g} h, "
              f"{offer.get('geolocation','')}). `vast.py ssh {iid}` once it is running.")
        return
    sys.exit(f"all candidate offers failed: {last_err}")


def cmd_list(a):
    live = research_instances()
    if not live:
        print("no research instances")
        return
    for i in live:
        hours = max(0.0, time.time() - float(i.get("start_date") or time.time())) / 3600
        print(f"{i['id']} {i.get('label')} {i.get('gpu_name')} m{i.get('machine_id')} {i.get('actual_status')} "
              f"age {hours:.2f} h  ${float(i.get('dph_total') or 0):.3f}/h  ~${hours*float(i.get('dph_total') or 0):.2f}  "
              f"ssh -p {i.get('ssh_port')} root@{i.get('ssh_host')}")


def cmd_ssh(a):
    i = next((i for i in research_instances() if str(i["id"]) == str(a.id)), None)
    if not i:
        sys.exit(f"{a.id} is not a research instance")
    print(f"ssh -o StrictHostKeyChecking=no -p {i['ssh_port']} root@{i['ssh_host']}")


def close_row(rows, iid, est, note):
    for r in rows:
        if r["instance_id"] == str(iid) and r["status"] != "closed":
            r.update(status="closed", closed_utc=now().strftime("%Y-%m-%dT%H:%M:%SZ"),
                     est_usd=f"{est:.3f}", note=(r["note"] + " " + note).strip())


def destroy(iid):
    vast("destroy", "instance", str(iid), "-y", raw=False)


def cmd_destroy(a):
    live = research_instances()
    targets = live if a.id == "all" else [i for i in live if str(i["id"]) == str(a.id)]
    if not targets:
        sys.exit("nothing to destroy (research-labelled instances only)")
    rows = read_ledger()
    for i in targets:
        hours = max(0.0, time.time() - float(i.get("start_date") or time.time())) / 3600
        destroy(i["id"])
        close_row(rows, i["id"], hours * float(i.get("dph_total") or 0), "destroyed by hand")
        print(f"destroyed {i['id']} ({i.get('label')}) after {hours:.2f} h")
    write_ledger(rows)


def cmd_reconcile(a):
    rows = read_ledger()
    live = research_instances()
    known = {r["instance_id"]: r for r in rows}
    live_ids = set()
    for i in live:
        iid = str(i["id"])
        live_ids.add(iid)
        hours = max(0.0, time.time() - float(i.get("start_date") or time.time())) / 3600
        est = hours * float(i.get("dph_total") or 0)
        r = known.get(iid)
        if r is None:
            destroy(iid)
            rows.append({"created_utc": "", "instance_id": iid, "label": i.get("label", ""), "offer_id": "",
                         "gpu": i.get("gpu_name", ""), "dph": f"{float(i.get('dph_total') or 0):.4f}", "ttl_h": "",
                         "purpose": "", "status": "closed", "closed_utc": now().strftime("%Y-%m-%dT%H:%M:%SZ"),
                         "est_usd": f"{est:.3f}", "note": "ORPHAN destroyed by reconcile"})
            print(f"ORPHAN {iid} ({i.get('label')}) destroyed after {hours:.2f} h")
            continue
        ttl = float(r["ttl_h"] or DEFAULT_TTL_H)
        if hours > ttl + GRACE_MIN / 60:
            destroy(iid)
            close_row(rows, iid, est, f"past TTL ({hours:.2f} h > {ttl:g} h) destroyed by reconcile")
            print(f"EXPIRED {iid} ({r['label']}) destroyed after {hours:.2f} h (TTL {ttl:g} h)")
        else:
            print(f"live {iid} ({r['label']}) {hours:.2f}/{ttl:g} h ~${est:.2f}")
    for r in rows:
        if r["status"] == "open" and r["instance_id"] not in live_ids:
            ttl = float(r["ttl_h"] or DEFAULT_TTL_H)
            close_row(rows, r["instance_id"], ttl * float(r["dph"] or 0), "vanished; charged at TTL x dph until invoiced")
            print(f"closed {r['instance_id']} ({r['label']}): gone (self-destroyed or preempted)")
    write_ledger(rows)
    start, end, invoiced, fleet, by_type = month_spend()
    est = open_estimate(rows, live)
    c = credit()
    days_left = (end - now().date()).days
    print(f"\n{start:%Y-%m}: research invoiced ${invoiced:.2f} ({', '.join(f'{k} ${v:.2f}' for k, v in sorted(by_type.items()))}); "
          f"ledger estimate ${est:.2f}; cap ${CAP_USD:.0f}; {days_left} days left; fleet invoiced ${fleet:.2f}; credit ${c:.2f}")
    if c < CREDIT_FLOOR:
        print(f"WARNING: credit ${c:.2f} below the ${CREDIT_FLOOR:.0f} floor: no rentals; tell the user.")
    if max(invoiced, est) > 0.8 * CAP_USD:
        print("WARNING: over 80 % of the monthly cap.")


def cmd_month(a):
    start, end, res, fleet, by_type = month_spend(a.ym)
    print(f"{start:%Y-%m}: research ${res:.2f} ({', '.join(f'{k} ${v:.2f}' for k, v in sorted(by_type.items()))}), "
          f"fleet ${fleet:.2f}, cap ${CAP_USD:.0f}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    s = p.add_subparsers(dest="cmd", required=True)
    s.add_parser("credit").set_defaults(f=cmd_credit)
    o = s.add_parser("offers"); o.set_defaults(f=cmd_offers)
    o.add_argument("--gpu"); o.add_argument("--max-dph", type=float); o.add_argument("--bid", action="store_true")
    o.add_argument("--query", default=""); o.add_argument("-n", type=int, default=15)
    c = s.add_parser("create"); c.set_defaults(f=cmd_create)
    c.add_argument("offer", nargs="?"); c.add_argument("--gpu"); c.add_argument("--query", default=""); c.add_argument("--max-dph", type=float); c.add_argument("--name", required=True); c.add_argument("--ttl-hours", type=float, default=DEFAULT_TTL_H)
    c.add_argument("--image", default=DEFAULT_IMAGE); c.add_argument("--disk", type=int, default=16)
    c.add_argument("--onstart-cmd", default=""); c.add_argument("--bid", type=float); c.add_argument("--purpose", default="")
    s.add_parser("list").set_defaults(f=cmd_list)
    sh = s.add_parser("ssh"); sh.add_argument("id"); sh.set_defaults(f=cmd_ssh)
    d = s.add_parser("destroy"); d.add_argument("id"); d.set_defaults(f=cmd_destroy)
    s.add_parser("reconcile").set_defaults(f=cmd_reconcile)
    m = s.add_parser("month"); m.add_argument("ym", nargs="?"); m.set_defaults(f=cmd_month)
    a = p.parse_args()
    a.f(a)


if __name__ == "__main__":
    main()
