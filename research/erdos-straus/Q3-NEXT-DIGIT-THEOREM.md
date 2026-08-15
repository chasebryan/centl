# q=3 Next-Digit Theorem

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Depends on:** `REDUCED-PARAMETER-DOMAIN.md`, `Q3-ABSORPTION.md`, `Q3-WEAK-REDUNDANCY.md`, `Q3-POINTWISE-ABSORPTION.md`  
**Claim boundary:** identifies the exact common 3-adic coordinate used by every `q=3` pullback. It does not by itself prove that pointwise-primitive traps cannot occupy all three next digits, universal DSC-P, López-all-primes, or Erdős-Straus.

---

## 1. Setup

Fix an admissible progression

\[
x(s)=r+Ls
\]

with

\[
\gcd(r,L)=1.
\]

Write

\[
\nu=v_3(L),
\qquad
L=3^\nu B,
\qquad
3\nmid B.
\]

Since `840 | L`, every program progression has `nu >= 1`.

Let `j` be an earlier layer with

\[
m_j=4j-1
\]

and assume

\[
q_j=\frac{m_j}{\gcd(L,m_j)}=3.
\]

Put

\[
g_j=\gcd(L,m_j)=m_j/3.
\]

A pullback class `a mod 3` is forbidden by `j` when there is a trap residue

\[
u\in T_j
\]

such that

\[
r+La\equiv u\pmod{m_j}.
\]

---

## 2. Valuation consequence of `q_j=3`

Because the entire quotient `m_j/g_j` is the single prime `3`, every prime-power factor of `m_j` other than one additional factor of `3` is already absorbed by `L`.

Hence

\[
\boxed{v_3(m_j)=\nu+1.}
\]

In particular

\[
3^\nu\mid g_j
\]

and every trap witness contributing to `R_j` satisfies

\[
\boxed{u\equiv r\pmod{3^\nu}.}
\]

---

## 3. Theorem — one global next digit

For every `q_j=3` layer and every trap witness `u in T_j` contributing the forbidden parameter class `a mod 3`, one has

\[
\boxed{
 a
 \equiv
 \frac{u-r}{3^\nu}\,B^{-1}
 \pmod 3.
}
\]

The quotient `(u-r)/3^nu` is integral by the preceding section, and `B^{-1}` exists modulo `3`.

### Proof

From

\[
r+La\equiv u\pmod{m_j}
\]

and

\[
3^{\nu+1}\mid m_j
\]

we may reduce modulo `3^(nu+1)`:

\[
u-r\equiv 3^\nu B a\pmod{3^{\nu+1}}.
\]

Divide by `3^nu`:

\[
\frac{u-r}{3^\nu}\equiv Ba\pmod3.
\]

Multiplying by `B^{-1}` modulo `3` gives the result. QED.

---

## 4. Interpretation

All `q=3` layers read the **same next 3-adic digit** above the frozen prefix

\[
x\equiv r\pmod{3^\nu}.
\]

The three parameter classes `a=0,1,2` correspond exactly to the three lifts

\[
\boxed{
r,
\quad r+3^\nu B,
\quad r+2\cdot3^\nu B
\pmod{3^{\nu+1}}.
}
\]

The labeling by `a` is global. It does not depend on `j`.

Therefore a corrected-domain `q=3` cover is equivalent to finding trap witnesses among the active `q=3` layers that occupy **all three next 3-adic digits**.

---

## 5. Hard-class specialization when `nu=1`

When

\[
v_3(L)=1,
\]

write `L=3B`, `3∤B`. Every Mordell-hard class satisfies

\[
r\equiv1\pmod3.
\]

Any hard-compatible Type A/B trap has the form

\[
u\equiv-e\quad\text{or}\quad u\equiv-4e
\]

with `e|j` and necessarily

\[
e\equiv2\pmod3.
\]

Thus

\[
e\pmod9\in\{2,5,8\}
\]

and every compatible trap satisfies

\[
\boxed{u\pmod9\in\{1,4,7\}.}
\]

The correspondence is

| `e mod 9` | `-e mod 9` | `-4e mod 9` |
|---:|---:|---:|
| 2 | 7 | 1 |
| 5 | 4 | 7 |
| 8 | 1 | 4 |

Since the affine map

\[
u\mapsto ((u-r)/3)B^{-1}\pmod3
\]

is a bijection from `{1,4,7}` to `{0,1,2}`, a full `q=3` cover is equivalent to occupying all three values

\[
\boxed{u\bmod9=1,4,7}
\]

after the common affine relabeling determined by `(r,L)`.

---

## 6. Interaction with absorption

On a directly novel candidate:

1. **strong-absorbed layers** cannot have nonempty `R_j`;
2. **weak layers** add no new class because `R_j subset R_i` for an earlier `q=3` ancestor;
3. **pointwise non-primitive trap witnesses** force a direct shadow;
4. therefore every genuinely new occupied next digit must be supplied by a **pointwise-primitive trap witness**.

Hence the exact remaining `q=3` theorem target is

\[
\boxed{
\text{Can pointwise-primitive admissible trap witnesses occupy all three next 3-adic digits?}
}
\]

This is strictly sharper than the former complementary-pair target.

---

## 7. Immediate finite-proof mining target

The correct falsifier is now a directly novel admissible target candidate carrying pointwise-primitive `q=3` witnesses whose digit union is

\[
\boxed{\{0,1,2\}.}
\]

A two-digit union is not an obstruction, because the third parameter class remains available and is prime-compatible at `3` (`3|L`).
