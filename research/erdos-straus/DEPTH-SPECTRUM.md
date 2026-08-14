# The Type A/B minimal-depth spectrum

**Status:** active research note
**Date:** 2026-08-14
**Claim boundary:** the theorems below are elementary consequences of the Type A/B congruence system, CRT, and Dirichlet's theorem. The terminology and organization are part of the CENTL/FCF research program; no literature-priority claim is made here without a separate prior-art review.

## 1. Minimal Type A/B depth

For a prime `p`, define

\[
C_{AB}(p)=\min\{k\ge1:\exists e\mid k,\ p\equiv-e\text{ or }-4e\pmod{4k-1}\},
\]

with `C_AB(p)=infinity` when no Type A/B witness exists.

Write

\[
m_k=4k-1,
\qquad
T_k=\{-e,-4e\pmod{m_k}:e\mid k\}.
\]

Then `C_AB(p)=k` exactly when

\[
p\bmod m_k\in T_k
\]

and

\[
p\bmod m_j\notin T_j\qquad(1\le j<k).
\]

The Mordell hard residue classes used here are

\[
H=\{1,121,169,289,361,529\}\pmod{840}.
\]

## 2. Exact candidate progression

Fix a layer `k`, hard class `h in H`, and a unit trap residue `t in T_k` compatible with `h` modulo `gcd(840,m_k)`.

CRT gives a progression

\[
x\equiv r\pmod L,
\qquad
L=\operatorname{lcm}(840,m_k),
\]

that simultaneously enforces

\[
x\equiv h\pmod{840},
\qquad
x\equiv t\pmod{m_k}.
\]

Write every integer in this progression as

\[
x=r+Ls.
\]

For each earlier layer `j<k`, put

\[
g_j=\gcd(L,m_j),
\qquad
q_j=\frac{m_j}{g_j}.
\]

The earlier hit condition induces a finite forbidden set

\[
R_j\subseteq\mathbb Z/q_j\mathbb Z
\]

such that

\[
r+Ls\bmod m_j\in T_j
\quad\Longleftrightarrow\quad
s\bmod q_j\in R_j.
\]

Thus the entire minimal-depth problem for this candidate becomes a finite congruence-avoidance problem in the single parameter `s`.

## 3. Exact depth-realization theorem

Let

\[
Q=\operatorname{lcm}\{q_j:1\le j<k,\ R_j\ne\varnothing\}.
\]

Suppose there exists `s0` such that

\[
s_0\bmod q_j\notin R_j\qquad\text{for every }j<k
\]

and

\[
\gcd(r+Ls_0,LQ)=1.
\]

Then every integer in the progression

\[
p=r+Ls_0+LQz
\]

avoids every earlier Type A/B layer and hits layer `k`.

Because the residue is coprime to the modulus, Dirichlet's theorem gives infinitely many primes in this progression. Consequently,

\[
\boxed{\text{infinitely many primes }p\equiv h\pmod{840}\text{ satisfy }C_{AB}(p)=k.}
\]

### Converse

If infinitely many primes in the fixed `(k,h,t)` candidate have minimal depth `k`, then at least one of their parameter residues modulo `Q` is an avoiding residue coprime to `LQ`. Therefore the criterion above is also necessary for infinite prime realization of that fixed candidate.

This converts a question about an infinite prime population into a finite modular decision problem.

## 4. The hard-class depth spectrum

Define

\[
\mathcal D_H=\{k:\text{infinitely many primes }p\bmod840\in H\text{ have }C_{AB}(p)=k\}.
\]

A layer can fail to enter this spectrum for at least two immediately detectable reasons:

1. it has no prime-compatible hard-class trap candidate;
2. every admissible candidate is already forced into an earlier Type A/B layer.

The second phenomenon is the congruence-shadow structure studied elsewhere in this directory.

The new realization theorem supplies the positive side: an explicit avoiding parameter class with the coprimality condition is a certificate that the layer belongs to `D_H`.

## 5. The k=104 anomaly resolves

The finite hard-prime sweep through `10^7` had a striking pattern. Among the zero-first-hit layers through `k=109`, every layer except `k=104` was already explained by either absence of admissible hard-prime candidates or complete direct shadowing.

Layer `104` was the lone apparent hole.

For `k=104`,

\[
m_{104}=415.
\]

Take

\[
h=169,
\qquad
t=399.
\]

Since

\[
399\equiv-4\cdot4\pmod{415},
\]

this is a Type A trap with

\[
d=4,
\qquad n=26,
\qquad dn=104.
\]

CRT gives

\[
r=19489,
\qquad
L=69720.
\]

The parameter

\[
s_0=158
\]

avoids every Type A/B layer `j<104`, and produces

\[
\boxed{p=19489+69720\cdot158=11035249.}
\]

Direct deterministic checking gives

\[
\boxed{p=11035249\text{ is prime and }C_{AB}(p)=104.}
\]

It is in the hard class

\[
p\equiv169\pmod{840}
\]

and

\[
p\equiv399\pmod{415}.
\]

The full parameter-period certificate uses

\[
Q=
1657066545168047912667733918921197871682681719068608922730379418987341668019768388986313127431496215
\]

and

\[
M=LQ=
115530679529116300471194408827185915613716569453463414092762053091797461094338252080125751244523916109800.
\]

Moreover,

\[
\gcd(11035249,M)=1.
\]

Therefore Dirichlet gives the stronger statement

\[
\boxed{\text{infinitely many primes have }C_{AB}(p)=104.}
\]

The absence of depth `104` in the earlier `10^7` data was therefore a finite-range effect, not structural impossibility. The first hard-class occurrence in an exhaustive sieve through `11035249` is exactly `11035249`, just beyond the previous cutoff.

## 6. Exact Erdős-Straus witness for p=11035249

For the Type A congruence

\[
p\equiv-4d\pmod{4dn-1}
\]

with `d=4`, `n=26`, write

\[
p=(4dn-1)q-4d=415q-16.
\]

For `p=11035249`,

\[
q=26591.
\]

Set

\[
u=nq-1=691365,
\qquad
v=np=286916474.
\]

The Type A solution `(du,dv,duv)` is

\[
\boxed{x=2765460},
\]

\[
\boxed{y=1147665896},
\]

\[
\boxed{z=793456032188040}.
\]

Hence

\[
\boxed{
\frac4{11035249}
=
\frac1{2765460}
+
\frac1{1147665896}
+
\frac1{793456032188040}
}.
\]

CENTL separately certifies this exact rational identity in `depth-spectrum-contracts.centl`.

## 7. Computational spectrum result through k=300

The accompanying `depth_spectrum_probe.py` performs exact modular checks for the hard classes. In the current experiment through `k=300`:

- `66` layers have no admissible hard-prime candidate;
- `39` layers have admissible candidates but every one is completely directly shadowed by an earlier layer;
- the remaining `195` layers all receive an explicit Dirichlet realization certificate with an avoiding parameter `s <= 5000`.

So, through `k=300`, every layer not already killed by the two simplest structural obstructions is explicitly certified as infinitely prime-realizable in the hard classes.

This is a finite computational theorem-certificate result, not a proof that the same dichotomy holds for every `k`.

## 8. Research target

The emerging object is no longer merely a list of difficult primes. It is the **minimal Type A/B depth spectrum** and its obstruction theory.

The immediate questions are:

- Is complete congruence shadowing the only obstruction to membership in `D_H` once prime compatibility is imposed?
- Can every non-shadowed candidate be shown to contain a reduced avoiding class without search?
- Is there a structural characterization of the complement of `D_H`?
- Can the shadow graph be quotiented to an irreducible congruence sieve whose vertices are exactly the prime-realizable depths?
- What asymptotic information about `C_AB(p)` follows from the density and geometry of these realizable depth classes?

A proof of a general realization criterion beyond finite computation would turn the empirical shadow picture into a theorem about the support of minimal Type A/B witnesses.
