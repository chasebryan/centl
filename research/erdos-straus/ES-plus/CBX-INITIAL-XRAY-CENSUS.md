# CBX initial X-ray census

**Status:** finite implementation-validation census  
**Date:** 2026-08-15  
**Program:** ES+  
**Kernel:** `cbx.kernel 0.1.0`  
**Core source blob:** `cd2202ae512c687cdd7af8ce591eb29806a35008`  
**Signal-atomic runtime blob:** `9f9b2c26a47f1c456e90d68824dd7313e69b8d48`  
**Claim boundary:** finite observation only. These maxima are not universal bounds, do not prove an adaptive K law, and do not prove Erdős–Straus.

---

## 1. Purpose

The first formal CB X-ray census validates the complete path

\[
\text{hard prime}
\to
(W,I,N,L)\text{ independent probes}
\to
\text{JSONL}
\to
\text{deduplicated stratum analysis}.
\]

The arithmetic/search core has Git blob SHA

```text
cd2202ae512c687cdd7af8ce591eb29806a35008
```

and the signal-atomic runtime wrapper has blob SHA

```text
9f9b2c26a47f1c456e90d68824dd7313e69b8d48
```

The build was GNU C 14.2.0 on x86_64 Linux.

### Dry-run correction

An earlier timeout-driven validation stream was intentionally discarded from the formal census. The termination signal arrived while its final target was inside Lane I, exposing a runtime flaw: the original core could interpret `halt_flag` as a Lane-I miss and then advance a batch cursor past an interrupted suffix.

That was an implementation artifact, not mathematics. Direct probing showed the apparent miss actually hits at `k=3`.

The production build now enters through `cbx_runtime.c`. Once a target has begun, all of its lane probes finish atomically before SIGINT/SIGTERM is honored. Sweep and home cursors also stop at the first unprocessed integer/S rather than jumping to the end of an interrupted batch.

Formal finite censuses no longer require a timeout. The runtime implements `--iterations N` so an exact number of complete batches can be requested.

---

## 2. Formal run configuration

The clean run used the default finite search grade

\[
\boxed{
\Gamma=(F,K_I,E_N,A_L)=(11,400,300,400)
}
\]

with fixed Lane-I policy, sweep only, step `5000`, and exactly `46908` complete iterations:

```text
cbx go --run formal --step 5000 --iterations 46908 --sweep-only
```

No termination signal was used.

Final saved state:

```text
sweep=234540000
home_S=5
observations=401752
unique_letters=0
windows=46908
fab_max=11
i_max=400
n_ell_max=300
l_max=400
policy=fixed
policy_scale=20
```

The run completed in approximately `18.96 s` on the validation host.

The clean observation stream contained exactly `401752` JSONL records, occupied approximately `180 MB`, and had SHA-256

```text
6079ae0848d271d69ddc528e7c1b90cec1c988bcde929e2e1316e6c7d2a43ea1
```

No sweep/home deduplication was needed because this formal run was sweep-only.

---

## 3. All hard-prime targets

Across all `401752` observed Mordell-hard primes:

| hidden lane | hits | misses | hit rate | min | p50 | p90 | p99 | max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Lane I: `k_I*` | 401752 | 0 | 100.00% | 3 | 7 | 11 | 23 | 107 |
| Lane N: first `ell` | 401752 | 0 | 100.00% | 11 | 13 | 19 | 31 | 103 |
| Lane L: first `a` | 397391 | 4361 | 98.91% | 3 | 6 | 33 | 210 | 396 |

The production-equivalent stacked verdict emitted

```text
0 letters
```

in this finite interval.

The finite Lane-I record is

\[
\boxed{
\max_{p\le234540000}^{\mathrm{observed}} k_I^*(p)=107.
}
\]

The configured Lane-I ceiling was `400`. The observed maximum `107` is not a theorem and is not a proposed universal ceiling.

---

## 4. R / fab-only stratum

CBX identified `102502` targets in `R`. Every observed target in this stratum was also hit by the configured fab window, so `R` and `fab-only` coincide in this run.

| hidden lane | hits | misses | hit rate | min | p50 | p90 | p99 | max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Lane I: `k_I*` | 102502 | 0 | 100.00% | 3 | 7 | 15 | 27 | 107 |
| Lane N: first `ell` | 102502 | 0 | 100.00% | 11 | 13 | 19 | 37 | 103 |
| Lane L: first `a` | 98770 | 3732 | 96.36% | 3 | 12 | 78 | 320 | 396 |

Thus the X-ray view confirms the reason CBX is useful: W/fab can finish the target operationally while the later lanes have a nontrivial hidden depth distribution underneath it.

In particular:

\[
\boxed{
\operatorname{p99}(k_I^*\mid R)=27,
\qquad
\max(k_I^*\mid R)=107.
}
\]

These are finite statistics only.

---

## 5. Linear W stratum

The remaining `299250` observed targets were linear-W hits.

| hidden lane | hits | misses | hit rate | min | p50 | p90 | p99 | max |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Lane I: `k_I*` | 299250 | 0 | 100.00% | 3 | 7 | 11 | 23 | 75 |
| Lane N: first `ell` | 299250 | 0 | 100.00% | 11 | 11 | 19 | 31 | 101 |
| Lane L: first `a` | 298621 | 629 | 99.79% | 3 | 6 | 20 | 122 | 396 |

The finite Lane-I tail is therefore visibly heavier inside `R` than in the linear-W population.

---

## 6. Spectrum split

### Spectrum A

`134165` targets:

```text
I: 134165/134165, p50=7, p90=15, p99=23, max=63
N: 134165/134165, p50=13, p90=19, p99=31, max=103
L: 132639/134165, p50=6, p90=33, p99=210, max=396
```

### Spectrum B

`133809` targets:

```text
I: 133809/133809, p50=7, p90=11, p99=23, max=107
N: 133809/133809, p50=11, p90=19, p99=31, max=79
L: 132384/133809, p50=6, p90=33, p99=207, max=396
```

### Spectrum C

`133778` targets:

```text
I: 133778/133778, p50=7, p90=15, p99=23, max=71
N: 133778/133778, p50=13, p90=19, p99=31, max=101
L: 132368/133778, p50=6, p90=35, p99=210, max=396
```

The largest observed Lane-I depth occurs in Spectrum B in this finite run. That does not establish an asymptotic spectrum ordering.

---

## 7. Running Lane-I frontier

The analyzer now computes the empirical running frontier

\[
K_{\mathrm{obs}}(X)
=
\max\{k_I^*(p):p\le X\text{ observed}\}.
\]

Across all observed targets, only six record events occurred:

| p | spectrum | R | `k_I*` | omega | Omega | box size |
| ---: | :---: | :---: | ---: | ---: | ---: | ---: |
| 1009 | B | no | 3 | 2 | 2 | 9 |
| 1129 | B | no | 11 | 3 | 3 | 27 |
| 1201 | C | no | 23 | 3 | 4 | 45 |
| 21169 | B | no | 31 | 3 | 5 | 75 |
| 118801 | C | yes | 59 | 4 | 4 | 81 |
| 8803369 | B | yes | 107 | 4 | 6 | 225 |

Inside `R`, the record sequence is:

| p | spectrum | `k_I*` |
| ---: | :---: | ---: |
| 2521 | A | 23 |
| 87481 | A | 31 |
| 118801 | C | 59 |
| 8803369 | B | 107 |

No new Lane-I record occurs between `p=8,803,369` and the formal sweep endpoint `234,540,000`.

---

## 8. First concrete X-ray example

For

\[
p=2521,
\]

CBX records at the default grade:

```text
W: linear=false, R=true, fab=(2,1)
I: hit=true, first_k=23, omega=3, Omega=4, box_size=45
N: hit=true, ell=11, shift=31
L: no hit through A_L=400
production_letter=false
```

Production W disposes of `2521`, while the X-ray view reveals independent signed-box and external-NR constructions underneath the W verdict.

---

## 9. Adaptive-K falsification machinery

`analyze.py` now evaluates experimental policies directly against the measured first-hit depths. It reports the first failure, worst failure and failure count for policies such as

\[
K(p)=\lceil c\log p\rceil,
\qquad
K(p)=\lceil c(\log p)^2\rceil,
\]

with an optional `R`-only restriction.

This is a falsification tool, not a theorem generator. A policy surviving the finite census remains only an empirical envelope.

For example, the deliberately aggressive policy

\[
K(p)=\lceil2\log p\rceil
\]

fails many observed R targets. The record point

\[
p=8,803,369,
\qquad
k_I^*(p)=107
\]

already requires far more than that policy assigns.

---

## 10. What this changes

Before CBX, the production matrix could legitimately show I/N/L near zero because W had already marked the targets. That was operationally correct but research-poor.

The clean census demonstrates that the hidden lanes are not dormant. Lane I and the current external-NR lane each hit every one of the `401752` observed hard primes when evaluated independently at the default grade, while López has a visible finite miss population.

This gives the adaptive-K program an actual empirical object:

\[
\boxed{
\text{the conditional distribution and running records of }k_I^*(p)
\text{ beneath the production cover}.
}
\]

Next experiments should correlate new record events with:

- A/B/C spectrum;
- factor pattern of `(p+k_I*)/4`;
- signed-box size;
- defect/stabilizer signatures;
- first external NR prime;
- López depth or López truncation.

A candidate law such as `K(p)=O(log p)` or `O((log p)^2)` should only be promoted after repeated attempts to break it and, ultimately, a proof.

---

## 11. Reproducibility

The raw `180 MB` formal stream is not committed to git. Its SHA-256 is recorded above so a retained copy can be checked exactly.

The formal census is reproducible from the named source blobs, grade, step, iteration count and endpoint. Future publication-grade runs should compress and archive the raw observation stream outside the source tree with its checksum.

---

Erdős–Straus remains open. The observed Lane-I maximum `107` is a finite record, not a bound.
