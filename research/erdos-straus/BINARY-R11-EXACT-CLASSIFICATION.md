# Exact `r=11` binary rescue classification for Mordell-hard primes

**Status:** proved iff classification  
**Date:** 2026-08-15  
**Depends on:** `BINARY-R-RESCUE.md`, `BINARY-R-DIVISOR-COLLISION.md`  
**Claim boundary:** this completely closes the fixed binary numerator `r=11`. It does not prove that every Mordell-hard prime is rescued at `r=11`, and therefore does not prove Erdős-Straus.

---

## 1. Hard-prime normalization

Let `p` be Mordell-hard. Then

\[
p\equiv1\pmod{24}.
\]

For the binary numerator

\[
\boxed{r=11}
\]

put

\[
A_{11}=\frac{p+11}{4}.
\]

Because `p==1 mod 3`,

\[
3\mid A_{11}.
\]

Write

\[
\boxed{A_{11}=3B,\qquad B=\frac{p+11}{12}.}
\]

Modulo `11`, since `12==1`,

\[
\boxed{B\equiv p\pmod{11}.}
\]

The binary denominator is

\[
N_{11}=pA_{11}=3pB.
\]

By `BINARY-R-DIVISOR-COLLISION.md`, rescue at `r=11` is equivalent to

\[
\boxed{-1\in D_{11}(N_{11})D_{11}(N_{11})^{-1}.}
\]

Equivalently, the signed divisor-exponent box of `N_11` must hit `-1 mod 11`.

---

## 2. Discrete-log coordinates

Use `2` as a primitive root modulo `11`:

\[
\begin{array}{c|cccccccccc}
 e&0&1&2&3&4&5&6&7&8&9\\
 \hline
 2^e\bmod11&1&2&4&8&5&10&9&7&3&6.
\end{array}
\]

Write

\[
\lambda(x)=\log_2(x)\in\mathbb Z/10\mathbb Z.
\]

Then

\[
\lambda(-1)=5,
\qquad
\lambda(3)=8=-2.
\]

Put

\[
\alpha=\lambda(p\bmod11).
\]

Factor

\[
B=\prod_q q^{e_q}
\]

and put

\[
\beta_q=\lambda(q\bmod11).
\]

Because `B==p mod 11`,

\[
\boxed{\sum_q e_q\beta_q\equiv\alpha\pmod{10}.}
\]

The signed-divisor collision exists iff there are

\[
z_3,z_p\in\{-1,0,1\},
\qquad
-e_q\le z_q\le e_q
\]

such that

\[
\boxed{
8z_3+\alpha z_p+\sum_q\beta_qz_q\equiv5\pmod{10}.
}
\]

This single finite cyclic-group equation gives the complete classification below.

---

## 3. Three residue classes are automatic

If

\[
\alpha\in\{3,5,7\},
\]

then the fixed factors `3` and `p` already hit exponent `5`; no factorization information about `B` is needed.

These exponents correspond to

\[
p\bmod11\in\{8,10,7\}.
\]

### Theorem A

If

\[
\boxed{p\equiv7,8,10\pmod{11},}
\]

then `r=11` always rescues `p`.

### Proof

For each `alpha in {3,5,7}`, the set

\[
\{8z_3+\alpha z_p:z_3,z_p\in\{-1,0,1\}\}
\]

contains `5 mod 10`. QED.

---

## 4. Nonzero quadratic-residue classes

The nonzero even exponents are

\[
\alpha\in\{2,4,6,8\},
\]

corresponding to

\[
p\bmod11\in\{4,5,9,3\}.
\]

For every such `alpha`, the fixed factors `3` and `p` generate **all five even exponents**:

\[
\boxed{
\{8z_3+\alpha z_p\}
=\{0,2,4,6,8\}.
}
\]

A prime factor `q|B` is a quadratic nonresidue modulo `11` exactly when `beta_q` is odd. Adding one occurrence of any odd exponent to the full even set hits every odd exponent, in particular `5`.

Conversely, if every prime factor of `B` is a quadratic residue modulo `11`, every signed exponent contribution is even, so exponent `5` is impossible.

### Theorem B

If

\[
\boxed{p\equiv3,4,5,9\pmod{11},}
\]

then

\[
\boxed{
\text{`r=11` rescues `p`}
\iff
B=\frac{p+11}{12}
\text{ has a prime factor that is a quadratic nonresidue mod }11.
}
\]

Equivalently, failure occurs iff every prime factor of `B` belongs to

\[
\boxed{\{1,3,4,5,9\}\pmod{11}.}
\]

---

## 5. The two `±1` exponent classes

Now

\[
\alpha\in\{1,9\},
\]

corresponding to

\[
p\bmod11\in\{2,6\}.
\]

The fixed factors `3,p` produce

\[
\boxed{\{0,1,2,3,7,8,9\},}
\]

missing only `4,5,6`.

Therefore the presence of any prime-factor exponent

\[
\beta_q\in\{2,3,4,5,6,7,8\}
\]

immediately forces rescue.

Suppose no such factor occurs. Then every nontrivial prime factor of `B` has exponent class `1` or `9=-1`; factors of class `0` are inert in the signed box. If the total multiplicity of these `±1` occurrences is at least `2`, their signed contribution can supply `±2`, and the fixed exponent `3` then reaches `5`. Thus failure requires exactly one nontrivial occurrence.

The total-product constraint

\[
B\equiv p\pmod{11}
\]

then fixes its direction.

### Theorem C

If

\[
\boxed{p\equiv2\pmod{11},}
\]

then `r=11` fails **iff**

- exactly one prime-factor occurrence of `B` is `2 mod 11`, with valuation exactly `1`;
- every other prime factor of `B` is `1 mod 11`.

If

\[
\boxed{p\equiv6\pmod{11},}
\]

then `r=11` fails **iff**

- exactly one prime-factor occurrence of `B` is `6 mod 11`, with valuation exactly `1`;
- every other prime factor of `B` is `1 mod 11`.

All other factorizations rescue.

---

## 6. The class `p == 1 mod 11`

Finally let

\[
\boxed{p\equiv1\pmod{11}.}
\]

Then `alpha=0`, so the fixed factor `p` contributes nothing in log coordinates and the factor `3` contributes the symmetric set

\[
\boxed{\{0,2,8\}=\{0,\pm2\}.}
\]

Thus rescue is equivalent to the signed exponent box of `B` meeting

\[
\boxed{\{3,5,7\}.}
\]

because adding `0,±2` must reach target `5`.

There are exactly two ways this can fail.

### Failure family I — entirely quadratic-residue support

If every prime factor of `B` is a quadratic residue modulo `11`, every signed exponent is even, so the odd target set `{3,5,7}` is unreachable.

Thus every factor may lie in

\[
\boxed{\{1,3,4,5,9\}\pmod{11}.}
\]

### Failure family II — one cancelling `2/6` pair

The only nonresidue-support exception that still avoids `{3,5,7}` is:

- one prime-factor occurrence `2 mod 11`, valuation `1`;
- one prime-factor occurrence `6 mod 11`, valuation `1`;
- every other prime factor `1 mod 11`.

Indeed the two nontrivial logs are `+1` and `-1`; their signed box is

\[
\{0,\pm1,\pm2\},
\]

which, after adding `0,±2`, still avoids `5` exactly in this minimal cancelling configuration. Any additional nontrivial occurrence, or any factor from another residue class, expands the signed box into `{3,5,7}` and forces rescue.

The total-product constraint `B==1 mod 11` is automatically respected by the cancelling pair.

### Theorem D

If

\[
\boxed{p\equiv1\pmod{11},}
\]

then `r=11` fails iff exactly one of the following holds:

1. every prime factor of `B` is a quadratic residue modulo `11`; or
2. `B` has exactly one occurrence of a prime `2 mod 11` and exactly one occurrence of a prime `6 mod 11`, each to valuation `1`, and every remaining prime factor is `1 mod 11`.

Every other factorization rescues.

---

## 7. Consolidated classification

Let

\[
\boxed{B=\frac{p+11}{12}.}
\]

For a Mordell-hard prime `p`, fixed binary numerator `r=11` behaves as follows.

| `p mod 11` | Exact `r=11` status |
|---:|---|
| `7,8,10` | **always rescued** |
| `3,4,5,9` | rescued iff `B` has a quadratic-nonresidue prime factor mod `11` |
| `2` | fails iff exactly one `2 mod 11` prime occurrence and all others `1 mod 11` |
| `6` | fails iff exactly one `6 mod 11` prime occurrence and all others `1 mod 11` |
| `1` | fails iff all factors are QR mod `11`, or the unique minimal `2/6` cancelling pair occurs |

This is an iff theorem, not a finite-range pattern.

---

## 8. Independent finite regression

The classification was independently compared against the exact binary-divisor collision test for every Mordell-hard prime below

\[
10^6.
\]

Population:

\[
\boxed{2,370\text{ hard primes}.}
\]

Result:

\[
\boxed{0\text{ classification mismatches}.}
\]

This finite regression is supporting evidence only; the theorem is the cyclic-group proof above.

---

## 9. Research consequence

The first three binary stages are now unusually explicit:

- `r=3`: failure forces every prime factor of `(p+3)/4` onto the `1 mod 3` side;
- `r=7`: failure forces every prime factor of `(p+7)/4` onto the quadratic-residue side modulo `7`;
- `r=11`: failure is now classified exactly by the table above.

Writing

\[
P=\frac{p-1}{4},
\]

these are the consecutive translates

\[
\boxed{P+1,\quad P+2,\quad P+3.}
\]

For hard primes `P` is divisible by `6`. A hypothetical counterexample must therefore make three consecutive translates satisfy three different, exact multiplicative-compression laws.

The next theorem target is no longer “understand r=11.” It is to exploit the simultaneous incompatibility, if any, of the exact `r=3`, `r=7`, and `r=11` failure patterns, and then incorporate `r=19/23` only if genuine survivors remain.
