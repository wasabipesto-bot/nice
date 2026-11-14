#!/usr/bin/env python3
"""add_inv.py FILE: investigation knob (not for the PR): NICE_TEST_ACCOUNT_WARN=1 prints the queue account's error
and returns the hits anyway, so the test's comparison with the host mirror shows whether survivors were lost."""
import sys
p = sys.argv[1]; s = open(p).read()
old = "    queue_complete(base, counts)?;\n"
assert s.count(old) == 1
s = s.replace(old, """    if let Err(e) = queue_complete(base, counts) {
        if std::env::var_os("NICE_TEST_ACCOUNT_WARN").is_some() {
            println!("ACCOUNT {e:#} (words {:?})", &counts[..3.min(counts.len())]);
        } else {
            return Err(e);
        }
    }
""")
open(p, 'w').write(s); print("inv ok")
