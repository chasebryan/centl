# Reduced h169 dependency grammar

**Status:** exact constraint-propagation synthesis, revision 2  
**Date:** 2026-08-16  
**Verifier:** `verify_h169_reduced_dependency_grammar.py`  
**Depends on:** realized k19 survivor normal form, k27 survivor grammar and QR-factor selectors, k31 survivor normal form and mode/seam coupling, k35 two-branch theorem and 3-adic coupling, Route-B k47 survivor normal form and joint k31/k47 seam coupling, route-conditioned phase state, and ten-cofactor support separation.  
**Claim boundary:** this document composes already-proved implications into a reduced symbolic state grammar. Counts are counts of formal phase/mode tuples not excluded by those implications. They are not counts or densities of actual arithmetic survivors, not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. The machine is now a dependency grammar

The active h169 state coordinates no longer form a Cartesian product.

Exact implications now connect:

- route ancestry to k19 defect phase;
- k19 phase to deterministic k27 factors;
- deterministic k27 factors to the seven-mode k27 skeleton grammar;
- k31 BARE to phase and parity;
- parity to the complete 2-adic support seam;
- the Route-B seam to both k31 and k47 survivor modes;
- the k35 3-adic phase to J35/S7 branch status.

The machine should therefore canonicalize an exact state by propagating these implications to a fixed point before scheduling new factor work.

## 2. Proof-bearing phase coordinates

Retain

```text
tau19 = t mod19
tau31 = t mod31
tau4  = t mod4
tau9  = t mod9
```

alongside the landed later phase envelope for k39/k43/k47/k51/k55.

The realized Route-A and Route-B progression moduli are coprime to 19,31,4,9, so these are valid independent CRT coordinates after route conditioning.

The exact necessary survivor phase sets are

```text
S19 = {0,2,7,8,11,14,15,16,17}
S31 = {0,2,6,7,8,9,11,12,14,15,19,22,27,28,29}.
```

## 3. Derived coordinates

### Parity and 2-adic seam

Parity is determined by tau4. The ten-cofactor theorem then determines the local support seam:

```text
tau4=0 -> EVEN_0
    gcd(B,G)=2, gcd(G,L)=2, gcd(B,L)=4, gcd(D,J)=1

tau4=2 -> EVEN_2
    gcd(B,G)=2, gcd(G,L)=2, gcd(B,L)=2, gcd(D,J)=1

tau4 in {1,3} -> ODD
    gcd(B,G)=1, gcd(G,L)=1, gcd(B,L)=1, gcd(D,J)=2.
```

Thus parity and support_seam are normally derived from the CRT phase rather than stored independently as proof-state coordinates.

### k35 3-adic bucket

For `F=17+70t`:

```text
tau9 in {1,7} -> v3(F)=1
tau9=4        -> v3(F)>=2
otherwise     -> v3(F)=0.
```

This bucket is lossless for the landed k35 branch/valuation theorem.

## 4. Exact mode dependencies

### k19

Modes:

`BARE | FULL_QR`.

The route-specific BARE phases are

```text
Route A BARE -> tau19=2
Route B BARE -> tau19=8.
```

FULL_QR has an exact local miss at each of the nine S19 phases.

### k27

The seven NR-skeleton modes are

`Q,A,B,C,D,E,F`.

The landed QR-factor selector theorem gives the phase rule

`tau19=8 -> 19|E`,

because `E=7+30t`.

Residue19 mod27 is a one-occurrence Q selector, so

```text
tau19=8 AND k27 miss -> k27_NR_mode=Q
                         E_support=QR27.
```

This rule is phase-driven. Route-B k19 BARE reaches it automatically because BARE forces tau19=8, yielding the important composition

```text
Route-B k19 BARE
    -> tau19=8
    -> 19|E
    -> on k27 miss: k27_NR_mode=Q
    -> E_support=QR27.
```

The same k27 collapse also applies to a FULL_QR k19 state whose phase is tau19=8.

### k31

Modes:

`BARE | FULL_QR`.

BARE support in `H31={1,5,25}` forces

```text
k31 BARE -> tau31 in {0,19,29}
k31 BARE -> tau4 even.
```

An odd-t k31 miss is therefore FULL_QR.

### k35

Because J35 and S7 may overlap, use

```text
J_ONLY
S7_ONLY
BOTH.
```

The exact 3-adic coupling is

```text
tau9=4 -> J_ONLY.
```

On tau9 in `{1,7}`, any state containing S7 additionally has rational prime3 as the distinguished S7 factor and `support(F/3) subset {q:q=1 mod7}`.

### Route-B k47

Modes:

`THIN | FULL_QR`.

THIN excludes rational prime2, hence

`k47 THIN -> tau4 even`.

The joint seam theorem strengthens this to

```text
tau4 odd -> k31 FULL_QR
          -> Route-B k47 FULL_QR
          -> gcd(D,J)=2.
```

## 5. Route-A formal grammar including k27

The fully naive coarse product now includes k27 explicitly:

```text
tau19       9
tau31      15
tau4        4
tau9        9
k19 mode    2
k27 mode    7
k31 mode    2
k35 status  3
```

for

`9*15*4*9*2*7*2*3 = 408,240`

formal tuples.

Apply the exact dependencies:

1. Route-A k19 BARE -> tau19=2;
2. tau19=8 -> k27 mode Q;
3. k31 BARE -> tau31 in `{0,19,29}` and even tau4;
4. tau9=4 -> J_ONLY.

Exactly

`105,600`

formal tuples are not excluded.

The resulting formal grammar ratio is

`105,600 / 408,240 = 440 / 1,701`

or approximately

`0.2586713697824809`.

This is not an arithmetic survivor fraction.

### k19/k27 block

The Route-A k19/k27 block explains the new reduction directly.

Naive:

`9 phases * 2 k19 modes * 7 k27 modes = 126`.

Not excluded:

- tau19=8: k19 is FULL_QR and k27 is forced Q ->1;
- tau19=2: FULL_QR or BARE, with any of seven k27 modes ->14;
- the other seven phases: FULL_QR with any of seven k27 modes ->49.

Total:

`64`.

The other blocks remain

```text
Route-A k31 block   120 -> 66
k35 block            27 -> 25.
```

Therefore

`64*66*25 = 105,600`.

## 6. Route-B formal grammar including k27

Route B also carries k47 mode, so the fully naive product contains

`408,240*2 = 816,480`

formal tuples.

Apply:

1. Route-B k19 BARE -> tau19=8;
2. tau19=8 -> k27 mode Q;
3. k31 BARE -> tau31 in `{0,19,29}` and even tau4;
4. k47 THIN -> even tau4;
5. odd tau4 -> FULL_QR31 × FULL_QR47;
6. tau9=4 -> J_ONLY.

Exactly

`147,900`

formal tuples are not excluded.

The formal grammar ratio is

`147,900 / 816,480 = 2,465 / 13,608`

or approximately

`0.18114344503233393`.

### Route-B k19/k27 block

Naive:

`126`.

Not excluded:

- tau19=8: FULL_QR or BARE at k19, but k27 forced Q ->2;
- the other eight S19 phases: FULL_QR at k19 with any seven k27 modes ->56.

Total:

`58`.

The other blocks are

```text
Route-B joint k31/k47 block  240 -> 102
k35 block                     27 -> 25.
```

Therefore

`58*102*25 = 147,900`.

## 7. Improvement over revision 1

Revision 1 deliberately left k27 opaque.

Tensoring its old reduced grammar with seven unconstrained k27 modes would have produced

```text
Route A: 16,500 * 7 = 115,500
Route B: 25,500 * 7 = 178,500.
```

The new phase-to-k27 selector reduces these to

```text
Route A: 105,600
Route B: 147,900.
```

Thus the new k27 theorem alone removes

```text
9,900  formal tuples from the already-reduced Route-A tensor
30,600 formal tuples from the already-reduced Route-B tensor.
```

The larger Route-B effect occurs because its BARE k19 mode is itself pinned to the Q-selector phase tau19=8.

## 8. Orthogonality to the later phase envelope

The landed later phase filters remain a separate exact layer.

After route conditioning, their independent CRT coordinates can be tensored with this reduced grammar without changing the grammar ratios above.

The machine should preserve three conceptually distinct surfaces:

- **phase envelope:** where t may live;
- **dependency grammar:** which mode labels may coexist on that phase;
- **support grammar:** what prime-factor resources each surviving mode requires.

Confusing these would turn exact state reduction into a false density or existence claim.

## 9. Revised normalized state

A more precise state signature is now

```text
Sigma_red = (
    route,
    CRT_phase,
    k19_mode,
    k27_NR_mode,
    k31_mode,
    k35_status,
    route_terminal_mode,
    separated_support,
    affine_data
)
```

where

- parity, seam, and k35 3-adic bucket are derived from CRT_phase;
- `k27_NR_mode` means the seven-mode nonresidue-skeleton behavioral class before QR completion;
- the phase selector may collapse `k27_NR_mode` to Q before the remaining E support is explored;
- Route-B k47 `THIN|FULL_QR` and the Route-A k51 endpoint family remain route-terminal coordinates;
- separated support and affine identities remain proof-bearing arithmetic data.

## 10. Constraint propagation to fixed point

Examples now include

```text
Route-B k19=BARE
    -> tau19=8
    -> 19|E
    -> k27 miss implies k27_NR_mode=Q
    -> E_support=QR27

k31=BARE
    -> tau31 in {0,19,29}
    -> tau4 even
    -> even support seam
    -> gcd(D,J)=1

Route-B tau4 odd
    -> gcd(D,J)=2
    -> k31=FULL_QR
    -> k47=FULL_QR

tau9=4
    -> v3(F)>=2
    -> S7=false
    -> on k35 miss: J35=true.
```

The machine should exhaust such exact propagation before performing new factor enumeration.

## 11. Bryan Entanglement Cross / BREC boundary

Directional entanglement is an annotation and scheduling layer over these exact edges.

For example, the chain

`BARE -> tau19=8 -> 19|E -> k27 Q`

is naturally interpretable as excavation that resolves into a sharper support law. That directional description may be valuable for scheduling and telemetry.

It does not create the implication. The exact state grammar is the only source of mathematical pruning permission.

## 12. Next theorem targets

k27 is no longer opaque, but only one already-retained phase coordinate currently selects Q.

The next theorem-mining targets are:

1. add deterministic rational-prime phase selectors whose QR27 residues are `{10,16,22}` and the two-occurrence selectors `{4,7,13,25}` where they intersect existing ancestry;
2. seek direct couplings between k27 mode subsets and k31/k35 support reservoirs;
3. implement the dependency grammar as a small fixed-point propagator so exact implications can be applied automatically before CBX schedules expensive factor work.

The third item is now an engineering problem built on proved arithmetic, not a new mathematical assumption.