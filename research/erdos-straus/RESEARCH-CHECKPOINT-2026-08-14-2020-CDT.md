# Crash-safe research checkpoint — 2026-08-14 20:20 CDT

**Project:** Free Computation Foundation / CENTL  
**Coordinator:** Operator-01 / primary research lead  
**Partner:** Operator-02  
**Canonical rule:** repository state is authoritative; chat and local scratch state are disposable.  
**Global claim boundary:** Erdős-Straus remains open. Universal López Type A/B coverage remains open. Universal DSC-P remains open. Full C1 remains open.

## 1. Recovery chain

Read in this order after any crash:

1. [`FUTURE-OPERATOR-INSTRUCTIONS.md`](FUTURE-OPERATOR-INSTRUCTIONS.md)
2. [`OPERATOR-COORDINATION.md`](OPERATOR-COORDINATION.md)
3. [`C1-PARTIAL-THEOREMS.md`](C1-PARTIAL-THEOREMS.md)
4. [`SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md`](SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md)
5. [`CLASS-C-CENSUS-K1500.md`](CLASS-C-CENSUS-K1500.md)
6. [`ANCESTRY-DIVISOR-CHILD-THEOREM.md`](ANCESTRY-DIVISOR-CHILD-THEOREM.md)
7. [`ANCESTRY-ASYMPTOTIC-SKELETON.md`](ANCESTRY-ASYMPTOTIC-SKELETON.md)
8. [`ODD-PRIME-SHIFT-ASYMPTOTIC-RIGIDITY.md`](ODD-PRIME-SHIFT-ASYMPTOTIC-RIGIDITY.md)
9. [`DIAMOND.md`](DIAMOND.md)
10. [`ERDOS-STRAUS-WALL.md`](ERDOS-STRAUS-WALL.md)

## 2. Finite candidatewise frontier

Completed `k<=1500` all-stage direct-shadow run:

```text
workflow run: 31849103304
head:         c508994fb48e6f701f15577352f275df5646cd78
artifact:     9238241616
artifact sha256:
e181a66bec9a8e0d68b4b6b46892b6c71c50ebe8ab64c45944c8c17408c983dd
```

Exact counts:

```text
admissible candidates:             73,814
directly shadowed:                 20,574
directly novel:                    53,240
integer avoiding witnesses:        53,240
reduced avoiding witnesses:        53,240
unresolved reduced:                     0
independent verifier:              VERIFIED
```

All 53,240 are also closed in this finite range by exact fiber peeling plus selector menu `0,±1,...,±64`, maximum radius `54`.

## 3. Class-C / C1 census provenance

Replay-only Class-C workflow:

```text
workflow run: 31854324273
head:         d330e20082297d21f3005f5a173eaebfdc40ea9b
artifact:     9238613961
artifact sha256:
9ba6c7425356dac272821a71b677811ed697c3dd062040cf78302b5f272031ba
independent verifier: VERIFIED
```

C1 counts:

```text
single-active candidates:                       2,770
fiber-empty:                                    1,290
fiber-nonempty:                                 1,480
active fixed-negative row survives final kernel:   18
nonfixed residual edge incidences:             69,672
bounded selector solved:                  1,480/1,480
maximum selector radius:                          48
```

Smallest residual signatures:

```text
{11,13}:       2
{3,11,13}:   336
```

The two `{11,13}` systems are now primary C1 proof laboratories.

## 4. Hard single-active finite collapse

Two-construction exact falsifier through `k<=100000`:

```text
workflow run: 31854964168
artifact:     9238743256
artifact sha256:
f390c20afe0c8fc97d9046c34117f4e0b2c8e56f255d6a31c732b337d16d2159
```

Exact finite result:

```text
hard-compatible target candidates: 8,021,288
single-active candidates:             419,123
q=3:                                  252,832
q=5:                                    4,173
q=9:                                  162,118
other q:                                    0
Class B:                                    0
independent construction: VERIFIED
```

This is finite-certified only. No universal `q in {3,5,9}` theorem is currently claimed.

## 5. Universal C1 theorems that survive review

### Unique-active excess prime-power theorem

\[
\boxed{|N^{act}|=1\Longrightarrow q=p\text{ or }p^2.}
\]

If the excess is Class B (`p∤L`), then necessarily `q=p^2`.

### Exact pullback injection

For compatible traps

\[
U=\{t\in T_j:t\equiv r\pmod g\},
\]

the affine pullback to parameter classes modulo `q=m/g` is a bijection onto the forbidden parameter set `R`:

\[
\boxed{|R|=|U|.}
\]

### Universal reduced local escape

For `|N^{act}|=1`, the unique active fixed-negative row always admits an exact reduced local escape.

Class A: reducedness is fixed because `p|L`.

Class B: `q=p^2`, `p>=11`, and

\[
|R|\le\frac{p^2+3}{2}<p^2-p,
\]

so `R` cannot cover every reduced parameter class.

Therefore:

\[
\boxed{
\text{the unique active fixed-negative row is never itself a reduced covering obstruction.}
}
\]

The remaining C1 difficulty is simultaneous compatibility with surviving nonfixed exact rows.

## 6. Correct reduced-parameter formula

Reducedness is a condition on

\[
x=r+Ls,
\]

not on `gcd(s,q)`.

For a row modulus quotient `q`, the number of parameter classes modulo `q` reduced at every prime dividing `q` is

\[
\boxed{
A(q,L)
=q\prod_{\substack{p\mid q\\p\nmid L}}
(1-1/p).
}
\]

The old use of `phi(q)` as the general reduced-parameter count is superseded.

## 7. Retracted proof attempts

### First-shell / hard 3-5-9 universal proof

Retracted. The failed step assumed arbitrary `d u^2` in a squarefree tower inherited a negative Jacobi sign. This requires `gcd(r,u)=1` and was not established for unrelated comparison shells.

Canonical file:

[`SINGLE-ACTIVE-FIRST-SHELL-THEOREM.md`](SINGLE-ACTIVE-FIRST-SHELL-THEOREM.md)

Status: `REVISE / RETRACTED PROOF`.

The earlier `q=p or p^2` theorem is unaffected because it only removes factors from the actual active square parameter.

### All-j odd-prime-shift rigidity

False. Counterexample:

\[
r=17,\quad j=2,\quad K=121=11^2,\quad m=7,
\]

with every divisor of `121` reducing into `S_2={1,2,4}`.

Canonical corrected file:

[`QUOTIENT-ODD-PRIME-S-RIGIDITY.md`](QUOTIENT-ODD-PRIME-S-RIGIDITY.md)

Status: retracted all-j statement.

The valid theorem is the large-ancestor version below.

## 8. Ancestry theorems now canonical

### Divisor-child theorem

For shift `s`, quotient `Q=4s+1`, child `K=Qj-s`:

\[
\boxed{
a\mid\gcd(j,s),\ K=ap,\ p\text{ prime}
\Longrightarrow T_K\bmod(4j-1)\subseteq T_j.}
\]

### Asymptotic skeleton

For `j>=s+1`, every external prime factor is at least `m=4j-1` while `K<m^2`, so at most one external prime exists.

For odd `s`, every nonsmooth full-shadow child is

\[
\boxed{K=ap,\qquad a\mid\gcd(j,s),\ p\text{ prime}.}
\]

### Odd-prime-shift rigidity outside the exception strip

For an odd prime `r`, no primality assumption on `4r+1` is needed:

\[
\boxed{
j\ge r+1
\Longrightarrow
T_K\bmod(4j-1)\subseteq T_j
\iff K\text{ prime or }K=rp.}
\]

The small strip `j<=r` is a genuine exception problem.

### Exact quotient classifications

```text
Q=5,  s=1: prime only
Q=9,  s=2: prime, 2p, plus (j,K)=(2,16)
Q=13, s=3: prime, 3p
Q=17, s=4: prime, 2p, 4p, plus (j,K)=(4,64)
Q=21, s=5: prime, 5p
Q=29, s=7: prime, 7p
```

The q21 and q29 parent proofs have been rewritten using the clean general skeleton plus exact finite windows.

## 9. Operator-02 accepted contributions

Accepted/promoted:

- active fixed-negative core `N^act` formulation;
- valuation-excess criterion;
- q13 exact classification;
- q17 exact classification;
- q21 pattern/source work, with canonical parent proof independently replaced;
- mixed-box support-2 finite evidence through `j<=50000`;
- multiplicative defect and zero-product atom adversarial review.

Not promoted as universal theorem:

- the former Operator-02 all-j odd-prime-shift file;
- signature-coset exact-equivalence language;
- any finite support-2 or hard-collapse pattern.

## 10. Current C1 wall

The active row is locally beaten.

The remaining obstruction is:

\[
\boxed{
\text{prove that the surviving nonfixed exact rows cannot jointly eliminate every}
\text{ parameter compatible with the active-row escape.}
}
\]

Finite diagnostics already show:

- nominal residual cover mass exceeds `1` in every nonempty C1 kernel;
- naive union bound therefore proves none;
- a naive asymmetric Lovász Local Lemma probe certifies none;
- residual edges have support size only `1,2,3` in the `k<=1500` C1 bundle;
- the residual graph can nevertheless be dense.

So the next invariant should be a **conditioned fiber / variable-elimination invariant**, not another global density estimate.

## 11. Immediate targets

### C1-A: `{11,13}`

Two exact systems, both target `k=574`, hard class `169`, active `j0=319`, `q=5`, active pullback empty.

Residual period:

\[
11^3 13^2=224,939.
\]

Each has `54,990` reduced safe residues.

After pure 11-adic constraints and reducedness, `725` values modulo `11^3` remain. Conditional 13-adic safe fiber sizes are always `65` or `78`:

```text
605 * 78 + 120 * 65 = 54,990.
```

Goal: derive these positive fiber sizes algebraically and identify the exact structural reason.

### C1-B: `{3,11,13}`

Occurs `336` times. Lift the conditioned-fiber theorem after C1-A.

### Ancestry exception strip

Classify `j<=r` for odd-prime shifts. Dyadic ancestors must be handled through the existing Mersenne trap lattice rather than rediscovered.

### Mixed-box support-2

Prove or falsify Operator-02's finite pattern.

## 12. Publication status

The public research page has been corrected to:

- state the `j>=r+1` boundary for the uniform odd-prime theorem;
- acknowledge genuine small-ancestor exceptions;
- replace the obsolete local C1 gap with the proved unique-active reduced-escape theorem;
- keep the hard `q in {3,5,9}` result explicitly finite-certified;
- retain the statement that Erdős-Straus, López universal coverage, universal DSC-P, and full C1 remain open.

No important result should exist only in chat after this checkpoint.
