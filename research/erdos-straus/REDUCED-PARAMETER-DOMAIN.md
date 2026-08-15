# Exact reduced-parameter domain for Type A/B pullbacks

**Status:** proved elementary correction / theorem  
**Date:** 2026-08-15  
**Claim boundary:** this corrects the parameter-domain used by the C1/C2/CN shared-factor proof program. It does not by itself prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- `DIRECT-SHADOW-COMPLETENESS.md`
- `C1-THEOREM.md`
- `C2-THEOREM.md`
- `CN-THEOREM.md`
- `CN-SHARED-THEOREM.md`

## 1. Setup

For an admissible target candidate write

\[
x(s)=r+Ls,
\qquad
L=\operatorname{lcm}(840,4k-1).
\]

Let the earlier pullback moduli be `q_j`, and put

\[
Q=\operatorname{lcm}\{q_j:R_j\ne\varnothing\}.
\]

The Dirichlet condition needed for an exact-depth prime progression is

\[
\boxed{\gcd(r+Ls,LQ)=1.}
\]

The parameter itself does **not** need to be a unit modulo `Q`.

Every Type A/B trap residue is coprime to its modulus, and every Mordell-hard class is coprime to `840`. Therefore every admissible CRT base residue satisfies

\[
\boxed{\gcd(r,L)=1.}
\]

## 2. Exact reduced-domain theorem

For every prime `p | Q`:

- if `p | L`, then
  \[
  r+Ls\equiv r\not\equiv0\pmod p
  \]
  for **every** `s`;
- if `p \nmid L`, then `L` is invertible modulo `p`, and
  \[
  p\mid r+Ls
  \iff
  s\equiv-rL^{-1}\pmod p.
  \]

Hence:

### Theorem

Assume `gcd(r,L)=1`. Then

\[
\boxed{
\gcd(r+Ls,LQ)=1
\iff
s\not\equiv -rL^{-1}\pmod p
\text{ for every }p\mid Q\text{ with }p\nmid L.
}
\]

No restriction at all is imposed on the parameter coordinate for primes already dividing `L`.

### Proof

Because `gcd(r,L)=1`, every prime divisor of `L` is automatically excluded from `r+Ls` for all `s`. For a prime `p|Q` with `p\nmid L`, multiplication by `L` is invertible modulo `p`, so exactly one residue class of `s mod p` makes `r+Ls` divisible by `p`. Avoiding those classes for every such prime is equivalent to coprimality with `LQ`. Higher powers of `p` in `Q` do not alter the gcd condition. QED.

Define the exact reduced parameter domain

\[
\mathcal D_{r,L}(Q)
=
\{s\bmod Q:\gcd(r+Ls,LQ)=1\}.
\]

Then

\[
\boxed{
|\mathcal D_{r,L}(Q)|
=Q\prod_{\substack{p\mid Q\\p\nmid L}}
\left(1-\frac1p\right).
}
\]

The old choice `U_Q=(Z/QZ)^*` is generally only an auxiliary subset. It is not the exact Dirichlet domain and should not be called the reduced domain without an additional equivalence proof.

## 3. Why this changes the shared-factor program

The distinction matters in both directions.

### Unit parameter is not necessary

If `p|L`, a parameter divisible by `p` is still perfectly prime-compatible because `r+Ls` is frozen to the nonzero residue `r mod p`.

### Unit parameter is not sufficient in general

If `p\nmid L`, the bad parameter residue is

\[
-rL^{-1}\pmod p,
\]

which need not be `0`. A unit parameter can therefore still make `r+Ls` divisible by `p`.

The correct C1/C2/CN domain is the affine domain `D_{r,L}`, not the multiplicative unit group unless a separate normalization has been proved.

## 4. Immediate 3-adic consequence

For the CENTL/FCF hard-class program,

\[
3\mid840\mid L.
\]

Therefore the exact reduced domain on every `q=3` coordinate is

\[
\boxed{\mathbb Z/3\mathbb Z,}
\]

not `{1,2}`.

Consequently two singleton pullbacks

\[
R_1=\{1\},\qquad R_2=\{2\}
\]

do **not** form a reduced obstruction. The class

\[
\boxed{s\equiv0\pmod3}
\]

avoids both and remains prime-compatible at the prime `3`.

Thus the complementary `q=3` pairs recorded in `CN-SHARED-THEOREM.md` are failures of the **unit-parameter sufficient strategy**, not failures of the actual reduced Dirichlet domain.

The `205 -> 10` absorption theorem remains correct as a shadow theorem, but it is no longer needed to rescue a two-row complementary `q=3` unit cover.

## 5. Correct full-ring lift-room for L-supported coordinates

Suppose `d|q` and every prime dividing `q` already divides `L`. Then the reduced domain modulo `q` is the full residue ring `Z/qZ`.

Reduction modulo `d` has constant fiber size

\[
\boxed{q/d.}
\]

Therefore a forbidden set `R subset Z/qZ` cannot block any residue modulo `d` when

\[
\boxed{|R|<q/d.}
\]

This is the full-ring analogue of the previous totient-ratio lift-room lemma.

For equal moduli `q`, two rows cannot cover the corrected domain whenever

\[
|R_1|+|R_2|<q.
\]

In particular, two singleton `q=3` rows always leave at least one class.

## 6. New 3-adic obstruction threshold

On an `L`-supported `q=3` coordinate, a genuine full local cover requires at least three singleton rows whose union is

\[
\{0,1,2\}.
\]

So the first meaningful 3-adic theorem target is no longer a complementary pair. It is a **three-class cover** and its interaction with direct novelty.

An exploratory corrected-domain scan found the first such hard-compatible three-class pattern at target depth `k=8378`, using rows `j=52,70,106`. Every candidate in that pattern was already directly shadowed by frozen earlier layers `j=6` and `j=12`. This observation must be replayed and independently certified before promotion to a finite theorem record.

## 7. Strategic consequence

The shared-factor program should now be rebuilt in this order:

1. replace `U_Q` by the exact affine domain `D_{r,L}(Q)`;
2. rerun C1/C2/CN falsifiers with exact reducedness;
3. treat primes in `rad(Q) cap rad(L)` as unrestricted parameter coordinates;
4. reserve affine one-class reducedness exclusions only for primes in `rad(Q) \ rad(L)`;
5. re-evaluate the 3/5/7-adic tight cluster, since all three primes already divide `840` and therefore carry **full residue-ring** parameter domains;
6. attack the first possible full 3-adic cover, which requires three classes rather than two;
7. only after this correction restate the universal DSC-P bridge.

## 8. Claim correction

Until the corrected-domain replay is complete:

- do not describe complementary `q=3` unit covers as failures of reduced prime realizability;
- do not use `gcd(s,Q)=1` as an equivalent form of `gcd(r+Ls,LQ)=1`;
- retain the old CN-shared certificates as valid certificates about the **unit-parameter subproblem** only;
- keep the original direct-shadow candidate certificates as authoritative, because those scripts check the correct condition `gcd(r+Ls,LQ)=1` directly.

This correction makes the theorem program stronger, not weaker: it removes an artificial obstruction and aligns the local proof machinery with the exact Dirichlet criterion already used by the primary Direct-Shadow Completeness verifier.
