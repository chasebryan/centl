# Hunt seeds

Each hunt has its own cursor. `current.json` is the default hunt (`main`). Sibling hunts live beside it as `h-<start>.json` or `w-<pid>.json`. Starting `--from` or `--random` creates or resumes a sibling. It does not overwrite `current.json`.

- `hunt_id` — name of this hunt
- `lane` — hunts that share a start factor share a lane and claim distinct windows
- `start_factor` — where this hunt began
- `scanned_through` — the last integer this hunt has looked at
- `cleared_through` — the last bound whose hard primes all have checked witnesses

The next interval is claimed from the lane so two processes do not scan the same stretch.

Letter numbers do not depend on any field in these files.
