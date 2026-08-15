# CN-shared certificate — 2026-08-15

**Status:** exact finite replay of `cn_shared_analyzer.py` / `verify_cn_shared.py`  
**Claim boundary:** certificate for the statements in `CN-SHARED-THEOREM.md`. Not Erdős-Straus, not López-all-primes, not universal DSC-P.

## Replayable commands

```text
python3 research/erdos-straus/cn_shared_analyzer.py \
  --out /tmp/cn-shared-output --j-limit 160 --k-limit 1500 --program-k-limit 200
python3 research/erdos-straus/verify_cn_shared.py \
  --out /tmp/cn-shared-output --j-limit 120 --k-limit 180
```

## Official machine replay

Artifacts in [`certificates/`](certificates/):

- [`certificates/cn-shared-report.md`](certificates/cn-shared-report.md)
- [`certificates/cn-shared.json`](certificates/cn-shared.json)
- [`certificates/cn-shared-independent-verifier.json`](certificates/cn-shared-independent-verifier.json)

Independent verifier: **VERIFIED**.

SHA-256 (`certificates/SHA256SUMS`):

```text
aed869f84500e109b1477d08cc24c7486bbe60397040bbe209ae285aada2a52e  cn-shared.json
741958030cfed41f56a7fb9e7faf728ca97110954bd21e016c27d9410fd8b0b0  cn-shared-report.md
2239aeb27765bc7515a7cfaa0dae83ebb0350a746bcae7eb718c97b82c124c78  cn-shared-independent-verifier.json
```

| Scan | Result |
|------|--------|
| Totient-ratio, odd `q ≤ 5000` | 10,071 checks; min ratio `2`; **0** fails |
| Standard-`L` pairs `j ≤ 160`, mixed `r` | 980,238 pairs; **0** fails; **0** C1 fails |
| Program `L`, hard `r`, `k ≤ 200` | 7,184,124 pairs; **0** fails |
| Exact complementary `q=3` on standard `L` | 124 unrestricted covers; **0** on `L=840` and `L=2520` |
| Admissible tight `q ≤ 9` pairs, `k ≤ 1500` | 73,814 candidates; 1,365,201 escapes; **21** complementary fails; **0** novel fails |
| Tight `q ≤ 9` triples, `k ≤ 1500` | 3,994,891 checks; **0** fails |
| Independent pair-mask recheck | 306,564 pairs; **0** disagreements |
| Independent program sample `k ≤ 180` | 5,186,154 pairs; **0** fails |

## The 21 admissible complementary covers

All have `q1=q2=3` and contain layer `205`.

| k | h | t | pair |
|--:|--:|--:|------|
| 465 | 289 | 1828 | 25, 205 |
| 608 | 1 | 2429 | 205, 322 |
| 972 | 1 | 3885 | 52, 205 |
| 972 | 169 | 3815 | 52, 205 |
| 972 | 361 | 3879 | 52, 205 |
| 1050 | 169 | 2099 | 205, 556 |
| 1050 | 529 | 4191 | 205, 556 |
| 1180 | 1 | 2359 | 205, 322 |
| 1180 | 1 | 4717 | 205, 322 |
| 1180 | 361 | 4711 | 205, 322 |
| 1180 | 529 | 4711 | 205, 322 |
| 1271 | 361 | 4919 | 52, 205 |
| 1271 | 529 | 4919 | 52, 205 |
| 1310 | 1 | 2619 | 70, 205 |
| 1310 | 121 | 4584 | 70, 205 |
| 1310 | 169 | 5237 | 70, 205 |
| 1310 | 529 | 5231 | 70, 205 |
| 1466 | 1 | 5861 | 205, 322 |
| 1466 | 1 | 2931 | 205, 322 |
| 1466 | 169 | 5861 | 205, 322 |
| 1466 | 529 | 5855 | 205, 322 |

Pair counts: `(205,322)×9`, `(52,205)×5`, `(70,205)×4`, `(205,556)×2`, `(25,205)×1`.

## Unrestricted counterexamples (not program-admissible)

Complementary `q=3` covers exist for arbitrary `(L,r)`. First recorded examples include `L=55440`, `j=7,520`, `r=653` with `R={2}` and `{1}`. These show unrestricted C2-shared is false. They are not Type A/B candidates.

## Absorption check

Every recorded case with `q_205=3` and `R_205 ≠ ∅` has `39 | L` and is covered by `T_10`, as proved in `CN-SHARED-THEOREM.md` §6.
