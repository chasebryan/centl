# Proof ledger

CC.kernel is the theorem/attack provider. It may only set `strike: true` when a universal certificate is deposited here.

Current machine status is `ledger/status.json`.

A finished hunt, an empty finite residual, or a cleared bound is **not** a proof of Erdős–Straus. Those events keep `proof_status: "open"` and `strike: false`.
