# Large-prime defect forcing by CRT starvation

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-UNBOUNDED-DEFECT-FORCING.md`, `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `FAB-TWO-TARGET-KNESER.md`, `FAB-KNESER-EVEN-DEFECT-EDGE.md`  
**Imported classical tools:** Chinese remainder theorem and Dirichlet's theorem on primes in reduced arithmetic progressions  
**Claim boundary:** strengthens unbounded-defect forcing by showing that a hypothetical prime counterexample requires failed external shifts whose stabilizer quotients have arbitrarily large least odd prime factor. It does not itself rule out those large-prime defects and therefore does not prove Erdős--Straus.

---

## 1. Setup

Fix a Mordell-hard prime `p` and suppose, for contradiction-program purposes, that `p` is an Erdős--Straus counterexample.

Then every admissible shift misses both exact signed-box targets.

Fix arbitrary integers

\[
\boxed{Y\ge3}
\]

and

\[
\boxed{B\ge1.}
\]

We will construct infinitely many external prime shifts `q` such that the corresponding full-stabilizer defect index

\[
n_q=[(\mathbb Z/q\mathbb Z)^\times:H_q]
\]

satisfies simultaneously:

1. `n_q>B`;
2. no odd prime `s<=Y` divides `n_q`.

Thus every odd prime divisor of `n_q` is greater than `Y`.

---

## 2. Choose a prescribed nonresidue load above the starvation bound

The quadratic character modulo `p` is nontrivial. Choose one nonzero quadratic-nonresidue residue class

\[
a\pmod p.
\]

Dirichlet's theorem supplies infinitely many primes in that class, so there are infinitely many primes `ell` with

\[
\left(\frac\ell p\right)=-1.
\]

Choose distinct such primes

\[
\ell_1,\ldots,\ell_t>Y
\]

and positive exponents

\[
e_1,\ldots,e_t
\]

so that

\[
\boxed{2\sum_{i=1}^t e_i+4>B.}
\]

Put

\[
M=\prod_i\ell_i^{e_i}.
\]

The loaded primes are all larger than `Y`, so they do not overlap the small-prime starvation conditions imposed below.

---

## 3. Starve q-1 of every small odd prime

Let

\[
\mathcal S_Y
=
\{s\le Y:s\text{ is an odd prime},\ s\ne p\}.
\]

For every `s in S_Y`, impose

\[
\boxed{q\equiv2\pmod s.}
\]

This residue is nonzero and is not `1 mod s`, so any resulting prime `q` satisfies

\[
\boxed{s\nmid q-1.}
\]

If `p<=Y`, no extra condition at `p` is needed: the chosen quadratic-nonresidue class `a mod p` is automatically neither `0` nor `1`, since `1` is a quadratic residue. Therefore

\[
p\nmid q-1
\]

as well.

---

## 4. Simultaneously force the nonresidue load into (p+q)/4

Impose the full CRT system

\[
\boxed{
\begin{aligned}
q&\equiv3\pmod4,\\
q&\equiv a\pmod p,\\
q&\equiv-p\pmod{\ell_i^{e_i}}
\qquad(1\le i\le t),\\
q&\equiv2\pmod s
\qquad(s\in\mathcal S_Y).
\end{aligned}}
\]

All moduli are pairwise coprime except for the deliberately omitted duplicate `p` condition, so CRT gives one class modulo

\[
L
=4pM\prod_{s\in\mathcal S_Y}s.
\]

The class is reduced modulo `L`:

- it is odd;
- `a` is nonzero modulo `p`;
- `-p` is nonzero modulo every loaded `ell_i`;
- `2` is nonzero modulo every odd `s`.

Therefore Dirichlet supplies infinitely many primes `q` in this class.

Every such `q` satisfies

\[
q\equiv3\pmod4,
\qquad
\left(\frac qp\right)=-1.
\]

Put

\[
C_q=\frac{p+q}{4}.
\]

As in `ES-UNBOUNDED-DEFECT-FORCING.md`, the congruences

\[
q\equiv-p\pmod{\ell_i^{e_i}}
\]

together with the common factor four imply

\[
\boxed{\ell_i^{e_i}\mid C_q.}
\]

Quadratic reciprocity gives

\[
\boxed{
\left(\frac{\ell_i}{q}\right)
=
\left(\frac{\ell_i}{p}\right)
=-1.
}
\]

Thus the full prescribed load remains visible quadratic-nonresidue valuation at the new prime shift.

---

## 5. The defect index is simultaneously large and small-prime-free

Let

\[
R_q=\mathcal R_q(C_q),
\qquad
H_q=\operatorname{Stab}(R_q),
\qquad
n_q=[(\mathbb Z/q\mathbb Z)^\times:H_q].
\]

Under the hypothetical-counterexample assumption, both exact targets miss.

The external nonresidue Kneser bound gives

\[
n_q
\ge
2E_q(C_q)+4
\ge
2\sum_i e_i+4
>B.
\]

So

\[
\boxed{n_q>B.}
\]

Also

\[
\boxed{n_q\mid q-1}
\]

because the ambient unit group modulo prime `q` has order `q-1`.

For every odd prime `s<=Y`, the CRT starvation conditions give

\[
s\nmid q-1.
\]

Hence

\[
\boxed{s\nmid n_q.}
\]

Since `q=3 mod4`,

\[
v_2(q-1)=1.
\]

Every combined failure has even defect index and index two is impossible, so

\[
n_q=2m_q
\]

with

\[
\boxed{m_q>1\text{ odd}.}
\]

Every prime divisor of `m_q` is therefore strictly greater than `Y`.

---

## 6. Theorem — arbitrarily large least odd defect prime

For every pair of bounds `B,Y`, a hypothetical Mordell-hard prime counterexample `p` admits infinitely many external prime shifts `q` such that

\[
\boxed{n_q>B}
\]

and

\[
\boxed{
\min\{\lambda:\lambda\text{ odd prime},\ \lambda\mid n_q\}>Y.
}
\]

Equivalently, the least odd prime factor of the full-stabilizer quotient index is unbounded over the failed external prime shifts.

In particular, no counterexample can be supported by defect indices whose odd parts are built from any fixed finite collection of primes.

---

## 7. Consequences for proof architecture

The earlier unbounded-defect theorem ruled out a bounded list of indices.

The present theorem is stronger. It rules out every model in which the obstruction lives indefinitely inside a fixed finite menu of character orders.

For example, a hypothetical counterexample cannot have all failed external shifts supported only by quotients with odd prime factors among

\[
\{3,5,7,11,13\}
\]

or any other fixed finite set.

For arbitrarily large `Y`, one is forced into a quotient

\[
\boxed{C_{2m}}
\]

whose odd part has no prime factor at most `Y`.

Thus any universal closure theorem must work uniformly across genuinely new high-order character directions.

This makes two kinds of completion strategy especially natural:

1. a **uniform expansion theorem** that is independent of the prime factors of the defect index;
2. a **high-order reciprocity obstruction** showing that the required low-entropy signed boxes cannot persist when the least odd quotient prime tends to infinity.

Finite case-by-case classification of `6,10,14,...` is provably insufficient as a final proof strategy.
