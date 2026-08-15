# Current research frontier

**Date:** 2026-08-15  
**Claim boundary:** Erdős--Straus remains open. Universal López Type A/B coverage remains open. Universal DSC-0 and DSC-P are false by explicit hosted-verified counterexample. The new signed-box results below are exact reformulations and obstruction theorems, not a complete proof.

## 1. DSC is closed as the main route

The exact reduced-parameter condition is

\[
\gcd(r+Ls,LQ)=1,
\]

not `gcd(s,Q)=1`; see `REDUCED-PARAMETER-DOMAIN.md`.

`DSC-COUNTEREXAMPLE.md` gives explicit directly novel but collectively union-shadowed candidates. Therefore

\[
\boxed{\mathrm{DSC\!\!-0}\text{ is false}},
\qquad
\boxed{\mathrm{DSC\!\!-P}\text{ is false}}.
\]

The finite shadow certificates and the strong/weak/pointwise `q=3` theorems remain valid local structure, but DSC is no longer the main Erdős--Straus bridge.

---

## 2. Exact prime Erdős--Straus reformulation

The direct route now uses the complete standard prime Type-I/Type-II parametrization.

For a prime

\[
p\equiv1\pmod4
\]

and a positive shift

\[
k\equiv3\pmod4,
\qquad
\gcd(k,p)=1,
\]

put

\[
C_k=\frac{p+k}{4}
=\prod_i r_i^{e_i}
\]

and define the signed divisor box

\[
\boxed{
\mathcal R_k(C_k)
=
\left\{
\prod_i r_i^{z_i}\pmod k:
-e_i\le z_i\le e_i
\right\}.}
\]

`ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md` proves the exact equivalence

\[
\boxed{
 p\text{ satisfies Erdős--Straus}
\iff
\exists k\equiv3\pmod4,\ \gcd(k,p)=1:
\{-p^{-1},-1\}\cap\mathcal R_k(C_k)\ne\varnothing.}
\]

The two targets are precisely the standard solution types:

\[
\boxed{\tau_I=-p^{-1}}
\]

for Type I, and

\[
\boxed{\tau_{II}=-1}
\]

for Type II.

Because the signed box is inversion-symmetric,

\[
-p^{-1}\in\mathcal R_k(C_k)
\iff
-p\in\mathcal R_k(C_k).
\]

Therefore an unsolved fixed shift must avoid the three natural residues

\[
\boxed{-p^{-1},\quad -p,\quad -1,}
\]

where the first two are the two orientations of the same Type-I ratio.

This is now the primary direct-ES coordinate system.

---

## 3. Consequence for López Type A/B

Universal López Type A/B coverage is still a strong and mathematically valuable conjecture, but it is **not logically required** for the shortest direct proof of Erdős--Straus.

The direct proof can work in the complete Type-I/Type-II signed-box formulation above. López-all-primes and the zero-density Type-A/B composite-rescue core remain a parallel research track.

---

## 4. External nonresidue prime shifts

Let `p` be Mordell-hard and choose an external quadratic-nonresidue prime

\[
q<p,
\qquad
q\equiv3\pmod4,
\qquad
\left(\frac qp\right)=-1.
\]

Put

\[
C_q=\frac{p+q}{4},
\qquad
G_q=(\mathbb Z/q\mathbb Z)^\times,
\]

and let

\[
H=\operatorname{Stab}(\mathcal R_q(C_q)),
\qquad
n=[G_q:H].
\]

`FAB-TWO-TARGET-KNESER.md` proves that if both exact solution targets miss, then:

1. `n` cannot be odd, because every odd-index stabilizer contains `-1`, which is the Type-II target;
2. `n` cannot be `2`, because the Type-I target lies in the quadratic-residue subgroup;
3. hence
   \[
   \boxed{n\ge6\text{ and }n\text{ is even};}
   \]
4. the three excluded residues `-p^{-1}`, `-p`, and `-1` occupy three distinct `H`-cosets;
5. Kneser's theorem therefore gives the strengthened symmetric budget
   \[
   \boxed{
   \sum_i
   \left(
   \min(2e_i+1,\operatorname{ord}_{G_q/H}(r_iH))-1
   \right)
   \le n-4.}
   \]

Thus every odd-index Type-I defect is automatically rescued by Type II at the same shift. The former cubic/fifth/seventh-power defect hierarchy is not the direct ES wall.

---

## 5. First surviving prime-shift defect: index six

At

\[
n=6,
\]

the symmetric Kneser budget is only

\[
\boxed{\sum_i(s_i-1)\le2.}
\]

`FAB-INDEX6-COMBINED-DEFECT.md` classifies this case exactly.

A combined index-six failure forces

\[
\boxed{
C_q=\frac{p+q}{4}=rS
}
\]

with:

1. exactly one prime factor `r` outside the sixth-power subgroup `G_q^6`;
2. `v_r(C_q)=1`;
3. `rG_q^6` generates `G_q/G_q^6\cong C_6`;
4. every prime factor of `S` is a sixth-power residue modulo `q`;
5. `r` is both a quadratic and cubic nonresidue modulo `q`;
6. shifted-nonresidue transfer makes `r` the **unique** external quadratic-nonresidue prime factor relative to `p`;
7. the external factor graph therefore has the forced edge
   \[
   \boxed{q\longrightarrow r;}
   \]
8. the quotient signed box occupies exactly `0,±1`, while the three excluded natural targets occupy exactly `±2,3`.

Thus the first surviving obstruction is a **single primitive sextic defect**, not an uncontrolled index-six factorization pattern.

---

## 6. Forced successor with r = 3 mod 4

If the unique exceptional successor satisfies

\[
r\equiv3\pmod4,
\]

then `k=r` is itself another admissible prime shift.

The next goal in this branch is to compare the primitive sextic defect at `q` with the exact two-target Kneser structure at `r` and prove that compatible primitive defects cannot persist around the finite external-nonresidue factor cycle.

Finite experiments show that one can have more than one consecutive index-six step, so a one-edge contradiction is too strong. The theorem must use cycle-level or monotonic defect information.

---

## 7. Forced successor with r = 1 mod 4

If instead

\[
r\equiv1\pmod4,
\]

the prime shift `r` is not admissible. The natural next shift is

\[
\boxed{k=3r.}
\]

`ES-COMPOSITE-SUCCESSOR-3R.md` proves that this composite shift is still clean.

Put

\[
C=\frac{p+3r}{4}.
\]

Since `p\equiv1 mod3`, one has

\[
C\equiv1\pmod3.
\]

CRT splits the signed box modulo `3r` into a mod-`3` parity bit and a prime-`r` residue coordinate. Define the negative-parity fibre

\[
\mathcal R_r^-(C)
=
\left\{
\prod_i s_i^{z_i}\pmod r:
-e_i\le z_i\le e_i,
\quad
\prod_i (s_i\bmod3)^{z_i}=-1
\right\}.
\]

All three natural excluded residues are `-1 mod3`, and the exact fixed-shift criterion becomes

\[
\boxed{
 k=3r\text{ solves }p
\iff
\mathcal R_r^-(C)\cap\{-p^{-1},-1\}\ne\varnothing.}
\]

Thus the composite successor is only a **prime-r divisor-placement problem plus one parity bit**.

### Empty-fibre theorem

\[
\boxed{
\mathcal R_r^-(C)=\varnothing
\iff
\text{every prime factor of }C\text{ is }1\pmod3.}
\]

So the first composite-successor obstruction is exactly Eisenstein splitting.

### Index-two theorem

Let

\[
\widetilde G=(\mathbb Z/3r\mathbb Z)^\times
\]

and `H` be the stabilizer of the full signed box.

Odd stabilizer index again cannot support a combined failure because it forces `-1\in H` and therefore a Type-II hit.

If a combined failure has stabilizer index `2`, then necessarily

\[
\boxed{H=\ker(\text{mod-3 parity})}
\]

and

\[
\boxed{
\text{every prime factor of }
\frac{p+3r}{4}
\text{ is }1\pmod3.}
\]

Therefore **every non-Eisenstein-split `3r` successor automatically eliminates index two** and must move to a finer even quotient if it still fails.

---

## 8. Closed and retained theorem stack

| Result | File |
|---|---|
| Exact prime two-target signed-box equivalence | `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md` |
| Normalized Type-II target | `FAB-TYPE-II-SIGNED-DIVISOR.md` |
| Coprime FAB divisor criterion | `FAB-COPRIME-DIVISOR-CRITERION.md` |
| Fixed-k signed divisor box | `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md` |
| One-target Kneser defect theorem | `FAB-KNESER-DIVISOR-DEFECT.md` |
| Symmetric combined Kneser collapse | `FAB-TWO-TARGET-KNESER.md` |
| Primitive index-six defect theorem | `FAB-INDEX6-COMBINED-DEFECT.md` |
| External nonresidue factor cycle | `EXTERNAL-NR-FACTOR-CYCLE.md` |
| Composite `3r` successor theorem | `ES-COMPOSITE-SUCCESSOR-3R.md` |
| Shifted-factor descent / norm bridge | `FAB-SHIFTED-FACTOR-DESCENT.md` |
| GCD-square reformulation | `FAB-GCD-SQUARE-CRITERION.md` |
| Hard-prime first factor filters | `FAB-HARD-FIRST-FILTERS.md` |
| Prime-modulus Type A/B backbone | `PRIME-MODULUS-BACKBONE.md` |
| Type A/B composite-rescue core | `COMPOSITE-CORE.md` |
| Strong/weak/pointwise q=3 shadow results | parent q=3 theorem notes |

---

## 9. Research priorities

### A. Direct Erdős--Straus track: highest priority

1. Treat `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md` as the primary exact statement.
2. Choose external nonresidue shifts and apply the symmetric `n-4` Kneser budget.
3. Attack the primitive sextic index-six defect.
4. For a forced successor `r≡3 mod4`, seek a cycle invariant preventing persistent primitive sextic defects.
5. For `r≡1 mod4`, use the exact `3r` parity-fibre theorem:
   - eliminate the Eisenstein-split empty-fibre branch, or
   - classify the first even defect above index two in the non-split branch.
6. If index six cannot persist, iterate the same argument at the next possible even quotient.
7. After prime coverage, use the standard divisor/scaling reduction for composite `n`.

### B. López Type A/B track

Continue the all-prime Type A/B problem and the zero-density composite-rescue core as a parallel route. It remains potentially powerful but is not imposed as a prerequisite for direct ES.

### C. Depth-spectrum / shadow track

Continue the covering-core and hypergraph theory after the universal DSC falsification. Preserve strong/weak/pointwise absorption and finite exact-depth certificates as independent mathematical results.

---

## 10. Immediate theorem target

The proof search has now reduced to a two-branch forced-successor problem:

\[
\boxed{
\begin{array}{ll}
r\equiv3\pmod4:&
\text{primitive sextic defect cycle obstruction},\\[1mm]
r\equiv1\pmod4:&
\text{Eisenstein split or finer-even-defect obstruction at }3r.
\end{array}}
\]

The most promising next move is to extract a monotone or reciprocity-sensitive invariant from these successor transitions rather than enumerate more unrelated shifts.

## One-line status

**Prime Erdős--Straus is now exactly a two-target signed-divisor-box problem; external nonresidue shifts collapse every odd Kneser defect, index six reduces to one forced sextic prime, and the awkward `1 mod 4` successor reduces exactly to a prime-modulus box with one parity bit.**
