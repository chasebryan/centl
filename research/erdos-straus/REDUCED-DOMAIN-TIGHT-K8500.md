# Corrected reduced-domain tight-cluster certificate through k = 8500

**Status:** exact finite theorem-certificate result, independently replayed in GitHub Actions  
**Date:** 2026-08-15  
**Branch:** `research/es-reduced-parameter-domain`  
**Claim boundary:** this is a finite result for the corrected `q<=9` tight cluster. It does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- `REDUCED-PARAMETER-DOMAIN.md`
- `reduced_domain_tight_probe.py`
- `verify_reduced_domain_tight.py`
- `CURRENT-FRONTIER.md`

## 1. Why this replay was necessary

The exact Dirichlet condition for a candidate progression

\[
x(s)=r+Ls
\]

is

\[
\gcd(r+Ls,LQ)=1.
\]

It is not generally equivalent to `gcd(s,Q)=1`.

For an admissible candidate, `gcd(r,L)=1`. Hence a prime `p|Q` already dividing `L` imposes no condition on `s`, whereas a prime `p|Q` with `p∤L` excludes exactly one affine class

\[
s\equiv-rL^{-1}\pmod p.
\]

In particular, because `3|840|L`, the correct local parameter domain for a `q=3` coordinate is the entire ring `Z/3Z`. The earlier `{1},{2}` complementary-pair obstruction was therefore an artifact of restricting the parameter itself to units.

## 2. Independent constructions

The hosted replay uses two separate implementations.

### Primary

`reduced_domain_tight_probe.py`

- generates every `q<=9` earlier layer from the exact divisor condition `m_j | qL`;
- reconstructs each forbidden pullback `R_j` by modular inversion;
- enumerates the complete corrected reduced parameter domain modulo the tight period `Q`;
- applies the exact full-fibre direct-shadow criterion to every full-domain failure.

### Independent verifier

`verify_reduced_domain_tight.py`

- does **not** import the primary probe;
- scans every earlier depth `j<k` directly;
- discovers `q_j` from `m_j/gcd(L,m_j)`;
- reconstructs pullbacks by enumerating the defining parameter congruence rather than using the primary inverse formula;
- checks the affine reduced-domain rule against `gcd(r+Ls,LQ)==1` directly;
- recomputes direct shadows from the complete attained fibre.

The two constructions returned identical counts.

## 3. Hosted provenance

GitHub Actions workflow:

```text
workflow:  CENTL Erdős-Straus corrected reduced domain
run id:    31861038101
head SHA:  718b02f00fcfacd145c0fb5862094d645b500b34
artifact:  9240572327
```

Artifact name:

```text
erdos-straus-reduced-domain-tight-ee2e632a28081b5287813eb85e67fda5ced4ddf5
```

Artifact archive digest:

```text
sha256:26f4d3e8e5f4184219acca1e21a1f0f6f4d5a0327aeb7d6ab5661e691b71ca8a
```

Internal certificate hashes:

```text
fc9ebcade360bc6c69bc0a755c73c0a23552fc01980c413cb8bc98af5738e1f3  reduced-domain-tight.json
05c972bb75049b954ef9a6633b59220501743a0e9b30d60dcf3c47dac39524ef  reduced-domain-tight-report.md
01194f116160946455729055e3d8103ebf9a386604bad1e5148ce54bc47e0d21  reduced-domain-tight-independent-verifier.json
478fe58db7bf605304cb201fa8b28decc1f8415dabac006a8337d23aede07a76  provenance.txt
```

Independent verifier verdict:

```text
VERIFIED
primary comparison: MATCH
```

## 4. Exact finite result

Configured range:

```text
k <= 8500
q <= 9
```

Result:

```text
candidates with tight layers:            527,139
corrected-domain tight escapes:           527,127
full corrected-domain tight failures:          12
failures already directly shadowed:             12
directly novel tight failures:                   0
maximum tight period Q:                         315
```

Therefore

\[
\boxed{
\text{there is no directly novel full corrected-domain }q\le9
\text{ tight-cluster failure through }k\le8500.
}
\]

This is an exact finite theorem-certificate statement.

## 5. First genuine 3-adic full cover

The first corrected-domain three-class `q=3` cover occurs at

\[
\boxed{k=8378}.
\]

The target modulus factors as

\[
4k-1=33511=23\cdot31\cdot47.
\]

The three decisive earlier rows are

\[
\begin{aligned}
j&=52,  &4j-1&=207=9\cdot23,\\
j&=70,  &4j-1&=279=9\cdot31,\\
j&=106, &4j-1&=423=9\cdot47.
\end{aligned}
\]

Their singleton pullbacks cover the complete local coordinate

\[
\boxed{\{0,1,2\}\pmod3.}
\]

There are exactly 12 hard-compatible target candidates in this first failure family. Every one is already directly shadowed by earlier frozen rows

\[
\boxed{j=6\quad\text{and}\quad j=12,}
\]

whose moduli are `23` and `47` respectively.

Thus the first real three-class `q=3` cover does not contradict Direct-Shadow Completeness: it occurs only inside candidates that were already non-novel.

## 6. What changed

Under the old unit-parameter model, a two-singleton complementary `q=3` pair looked fatal because `{1,2}` exhausted the units.

Under the exact Dirichlet domain:

\[
\boxed{\text{two singleton q=3 rows can never cover the local parameter coordinate}.}
\]

The first possible full local cover requires all three classes. The hosted finite replay shows that the first such cover is itself swallowed by direct shadows.

This moves the active theorem target from

```text
complementary pair -> absorption
```

to

```text
full corrected tight cover -> direct shadow
```

with the first 3-adic laboratory supplied by `k=8378`.

## 7. Next theorem target

Prove the hard-conditioned parent-shadow mechanism behind the `k=8378` family, then generalize it:

\[
\boxed{
R_{j_1}\cup R_{j_2}\cup R_{j_3}=\mathbb Z/3\mathbb Z
\Longrightarrow
\text{an earlier frozen Type A/B shadow exists}
}
\]

for admissible hard candidates, or find the first directly novel counterexample.

The immediate exact rows `52 -> 6` and `106 -> 12` are sufficiently small to close by direct divisor/trap arithmetic rather than computational enumeration alone.
