# Full fiber-kernel and bounded-selector replay through k = 1200

**Status:** exact finite replay against the frozen `k<=1200` candidate certificate bundle  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this result is finite. It does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. The counts below were replayed from the already frozen `k<=1200` candidate bundle using the exact fiber-peeling and bounded-selector constructions now checked into the repository. They should be superseded by the next all-in-one hashed workflow artifact once that workflow completes.

Read with:

- [DIRECT-SHADOW-K1200.md](DIRECT-SHADOW-K1200.md)
- [FIBER-SHADOW-KERNEL.md](FIBER-SHADOW-KERNEL.md)
- [SMALL-SELECTOR-HYPOTHESIS.md](SMALL-SELECTOR-HYPOTHESIS.md)
- [`shadow_fiber_kernel_analyzer.py`](shadow_fiber_kernel_analyzer.py)
- [`shadow_small_selector_analyzer.py`](shadow_small_selector_analyzer.py)
- [CURRENT-FRONTIER.md](CURRENT-FRONTIER.md)

## 1. Input provenance

The input was the completed `k<=1200` Direct-Shadow bundle from GitHub Actions run

```text
31846146909
```

with artifact ID

```text
9236427053
```

and uploaded artifact ZIP digest

```text
sha256:a2479a4113d693af2e647ffc2e007d3d7b1cf628ce7190f72c4ad6282a98ba14
```

That bundle had already independently verified all `41,470` directly novel candidate witnesses through depth `1200`.

The replay did **not** use those stored reduced witnesses to decide fiber peelability or bounded-selector success.

## 2. Fiber-kernel result

There are

\[
41,470
\]

directly novel candidates in the frozen range.

Exact augmented fiber peeling empties the complete residual coordinate system for

\[
\boxed{26,044}
\]

of them:

\[
\boxed{26,044/41,470=62.802\%}.
\]

For those candidates, the fiber-peeling theorem itself supplies an independent constructive existence proof of a reduced avoiding class by reverse extension.

The remaining

\[
\boxed{15,426}
\]

candidates have nonempty residual fiber kernels.

## 3. Residual prime universe

Across the entire finite replay, every nonempty fiber kernel is supported on primes at most

\[
\boxed{23}.
\]

The complete kernel-size distribution is:

```text
size 0: 26,044
size 2:     28
size 3:  3,868
size 5:    142
size 6:    498
size 7: 10,890
```

No residual kernel of size `1` or `4` appeared.

The observed signatures were exactly:

```text
{}                                              26,044
{3,11,13}                                       3,868
{11,13}                                            28
{3,11,13,19,23}                                   142
{3,5,11,13,17,19,23}                           10,890
{3,5,11,13,17,23}                                 124
{3,5,13,17,19,23}                                  92
{5,11,13,17,19,23}                                  88
{3,5,11,13,17,19}                                  72
{3,5,11,13,19,23}                                  48
{3,5,11,17,19,23}                                  42
{3,11,13,17,19,23}                                 32
```

These signatures are finite observations, not a universal `p<=23` theorem.

## 4. Bounded-selector assault

For each of the `15,426` nonempty residual kernels, test the deterministic menu

\[
\mathcal S_{64}=\{0,\pm1,\pm2,\ldots,\pm64\}.
\]

A selector is accepted only if it:

1. avoids every residual exact forbidden pullback set;
2. preserves the required local reducedness conditions.

Result:

\[
\boxed{15,426/15,426}
\]

nonempty residual kernels are solved by this fixed menu.

Therefore

\[
\boxed{41,470/41,470}
\]

directly novel candidates through `k<=1200` are independently resolved by the two-stage construction

\[
\boxed{
\text{fiber peeling}
+
\text{bounded residual selector}.
}
\]

Unresolved selector kernels:

\[
\boxed{0}.
\]

## 5. Selector radius

The largest selector radius actually required was

\[
\boxed{54},
\]

not the configured bound `64`.

Cumulative resolution, including fiber-empty candidates, was:

| radius | total resolved fraction |
|---:|---:|
| fiber empty | 62.802% |
| 0 | 67.036% |
| <=1 | 75.124% |
| <=2 | 80.801% |
| <=3 | 85.028% |
| <=4 | 88.071% |
| <=5 | 90.586% |
| <=6 | 92.390% |
| <=7 | 93.800% |
| <=8 | 94.951% |
| <=9 | 95.975% |
| <=10 | 96.696% |
| <=11 | 97.273% |
| <=12 | 97.769% |
| <=13 | 98.153% |
| <=14 | 98.500% |
| <=16 | 99.016% |
| <=19 | 99.491% |
| <=31 | 99.961% |
| <=43 | 99.993% |
| <=48 | 99.998% |
| <=54 | 100.000% |

## 6. Hardest selector in the replay

The unique candidate requiring radius `54` under the deterministic selector ordering was

```text
candidate index: 35,972
k:               1062
h mod 840:       361
t mod (4k-1):    4129
r:               1,940,761
L:               3,567,480
selector:        -54
```

Its residual fiber kernel uses

\[
\boxed{\{3,5,11,13,17,19,23\}}
\]

and contains `64` residual exact constraints.

Every selector of smaller absolute value fails that residual system; `+54` also fails before `-54` succeeds in the deterministic order.

This is a useful regression fixture for future theorem attempts.

## 7. Why this is materially stronger than the raw witness scan

The original candidatewise scan established, for each candidate, an explicit reduced parameter found by searching the original progression.

The replay uses a different architecture:

\[
\text{hundreds of earlier layers}
\to
\text{exact fiber elimination}
\to
\text{tiny small-prime kernel}
\to
\text{one selector from a fixed 129-element menu}.
\]

The stored witness is not needed to decide either step.

Thus the finite phenomenon is no longer only

> a witness exists.

It is now

> a witness can be constructed after theorem-driven elimination from a uniformly tiny residual menu throughout the tested range.

That is substantially closer to a proof architecture.

## 8. The next theorem target

The data suggests two increasingly strong statements:

### Bounded-kernel target

Prove that every directly novel candidate peels to a residual kernel belonging to a controlled small-prime family.

### Selector target

Prove that every such residual kernel admits a selector from a bounded set independent of `k`, or identify the arithmetic mechanism that replaces the finite menu.

A theorem of that form would give

\[
\boxed{
\text{direct novelty}
\Longrightarrow
\text{fiber peel}
\Longrightarrow
\text{bounded local selector}
\Longrightarrow
\text{reduced avoiding progression},
}
\]

which is a concrete route to universal DSC-P.
