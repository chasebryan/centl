# Six exact nonresidue detectors at d = 3, 7, 15

**Status:** proved exact theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-RECIPROCAL-SIGNED-TARGET.md`, `FAB-RECIPROCAL-CHARACTER-TRANSPORT.md`, `FAB-RECIPROCAL-M7-CLASSIFICATION.md`, `FAB-NONRESIDUE-DETECTOR-TRIAD.md`  
**Claim boundary:** this identifies six exact local detectors. It does not prove that one detector fires for every Mordell-hard prime.

## 1. Paired forms

Let `p` be a Mordell-hard prime. For

\[
d\in\{3,7,15\}
\]

define

\[
\boxed{
X_d=\frac{p+d}{4},
\qquad
Y_d=\frac{pd+1}{4}.
}
\]

The forward fixed-`d` fab lane uses the signed target `-p mod d` in the bounded signed divisor set of `X_d`. The reciprocal fixed-`d` lane uses the constant signed target `-1 mod d` in the bounded signed divisor set of `Y_d`.

The character-transport theorem gives, for every prime factor `r` of either form,

\[
\boxed{
\left(\frac r p\right)=\left(\frac r d\right),
}
\]

with Jacobi symbol for `d=15`.

Thus it remains only to classify the exact finite signed-product failure states.

## 2. d = 3

A hard prime satisfies

\[
p\equiv1\pmod3.
\]

The unit group modulo `3` is `{1,2}` and its Jacobi-positive kernel is `{1}`.

Both the forward and reciprocal target are `-1=2 mod3`. Therefore either lane fails exactly when all prime factors of the corresponding base are `1 mod3`.

Hence

\[
\boxed{
\begin{aligned}
\text{forward }d=3\text{ succeeds}
&\iff X_3\text{ contains a }p\text{-nonresidue prime factor},\\
\text{reciprocal }d=3\text{ succeeds}
&\iff Y_3\text{ contains a }p\text{-nonresidue prime factor}.
\end{aligned}}
\]

## 3. d = 7

Since every hard prime is `1 mod8`, both

\[
X_7=\frac{p+7}{4}
\qquad\text{and}\qquad
Y_7=\frac{7p+1}{4}
\]

are even. Thus each factorization contains at least one occurrence of residue `2 mod7`.

Starting with that forced occurrence, the exact signed-state calculation in the six-element unit group gives the following table.

| lane | `p mod 7` | forced total residue | forbidden target | unique failure reach set |
|---|---:|---:|---:|---|
| forward | 1 | 2 | 6 | `{1,2,4}` |
| forward | 2 | 4 | 5 | `{1,2,4}` |
| forward | 4 | 1 | 3 | `{1,2,4}` |
| reciprocal | any | 2 | 6 | `{1,2,4}` |

The set

\[
\boxed{\{1,2,4\}}
\]

is exactly the quadratic-residue subgroup modulo `7`.

Therefore all exceptional formal failure atoms from the unrestricted `m=7` classification disappear once the forced factor `2` is included.

Consequently both lanes satisfy

\[
\boxed{
\text{lane at }d=7\text{ succeeds}
\iff
\text{its base contains a prime }r
\text{ with }
\left(\frac r7\right)=-1.
}
\]

By character transport this is equivalent to `(r/p)=-1`.

## 4. d = 15

Again `p=1 mod8` forces both `X_15` and `Y_15` to be even, so residue `2 mod15` occurs in each factorization.

The Jacobi-positive kernel modulo `15` is

\[
\boxed{H_{15}=\{1,2,4,8\}.}
\]

Hard primes occupy only

\[
p\bmod15\in\{1,4\}.
\]

After inserting the forced factor `2`, exact enumeration of the eight-element unit group gives:

| lane | `p mod 15` | forced total residue | forbidden target | unique failure reach set |
|---|---:|---:|---:|---|
| forward | 1 | 4 | 14 | `H_15` |
| forward | 4 | 1 | 11 | `H_15` |
| reciprocal | any | 4 | 14 | `H_15` |

Thus every other formal failure kernel is destroyed by the forced factor `2`.

Therefore

\[
\boxed{
\text{lane at }d=15\text{ succeeds}
\iff
\text{its base contains a prime }r
\text{ with }
\left(\frac r{15}\right)=-1.
}
\]

Character transport again converts this exactly to `(r/p)=-1`.

## 5. Six-form detector theorem

Combining the cases proves:

### Theorem

Let `p` be a Mordell-hard prime. For each

\[
\boxed{d\in\{3,7,15\}}
\]

and for each of the paired forms

\[
\boxed{
X_d=\frac{p+d}{4},
\qquad
Y_d=\frac{pd+1}{4},
}
\]

the corresponding exact fab lane succeeds **if and only if** its base has a prime divisor `r` satisfying

\[
\boxed{
\left(\frac r p\right)=-1.
}
\]

Equivalently, a hypothetical Mordell-hard prime counterexample must make every prime factor of all six integers

\[
\boxed{
\frac{p+3}{4},
\frac{3p+1}{4},
\frac{p+7}{4},
\frac{7p+1}{4},
\frac{p+15}{4},
\frac{15p+1}{4}
}
\]

a quadratic residue modulo `p`.

## 6. Pairwise support is almost disjoint

For `d,e=3 mod4`, the paired forms satisfy

\[
\boxed{
X_d-X_e=\frac{d-e}{4},
}
\]

\[
\boxed{
Y_d-Y_e=\frac{p(d-e)}4,
}
\]

and, because every `Y_d` is coprime to `p`,

\[
\boxed{
\gcd(Y_d,Y_e)\mid\frac{|d-e|}{4}.
}
\]

Also

\[
\boxed{
eX_d-Y_e=\frac{de-1}{4},}
\]

so

\[
\boxed{
\gcd(X_d,Y_e)\mid\frac{de-1}{4}.
}
\]

For the six detector forms, every pairwise common prime divisor is therefore confined to a small constant independent of `p`.

The obstruction is no longer one integer accidentally factoring into residue primes. A counterexample would require six largely independent short linear forms to do so simultaneously.

## 7. Finite signal is not the theorem

A finite replay shows that the six detectors alone are **not** sufficient on all tested hard primes; there are finite survivors. Therefore no universal claim is made for the six-form set itself.

The theorem is the exact equivalence between each lane and the presence of a `p`-nonresidue prime factor. The next step is to extend this detector mechanism adaptively, preferably from the least external nonresidue of `p`, rather than merely append more fixed moduli.
