# Current research frontier

**Date:** 2026-08-15  
**Claim boundary:** Erdős-Straus remains open. Universal DSC-0 and DSC-P are false. The strongest current all-prime reduction is the complete coprime `fab` formulation plus the exact Type I sector.

---

## 1. Direct-Shadow Completeness is refuted

The exact Dirichlet condition is

\[
\gcd(r+Ls,LQ)=1,
\]

not `gcd(s,Q)=1`.

After correcting that domain, the program produced and independently verified the explicit directly-novel union shadow in `DSC-COUNTEREXAMPLE.md`:

```text
k = 4,478,950
m = 17,915,799
h = 1
t = 17,892,349
r = 1,236,166,681
L = 5,016,423,720
q=3 core = {25,70,187}
union mask = {0,1,2}
direct-shadow sources = 0
```

Hosted provenance:

```text
run:      31863463072
sha:      566520c0649b30151c1120c902030c8a758844f2
artifact: 9241281418
digest:   sha256:021bb1142fdd5b069ee8492b92405d0e3dcad2ada9647f8e22c8af951b175b91
```

Therefore

\[
\boxed{\text{DSC-0 is false}},
\qquad
\boxed{\text{DSC-P is false}}.
\]

The replacement local object is the **collective core**, formalized in `COLLECTIVE-CORE.md`.

The prototype core

\[
\mathcal C=\{25,70,187\}
\]

is rank three, supported on `q=3`, and load-tight:

\[
\lambda(\mathcal C)=\frac13+\frac13+\frac13=1.
\]

`Q3-COLLECTIVE-SYNTHESIS.md` constructs an infinite arithmetic family carrying this same three-row cover.

---

## 2. Prime reduction removes the composite endgame

`PRIME-REDUCTION.md` proves:

\[
\boxed{
\text{ES for all primes}
\Longrightarrow
\text{ES for all integers }n\ge2.
}
\]

So the true final wall is **all-prime solvability**. There is no separate composite-`n` theorem after the prime case.

---

## 3. Complete divisor-parametrization route

The 2026 `fab` parametrization is now integrated as a second, complete language for prime solutions.

### Coprime completeness

`FAB-COPRIME-COMPLETENESS.md` proves:

\[
\boxed{
\text{prime ES solvability}
\iff
\text{existence of some admissible coprime }(a,b)\text{ `fab` certificate}.
}
\]

The proof uses the published inverse map but orders two scaled solution denominators by `p`-adic valuation. If

\[
g=\gcd(x,y),
\qquad
b=x/g,
\qquad
q=y/g,
\qquad
k=x-p,
\qquad
a=kq-pb,
\]

then

\[
\gcd(a,b)=\gcd(k,b)=\gcd(p,b)=1.
\]

Thus **non-coprime `fab` parameters are universally redundant for prime targets**.

---

## 4. Exact Type I sector

`FAB-TYPE-I-EQUIVALENCE.md` proves:

\[
\boxed{
\text{Type I solution}
\iff
\text{coprime `fab` certificate with }p\nmid a.
}
\]

On this p-primitive sector the complete published admissibility conditions collapse to one divisor congruence:

\[
\boxed{
\gcd(a,b)=1,
\quad
p\nmid a,
\quad
k\mid a+bp,
\quad
k\equiv-p\pmod{4ab}.
}
\]

Equivalently, writing

\[
p+k=4abc,
\]

one has the classical Type I divisor equation

\[
\boxed{k\mid1+4b^2c.}
\]

This is exactly the Elsholtz-Tao Type I variety under the variable crosswalk

\[
(a_{ET},c_{ET},d_{ET},f)
=(b_{fab},a_{fab},c_{fab},k).
\]

---

## 5. Character bridge on the Type I / primitive sector

`FAB-CHARACTER-BRIDGE.md` proves

\[
\left(\frac ck\right)=-1
\]

and

\[
\boxed{
\left(\frac kp\right)
=-\left(\frac ak\right).
}
\]

`FAB-ELEVEN-BARRIER.md` then shows that for a Mordell-hard prime, every certificate with `a` supported only on

\[
\{2,3,5,7\}
\]

has

\[
\left(\frac ak\right)=+1.
\]

Hence `a=11` is the first possible numerator parameter capable of crossing into the positive-target-character mode.

This is a character barrier, not a proof that the universal parameter bound is 11.

---

## 6. Verified Type I frontier through 10^9

`FAB-COPRIME-K1E9.md` freezes two independent exact computations on all Mordell-hard primes below one billion.

Hosted provenance:

```text
run:      31864821526
sha:      ae0e89847642acb550bbbae467c6b0c569aa00e9
artifact: 9241686442
digest:   sha256:37537df7a3bc8f3521c31815db101ee285c0d3ebfcc3d4cca823a20e1bc9dd76
```

Result:

```text
Mordell-hard primes checked: 1,587,581
coprime a,b<=11 survivors:           0
```

Because `a<=11<p` throughout the nontrivial hard range, all of these certificates lie in the p-primitive sector. Therefore:

\[
\boxed{
\text{every Mordell-hard prime below }10^9
\text{ has a Type I solution.}
}
\]

Minimal parameter-box distribution:

```text
C=max(a,b)
1: 776829
2: 592090
3: 198370
4: 15697
5: 4366
6: 169
7: 50
8: 7
9: 2
10: 0
11: 1
```

The unique hard prime in the range requiring `C=11` is

\[
84,525,841
\]

with certificate

\[
(a,b,k,q)=(11,4,71375,4737).
\]

---

## 7. Exact remaining p-adic sector

Coprime completeness does **not** prove that every prime is Type I.

The complete coprime parameter space splits into:

### Sector I

\[
p\nmid a.
\]

This is exactly Type I and is governed by the one-congruence divisor equation above.

### Residual sector

\[
\boxed{p\mid a.}
\]

The parameters can remain coprime because `p∤b`, but the target factor `p` may supply part of the second published divisibility condition. The one-congruence collapse is therefore no longer automatic.

A prime with no Type I solution, if ES is true for it, must be rescued in this residual sector. In classical language, only Type II geometry remains.

---

## 8. Relation to López Type A/B

López Type A and Type B are both proved subclasses of Type II.

Therefore the two active prime programs now have a precise handoff:

\[
\boxed{
\text{Type I: complete primitive coprime divisor plane}
\quad\cup\quad
\text{Type II: López A/B + broader Type II residual}.
}
\]

The program no longer needs to force Type A/B to solve primes that already have Type I solutions.

A sharper possible sufficient theorem is:

\[
\boxed{
\text{every prime without Type I has Type A or Type B}.
}
\]

This is weaker than López's conjecture that every prime has A or B, but is still unproved.

---

## 9. Prior-art audits

Two recent headline proof claims were audited and are **not accepted as complete proofs**:

- `DYACHENKO-2025-AUDIT.md`: false lattice uniqueness / rectangle-hitting statements and an unsupported nonlinear existence step.
- `BRADFORD-2026-AUDIT.md`: the manuscript explicitly reaches the statement that the remaining task is to prove its residue families form a covering system, but does not provide that covering proof.

Their valid algebraic families may still be reused with attribution.

---

## 10. Active theorem edge

### A. Type I universality attack

Determine whether every prime

\[
p\equiv1\pmod4
\]

admits p-primitive coprime parameters, equivalently a Type I solution.

Use the exact equation

\[
\boxed{
p=4abc-k,\qquad k\mid1+4b^2c,\qquad \gcd(a,b)=1.}
\]

Do not confuse the billion-prime finite result with a proof.

### B. Residual Type II handoff

If a Type I obstruction is found or derived, pass it immediately to:

- López Type A/B congruence layers;
- full classical Type II parametrization;
- exact collective-core reductions.

The true combined target is not “A/B for every prime”; it is **Type I or Type II for every prime**, with A/B as a structured Type II rescue.

### C. Collective-core theory

Continue classifying irreducible collective shadows because they are positive coverage certificates inside the Type A/B branch. Do not resurrect DSC.

### D. Character synthesis

Unify the Type I character bridge with the existing Type A/B character/signature machinery. A hypothetical all-prime survivor must evade both character systems simultaneously.

---

## One-line status

Direct-shadow completeness is false, but the prime problem is now more sharply organized: every prime solution has a coprime `fab` representation; the p-primitive coprime sector is exactly Type I and has zero Mordell-hard survivors below `10^9`; any genuine Type I survivor must be rescued by the coprime p-divisible / Type II sector. Erdős-Straus remains open.
