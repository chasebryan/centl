# Reduced h169 dependency grammar

**Status:** exact constraint-propagation synthesis inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_h169_reduced_dependency_grammar.py`  
**Depends on:** realized k19 survivor normal form, k31 survivor normal form and mode/seam coupling, k35 two-branch theorem and 3-adic coupling, Route-B k47 survivor normal form and joint k31/k47 seam coupling, route-conditioned phase state, and ten-cofactor support separation.  
**Claim boundary:** this document composes already-proved implications into a reduced symbolic state grammar. Counts below are counts of formal phase/mode tuples not excluded by these implications. They are not counts or densities of actual arithmetic survivors, not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Why the state representation must change

The local h169 program no longer consists of independent coordinates.

Several coordinates that were initially stored side by side are now linked by exact implications:

- k19 BARE fixes an exact center phase modulo19;
- k31 BARE restricts both the modulo31 phase and parity;
- parity determines the complete local 2-adic support seam;
- on Route B, an odd seam forces both k31 and k47 into FULL_QR;
- k35 S7 is incompatible with the repeated-3 phase `t=4 mod9`;
- the 3-adic phase determines whether an S7 occurrence of rational prime3 is absent, unique, or impossible.

The machine should therefore stop treating these as Cartesian fields.

The correct object is a **dependency grammar** in which exact phase coordinates are proof-bearing state and many support/valuation coordinates are derived consequences.

## 2. Canonical phase coordinates

For the first reduced local grammar retain

```text
tau19 = t mod19
tau31 = t mod31
tau4  = t mod4
tau9  = t mod9
```

alongside the already-landed later phase tuple for k39/k43/k47/k51/k55.

The realized Route-A and Route-B progression moduli are coprime to 19,31,4,9, so these four coordinates remain free CRT coordinates after conditioning on either route.

The exact necessary survivor phase sets already proved are

```text
S19 = {0,2,7,8,11,14,15,16,17}
S31 = {0,2,6,7,8,9,11,12,14,15,19,22,27,28,29}.
```

## 3. Derived coordinates, not independent coordinates

### Parity

`parity = tau4 mod2`.

### 2-adic support seam

The ten-cofactor theorem makes the seam a deterministic function of tau4:

```text
tau4=0 -> EVEN_0
    gcd(B,G)=2
    gcd(G,L)=2
    gcd(B,L)=4
    gcd(D,J)=1

tau4=2 -> EVEN_2
    gcd(B,G)=2
    gcd(G,L)=2
    gcd(B,L)=2
    gcd(D,J)=1

tau4 in {1,3} -> ODD
    gcd(B,G)=1
    gcd(G,L)=1
    gcd(B,L)=1
    gcd(D,J)=2.
```

Therefore `support_seam` should normally be recomputed from tau4 rather than stored as an independent proof-state coordinate.

### k35 3-adic bucket

From `F=17+70t`:

```text
tau9 in {1,7} -> v3(F)=1
tau9=4        -> v3(F)>=2
otherwise     -> v3(F)=0.
```

The exact valuation may be larger than2 on tau9=4, but the three-way bucket above is lossless for the landed k35 branch rule.

## 4. Exact mode constraints

### k19 mode

For either realized pair route, the exact modes are

`BARE | FULL_QR`.

FULL_QR occurs at each of the nine QR19 center phases in the exact local state model.

BARE has one route-specific defect phase:

```text
Route A BARE -> tau19=2
Route B BARE -> tau19=8.
```

Thus BARE and tau19 are not independent.

### k31 mode

The exact modes are

`BARE | FULL_QR`.

BARE requires the cofactor D to have prime support in

`H31={1,5,25}`.

Consequently

```text
k31 BARE -> tau31 in {0,19,29}
k31 BARE -> tau4 in {0,2}.
```

Equivalently, an odd-t k31 miss is forced into FULL_QR.

### k35 branch status

Because J35 and S7 may overlap, represent the exact branch label as one of

```text
J_ONLY
S7_ONLY
BOTH.
```

The 3-adic coupling gives

```text
tau9=4 -> J_ONLY.
```

On tau9 in `{1,7}`, any state carrying S7 additionally has

```text
distinguished_S7_prime = 3
support(F/3) subset {q : q=1 mod7}.
```

### Route-B k47 mode

On Route B the exact modes are

`THIN | FULL_QR`.

The THIN factor grammar excludes rational prime2. Therefore

```text
k47 THIN -> tau4 in {0,2}.
```

Combining k31 and k47 with the seam theorem gives the stronger odd-sector rule

```text
tau4 in {1,3}
    -> k31 FULL_QR
    -> Route-B k47 FULL_QR.
```

The same factor2 is present in both D and J and `gcd(D,J)=2`.

## 5. Route-A formal grammar count

Define the first coarse Route-A symbolic product over

```text
tau19 in S19                         9 choices
tau31 in S31                        15 choices
tau4  in {0,1,2,3}                  4 choices
tau9  in {0,...,8}                  9 choices
k19_mode in {BARE,FULL_QR}           2 choices
k31_mode in {BARE,FULL_QR}           2 choices
k35_status in {J_ONLY,S7_ONLY,BOTH}  3 choices.
```

Before cross-coordinate implications this contains

`9*15*4*9*2*2*3 = 58,320`

formal phase/mode tuples.

Now apply only the proved dependency rules:

1. Route-A k19 BARE requires tau19=2;
2. k31 BARE requires tau31 in `{0,19,29}` and even tau4;
3. tau9=4 requires k35 status J_ONLY.

The exact number of formal tuples not excluded by these rules is

`16,500`.

Equivalently the current dependency grammar retains

`16,500 / 58,320 = 275 / 972`

of the coarse Cartesian product, approximately

`0.2829218106995885`.

This is a **formal grammar compression ratio**, not an arithmetic survivor fraction.

## 6. Route-B formal grammar count

Route B adds

`k47_mode in {THIN,FULL_QR}`.

The naive coarse product therefore contains

`58,320*2 = 116,640`

formal tuples.

Apply the exact rules:

1. Route-B k19 BARE requires tau19=8;
2. k31 BARE requires tau31 in `{0,19,29}` and even tau4;
3. Route-B k47 THIN requires even tau4;
4. an odd tau4 forces `FULL_QR31 × FULL_QR47`;
5. tau9=4 requires k35 status J_ONLY.

Exactly

`25,500`

formal tuples are not excluded.

Thus the current Route-B grammar retains

`25,500 / 116,640 = 425 / 1,944`

of the naive product, approximately

`0.21862139917695472`.

Again, this is not a count of realizable arithmetic states.

## 7. Factorization of the grammar reduction

The counts above can be understood without brute force.

### k19 phase/mode block

Naive:

`9 phases * 2 modes = 18`.

Not excluded:

- 9 FULL_QR phase/mode pairs;
- 1 route-specific BARE phase/mode pair.

Total:

`10`.

### Route-A k31 phase/seam block

Naive:

`15 tau31 * 4 tau4 * 2 modes = 120`.

Not excluded:

- FULL_QR: all `15*4=60` phase pairs;
- BARE: `3` tau31 phases times `2` even tau4 phases =6.

Total:

`66`.

### Route-B joint k31/k47 block

Naive:

`15 tau31 * 4 tau4 * 2 k31 modes * 2 k47 modes = 240`.

Not excluded:

- odd tau4: only FULL_QR/FULL_QR, giving `15*2=30`;
- even tau4 with tau31 in the three BARE-compatible phases: `3*2*4=24`;
- even tau4 on the other twelve tau31 phases: `12*2*2=48`.

Total:

`102`.

### k35 phase/branch block

Naive:

`9 tau9 * 3 statuses = 27`.

Not excluded:

- eight ordinary tau9 phases retain all three statuses:24;
- tau9=4 retains only J_ONLY:1.

Total:

`25`.

Therefore

```text
Route A: 10 * 66  * 25 = 16,500
Route B: 10 * 102 * 25 = 25,500.
```

## 8. Orthogonality to the later phase envelope

The landed k39/k43/k47/k51/k55 phase filters use moduli independent of the coarse `19,31,4,9` grammar after route conditioning, except for the route-fixed modulus already removed on each route.

Those later filters can therefore be tensored onto the reduced grammar without changing the formal compression ratios above.

This is useful architecturally:

- the **phase envelope** restricts where a route may live;
- the **dependency grammar** restricts which mode labels may coexist on that phase;
- the **support grammars** restrict the prime-factor resources inside each surviving label.

They are distinct layers and should remain distinct in the machine.

## 9. Proposed normalized exact state

For the realized h169 pair-route laboratory, a more faithful state signature is now

```text
Sigma_red = (
    route,
    CRT_phase,
    k19_mode,
    k27_mode,
    k31_mode,
    k35_status,
    route_terminal_mode,
    separated_support,
    affine_data
)
```

where

- `CRT_phase` contains the exact residues needed by the proved phase rules;
- parity, 2-adic seam, and k35 3-adic bucket are derived from CRT_phase;
- `route_terminal_mode` is currently Route-B k47 `THIN|FULL_QR` or the Route-A fixed k51 endpoint family;
- k27 remains an exact seven-mode coordinate until a cross-coordinate coupling theorem reduces it;
- separated support and affine identities remain proof-bearing arithmetic data.

The old schematic field list is not wrong, but several fields are now redundant unless retained for telemetry.

## 10. Constraint-propagation direction

The machine should apply exact implications to a fixed point before scheduling new factor work.

Examples:

```text
k31=BARE
    -> tau31 in {0,19,29}
    -> tau4 even
    -> even support seam
    -> gcd(D,J)=1

Route-B k47=THIN
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

This is the beginning of an actual propagation engine rather than a passive state record.

## 11. Bryan Entanglement Cross / BREC integration boundary

The directional entanglement layer should consume these exact propagation events as annotations, never replace them.

A theorem that removes a formal state combination is a natural candidate for a downward/excavation annotation. A forced signed-box certificate is a natural candidate for a rightward/constructive annotation. An ontology expansion may be annotated upward.

But the canonical proof state remains `Sigma_red`, and the arithmetic implication remains the sole source of pruning permission.

If directional history is retained, store it as telemetry such as

`BEC_history`

beside the proof state, not inside the mathematical predicate that decides whether a branch is valid.

## 12. Next theorem target

The glaring unreduced coordinate is now k27.

The next high-value problem is:

> couple the exact k27 seven-mode grammar to one of the already-derived phase, valuation, or separated-support coordinates.

A successful k27 coupling would remove the largest remaining local finite-state block from the formal Cartesian product and materially strengthen the case that the candidate framework admits a finite constraint-propagation engine.