# CN-Shared Theorem — Lift-Room, Tight Clusters, and Admissible Escape

**Status:** lift-room and totient-ratio lemmas proved; unrestricted shared-factor C2 is false; admissible program C2-shared certified on the remaining tight cluster  
**Date:** 2026-08-15  
**Depends on:** `C1-THEOREM.md`, `C2-THEOREM.md`, `CN-THEOREM.md`  
**Claim boundary:** Does not prove Erdős-Straus, López-all-primes, or universal DSC-P. Closes the analytic reduction of shared-factor CN to a 3-adic complementary-cover problem, and certifies that problem on every admissible hard Type A/B candidate through `k ≤ 1500`.

Read with:

- [`cn_shared_analyzer.py`](cn_shared_analyzer.py)
- [`verify_cn_shared.py`](verify_cn_shared.py)

---

## 1. Setup

As in C1/C2, a directly novel candidate at target depth `k` has progression

\[
x=r+Ls,\qquad L=\operatorname{lcm}(840,4k-1),
\]

with `r` the CRT combination of a Mordell-hard class `h ∈ H` and a trap `t ∈ T_k`. For each earlier layer `j`,

\[
m_j=4j-1,\qquad
g_j=\gcd(L,m_j),\qquad
q_j=m_j/g_j,
\]

and `R_j` is the affine pullback of `T_j` to `s \bmod q_j`. Write `S_j = U_j \setminus R_j` with `U_j = (\mathbb Z/q_j\mathbb Z)^\times`.

A simultaneous reduced escape is an `s` with `gcd(s,Q)=1` and `s \bmod q_j \in S_j` for every active `j`, where `Q=\operatorname{lcm}(q_j)`.

---

## 2. Lemma (odd totient ratio)

Let `d \mid q` with `1 \le d < q` and `q` odd. Then

\[
\boxed{\frac{\varphi(q)}{\varphi(d)}\ge 2.}
\]

### Proof

Write `q=dm` with `m\ge 3` odd. Euler's product gives

\[
\frac{\varphi(q)}{\varphi(d)}
=
m\prod_{\substack{p\mid q\\ p\nmid d}}\Bigl(1-\frac1p\Bigr).
\]

If every prime of `m` already divides `d`, the product is empty and the ratio equals `m \ge 3`. If `m` contributes a new prime, the product is at least `φ(m_{\mathrm{new}})/m_{\mathrm{new}}` times an integer `≥ 3` factor, and for odd `m_{\mathrm{new}}≥3` one has `φ(m_{\mathrm{new}})≥2`. In all cases the ratio is an integer at least `2`.

Checked for every odd `q ≤ 5000` and every proper divisor: minimum ratio `2`, zero failures.

---

## 3. Theorem (lift-room)

Let `d=\gcd(q_1,q_2)>1`. Write `P_i` for the set of residues `a \bmod d` that lift to at least one element of `S_i`. If

\[
\frac{\varphi(q_i)}{\varphi(d)} > |R_i|
\]

for some `i`, then `P_i` contains every unit modulo `d`. Combined with C1 on the other layer, `P_1 ∩ P_2 \ne \emptyset`, and CRT supplies a reduced simultaneous escape.

### Proof

The reduction `U_i \to (\mathbb Z/d\mathbb Z)^\times` is surjective with fibres of size `φ(q_i)/φ(d)`. A residue `a \bmod d` fails to lie in `P_i` only if that entire fibre sits in `R_i`, which requires at least `φ(q_i)/φ(d)` forbidden units. This is impossible if the displayed inequality holds. C1 supplies some `a' ∈ S_{3-i}`; its projection is a unit modulo `d` and therefore lies in the full `P_i`. QED.

### Uniform form (independent of `r`)

Since `|R_i| \le |T_{j_i}| \le 2\tau(j_i)`,

\[
2\tau(j_i) < \frac{\varphi(q_i)}{\varphi(d)}
\]

implies lift-room for every `r`.

---

## 4. Theorem (C2-thin reduction)

Assume `|R_1| \le 1` and `|R_2| \le 1`. Then a shared-factor C2 failure can occur only if

\[
\boxed{q_1=q_2=3}
\]

and the two singleton forbidden sets are complementary in `{1,2}`.

### Proof

If `d < q_i`, the totient-ratio lemma gives `φ(q_i)/φ(d) ≥ 2 > |R_i|`, so that layer has lift-room. Thus both layers fail lift-room only if `q_1=d=q_2`. For equal moduli, `|R_1 ∪ R_2| ≤ 2`, so the units are covered only if `φ(q) ≤ 2`. The only odd `q>1` with `φ(q)=2` is `q=3`. QED.

Census through `k ≤ 1500` found `|R| ∈ \{0,1\}` on every single-active row. The thin reduction is therefore the generic remaining C2 hole.

---

## 5. Unrestricted C2-shared is false

The previous C2 write-up claimed zero shared-factor failures for “standard `L` and multiple `r`”. That scan did not hit the complementary-producing residue classes.

An exact search — every `r` satisfying

\[
r+\sigma_1 L \in T_{j_1}\pmod{m_{j_1}},\qquad
r+\sigma_2 L \in T_{j_2}\pmod{m_{j_2}}
\]

with `{σ_1,σ_2}={1,2}` — finds complementary `q=3` covers. First examples:

| `L` | `j1` | `j2` | `r` | `R1` | `R2` |
|---:|---:|---:|---:|---|---|
| 55440 | 7 | 520 | 653 | `{2}` | `{1}` |
| 360360 | 88 | 520 | 3361 | `{2}` | `{1}` |
| 360360 | 34 | 88 | 223 | `{2}` | `{1}` |

So C2-shared is **not a theorem for arbitrary** `(L,r,j_1,j_2)`.

The Type A/B program does not use arbitrary `r`. A candidate is **admissible** when

\[
r \equiv h \pmod{840},\qquad
r \equiv t \pmod{4k-1}
\]

for some hard `h` and some `t ∈ T_k`, and `L=\operatorname{lcm}(840,4k-1)`.

---

## 6. Theorem (205-ancestor absorption)

Let `j=205`. Then

\[
m_{205}=819=21\cdot 39=21\cdot m_{10},
\]

and the divisor-child theorem gives `T_{205} \bmod 39 \subseteq T_{10}`.

### Theorem

If `q_{205}=3` and `R_{205} \ne \emptyset`, the candidate is directly shadowed by layer `10`.

### Proof

`m_{205}=3^2\cdot 7\cdot 13`. The condition `q_{205}=3` means

\[
\gcd(L,819)=273=3\cdot 7\cdot 13,
\]

so `13 \mid L`. Already `3 \mid 840 \mid L`, hence `39 \mid L`. Therefore `q_{10}=1` and the entire progression is frozen modulo `39`:

\[
x=r+Ls \equiv r \pmod{39}
\qquad\text{for every }s.
\]

Nonempty `R_{205}` supplies some parameter whose point lies in `T_{205}`. Reducing modulo `39` and applying the divisor-child inclusion puts that point in `T_{10}`. But every point of the progression has the same residue modulo `39`, so the whole progression lies in `T_{10}`. QED.

### Corollary

Layer `205` cannot participate in a complementary `q=3` cover on any **directly novel** candidate.

---

## 7. Admissible complementary covers through `k ≤ 1500`

Replayable tight scan on all `73,814` hard-compatible admissible candidates with `k ≤ 1500` (this is the same candidate population as the frozen DSC-P `k≤1500` bundle):

```text
tight q<=9 shared pairs checked:     1,365,222
pair escapes:                        1,365,201
pair failures:                              21
C1 failures:                                 0
tight q<=9 triples checked:          3,994,891
triple failures:                             0
```

The `21` pair failures are **all** complementary `q=3` covers, and **all** contain layer `205`:

| pair | count |
|------|------:|
| `(205, 322)` | 9 |
| `(52, 205)` | 5 |
| `(70, 205)` | 4 |
| `(205, 556)` | 2 |
| `(25, 205)` | 1 |

Each of the `21` is directly shadowed by layer `10` (and usually by one more `q=1` ancestor such as `6`, `8`, or `36`), exactly as the absorption theorem predicts.

Therefore:

\[
\boxed{
\text{directly novel admissible candidates through }k\le 1500
\text{ have zero complementary }q=3\text{ covers.}
}
\]

A residue-class search that only reduces complementary `r` modulo `lcm(m_{j_1},m_{j_2})` can miss these `21` lifts; the admissible-first scan is the complete check.

---

## 8. Theorem CN-shared (program form)

For every directly novel admissible Type A/B candidate with target depth `k`:

1. **Coprime active moduli** escape by CN-coprime (already proved).
2. **Any layer with lift-room** over `gcd(q, lcm(q_{\mathrm{rest}}))` extends a solution of the complementary cluster (lift-room theorem).
3. **Uniformly roomy pairs** (`2τ(j) < φ(q)/φ(d)`, or same-`q` with `2τ(j_1)+2τ(j_2) < φ(q)`) escape independently of `r`.
4. The only remaining C2-thin obstruction is a complementary `q=3` pair. Every admissible example through `k ≤ 1500` uses layer `205` and is directly shadowed by layer `10`. Directly novel candidates have **zero** such covers in the range.
5. Tight `q ≤ 9` triples on admissible candidates: `3,994,891` checks, **0** failures.

Thus every **directly novel** admissible shared-factor pair in the completed range has a reduced simultaneous escape.

This upgrades the C2/CN shared-factor story from “sampled `r`, zero fails” to:

- a proved reduction to one local obstruction;
- an explicit counterexample to the unrestricted statement;
- a proved absorption theorem that kills the `205` family on novel candidates;
- an exact certificate that no other complementary family appears through `k ≤ 1500`.

---

## 9. Finite certificates (replayable)

| Scan | Result |
|------|--------|
| Totient-ratio, odd `q ≤ 5000` | min ratio `2`, **0** fails |
| Standard-`L` pairs `j ≤ 180`, mixed `r` | 358,188 pairs, **0** fails, **0** C1 fails |
| Program `L=\mathrm{lcm}(840,4k-1)`, hard `r`, `k ≤ 200` | 7,184,124 pairs, **0** fails |
| Exact complementary `q=3` search, standard `L` | 124 unrestricted covers; **0** on `L=840` and `L=2520` |
| Tight `q ≤ 9` admissible pairs, `k ≤ 1500` | 1,365,222 checks; 21 complementary fails, all `205`-family, all directly shadowed by `10` |
| Tight `q ≤ 9` admissible triples, `k ≤ 1500` | 3,994,891 checks, **0** fails |

Independent control flow: `verify_cn_shared.py` rebuilds blocked projections from Euler's product and rechecks the totient-ratio lemma, the `4j-1 \mid qL` classification of exact-`q` layers, and a program-`L` sample.

---

## 10. Correction to earlier C2/C3/C4 claims

`C2-THEOREM.md` and `CN-THEOREM.md` reported zero shared-factor failures for standard `L` and sampled `r`. That is true of those samples and is **not** a universal C2-shared theorem. Complementary-aligned `r` produce covers. The correct claim is the program-admissible statement in §7.

---

## 11. Scoreboard

| Result | Status |
|--------|--------|
| Totient-ratio lemma | **Proved** |
| Lift-room theorem | **Proved** |
| Uniform lift-room / same-`q` pigeonhole | **Proved** |
| C2-thin reduction to `q=3` | **Proved** |
| Unrestricted C2-shared | **False** (explicit covers) |
| `205`-ancestor absorption | **Proved** |
| Directly novel complementary `q=3`, `k ≤ 1500` | **0** (exact) |
| Other complementary families for all `k` | Open (none through 1500) |
| Shared-factor CN for all finite clusters | Open beyond the lift-room peel + tight certificate |
| Universal DSC-P | Open |
| López all primes | Open |
| Erdős-Straus | Open |

---

## 12. Next

1. Classify every `q=3` layer as an ancestry child of a `q=1` anchor, generalising the `205 → 10` absorption.
2. Peel every roomy layer from an arbitrary finite active core; only a 3/5/7-adic tight cluster remains.
3. Bound `|N^{act} ∩ tight|` on Class-C residuals, then assemble DSC-P.
