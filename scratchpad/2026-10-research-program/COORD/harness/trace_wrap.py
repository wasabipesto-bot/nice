#!/usr/bin/env python3
"""Run the coordinator script unchanged, recording how much of each state file is durable.

usage: trace_wrap.py SCRIPT [coordinator args...]   (env COORD_TRACE_DIR = where to record)

Every os.fsync(fd) of a regular file records that file's size at that moment in COORD_TRACE_DIR/<basename>.durable
(overwritten in place, so it stays a few bytes). The harness reads these after a SIGKILL to model a power loss:
everything past the last fsynced size may be lost, in part or whole, at any byte. Nothing else is changed.
"""
import os, runpy, sys

TRACE = os.environ["COORD_TRACE_DIR"]
_real_fsync = os.fsync


def _fsync(fd):
    _real_fsync(fd)
    try:
        path = os.readlink("/proc/self/fd/%d" % fd)
        st = os.fstat(fd)
    except OSError:
        return
    if not os.path.isfile(path) or os.path.dirname(os.path.abspath(path)) == os.path.abspath(TRACE):
        return
    rec = os.path.join(TRACE, os.path.basename(path) + ".durable")
    b = ("%d\n" % st.st_size).encode().ljust(24)
    f = os.open(rec, os.O_WRONLY | os.O_CREAT, 0o644)
    try:
        os.pwrite(f, b, 0)
    finally:
        os.close(f)


os.fsync = _fsync
script = sys.argv[1]
sys.argv = [script] + sys.argv[2:]
runpy.run_path(script, run_name="__main__")
