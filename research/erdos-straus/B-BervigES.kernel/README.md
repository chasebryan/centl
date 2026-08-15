# bb.kernel

Also `B-BervigES.kernel`. Python reference stack for `4/n = 1/x + 1/y + 1/z`.

This is the readable full-menu kernel. It coexists with [`../CC.kernel`](../CC.kernel), the fast hard-prime engine. Same mathematics, different job: bb.kernel covers general `n` and the full construction menu; CC.kernel only attacks Mordell-hard primes at C speed.

It does **not** prove the Erdős–Straus conjecture. A solved range is a certificate for those `n` only.

## Layers

| layer | meaning |
|---|---|
| `classical` | even, `3 mod 4`, `2 mod 3`, `5 mod 8` |
| `theorem` | `4p+1`, `p+4`, two-target shifts `3,7,11,15` |
| `window` | coprime `fab(a,b)` with `a,b ≤ 11` |
| `search` | external-nonresidue shifts, later corridor, López A/B |

## Commands

```sh
python3 kernel.py solve 10369
python3 kernel.py hunt --until-proof --max-bound 200000
python3 kernel.py status
python3 verify_kernel.py
python3 verify_findings.py
python3 verify_seed.py
```

From the repo root the live hunt is `./centl es go`.

`solve` and `hunt` prefer CC.kernel when the binary is present, then verify the witness in Python. `--through` still works on the Python menu if CC is unavailable.

`--through classical|theorem|window|search` stops the menu early so the residual of a given layer is visible.
