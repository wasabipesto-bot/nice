#!/usr/bin/env python3
"""Mutants of Scratch::enter (the carry/reset rule), applied to a copy of the
branch tree for the L2 test. Usage: mutants.py <tree> <reset|back|id>"""
import sys
p = sys.argv[1] + '/common/src/cpu_join.rs'
s = open(p).read()
m = sys.argv[2]
if m == 'reset':  # forgets to reset: keeps the old entries on every path
    old = '''        if !carry {
            self.next.clear();
            self.next.resize(len, 0);
        }'''
    new = '''        let _ = carry;
        self.next.resize(len, 0);'''
elif m == 'back':  # carries the state to a retry or an earlier partition
    old = 'Some((last_id, last)) if last_id == id && last < v => (true, v - last <= RUN_GAP),'
    new = 'Some((last_id, last)) if last_id == id && last != v => (true, v.wrapping_sub(last) <= RUN_GAP),'
elif m == 'id':  # carries the state into another join
    old = 'Some((last_id, last)) if last_id == id && last < v => (true, v - last <= RUN_GAP),'
    new = 'Some((_last_id, last)) if last < v => (true, v - last <= RUN_GAP),'
assert s.count(old) == 1, m
open(p, 'w').write(s.replace(old, new))
print('mutant', m, p)
