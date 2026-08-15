# Current research frontier

**Date:** 2026-08-15  
**Claim boundary:** Erdős-Straus open; universal DSC-P open; López-all-primes open.

## Correction now governing the shared-factor program

The exact Dirichlet condition is

\[
\gcd(r+Ls,LQ)=1,
\]

not `gcd(s,Q)=1`.

`REDUCED-PARAMETER-DOMAIN.md` proves the exact parameter domain:

- primes `p|Q` already dividing `L` impose **no** restriction on `s`;
- primes `p|Q` with `p∤L` exclude exactly the affine class `s=-rL^{-1} (mod p)`.

Therefore the old complementary `q=3` pair obstruction is only an obstruction inside the auxiliary unit-parameter subset. Since `3|840|L`, the true local domain at `q=3` is all of `Z/3Z`; singleton rows `{1}` and `{2}` leave `s=0`.

## Closed / retained this arc

| Result | File |
|---------|------|
| Ancestry rigidity q=13,17,21,29 | `QUOTIENT-*-RIGIDITY.md` |
| Exact reduced-parameter domain | `REDUCED-PARAMETER-DOMAIN.md` |
| CN-coprime CRT mechanism | `CN-THEOREM.md` (domain bridge must be reread through the correction) |
| Lift-room / totient-ratio machinery | `CN-SHARED-THEOREM.md` (unit-domain version retained as proof-mining asset) |
| `205 -> 10` ancestry absorption | `CN-SHARED-THEOREM.md` |
| Finite candidatewise DSC through `k<=1500` | `DIRECT-SHADOW-K1500.md` |

The original direct-shadow certificates remain authoritative because their verifier checks `gcd(r+Ls,LQ)=1` directly.

## New finite frontier under the corrected domain

Two independent local constructions have been used during this correction pass:

1. tight layers generated from the exact divisor condition `m_j | qL`;
2. every earlier `j` scanned directly and each pullback class enumerated from the defining congruence.

They agree through `k<=8500` on the corrected `q<=9` tight cluster:

- first full corrected-domain tight covers occur at `k=8378`;
- the decisive 3-adic rows are `j=52,70,106`, which cover residues `0,1,2 mod 3`;
- all 12 hard-compatible failures at that target are already directly shadowed by frozen earlier layers `j=6` and `j=12`;
- directly novel corrected-domain tight failures: **0** through the independently replayed range.

The primary probe is `reduced_domain_tight_probe.py`; the independent construction is `verify_reduced_domain_tight.py`. Freeze a formal finite certificate only after the branch workflow replay is green.

## Active edge

1. Replay and independently certify the corrected-domain `q<=9` scan on the branch.
2. Promote the exact affine reduced-domain theorem into C1/C2/CN notation and remove language equating reducedness with parameter units.
3. Prove the first real 3-adic obstruction theorem:
   \[
   R_{j_1}\cup R_{j_2}\cup R_{j_3}=\mathbb Z/3\mathbb Z
   \Longrightarrow
   \text{direct shadow}
   \]
   under hard-compatible admissibility, or find a directly novel counterexample.
4. Generalize corrected lift-room on the `3/5/7`-adic cluster using full residue-ring fibers for primes already in `L`.
5. Re-run the Class-C active-core reduction using the exact affine domain for free primes.
6. Assemble corrected DSC-P only after both exact avoidance and exact Dirichlet reducedness are preserved.
7. López remainder remains separate: density one is not pointwise coverage.

## One-line status

The previous `q=3` complementary-pair bottleneck was an artifact of restricting the parameter to units. The exact reduced domain moves the first possible 3-adic cover to at least three classes; the first observed three-class cover at `k=8378` is already directly shadowed. Universal DSC-P and Erdős-Straus remain open.
