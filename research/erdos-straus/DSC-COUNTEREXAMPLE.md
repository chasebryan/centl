# Constructive counterexample to universal Direct-Shadow Completeness

**Status:** exact constructive counterexample; independently replayed and frozen in GitHub Actions  
**Date:** 2026-08-15  
**Claim boundary:** this falsifies the universal conjectures DSC-0 and DSC-P as stated in the research program. It does **not** falsify the Erdős-Straus conjecture, and it does not falsify López Type A/B coverage. The target candidate is collectively redundant rather than directly redundant.

Verifier:

- `verify_dsc_counterexample.py`
- `DIRECT-SHADOW-SMOOTHNESS.md`

Hosted certificate:

```text
workflow run: 31862644146
head SHA:     ee08dd722164843da6cfa417fc6439d5ac09447d
artifact id:  9241048158
artifact digest:
sha256:7a8ee6c11d77b1d637238de10fae033be64b3099388c43e17942748b38b354df
verdict:      SUCCESS
```

---

## 1. The statements falsified

The program defined:

### DSC-0

\[
\text{not directly shadowed}
\Longrightarrow
\text{not union-shadowed}.
\]

### DSC-P

\[
\text{not directly shadowed}
\Longrightarrow
\text{there exists a reduced avoiding parameter class}.
\]

The candidate below is not directly shadowed, but three earlier `q=3` rows cover **every integer parameter**. Therefore it has no integer avoiding parameter at all, hence certainly no reduced avoiding parameter.

Thus:

\[
\boxed{\text{DSC-0 is false}}
\]

and

\[
\boxed{\text{DSC-P is false}.}
\]

---

## 2. Constructed target

Set

\[
D=2,218,779,486,
\qquad
N=1,900,986,818,
\]

and

\[
\boxed{
k=DN=4,217,870,554,934,815,548.}
\]

Then

\[
\boxed{
M=4k-1
=16,871,482,219,739,262,191.
}
\]

Its exact factorization is

\[
\boxed{
M
=19\cdot229\cdot433\cdot487\cdot3823\cdot4,809,977.
}
\]

All displayed factors are prime.

Because `D|k`, the residue

\[
\boxed{
t\equiv-4D\pmod M}
\]

is a Type A/B target trap. In least nonnegative form,

\[
\boxed{
t=16,871,482,210,864,144,247.}
\]

Also

\[
\gcd(M,840)=1,
\]

so

\[
\boxed{
L=\operatorname{lcm}(840,M)
=840M
=14,172,045,064,580,980,240,440.
}
\]

Two Mordell-hard siblings work:

\[
h=361
\qquad\text{and}\qquad
h=529.
\]

Their CRT bases are respectively

\[
\boxed{
r_{361}=13,750,258,009,078,623,567,721}
\]

and

\[
\boxed{
r_{529}=2,412,621,957,413,839,375,369.}
\]

Each satisfies

\[
r_h\equiv h\pmod{840},
\qquad
r_h\equiv t\pmod M,
\qquad
\gcd(r_h,L)=1.
\]

Either sibling by itself falsifies DSC-0 and DSC-P.

---

## 3. Three earlier q=3 rows cover every parameter

Use the following earlier layers:

| `j` | `m_j=4j-1` | trap divisor `e` | branch | trap `u` |
|---:|---:|---:|:---:|---:|
| 6,820 | 27,279 | 20 | `-4e` | 27,199 |
| 8,602 | 34,407 | 506 | `-e` | 33,901 |
| 9,790 | 39,159 | 89 | `-4e` | 38,803 |

The trap divisibility is exact:

```text
20  | 6820
506 | 8602
89  | 9790
```

and the moduli factor as

\[
27279=3^2\cdot7\cdot433,
\]

\[
34407=3^2\cdot3823,
\]

\[
39159=3^2\cdot19\cdot229.
\]

For the target `L`, their gcds are

\[
9093,
\qquad
11469,
\qquad
13053,
\]

so all three have

\[
\boxed{q_j=3.}
\]

### Hard sibling h=361

The exact pullback classes are

```text
j=6820  -> s = 1 mod 3
j=8602  -> s = 2 mod 3
j=9790  -> s = 0 mod 3
```

### Hard sibling h=529

They are the cyclic shift

```text
j=6820  -> s = 0 mod 3
j=8602  -> s = 1 mod 3
j=9790  -> s = 2 mod 3
```

Therefore in either candidate

\[
\boxed{
R_{6820}\cup R_{8602}\cup R_{9790}
=\mathbb Z/3\mathbb Z.
}
\]

By `Q3-SINGLETON-PULLBACK.md`, each row contributes only its displayed singleton class, but together the three singletons cover all classes.

Hence for **every integer** `s`, at least one earlier Type A/B row is hit:

\[
\boxed{
\forall s\in\mathbb Z,
\quad
r_h+Ls
\text{ lies in an earlier Type A/B layer.}
}
\]

This is an exact union shadow.

---

## 4. Why the direct-shadow check is finite

A direct shadow cannot contain any prime outside the support of `L`.

`DIRECT-SHADOW-SMOOTHNESS.md` proves:

\[
\boxed{
\text{direct shadow by modulus }m
\Longrightarrow
\operatorname{rad}(m)\mid\operatorname{rad}(L).
}
\]

Reason: if `p|m` but `p∤L`, the attained fibre contains a value divisible by `p`, while every Type A/B trap is a unit modulo `m`.

Therefore every possible earlier direct-shadow modulus is smooth over the odd prime support

\[
\boxed{
\{3,5,7,19,229,433,487,3823,4,809,977\}.
}
\]

There are exactly

\[
\boxed{270,836}
\]

positive smooth integers below `M`, of which exactly

\[
\boxed{135,402}
\]

are nontrivial and congruent to `3 mod 4`, hence are possible earlier Type A/B moduli.

The verifier enumerates all of them.

For each modulus `m=4i-1`, it computes

\[
g=\gcd(L,m),
\qquad
q=m/g,
\]

and checks every one of the `q` attained fibre points directly against the exact Type A/B trap criterion.

Result for `h=361`:

```text
possible smooth Type A/B direct-shadow moduli checked: 135,402
direct shadows: 0
```

Result for `h=529`:

```text
possible smooth Type A/B direct-shadow moduli checked: 135,402
direct shadows: 0
```

Thus both candidates are **directly novel**.

---

## 5. Independent hosted replay

The GitHub Actions verifier reconstructs the target factorization, candidate CRT data, all three q=3 pullbacks, the complete smooth direct-shadow search space, and every attained fibre without consulting a stored verdict.

The first hosted run completed successfully:

```text
run id:      31862644146
head:        ee08dd722164843da6cfa417fc6439d5ac09447d
artifact:    9241048158
archive sha: 7a8ee6c11d77b1d637238de10fae033be64b3099388c43e17942748b38b354df
```

Thus the counterexample is now frozen as a replayable theorem-certificate, not merely a local search observation.

---

## 6. Exact conclusion

For each of the two hard siblings:

1. the target is a valid admissible Type A/B candidate;
2. no single earlier layer directly shadows it;
3. three earlier `q=3` layers jointly cover every integer parameter.

Therefore

\[
\boxed{
\text{directly novel}
\centernot\Longrightarrow
\text{not union-shadowed}.
}
\]

and

\[
\boxed{
\text{directly novel}
\centernot\Longrightarrow
\text{reduced prime-realizable}.
}
\]

The finite `k<=1500` and related DSC certificates remain correct **finite statements**. What fails is their universal extrapolation.

---

## 7. What this means for the research program

This result removes the proposed DSC shortcut. The shadow graph is not a complete obstruction theory when only direct edges are retained.

The replacement object must preserve **collective local covers**. At minimum, the correct structure needs hyperedges / covering cores rather than only single-layer ancestry edges.

For the Erdős-Straus goal, however, this is not a negative result: a union-shadowed target candidate is already covered by earlier Type A/B decompositions. Exact-depth prime realizability was a stronger auxiliary objective than pointwise Type A/B coverage requires.

The immediate program should therefore split cleanly:

1. **Depth-spectrum track:** classify minimal union-shadow cores and replace DSC with a hypergraph/covering-core theory.
2. **Erdős-Straus track:** attack pointwise Type A/B coverage directly, especially the zero-density prime-modulus survivor/composite-rescue core.
3. Retain Strong Absorption, Weak Redundancy, Pointwise Absorption, singleton q=3 pullbacks, and direct-shadow smoothness as exact reduction tools.
4. Keep López-all-primes separate: this counterexample concerns minimal-depth realizability of one target candidate, not existence of some Type A/B decomposition for a prime.
5. Keep the Erdős-Straus wall honest until the all-prime/composite remainder is actually closed.

The project has learned something stronger than another finite survival bound: **the universal bridge itself has been falsified constructively, and the ES route can now discard that unnecessary burden.**
