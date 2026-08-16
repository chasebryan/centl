# CBX finite Lane-I K certificate — 10,000,000

**Status:** exact finite computational certificate  
**Date:** 2026-08-15  
**Kernel:** `cbx.kernel 0.1.0`  
**Finite domain:** Mordell-hard primes `p <= 10,000,000`  
**Certified coordinate:** signed-box Lane-I ceiling `K_I`  
**Result:** `K_I^min = 107` on the stated finite domain  
**Witness:** `p = 8,803,369`  
**Primary platform:** Fedora-family GNU/Linux  
**Underlying exact census:** `CBX-LANE-I-DEEP-CENSUS-10M.md`  
**Claim boundary:** this is a finite Lane-I certificate. It is not a universal K(p) law, not the minimum complete CBX grade, not automatically the minimum shared cbis scalar K, and not a proof of Erdős–Straus.

---

## 1. Statement

Let

\[
H_{10^7}
=
\{p\le10^7:\ p\text{ is a Mordell-hard prime}\}.
\]

For each `p` define the minimal Lane-I signed-box first-hit depth

\[
k_I^*(p)
=
\min\left\{
 k\equiv3\pmod4:
 \delta_k\!\left(\frac{p+k}{4}\right)=0
\right\}.
\]

The exact finite census contains

\[
|H_{10^7}|=20,513
\]

and every target has a Lane-I hit.

The maximum first-hit depth is

\[
\boxed{
\max_{p\in H_{10^7}}k_I^*(p)=107.
}
\]

Therefore the minimal admissible Lane-I ceiling sufficient for the entire finite hard-prime domain is

\[
\boxed{
K_I^{\min}(10^7)=107.
}
\]

---

## 2. Sufficiency

The exact ordered Lane-I census gives

\[
\boxed{20,513/20,513}
\]

hard primes covered by shifts through 107.

Equivalently,

\[
\forall p\in H_{10^7},
\qquad
k_I^*(p)\le107.
\]

Thus

\[
\boxed{K_I=107\text{ is sufficient on }H_{10^7}.}
\]

This is not inferred from a percentage or random sample. The p-major, target-gated C-major, and shift-major engines agree exactly on the complete finite `p -> k_I^*(p)` map.

---

## 3. Minimality

The admissible ceilings occur at

\[
3,7,11,\ldots
\]

because Lane I uses `k ≡ 3 mod 4`.

The unique finite record target is

\[
\boxed{p=8,803,369}
\]

with

\[
\boxed{k_I^*(8,803,369)=107.}
\]

Therefore this prime has no Lane-I hit at any admissible shift

\[
k\le103.
\]

So

\[
\boxed{K_I=103\text{ is insufficient}.}
\]

Since 103 is the immediately preceding admissible ceiling, sufficiency at 107 and failure at 103 prove the exact finite minimality statement

\[
\boxed{K_I^{\min}(10^7)=107.}
\]

---

## 4. The witness gauntlet

The record prime gives more information than merely the endpoint.

After the ordered cover reaches `k=59`, every other hard prime through 10M has already been captured. The only survivor is

\[
p=8,803,369.
\]

It then fails every admissible shift

\[
63,67,71,75,79,83,87,91,95,99,103
\]

and succeeds at 107.

Thus the finite certificate includes the explicit vacancy pattern

\[
\delta_k\!\left(\frac{8,803,369+k}{4}\right)>0
\]

for each

\[
k\in\{63,67,71,75,79,83,87,91,95,99,103\},
\]

followed by

\[
\delta_{107}\!\left(\frac{8,803,369+107}{4}\right)=0.
\]

This is the concrete obstruction pattern that any theorem explaining the finite record must account for.

---

## 5. Why this is not “the cbis K”

The original `cbis.kernel 1.2.0` operator exposes one scalar `K`, but that scalar is consumed by two different lanes:

- Lane I signed-box recognition;
- Lane L López Type A/B layers.

CBX separates the finite grade into

\[
\Gamma=(F,K_I,E_N,A_L).
\]

The certificate in this note concerns only

\[
\boxed{K_I}.
\]

It does **not** establish that a complete cbis/CBX grade with shared scalar `K=107` is minimal, because:

1. W can solve targets before Lane I;
2. N has its own independent depth coordinate;
3. L has its own independent layer ceiling;
4. changing a shared scalar affects both I and L simultaneously.

Therefore the scientifically clean statement is

> 107 is the exact minimal finite Lane-I signed-box ceiling for all Mordell-hard primes through 10,000,000.

Anything stronger requires a separate grade-minimality analysis.

---

## 6. Relation to adaptive K

This certificate realizes one of the natural ideas identified in the original K research note:

> determine a minimal K already known to be sufficient below the current frontier.

For Lane I and the 10M finite hard-prime frontier, that object now exists exactly:

\[
\boxed{K_I^{\min}(10^7)=107.}
\]

But one finite frontier value does not determine an adaptive law.

The research sequence remains:

1. compute `K_I^min(X)` on successively larger exact domains;
2. track record primes and record first-hit depths;
3. fit candidate envelopes only as hypotheses;
4. actively falsify those envelopes on stronger fixed-K corpora;
5. seek a defect/spectrum theorem that forces an actual bound.

An empirical sequence

\[
X\mapsto K_I^{\min}(X)
\]

is data. A proved function

\[
K_I(p)
\]

is mathematics. CBX keeps those claim levels separate.

---

## 7. Reproducible command

CBX includes a dedicated certificate command:

```sh
./centl es cbx certify-i \
  --hi 10000000 \
  --i-max 400 \
  --segment 1000000 \
  --json
```

The command:

1. builds the exact p-major first-hit map;
2. independently builds and verifies the shift-major first-hit map;
3. requires exact hit-map equality;
4. requires exact residual-set equality;
5. checks whether the tested ceiling leaves any finite residual;
6. computes the maximum exact first-hit depth;
7. records every target realizing that maximum;
8. hashes the canonical hit and residual sets.

If the residual set is empty, then

\[
\max_p k_I^*(p)
\]

is sufficient on the finite domain, and a target whose first hit equals that maximum witnesses the insufficiency of every smaller admissible ceiling.

---

## 8. Provenance

The underlying publication-grade finite map is preserved by the deep 10M Lane-I census:

```text
GitHub Actions run: 31928217803
artifact id:        9258483327
artifact name:      cbx-fedora-X10000000-K160-2ca47f56179b2364f5d5ca9b8f765df1c6b94cf3
archive digest:     sha256:be4574b1662bc856265233b8a95ce53afb1e67c61f1a6716824368be4a30b678
```

Its canonical exact first-hit map has SHA-256

```text
0355a90d4956a6023514f7d1fad2d4767ac32cb41c29ac5075e7484061863b15
```

and contains the unique depth-107 witness `8,803,369`.

A separate Fedora `certify-i` workflow exists to regenerate the finite certificate independently from the reference engines.

---

Erdős–Straus remains open. This is an exact finite Lane-I ceiling certificate, not a universal bound.