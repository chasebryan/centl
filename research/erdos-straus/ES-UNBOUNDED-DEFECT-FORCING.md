# Unbounded defect forcing from prescribed external nonresidue load

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `FAB-TWO-TARGET-KNESER.md`, `FAB-KNESER-EVEN-DEFECT-EDGE.md`, `FAB-KNESER-FULL-STABILIZER-DEFECT.md`  
**Imported classical tools:** Chinese remainder theorem and Dirichlet's theorem on primes in reduced arithmetic progressions  
**Claim boundary:** this proves that a hypothetical prime counterexample would require arbitrarily large full-stabilizer defect quotients as the auxiliary external prime shift varies. It does not by itself rule out those unbounded defects and therefore does not prove Erdős--Straus.

---

## 1. Setup

Fix a Mordell-hard prime `p` and suppose, for contradiction-program purposes only, that `p` is an Erdős--Straus counterexample.

Then by the exact two-target signed-box equivalence, every admissible shift

\[
k\equiv3\pmod4,
\qquad
\gcd(k,p)=1
\]

misses both targets

\[
-p^{-1}
\qquad\text{and}\qquad
-1.
\]

Let

\[
\ell_1,\ldots,\ell_t
\]

be distinct primes satisfying

\[
\boxed{
\left(\frac{\ell_i}{p}\right)=-1.}
\]

Choose arbitrary positive exponents

\[
e_1,\ldots,e_t.
\]

Put

\[
\boxed{M=\prod_{i=1}^t\ell_i^{e_i}.}
\]

---

## 2. Force the entire prescribed load into one shifted integer

Choose a quadratic nonresidue class

\[
a\pmod p.
\]

By CRT there is a residue class `b` modulo

\[
\boxed{4pM}
\]

satisfying

\[
\boxed{
\begin{aligned}
b&\equiv3\pmod4,\\
b&\equiv a\pmod p,\\
b&\equiv-p\pmod{\ell_i^{e_i}}
\quad(1\le i\le t).
\end{aligned}}
\]

This class is reduced modulo `4pM`:

- it is odd;
- `a` is nonzero modulo `p`;
- `-p` is nonzero modulo every `ell_i` because `ell_i ne p`.

Therefore Dirichlet's theorem gives infinitely many primes

\[
\boxed{q\equiv b\pmod{4pM}.}
\]

Every such prime satisfies

\[
q\equiv3\pmod4
\]

and

\[
\left(\frac qp\right)=-1
\]

because `q≡a mod p`.

Put

\[
\boxed{C_q=\frac{p+q}{4}.}
\]

Since

\[
q\equiv-p\pmod{4\ell_i^{e_i}},
\]

we obtain

\[
\boxed{
\ell_i^{e_i}\mid C_q
\qquad(1\le i\le t).}
\]

Thus any prescribed finite external-nonresidue prime-power load can be inserted into a shifted factorization at infinitely many prime shifts.

---

## 3. The loaded primes remain nonresidues modulo q

For each loaded prime `ell=ell_i`, we have

\[
q\equiv-p\pmod\ell
\]

and `q≡3 mod4`.

Quadratic reciprocity gives

\[
\left(\frac\ell q\right)
=
(-1)^{((\ell-1)/2)((q-1)/2)}
\left(\frac q\ell\right).
\]

Because `(q-1)/2` is odd,

\[
\left(\frac\ell q\right)
=
(-1)^{(\ell-1)/2}
\left(\frac{-p}\ell\right).
\]

Now

\[
\left(\frac{-p}\ell\right)
=
\left(\frac{-1}\ell\right)
\left(\frac p\ell\right)
=
(-1)^{(\ell-1)/2}
\left(\frac p\ell\right).
\]

The two signs cancel. Since `p≡1 mod4`, reciprocity between `p` and `ell` gives

\[
\left(\frac p\ell\right)
=
\left(\frac\ell p\right).
\]

Therefore

\[
\boxed{
\left(\frac{\ell_i}{q}\right)
=
\left(\frac{\ell_i}{p}\right)
=-1.}
\]

So every loaded prime power contributes visible quadratic-nonresidue valuation at the new external prime shift.

---

## 4. Forced lower bound on the defect index

Let

\[
R_q=\mathcal R_q(C_q)
\]

be the exact signed divisor box modulo `q`, and let

\[
H_q=\operatorname{Stab}(R_q),
\qquad
n_q=[(\mathbb Z/q\mathbb Z)^\times:H_q].
\]

Under the hypothetical-counterexample assumption, both exact solution targets miss.

The combined Kneser theorem forces `n_q` to be even, while the external-nonresidue edge theorem gives

\[
\boxed{
n_q\ge2E_q(C_q)+4,}
\]

where

\[
E_q(C_q)
=
\sum_{
 r^e\parallel C_q,
 (r/q)=-1
}e.
\]

The prescribed load gives

\[
E_q(C_q)
\ge
\sum_{i=1}^t e_i.
\]

Hence:

### Theorem — prescribed-load defect bound

For every prime `q` in the Dirichlet family above,

\[
\boxed{
 n_q
\ge
2\sum_{i=1}^t e_i+4.}
\]

Moreover each loaded prime satisfies the full-stabilizer projected-order gap

\[
\boxed{
\operatorname{ord}_{G_q/H_q}(\ell_iH_q)
>2e_i+1.}
\]

Thus the obstruction is forced to expose every prescribed external prime power as a high-order quotient atom.

---

## 5. Unbounded-defect corollary

Take any integer

\[
B\ge1.
\]

Choose the exponents so that

\[
2\sum_i e_i+4>B.
\]

Then the theorem produces infinitely many external prime shifts `q` for which a hypothetical counterexample must have

\[
\boxed{n_q>B.}
\]

Therefore:

### Corollary — no bounded defect model can support a counterexample

If a Mordell-hard prime counterexample exists, then the full-stabilizer quotient indices of its failed external prime shifts are unbounded:

\[
\boxed{
\sup_{
 q\equiv3\ (4),
 (q/p)=-1
}
[(\mathbb Z/q\mathbb Z)^\times:H_q]
=\infty.}
\]

In fact arbitrarily large defect indices occur on infinite Dirichlet families whose shifted factorizations contain any prescribed finite external-nonresidue prime-power load.

---

## 6. Strategic consequence

This theorem rules out a large class of possible proof models.

A hypothetical counterexample cannot be explained by saying that every failed auxiliary shift falls into a fixed finite collection of quotient defects such as

\[
6,10,14,18,\ldots,N.
\]

For every finite ceiling `N`, one can force a new external shift whose visible nonresidue load requires defect index greater than `N`.

Thus the remaining direct proof must exploit something that survives **unbounded quotient complexity**, for example:

1. a global incompatibility among the loaded high-order atoms;
2. reciprocity constraints connecting different forced shifts;
3. analytic information showing that the required low-entropy stabilizer factorizations cannot persist on all such Dirichlet families;
4. a construction of one shift where the prescribed load plus an additional uncontrolled factor necessarily breaks every possible stabilizer.

The theorem therefore redirects the search away from finite classification of defect indices and toward a uniform expansion/reciprocity principle.
