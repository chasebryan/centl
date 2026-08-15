# Hunt seed

`current.json` is a resume cursor, not a random-number seed.

- `start_factor` — where this hunt began (0, a number you chose, or a random integer).
- `scanned_through` — the last integer the engine has looked at.
- `cleared_through` — the last bound whose hard primes all have checked witnesses.

The next interval is `(scanned_through, scanned_through + step]`.

Letter numbers do not depend on any field in this file.
