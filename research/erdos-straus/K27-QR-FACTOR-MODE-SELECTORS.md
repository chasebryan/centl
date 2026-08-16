# k27 QR-factor mode selectors

**Status:** exact cross-coordinate selector module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k27_qr_factor_mode_selectors.py`  
**Depends on:** `K27-SURVIVOR-GRAMMAR.md` and the realized k19 pair survivor normal form  
**Claim boundary:** exact necessary mode restrictions for k27 survival. This is not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Why the seven-mode coordinate can sometimes collapse

For h169,

`C27 = 7E`,

with

`E = 7 + 30t`.

The exact k27 theorem separates the nonresidue factor occurrences of E into one of seven live NR-skeleton modes

`Q,A,B,C,D,E,F`,

then processes QR27 factor occurrences through the exact transition table.

Because factor transitions commute and hits are absorbing, if one known rational prime factor of E has QR residue r modulo27, that occurrence may be applied immediately to the skeleton mode. Any skeleton mode sent to HIT by r is impossible for a final k27 miss.

Thus deterministic divisibility of E by a rational prime can act as a **mode selector** before the rest of E is factored.

## 2. Complete one-occurrence QR selector table

The landed transition table gives the exact live skeleton modes after requiring one occurrence of each QR residue:

```text
QR residue r   skeleton modes not killed by one r
-------------------------------------------------
1              Q,A,B,C,D,E,F
4              Q,A,D
7              Q,A,C
10             Q
13             Q,E
16             Q
19             Q
22             Q
25             Q,F
```

This is read directly from the exact transition table:

- Q is stable under every QR residue;
- A survives only r in `{1,4,7}`;
- B survives only r=1;
- C survives only r in `{1,7}`;
- D survives only r in `{1,4}`;
- E survives only r in `{1,13}`;
- F survives only r in `{1,25}`.

Therefore residues

`{10,16,19,22}`

are **one-occurrence Q selectors**:

> if E contains any prime-factor occurrence with one of those residues and k27 still misses, then the NR skeleton must be Q.

Since Q is the empty NR skeleton, this implies every prime factor of E is QR27.

## 3. Repeated QR occurrences

For residues

`{4,7,13,25}`,

one occurrence still permits one or two non-Q skeleton modes. A second occurrence removes them:

```text
r=4:  A -> C -> HIT, D -> B -> HIT
r=7:  A -> D -> HIT, C -> B -> HIT
r=13: E -> B -> HIT
r=25: F -> B -> HIT.
```

Hence for

`r in {4,7,13,25}`,

two occurrences of r force Q on any surviving k27 branch.

Symbolically:

`multiplicity_r(E) >= 2 AND k27 miss => mode Q`.

Together with the one-occurrence selectors, every nontrivial QR residue except1 has a finite mode-collapse threshold of at most2.

## 4. Rational-prime divisibility phases

For any rational prime q not dividing30,

`q | E`

is equivalent to the unique phase

`t = -7 * 30^(-1) mod q`.

Likewise

`q^2 | E`

has a unique phase modulo q^2.

The smallest useful examples are:

```text
q    q mod27    q|E phase       q^2|E phase       k27 miss consequence
7       7       t=0 mod7        t=21 mod49        Q/A/C; square -> Q
13     13       t=8 mod13       t=73 mod169       Q/E;   square -> Q
19     19       t=8 mod19       t=84 mod361       Q immediately
31      4       t=7 mod31       t=224 mod961      Q/A/D; square -> Q
37     10       t=1 mod37       t=593 mod1369     Q immediately
43     16       t=27 mod43      t=801 mod1849     Q immediately
79     25       t=34 mod79      t=1456 mod6241    Q/F;   square -> Q
103    22       t=65 mod103     t=4597 mod10609   Q immediately
```

These are exact phase-to-mode implications, not frequency observations.

## 5. The Route-B k19 BARE collapse

The realized Route-B k19 BARE state has exact center phase

`t = 8 mod19`.

But the k27 cofactor satisfies

`E = 7 + 30t`.

Modulo19,

`E = 7 + 11t`.

At t=8,

`E = 0 mod19`.

Therefore every Route-B k19 BARE branch has rational prime19 dividing E.

The residue of that prime in the k27 unit group is

`19 mod27`,

which is a one-occurrence Q selector.

Hence the exact cross-shift theorem:

`Route-B k19 BARE AND k27 miss => k27 mode Q`.

Equivalently:

> on a Route-B BARE survivor that also survives k27, every rational prime factor of E is a quadratic residue modulo27.

The seven-mode k27 coordinate collapses to one mode on this upstream state.

No factorization of the remaining cofactor E is needed to derive the mode collapse.

## 6. Stronger support form

Mode Q is the empty NR skeleton and is stable under arbitrary QR27 completion.

Therefore the Route-B BARE/k27 survivor state carries the exact support law

`support(E) subset QR27`.

The local simultaneous survivor state then includes four separated support systems already present in the program:

```text
R: Route-B k19 BARE residual support = 1 mod19
B: every prime factor QR mod23
E: every prime factor QR mod27
D: every prime factor QR mod31
```

with R,B,E,D pairwise coprime by the landed support-separation theorem.

This is substantially sharper than retaining `k27_mode in {Q,A,B,C,D,E,F}` on the Route-B BARE branch.

## 7. General phase selector t=8 mod19

The Q-selector statement does not require k19 BARE as a logical premise.

For any h169 branch,

`t=8 mod19 AND k27 miss => mode Q`,

because the phase alone forces19|E.

The Route-B BARE theorem is important because it supplies that phase automatically from an already-live upstream survivor mode.

Thus the dependency graph contains both edges:

```text
Route-B k19 BARE -> tau19=8

tau19=8 -> 19|E -> k27 Q  (conditional on k27 miss).
```

Their composition gives the cross-shift collapse.

## 8. Machine consequence

The normalized h169 dependency grammar should no longer treat Route-B k19 BARE and k27 mode as independent.

Add the exact propagation rule

```text
if route == B and k19_mode == BARE:
    tau19 = 8
    if k27 misses:
        k27_mode = Q
        E_support = QR27
```

More generally, whenever a proved phase or factorization route guarantees a QR27 factor residue in `{10,16,19,22}`, k27 mode Q may be promoted immediately on a miss.

Repeated residues in `{4,7,13,25}` provide an analogous Q promotion after the second occurrence.

This turns the seven-mode k27 automaton into a factor-triggered selector rather than an opaque state block.

## 9. Bryan Entanglement Cross / BREC boundary

A deterministic factor that collapses seven possible k27 modes to one is a natural candidate for a downward/excavation annotation in the directional layer, while the surviving QR27 support law is the constructive information exposed by that descent.

That narrative is metadata. The exact residue transition table and divisibility phase are the proof-bearing objects and the sole source of the mode reduction.

## 10. Next target

Two immediate continuations are now concrete:

1. feed `Route-B BARE -> k27 Q` back into the reduced dependency grammar and measure the additional formal-state contraction;
2. search the remaining upstream modes/phases for deterministic factors whose QR27 residues select smaller subsets of `{Q,A,...,F}`.

The first is bookkeeping. The second is theorem mining. Both can now be performed without reopening the raw 132-state k27 closure.