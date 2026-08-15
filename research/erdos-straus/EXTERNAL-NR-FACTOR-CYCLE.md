# External-nonresidue factor cycle

**Status:** proved universal elementary theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-HARD-NONRESIDUE-BRIDGE.md`, `SHIFTED-NONRESIDUE-TRANSFER.md`, `FAB-KNESER-DIVISOR-DEFECT.md`  
**Claim boundary:** constructs a finite descent/cycle graph of external quadratic nonresidue primes for every Mordell-hard prime. It does not by itself force a FAB divisor placement and therefore does not prove Erdős-Straus.

---

## 1. Hard-prime external nonresidue set

Let `p` be a Mordell-hard prime. Then

\[
p\equiv1\pmod8
\]

and

\[
\left(\frac2p\right)
=\left(\frac3p\right)
=\left(\frac5p\right)
=\left(\frac7p\right)=+1.
\]

Define

\[
\boxed{
E_p=
\left\{
q<p:q\text{ prime and }\left(\frac qp\right)=-1
\right\}.
}
\]

### Lemma — E_p is nonempty and begins beyond the hard shield

The set `E_p` is nonempty, and every member satisfies

\[
\boxed{q\ge11.}
\]

### Proof

The quadratic character modulo `p` is nontrivial, so there is a positive integer `n<p` with

\[
\left(\frac np\right)=-1.
\]

Factor `n`. The Legendre symbol is multiplicative, so at least one prime divisor `q|n` has odd nonresidue contribution:

\[
\left(\frac qp\right)=-1.
\]

Then `q<=n<p`, so `q in E_p`.

The primes `2,3,5,7` are quadratic residues modulo every Mordell-hard `p`, hence no member of `E_p` can lie in the hard shield. QED.

---

## 2. Positive shifted factor attached to every external nonresidue

For `q in E_p`, define

\[
\boxed{
\sigma(q)=
\begin{cases}
1,&q\equiv3\pmod4,\\
3,&q\equiv1\pmod4,
\end{cases}}
\]

and

\[
\boxed{
A_q=\frac{p+\sigma(q)q}{4}.
}
\]

This is always a positive integer:

- if `q=3 mod4`, then `p+q=0 mod4`;
- if `q=1 mod4`, then `p+3q=0 mod4`.

Because `q<p`, we also have

\[
\boxed{A_q<p.}
\]

Indeed,

\[
A_q<\frac{p+p}{4}=\frac p2
\]

in the `3 mod4` case, while

\[
A_q<\frac{p+3p}{4}=p
\]

in the `1 mod4` case.

Also

\[
\boxed{\gcd(A_q,q)=1,}
\]

because

\[
4A_q\equiv p\pmod q
\]

and `q!=p`.

---

## 3. Every vertex has a distinct outgoing nonresidue factor

Modulo `p`,

\[
4A_q\equiv\sigma(q)q.
\]

Since `4` is a square and the hard prime satisfies

\[
\left(\frac3p\right)=+1,
\]

we obtain

\[
\boxed{
\left(\frac{A_q}{p}\right)
=
\left(\frac{\sigma(q)}p\right)
\left(\frac qp\right)
=-1.
}
\]

Therefore the prime factorization of `A_q` contains at least one prime `r` with odd valuation contribution and

\[
\boxed{\left(\frac rp\right)=-1.}
\]

Because `r|A_q<p`,

\[
\boxed{r<p.}
\]

Because `gcd(A_q,q)=1`,

\[
\boxed{r\ne q.}
\]

Thus

\[
\boxed{r\in E_p\setminus\{q\}.}
\]

### Theorem — external nonresidue factor descent

For every

\[
q\in E_p,
\]

the shifted integer

\[
A_q=\frac{p+\sigma(q)q}{4}
\]

has a prime divisor

\[
\boxed{r\in E_p,\qquad r\ne q.}
\]

No search bound or density statement is used.

---

## 4. Directed graph and cycle theorem

Create a directed graph on the finite vertex set `E_p` by choosing, for each vertex `q`, one prime divisor

\[
f(q)\mid A_q
\]

with

\[
\left(\frac{f(q)}p\right)=-1.
\]

The theorem above guarantees

\[
f(q)\in E_p
\]

and

\[
f(q)\ne q.
\]

Hence every vertex has outdegree one and there are no self-loops.

A finite functional digraph always contains a directed cycle. Since self-loops are absent, every cycle has length at least two.

### Corollary — external nonresidue factor cycle

Every Mordell-hard prime admits distinct external nonresidue primes

\[
q_1,\ldots,q_m,
\qquad m\ge2,
\]

with indices understood cyclically such that

\[
\boxed{
q_{i+1}\mid
\frac{p+\sigma(q_i)q_i}{4}
}
\]

and

\[
\boxed{
\left(\frac{q_i}{p}\right)=-1
\quad\text{for every }i.
}
\]

Equivalently, there are positive integers `c_i` satisfying

\[
\boxed{
p+\sigma(q_i)q_i=4c_iq_{i+1}.}
\]

This is an exact finite cyclic system attached to every hard prime.

---

## 5. Edge character when the source is 3 mod 4

Suppose

\[
q\equiv3\pmod4
\]

and `r` is a nonresidue factor chosen from

\[
A_q=\frac{p+q}{4}.
\]

`SHIFTED-NONRESIDUE-TRANSFER.md` proves factorwise that

\[
\left(\frac rp\right)
=
\left(\frac rq\right).
\]

Since the edge was chosen with `(r/p)=-1`,

\[
\boxed{
q\equiv3\pmod4
\Longrightarrow
\left(\frac rq\right)=-1.
}
\]

Thus every outgoing edge from a `3 mod4` vertex lands on a quadratic nonresidue modulo the source as well as modulo `p`.

---

## 6. Edge character when the source is 1 mod 4

Now suppose

\[
q\equiv1\pmod4
\]

and

\[
r\mid A_q=\frac{p+3q}{4}
\]

is chosen with `(r/p)=-1`.

Modulo `r`,

\[
p\equiv-3q.
\]

Because `p=1 mod4`, reciprocity gives

\[
\left(\frac rp\right)
=
\left(\frac pr\right)
=
\left(\frac{-3q}{r}\right).
\]

Since `q=1 mod4`,

\[
\left(\frac qr\right)=\left(\frac rq\right).
\]

Therefore

\[
-1
=
\left(\frac{-3}{r}\right)
\left(\frac rq\right),
\]

so

\[
\boxed{
q\equiv1\pmod4
\Longrightarrow
\left(\frac rq\right)
=-\left(\frac{-3}{r}\right).
}
\]

This is the exact reciprocity rule on the second edge type.

---

## 7. Two-cycle obstruction in the all-3-mod-4 sector

Suppose two distinct primes

\[
q,r\equiv3\pmod4
\]

formed a two-cycle:

\[
q\to r\to q.
\]

The edge rule would give

\[
\left(\frac rq\right)=-1
\]

and

\[
\left(\frac qr\right)=-1.
\]

But quadratic reciprocity for two `3 mod4` primes gives

\[
\left(\frac rq\right)
=-\left(\frac qr\right),
\]

a contradiction.

Therefore:

### Corollary

\[
\boxed{
\text{No directed 2-cycle can consist of two }3\bmod4\text{ vertices.}
}
\]

So the shortest possible cycles are already constrained by reciprocity.

---

## 8. Relation to the Kneser divisor defect

At a `3 mod4` vertex `q`, the same shifted integer

\[
A_q=\frac{p+q}{4}
\]

is precisely the fixed-k FAB factor box

\[
C_q=\frac{p+q}{4}.
\]

Therefore every such vertex carries two simultaneous structures:

1. a signed divisor product box in `G_q` whose failure has a Kneser quotient defect;
2. an outgoing external-nonresidue prime factor `r|C_q` leading to another vertex of the finite cycle graph.

This gives the desired **entropy-or-descent** framework:

\[
\boxed{
\begin{array}{c}
\text{external nonresidue vertex }q\\
\downarrow\\
\text{FAB divisor box at }C_q\\
\begin{cases}
\text{target hit} &\Rightarrow \text{ES certificate},\\
\text{target miss}&\Rightarrow\text{proper Kneser quotient defect}
\end{cases}\\
\downarrow\\
\text{nonresidue factor edge }q\to r\\
\downarrow\\
\text{finite directed cycle.}
\end{array}
}
\]

A universal proof would follow if one can show that the quotient defect cannot persist consistently around such a cycle.

---

## 9. Next exact target

The first nontrivial defect is the cubic case from `FAB-KNESER-DIVISOR-DEFECT.md`.

At a `3 mod4` vertex with index-three failure:

- every prime factor of `(p+q)/4` is a cubic residue modulo `q`;
- `2` is not a cubic residue modulo `q`;
- every chosen nonresidue factor edge `q->r` therefore has
  \[
  r\in G_q^3
  \quad\text{and}\quad
  \left(\frac rq\right)=-1.
  \]

So the next theorem target is concrete:

\[
\boxed{
\text{prove that cubic-defect edge labels cannot persist around an external-nonresidue cycle,}
}
\]

or show that persistence forces a higher-index defect with strictly smaller Kneser room.

That is now an exact finite-cycle obstruction problem rather than an unbounded search over unrelated auxiliary parameters.
