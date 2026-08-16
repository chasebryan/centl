# CBX implementation status

**Status:** active experimental research kernel implementation  
**Date:** 2026-08-15  
**Program:** ES+  
**Kernel:** `cbx.kernel 0.1.0`  
**Production boundary:** `cbis.kernel 1.2.0` remains the production letter engine  
**Claim boundary:** this note records software and finite-search semantics. It does not prove an adaptive K law and does not prove Erdős–Straus.

---

## 1. Why CBX is separate

`cbis.kernel` answers the operational question:

> does the current production cover dispose of this Mordell-hard prime?

Because W runs first, a W hit correctly prevents I/N/L from affecting the production verdict. That is efficient for hunting letters but hides the later-lane geometry.

`cbx.kernel` answers a different research question:

> what would every lane have done independently, even when an earlier lane already solved the target?

The production ordering is retained as

\[
W\to I\to N\to L,
\]

but CBX also evaluates the hidden lanes and records their first depths.

The two kernels therefore have different jobs and intentionally separate state directories, cursors and operator surfaces.

---

## 2. Finite search grade

CBX replaces the misleading one-scalar description of the finite search with

\[
\boxed{\Gamma=(F,K_I,E_N,A_L)}
\]

where

- `F` is the coprime fab edge;
- `K_I` is the signed-box Lane-I ceiling;
- `E_N` is the external-NR prime ceiling;
- `A_L` is the López layer ceiling.

The default is

\[
\boxed{(11,400,300,400).}
\]

Named run grades are immutable. A different finite strength requires a different run name. `--k-max K` remains only a compatibility convenience setting `K_I=A_L=K`.

---

## 3. Implementation layout

The implementation is deliberately split.

### Arithmetic/search core

`research/erdos-straus/cbx.kernel/src/cbx.c`

Contains:

- deterministic 64-bit Miller–Rabin primality;
- Pollard-rho exact factorization;
- hard-class and A/B/C spectrum classification;
- W linear/R/fab predicates;
- signed-box vacancy and Lane-I search;
- external-NR Lane-N search;
- López Lane-L search;
- ES-LETTER-v1 hashing and basic state primitives.

The clean initial census is permanently tied to the exact core blob recorded in `CBX-INITIAL-XRAY-CENSUS.md`.

### Preservation runtime

`research/erdos-straus/cbx.kernel/src/cbx_runtime.c`

Includes the arithmetic core as one translation unit and supplies the operator/runtime semantics. Keeping this layer separate allowed crash behavior to be hardened without rewriting the arithmetic blob used by the formal census.

### Analyzer

`research/erdos-straus/cbx.kernel/analyze.py`

Consumes the append-only X-ray stream and turns it into first-depth distributions, record sequences and empirical K-policy falsification data.

---

## 4. Crash preservation semantics

The runtime now prefers harmless replay over skipped mathematics.

### Signal atomicity

Once a target enters the X-ray probe, all W/I/N/L measurements for that target finish before SIGINT or SIGTERM is honored.

A partially evaluated target is never serialized as a Lane-I or Lane-N miss.

### Cursor correctness

For sweep:

\[
\text{saved cursor}=\text{last fully processed integer}.
\]

For home:

\[
\text{saved cursor}=\text{first unprocessed }S.
\]

The end-of-uint64 sentinel is handled without wrapping the home cursor back to the beginning.

### Hard-crash replay

The seed is checkpointed after a complete batch. If the process dies inside a batch, the old seed remains authoritative and that batch may be replayed on restart.

This can duplicate complete observation rows but cannot skip the uncheckpointed search interval. The analyzer deduplicates by target and exact grade.

### Truncated JSON repair

A hard process or machine failure can leave the final append incomplete. Before a named run resumes, CBX trims only a non-newline-terminated final record. The analyzer independently tolerates the same single crash-truncated EOF record when examining a corpus before restart.

A malformed complete JSON record remains a hard analysis error.

### Single writer per named run

The runtime uses a POSIX advisory lock under `state/`. Only one writer can mutate a named run at once. Different run names remain independent and can execute concurrently.

The lock is released by the operating system if the process crashes, so a dead process does not permanently strand the run.

### Letter-count reconciliation

Per-run letter markers are treated as the durable unique-letter set. On startup/status the unique count is reconstructed from those markers, closing the crash window between storing a letter and writing the next seed checkpoint.

---

## 5. Exactness and the cbis equivalence boundary

At the default finite grade, CBX implements the same mathematical cover predicates and ordering as cbis 1.2.0:

- W: `4p+1`, `p+4`, and all coprime `a,b<=11` fab pairs;
- I: every admissible signed-box shift through `K_I`;
- N: external nonresidue primes through `E_N` and their direct/aligned shifts;
- L: prime-modulus López Type A/B layers through `A_L`.

CBX does **not** intentionally reproduce cbis implementation defects.

In particular, cbis 1.2.0 uses a bounded trial-factor table and can eventually treat a remaining composite as prime after the table is exhausted. CBX uses Pollard rho and keeps factorization exact over its uint64 arithmetic domain.

Therefore “production-equivalent” means

\[
\boxed{\text{same mathematical finite cover and verdict ordering}}
\]

not

\[
\text{bit-for-bit reproduction of every future cbis implementation error}.
\]

The preservation runtime also evaluates the external-NR Jacobi symbol with unsigned 64-bit arithmetic, avoiding the signed cast boundary above `INT64_MAX`.

---

## 6. Adaptive-K experiment surface

The runtime supports experimental Lane-I schedules:

```text
fixed
log
log2
spectrum-log
```

with an explicit `policy_scale` and a hard `K_I` cap.

These schedules are measurement devices, not theorem statements.

`analyze.py` supports two complementary attacks.

### Falsification

Given a stronger fixed-K stream, test a proposed rule such as

\[
K(p)=\lceil c\log p\rceil
\]

or

\[
K(p)=\lceil c(\log p)^2\rceil.
\]

The analyzer reports:

- number of measured hits tested;
- number and rate of failures;
- first finite failure;
- worst finite deficit.

### Empirical envelope calibration

For each built-in policy family the analyzer also computes

\[
\boxed{
c_{\mathrm{obs}}
=\max_{p\ \mathrm{observed}}
\frac{k_I^*(p)}{B(p)}
}
\]

for all targets and separately inside `R`, and records the exact prime that forces the maximum.

This is a conservative finite calibration only. It has no asymptotic or universal force.

---

## 7. First clean census

The deterministic default-grade census already preserved in `CBX-INITIAL-XRAY-CENSUS.md` used

```text
cbx go --run formal --step 5000 --iterations 46908 --sweep-only
```

and reached

```text
sweep = 234,540,000
hard-prime X-rays = 401,752
production letters = 0
```

Observed hidden-lane results included:

\[
\max k_I^*(p)=107
\]

at

\[
p=8,803,369,
\]

with `R` Lane-I p99 equal to `27`.

The aggressive empirical rule

\[
K(p)=\lceil2\log p\rceil
\]

already fails `244 / 102,502` measured `R` targets in that corpus.

All of those statements are finite observations only.

---

## 8. CI and portability

A dedicated workflow

```text
.github/workflows/cbx-kernel.yml
```

builds and exercises CBX on Linux and macOS.

The regression gate covers:

- build and self-test;
- root `./centl es cbx` launcher;
- known `p=2521` X-ray semantics;
- deterministic finite census;
- analyzer parsing;
- immutable named grades.

The runtime resolves `/proc/self/exe` on Linux and falls back to the invoked executable path on other POSIX systems, allowing the same state-root semantics on macOS.

Windows-native support is not claimed by this 0.1.0 POSIX research runtime.

---

## 9. What remains

The implementation program is now beyond the “make K adaptive” stage. The valuable next targets are:

1. accumulate deeper fixed-K X-ray corpora, especially in `R`;
2. archive publication-grade raw streams outside git with checksums;
3. correlate each new `k_I^*` record with factor pattern, box size, defect/stabilizer data, spectrum and López depth;
4. repeatedly falsify candidate envelopes rather than promoting a good finite fit;
5. only after a stable candidate law appears, attack it with the existing defect/spectrum/Kneser theory;
6. separately investigate the still-unimplemented true inverse generator `k -> C -> p`, rather than the current recognition orientation `p -> k -> C`.

---

Erdős–Straus remains open. CBX is an X-ray instrument, not a proof engine.