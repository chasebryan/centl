# q=3 Collective-Core Synthesis

**Status:** proved construction theorem with an explicit infinite family  
**Date:** 2026-08-15  
**Depends on:** `Q3-FACTOR-PAIR-TYPES.md`, `Q3-NEXT-DIGIT-THEOREM.md`, `COLLECTIVE-CORE.md`, `DSC-COUNTEREXAMPLE.md`  
**Claim boundary:** constructs infinitely many admissible Type A/B target candidates carrying a fixed load-tight q=3 rank-three cover. Only the first member is currently certified to be directly novel against every earlier layer. This theorem does not prove all-prime Erdős-Straus coverage.

---

## 1. General CRT synthesis principle

Let three pure q=3 local layers have

\[
m_i=9p_i
\]

with pairwise distinct odd primes `p_i`, and choose hard-compatible trap factor pairs

\[
(w_i,a_i),
\qquad
w_i a_i=m_i+1=9p_i+1.
\]

Assume the three pairs represent the three q=3 species

\[
(2,5),\qquad(5,2),\qquad(8,8)\pmod9.
\]

Put

\[
B=p_1p_2p_3.
\]

Choose integers `W,A` solving

\[
W\equiv w_i\pmod{p_i},
\qquad
A\equiv a_i\pmod{p_i}
\]

for all three `i`.

Then

\[
WA\equiv w_i a_i\equiv1\pmod{p_i}
\]

for every `i`, so

\[
\boxed{B\mid WA-1.}
\]

If in addition

1. `4|WA`, so `M=WA-1` has the form `4k-1`;
2. `W` is a valid target trap numerator, for example `4|A` so `W|k`;
3. `v_3(M)<=1`;
4. the target trap `t=-W mod M` is compatible with a Mordell-hard class modulo `gcd(840,M)`;

then the target candidate at

\[
M=WA-1,
\qquad
k=WA/4
\]

carries all three local q=3 rows.

### Why each local row remains q=3

Because `p_i|M`, one has

\[
p_i\mid L=\operatorname{lcm}(840,M).
\]

The condition `v_3(M)<=1`, together with `v_3(840)=1`, gives

\[
v_3(L)=1.
\]

Therefore

\[
\gcd(L,9p_i)=3p_i
\]

and

\[
\boxed{q_i=3.}
\]

### Why the selected local trap aligns

Let the hard class be `h=1 mod 3`. The target progression residue `r` satisfies

\[
r\equiv-W\pmod{p_i}
\]

and, by the CRT construction,

\[
-W\equiv-w_i\pmod{p_i}.
\]

The local trap

\[
u_i\equiv-w_i\pmod{9p_i}
\]

is hard-compatible, hence

\[
u_i\equiv1\pmod3.
\]

Thus

\[
r\equiv u_i\pmod{3p_i}.
\]

So the local q=3 pullback is nonempty.

### Why the three rows cover every q=3 parameter class

The three species give three distinct trap residues modulo 9:

\[
7,\qquad4,\qquad1.
\]

By `Q3-NEXT-DIGIT-THEOREM.md`, one common affine bijection sends these three residues to the three parameter classes

\[
\boxed{\mathbb Z/3\mathbb Z.}
\]

Hence the three local rows collectively cover every integer parameter.

If each aligned local row has exactly one compatible trap in its frozen `3p_i` fibre, the three pullbacks are singletons and form a load-tight rank-three core.

---

## 2. Fixed local rows

Use the three ancestry-minimal rows from `DSC-COUNTEREXAMPLE.md`:

\[
\begin{array}{c|c|c|c|c}
 j & p & m=9p & (w,a) & u=-w\pmod m\\
\hline
25  & 11 & 99  & (20,5)  & 79\\
70  & 31 & 279 & (14,20) & 265\\
187 & 83 & 747 & (44,17) & 703
\end{array}
\]

Their species are respectively

\[
(2,5),\quad(5,2),\quad(8,8)\pmod9.
\]

The shared target support is

\[
\boxed{B=11\cdot31\cdot83=28,303.}
\]

The CRT pair used in the verified counterexample is

\[
\boxed{W_0=23,450,\qquad A=764.}
\]

It satisfies

\[
W_0\equiv20\pmod{11},
\quad
W_0\equiv14\pmod{31},
\quad
W_0\equiv44\pmod{83},
\]

and

\[
A\equiv5\pmod{11},
\quad
A\equiv20\pmod{31},
\quad
A\equiv17\pmod{83}.
\]

Also

\[
\boxed{A=4\cdot191.}
\]

Therefore `W` is automatically a plain target trap numerator whenever `W` is replaced by another positive CRT-equivalent lift.

---

## 3. Infinite family

For every integer

\[
n\ge0
\]

define

\[
\boxed{
W_n
=23,450+28,303\cdot315\,n
=23,450+8,915,445n.
}
\]

Keep

\[
\boxed{A=764.}
\]

Then put

\[
\boxed{
k_n=\frac{W_nA}{4}=191W_n}
\]

and

\[
\boxed{M_n=4k_n-1=W_nA-1.}
\]

Explicitly,

\[
\boxed{
k_n=4,478,950+1,702,849,995n}
\]

and

\[
\boxed{M_n=17,915,799+6,811,399,980n.}
\]

---

## 4. The local support is preserved for every n

Because

\[
W_n\equiv W_0\pmod{28,303},
\]

the target pair preserves all three local CRT coordinates.

Hence

\[
11\cdot31\cdot83\mid M_n
\]

for every `n`.

The multiplier `315=5*7*9` makes the small-prime behavior constant:

\[
M_n\equiv3\pmod9,
\]

so

\[
\boxed{v_3(M_n)=1;}
\]

also

\[
M_n\equiv4\pmod5,
\qquad
M_n\equiv6\pmod7.
\]

Since `M_n` is odd,

\[
\boxed{\gcd(840,M_n)=3}
\]

for every `n`.

---

## 5. Hard admissibility for every n

Use

\[
\boxed{h=1\pmod{840}.}
\]

The target trap is

\[
t_n\equiv-W_n\pmod{M_n}.
\]

Because

\[
W_n\equiv2\pmod3,
\]

one has

\[
t_n\equiv1\pmod3.
\]

Since

\[
\gcd(840,M_n)=3,
\]

this is exactly the compatibility condition with `h=1`.

Also

\[
\gcd(W_n,M_n)=1
\]

because `M_n=W_nA-1`, so

\[
\boxed{\gcd(t_n,M_n)=1.}
\]

Thus every `n>=0` gives an admissible hard Type A/B target candidate.

---

## 6. The same three rows form a load-tight q=3 cover for every n

Let

\[
L_n=\operatorname{lcm}(840,M_n).
\]

For `j=25,70,187` one has

\[
q_j=3
\]

for every `n`.

Moreover, in the relevant frozen fibres the selected traps are unique:

```text
j=25:  u=79  is the unique T_25 trap in its class mod 33
j=70:  u=265 is the unique T_70 trap in its class mod 93
j=187: u=703 is the unique T_187 trap in its class mod 249
```

Hence each local pullback is a singleton.

Their residues modulo 9 are

\[
79\equiv7,
\qquad
265\equiv4,
\qquad
703\equiv1
\pmod9.
\]

The global next-digit map is a bijection, so the three singleton pullbacks occupy the three distinct classes of `Z/3Z`.

Therefore, for every `n>=0`,

\[
\boxed{
R_{25}\cup R_{70}\cup R_{187}
=\mathbb Z/3\mathbb Z.
}
\]

Their collective load is

\[
\boxed{
\frac13+\frac13+\frac13=1.
}
\]

So each member of this infinite target family contains an embedded **load-tight rank-three q=3 collective core** supported on the fixed rows

\[
\boxed{\{25,70,187\}.}
\]

---

## 7. First member and direct novelty

At

\[
n=0
\]

the family gives

\[
k_0=4,478,950.
\]

`DSC-COUNTEREXAMPLE.md` independently checks all `4,478,949` earlier layers and proves that this first member has no direct shadow.

Therefore `n=0` is a genuine counterexample to Direct-Shadow Completeness.

For `n>0`, the theorem here asserts the fixed three-row collective cover, not direct novelty against every other earlier row. Some later family members may also admit separate direct shadows.

---

## 8. Consequence

Collective shadows are not isolated high-depth accidents.

The q=3 factor-pair CRT mechanism creates an explicit infinite arithmetic family of admissible target candidates carrying the same rank-three collective cover.

This changes the role of the factor-pair theory:

\[
\boxed{
\text{q=3 factor pairs are a constructive engine for collective coverage.}
}
\]

The next questions are whether other small-support cores admit analogous synthesis families and how these families contribute to all-prime Type A/B coverage.
