# Quadratic trap signature and character shield

**Status:** exact theorem note and active proof direction  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. Literature priority for this character formulation inside the present minimal-depth/shadow framework remains under review.

This note records a structural invariant discovered while trying to explain why the Type A/B shadow-cover systems overlap so strongly.

Read with:

- [DIAMOND.md](DIAMOND.md)
- [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md)
- [SHADOW-COVER-GEOMETRY.md](SHADOW-COVER-GEOMETRY.md)
- [SHADOW-KERNEL.md](SHADOW-KERNEL.md)
- [FIBER-SHADOW-KERNEL.md](FIBER-SHADOW-KERNEL.md)

## 1. Type A/B trap sets

For

\[
m_k=4k-1,
\]

write

\[
T_k=\{-e,-4e\pmod{m_k}:e\mid k\}.
\]

A López Type A/B hit at depth `k` is exactly the condition that the integer under study lands in `T_k` modulo `m_k`.

The first result below shows that every such trap lies on the same quadratic-character side of the unit group.

## 2. Quadratic nonresidue theorem

### Theorem

Let `k>=1`, let `e|k`, and put

\[
m=4k-1.
\]

Then

\[
\boxed{
\left(\frac{-e}{m}\right)
=
\left(\frac{-4e}{m}\right)
=-1,
}
\]

where `(a/m)` denotes the Jacobi symbol.

Consequently

\[
\boxed{
T_k\subseteq\{u\in(\mathbb Z/m_k\mathbb Z)^\times:(u/m_k)=-1\}.
}
\]

### Proof

Write

\[
k=ed.
\]

Then

\[
m=4ed-1\equiv3\pmod4
\]

and `gcd(e,m)=1`.

We first prove

\[
\left(\frac e m\right)=1.
\]

Write `e=2^a u` with `u` odd.

If `a>0`, then `8|4e`, hence

\[
m\equiv-1\equiv7\pmod8,
\]

so

\[
\left(\frac2m\right)=1.
\]

For the odd part `u`, Jacobi reciprocity gives, because `m=3 mod 4`,

\[
\left(\frac u m\right)
=
(-1)^{(u-1)/2}
\left(\frac m u\right).
\]

But `m=4ed-1` is congruent to `-1 mod u`, hence

\[
\left(\frac m u\right)
=
\left(\frac{-1}u\right)
=
(-1)^{(u-1)/2}.
\]

Therefore

\[
\left(\frac u m\right)=1.
\]

Together with `(2/m)=1` when the power of two is present, this gives

\[
\left(\frac e m\right)=1.
\]

Since `m=3 mod 4`,

\[
\left(\frac{-1}m\right)=-1,
\]

and since `4` is a square,

\[
\left(\frac4m\right)=1.
\]

Hence

\[
\left(\frac{-e}m\right)
=
\left(\frac{-1}m\right)
\left(\frac e m\right)
=-1,
\]

and

\[
\left(\frac{-4e}m\right)
=
\left(\frac4m\right)
\left(\frac{-e}m\right)
=-1.
\]

QED.

## 3. Immediate interpretation

Type A and Type B traps are not arbitrary unit residues. They are confined to the Jacobi `-1` half of the unit group.

Therefore any unit `x mod m_k` satisfying

\[
\left(\frac{x}{m_k}\right)=+1
\]

is automatically safe from the entire Type A/B trap set `T_k`.

This gives a new way to attack the union-shadow problem: instead of avoiding every exact trap residue separately, try to place the candidate progression on the `+1` quadratic-character side of every earlier modulus.

## 4. Quadratic character shield

Fix an admissible candidate `(k,h,t)` and write its CRT progression as

\[
x\equiv r\pmod L,
\qquad
L=\operatorname{lcm}(840,m_k).
\]

For every odd prime `p|L`, the Legendre sign

\[
\epsilon_p\in\mathbb F_2,
\qquad
\left(\frac rp\right)=(-1)^{\epsilon_p},
\]

is fixed throughout the candidate progression.

For every odd prime `p` dividing some earlier `m_j` but not dividing `L`, introduce a binary variable `z_p`, intended to encode a chosen Legendre sign

\[
\left(\frac xp\right)=(-1)^{z_p}.
\]

For an earlier modulus

\[
m_j=\prod_p p^{a_{j,p}},
\]

its Jacobi sign depends only on the primes whose exponent is odd. To force

\[
\left(\frac{x}{m_j}\right)=+1,
\]

we therefore require the linear equation over `F_2`

\[
\boxed{
\sum_{\substack{p\nmid L\\a_{j,p}\text{ odd}}} z_p
=
\sum_{\substack{p\mid L\\a_{j,p}\text{ odd}}}\epsilon_p
\pmod2.
}
\]

Collect these equations for all `j<k`.

### Character-shield theorem

If this finite linear system over `F_2` is solvable, then the candidate has a reduced avoiding arithmetic progression and hence infinitely many primes of exact Type A/B depth `k`.

### Proof

Choose one nonzero residue `a_p mod p` with Legendre sign `(-1)^{z_p}` for every free prime. By CRT, combine

\[
x\equiv r\pmod L
\]

with

\[
x\equiv a_p\pmod p
\]

for all free primes.

The resulting arithmetic progression is reduced: `r` is already a unit modulo `L` by prime compatibility, and every newly imposed residue `a_p` is nonzero.

By construction, every earlier `m_j` has Jacobi symbol `+1` on the progression. The quadratic nonresidue theorem shows that every element of `T_j` has Jacobi symbol `-1`. Thus no member of the progression can hit any earlier Type A/B trap.

At depth `k`, the congruence `x=t mod m_k` is already fixed by `x=r mod L`, so every member of the progression remains in the target Type A/B trap class.

Dirichlet's theorem on primes in reduced arithmetic progressions therefore gives infinitely many primes whose first Type A/B hit is exactly the target candidate at depth `k`.

QED.

## 5. All-square shield

A particularly simple sufficient condition is obtained by taking

\[
z_p=0
\]

for every free prime, i.e. choosing quadratic-residue local signs everywhere outside `L`.

If every shared prime appearing to odd exponent in an earlier `m_j` already satisfies

\[
\left(\frac rp\right)=+1,
\]

then every earlier Jacobi symbol is automatically `+1` and the character-shield theorem applies.

Equivalently, one may choose `x=1 mod p` for every free prime coordinate.

This produces an especially transparent infinite exact-depth family without searching the enormous parameter period.

## 6. Why this may explain part of the shadow geometry

The raw trap sets looked dense after pullback because hundreds of exact residue constraints can be active simultaneously. The quadratic signature reveals that all those exact traps live inside character-negative regions.

Thus there are now two layers of compression:

1. **exact shadow/fiber compression**, which removes redundant residue constraints;
2. **quadratic character compression**, which can discard an entire earlier layer whenever its Jacobi sign is forced to `+1`.

The remaining obstruction is not an arbitrary covering system. It is the intersection of a divisor-generated exact trap system with a highly structured family of quadratic-character half-spaces.

## 7. Computational program

The companion analyzer `quadratic_trap_signature_analyzer.py` is designed to:

1. recheck the Jacobi `-1` theorem by explicit trap enumeration through the configured finite range;
2. solve the exact `F_2` character-shield system for every directly novel candidate in a certificate bundle;
3. count candidates already proved infinitely exact-depth realizable by the character shield alone;
4. identify the residual **character core** where at least one earlier modulus cannot simultaneously be placed on the Jacobi `+1` side;
5. compare that core with the prime-power and fiber shadow kernels.

The character criterion is sufficient, not necessary. Failure of the linear system does not imply union shadowing. It means only that some earlier layers must be escaped inside their Jacobi `-1` region by using the finer exact trap geometry.

## 8. New proof target

The strongest next question is whether the combination

\[
\boxed{
\text{quadratic character shield}
+
\text{fiber shadow kernel}
}
\]

collapses every directly novel candidate to a uniformly bounded small-prime residual core.

If so, universal DSC-P would reduce to classifying that residual core rather than controlling the full set of hundreds or thousands of earlier congruence layers.

That is now a primary theorem target.