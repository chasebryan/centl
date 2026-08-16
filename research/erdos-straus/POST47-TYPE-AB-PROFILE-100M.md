# Type A/B profile of the corrected post-47 corridor through 100M

**Status:** exact finite bounded audit  
**Date:** 2026-08-16  
**Fixed-shift base:** exact classifiers through `k=55`  
**Type A/B model:** bounded all-layer audit matching the model in draft PR #231  
**Machine certificate:** `analyze_post47_ab_profile.py`  
**Claim boundary:** this is a finite comparison between two distinct research coordinates. It does not assert Type A/B completeness and does not prove Erdős–Straus.

## 1. Why this comparison matters

The fixed-shift signed-box corridor and the López Type A/B model are related but are not the same object.

The corrected 100M fixed-shift census has exactly 29 Mordell-hard primes that miss every classified fixed shift

\[
3,7,11,15,19,23,27,31,35,39,43,47.
\]

Draft PR #231 makes an important epistemic distinction explicit: a bounded Type A/B audit scans every layer

\[
m=4j-1,\qquad 1\le j\le K,
\]

including composite `m`, while a finite miss through `K` means only that no Type A/B witness was found through that bound.

Therefore the 29-prime fixed-shift corridor should be given an independent Type A/B label rather than being treated as evidence against Type A/B.

## 2. Exact bounded Type A/B scan

For each A/B index `j`, each divisor split

\[
j=dn
\]

is tested against

\[
\text{Type B}:\quad p\equiv-n\pmod{4dn-1},
\]

and

\[
\text{Type A}:\quad p\equiv-4d\pmod{4dn-1}.
\]

The analyzer scans increasing `j` and records the first bounded A/B witness.

## 3. Result

For the complete 29-prime post-47 survivor set through `100,000,000`, every prime has a Type A/B witness by

\[
\boxed{j\le71}.
\]

Thus at audit depth `K=71`:

```text
post-47 fixed-shift survivors     29
A/B explained through K=71       29
A/B unseen through K=71            0
Type A first witnesses            16
Type B first witnesses            13
maximum first A/B index           71
```

So none of the current 100M deep fixed-shift survivors is a bounded Type A/B model-escape candidate at depth 71.

This does **not** prove Type A/B complete. It says only that this particular finite fixed-shift survivor set is already explained very shallowly by the broader Type A/B model.

## 4. First-witness depth distribution

```text
j=15   4
j=17   1
j=18   6
j=20   2
j=21   1
j=22   3
j=26   2
j=28   1
j=32   1
j=33   1
j=41   1
j=48   2
j=50   1
j=54   1
j=65   1
j=71   1
```

The corridor is therefore not concentrating at the known large `C_AB` frontier. It is largely composed of primes that are difficult for the selected fixed shifts but easy for the broader Type A/B model.

## 5. The `25,569,769` anomaly under the new interpretation

The prime

\[
\boxed{p=25,569,769}
\]

was important because it refuted the 10M cross-shift conjecture: it misses every tested fixed shift through `k=51` and first hits the fixed-shift corridor at `k=55`.

Under the independent Type A/B audit, however, its first bounded witness is already

```text
Type B
A/B index j = 15
m = 59
d = 3
n = 5
```

because

\[
p\equiv-5\pmod{59}.
\]

Therefore this prime is a **fixed-shift obstruction anomaly**, not a bounded Type A/B escape.

That distinction is exactly the kind of assumption hygiene introduced by PR #231.

## 6. Post-51 and post-55 slices

The corrected 100M corridor has:

```text
post-47 survivors   29
hit at fixed k=51    7
post-51 survivors   22
hit at fixed k=55   10
post-55 survivors   12
```

All 22 post-51 survivors are Type A/B explained by `j<=71`.

All 12 post-55 survivors are also Type A/B explained by `j<=65`; their first bounded witnesses are:

```text
118801     B  j=48  m=191  d=48 n=1
806521     B  j=65  m=259  d=13 n=5
8803369    A  j=48  m=191  d=3  n=16
10051441   A  j=54  m=215  d=6  n=9
11720641   A  j=15  m=59   d=1  n=15
14872729   A  j=22  m=87   d=2  n=11
22202569   A  j=26  m=103  d=2  n=13
32794441   B  j=15  m=59   d=15 n=1
39606961   B  j=20  m=79   d=4  n=5
77599729   A  j=22  m=87   d=2  n=11
80156521   B  j=17  m=67   d=17 n=1
90108841   B  j=33  m=131  d=1  n=33
```

This substantially changes the interpretation of the next fixed-shift stages.

## 7. Strategic consequence

The fixed-shift program remains valuable because its finite-group closures expose exact obstruction geometry, character selection, and companion interactions.

But if the research objective is specifically to test whether Type A/B is a false completeness assumption, the current 100M post-47/post-51/post-55 corridor is **not** the strongest target population.

A better Type A/B-skeptic search should prioritize primes satisfying both:

1. unusually deep or unseen bounded Type A/B status under the full all-layer audit; and
2. interesting behavior under the independent W/I/N/fixed-shift machinery.

In other words:

> fixed-shift depth and Type A/B depth should be treated as separate axes of hardness.

PR #231 provides the correct instrument for the second axis.

## 8. Reproduction

```sh
python3 research/erdos-straus/analyze_post47_ab_profile.py --K 71 --json
```

The script's embedded 29-prime list is the corrected post-47 survivor set through 100M. It performs only the bounded Type A/B audit; it does not redefine or regenerate the fixed-shift census universe.

For arbitrary selected primes:

```sh
python3 research/erdos-straus/analyze_post47_ab_profile.py --K 500 P1 P2 P3 --json
```

The key methodological rule is:

> **A fixed-shift miss is not a Type A/B miss, and a bounded Type A/B miss is not proof that Type A/B fails globally.**

Erdős–Straus remains open.
