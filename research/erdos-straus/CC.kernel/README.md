# CC.kernel

Fast hard-prime engine for the Erdős–Straus residual.

One job: for each Mordell-hard prime, emit an explicit

```text
4/p = 1/x + 1/y + 1/z
```

or report that the declared menu missed. It does not prove the conjecture.

Lives next to [`../bb.kernel`](../bb.kernel) (Python reference stack, also `B-BervigES.kernel`). Same two-target mathematics. bb.kernel covers general `n` and the full menu; this binary only attacks Mordell-hard primes.

## Menu

1. **theorem** — `4p+1`, `p+4`, two-target `k ∈ {3,7,11,15}`
2. **window** — coprime `fab(a,b)` with `a,b ≤ 11`
3. **search** — two-target corridor `k = 4h+3` through `--k-max`, then aligned external-nonresidue shifts

Every hit is an explicit witness: method, `(k,A,B,D,T,kind)` when applicable, and the three denominators.

## Build

```sh
make
./cc-kernel solve 9658489
./cc-kernel residual 200000
./cc-kernel residual 200000 --from 50000 --stream
./cc-kernel hunt --until-proof --start 20000 --max-bound 200000
./cc-kernel status
```

From the repo root, without rebuilding CENTL or touching SCi:

```sh
./centl es solve 1009
./centl es go
./centl es go --random
./centl es letters
./centl es status
```

`./centl es go` is the infinite hunt. It resumes the default cursor, collects letters, and stops when you press Ctrl+C. `--random`, `--from N`, `go N`, and `--from 0` / `--origin` start another hunt at any chosen number without destroying the first. Two `go` processes on the same hunt claim distinct windows. A finished hunt is not a proof. `strike` stays false until a universal certificate exists.
