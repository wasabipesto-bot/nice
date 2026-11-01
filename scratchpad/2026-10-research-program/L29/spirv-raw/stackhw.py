# gdb python: at exit_group (or SIGSEGV), report the DS* thread's stack mapping size, RSS, and depth.
import gdb, collections

def mappings(pid):
    out = []
    cur = None
    for line in open(f'/proc/{pid}/smaps'):
        parts = line.split()
        if '-' in parts[0] and len(parts) >= 5 and not parts[0].endswith(':'):
            a, b = parts[0].split('-')
            cur = [int(a, 16), int(b, 16), 0]
            out.append(cur)
        elif parts[0] == 'Rss:' and cur is not None:
            cur[2] = int(parts[1])
    return out

def report(tag):
    inf = gdb.selected_inferior()
    pid = inf.pid
    maps = mappings(pid)
    for t in inf.threads():
        if t.name and t.name.startswith('DS'):
            t.switch()
            sp = int(gdb.parse_and_eval('$sp'))
            for a, b, rss in maps:
                # the stack grows down; the guard page sits just below the mapping
                if a <= sp < b or (b <= sp + 65536 and sp < b and sp >= a - 65536):
                    print(f'STACKHW {tag} thread={t.name} lwp={t.ptid[1]} map={(b-a)//1024}kB rss={rss}kB sp_depth={(b-sp)//1024}kB')
            # frame histogram
            f = gdb.newest_frame()
            n = 0
            hist = collections.Counter()
            while f is not None:
                n += 1
                nm = f.name() or '??'
                hist[nm.split('<')[0][-90:]] += 1
                f = f.older()
            print(f'FRAMES {tag} thread={t.name} depth={n}')
            for nm, c in hist.most_common(25):
                print(f'  {c:6d} {nm}')

class Report(gdb.Command):
    def __init__(self):
        super().__init__('stackhw', gdb.COMMAND_USER)
    def invoke(self, arg, from_tty):
        report(arg or 'now')
Report()
