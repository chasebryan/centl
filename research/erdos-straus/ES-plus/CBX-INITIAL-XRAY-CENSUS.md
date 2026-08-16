# CBX initial X-ray census

**Status:** finite implementation-validation census  
**Date:** 2026-08-15  
**Program:** ES+  
**Kernel:** `cbx.kernel 0.1.0`  
**Source blob:** `cd2202ae512c687cdd7af8ce591eb29806a35008`  
**Claim boundary:** finite observation only. These maxima are not universal bounds, do not prove an adaptive K law, and do not prove Erdős–Straus.

---

## 1. Purpose

The first end-to-end CB X-ray run was made immediately after implementation to test the complete path

\[
\text{hard prime}
\to
(W,I,N,L)\text{ independent probes}
\to
\text{JSONL}
\to
\text{deduplicated stratum analysis}.
\]

The source used for the run has Git blob SHA

```text
cd2202ae512c687cdd7af8ce591eb29806a35008
```

which exactly matches `research/erdos-straus/cbx.kernel/src/cbx.c` on the implementation branch at the time of this census.

The test build was GNU C 14.2.0 on x86_64 Linux.

---

## 2. Run configuration

The run used the default finite search grade

\[
\boxed{
\Gamma=(F,K_I,E_N,A_L)=(11,400,300,400)
}
\]

with fixed Lane-I policy and sweep only.

Command shape:

```text
cbx go --run e2e --step 5000 --sweep-only
```

The process received a normal termination signal after approximately twenty seconds. CBX handled the signal and saved the cursor.

Final saved state:

```text
sweep=234540000
home_S=5
observations=401747
unique_letters=0
windows=46908
fab_max=11
i_max=400
n_ell_max=300
l_max=400
policy=fixed
policy_scale=20
```

The observation stream contained exactly `401747` JSONL records and had SHA-256

```text
dd43ec5d76c295869dfe02059b4f92513659f9ec13ea514154728761d81f663c
```

No sweep/home deduplication was needed because this validation run was sweep-only.

---

## 3. All hard-prime targets

Across all `401747` observed Mordell-hard primes:

| hidden lane | hit rate | min | p50 | p90 | p99 | max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Lane I: `k_I*` | 100.00% | 3 | 7 | 11 | 23 | 107 |
| Lane N: first `ell` | 100.00% | 11 | 13 | 19 | 31 | 103 |
| Lane L: first `a` | 98.91% | 3 | 6 | 33 | 210 | 396 |

The production-equivalent stacked verdict emitted

```text
0 letters
```

in this finite interval.

The most striking implementation-validation signal is:

\[
\boxed{
\max_{p\le234540000}^{\mathrm{observed}} k_I^*(p)=107
}
\]

while the configured Lane-I ceiling was `400`.

This is an observed maximum, not a theorem and not a proposed universal ceiling.

---

## 4. R / fab-only stratum

CBX identified `102500` targets in `R`. In this run every such observed target was also hit by the configured fab window, so the `R` and `fab-only` strata coincide.

For these `102500` targets:

| hidden lane | hit rate | min | p50 | p90 | p99 | max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Lane I: `k_I*` | 100.00% | 3 | 7 | 15 | 27 | 107 |
| Lane N: first `ell` | 100.00% | 11 | 13 | 19 | 37 | 103 |
| Lane L: first `a` | 96.36% | 3 | 12 | 78 | 320 | 396 |

Thus the first X-ray view confirms the reason CBX is useful: W/fab can finish the target operationally while the later lanes have a nontrivial hidden depth distribution underneath it.

In particular, the R/fab-only Lane-I tail is still shallow in this finite sample:

\[
\boxed{
\operatorname{p99}(k_I^*\mid R)=27,
\qquad
\max(k_I^*\mid R)=107.
}
\]

Again, these are finite statistics only.

---

## 5. Linear W stratum

The remaining `299247` observed targets were linear-W hits.

| hidden lane | hit rate | min | p50 | p90 | p99 | max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Lane I: `k_I*` | 100.00% | 3 | 7 | 11 | 23 | 75 |
| Lane N: first `ell` | 100.00% | 11 | 11 | 19 | 31 | 101 |
| Lane L: first `a` | 99.79% | 3 | 6 | 20 | 122 | 396 |

The Lane-I tail is therefore visibly heavier inside R than in the linear-W population at this finite scale.

That difference is precisely the kind of structural conditioning the X-ray program was designed to measure.

---

## 6. Spectrum split

### Spectrum A

`134163` targets:

```text
I: 100%, p50=7, p90=15, p99=23, max=63
N: 100%, p50=13, p90=19, p99=31, max=103
L: 98.86%, p50=6, p90=33, p99=210, max=396
```

### Spectrum B

`133808` targets:

```text
I: 100%, p50=7, p90=11, p99=23, max=107
N: 100%, p50=11, p90=19, p99=31, max=79
L: 98.94%, p50=6, p90=33, p99=207, max=396
```

### Spectrum C

`133776` targets:

```text
I: 100%, p50=7, p90=15, p99=23, max=71
N: 100%, p50=13, p90=19, p99=31, max=101
L: 98.95%, p50=6, p90=35, p99=210, max=396
```

The largest observed Lane-I depth in this run occurs in Spectrum B, but one finite maximum is not evidence that Spectrum B has the asymptotically heaviest tail.

---

## 7. First concrete X-ray example

The known prime

\[
p=2521
\]

is a useful microscopic example of the same phenomenon.

CBX records at the default grade:

```text
W: linear=false, R=true, fab=(2,1)
I: hit=true, first_k=23, omega=3, Omega=4, box_size=45
N: hit=true, ell=11, shift=31
L: no hit through A_L=400
production_letter=false
```

Production W therefore disposes of `2521`, while the X-ray view reveals independent signed-box and external-NR constructions underneath the W verdict.

---

## 8. What this changes

Before CBX, the production matrix could legitimately show I/N/L near zero because W had already marked the targets. That was operationally correct but research-poor.

The first CBX census demonstrates that the hidden lanes are not dormant. They are active on essentially the entire finite sample when evaluated independently.

This gives the adaptive-K program an actual empirical object:

\[
\boxed{
\text{the conditional distribution of }k_I^*(p)
\text{ beneath the production cover}.
}
\]

The next experiments should therefore track the running record sequence of `k_I*`, especially inside R/fab-only, and correlate record events with:

- A/B/C spectrum;
- factor pattern of `(p+k_I*)/4`;
- signed-box size;
- defect/stabilizer signatures;
- first external NR prime;
- López depth or López truncation.

A candidate law such as `K(p)=O(log p)` or `O((log p)^2)` should only be proposed after the record-depth sequence is long enough to support a meaningful falsification attempt.

---

## 9. Reproducibility warning

The raw `179 MB` validation stream was generated as an implementation test and is not committed to git. Its SHA-256 is recorded above so a retained copy can be checked exactly.

The theorem-facing evidence is the deterministic kernel source, the grade, the cursor and the summary. A future formal census intended for publication should be run under a named archival protocol with the observation stream compressed, checksummed, and deposited outside the source tree.

---

Erdős–Straus remains open. The observed Lane-I maximum `107` is a finite record, not a bound.
