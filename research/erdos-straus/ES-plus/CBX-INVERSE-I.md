# CBX inverse-I — constructive signed-box cover

**Status:** exact finite implementation of the Lane-I inverse orientation  
**Date:** 2026-08-15  
**Program:** ES+  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora-family GNU/Linux  
**Depends on:** `LETTER-EQUATION.md`, `CBIS-K-PARAMETER-STATUS.md`, `CBX-IMPLEMENTATION-STATUS.md`  
**Claim boundary:** this note specifies and implements finite cover constructions. It does not prove that inverse orientation is asymptotically faster, does not prove an adaptive K law, and does not prove Erdős–Straus.

---

## 1. The orientation

The p-first recognition form of Lane I is

\[
p\to k\to C=\frac{p+k}{4}\to\delta_k(C).
\]

The constructive form named by the ES+ letter equation reverses the outer search:

\[
\boxed{k\to C\to p=4C-k.}
\]

For an admissible shift

\[
k\equiv3\pmod4
\]

and a Mordell-hard prime target

\[
p\equiv h\pmod{840},
\qquad
h\in H=\{1,121,169,289,361,529\},
\]

we have

\[
4C-k\equiv h\pmod{840}.
\]

Because every `h` is `1 mod 4` and every admissible `k` is `3 mod 4`, `h+k` is divisible by four. Dividing the congruence by four gives

\[
\boxed{
C\equiv\frac{h+k}{4}\pmod{210}.
}
\]

Therefore a fixed `k` requires only six C residue classes modulo 210 when the desired outputs are Mordell-hard targets.

---

## 2. Two exact inverse implementations

The executable is built from

```text
research/erdos-straus/cbx.kernel/src/cbx_inverse.c
```

as `cbx-inverse` and is routed from the repository root by

```sh
./centl es cbx inverse ...
```

The implementation deliberately retains **two exact strategies**.

### 2.1 Strict C-first baseline

```sh
./centl es cbx inverse --strict-c-first ...
```

For each admissible `k` and each compatible C residue class, this form:

1. enumerates C;
2. factors C;
3. evaluates `delta_k(C)`;
4. forms `p=4C-k`;
5. consults the finite hard-prime target universe only after the signed-box test.

This is the most literal computational reading of the constructive equation. It is useful as a correctness and cost baseline.

### 2.2 Target-gated inverse

The default is

```sh
./centl es cbx inverse --target-gated ...
```

It keeps **exactly the same outer orientation**

\[
k\to C\to p,
\]

but after C generates p it applies three exact cheap gates before factoring C:

1. reject p if it is not in the Mordell-hard prime target universe;
2. reject p if it was already covered by a smaller k;
3. reject the non-coprime case `gcd(C,k) != 1`.

Only a surviving generated p causes factorization of C and evaluation of `delta_k(C)`.

This does **not** turn the algorithm back into p-first recognition. No outer loop chooses a prime and asks which k hits it. The candidate is still created by the map

\[
(k,C)\mapsto p=4C-k.
\]

The gates only avoid expensive work on a generated candidate that cannot change the finite cover.

The already-covered gate is exact because k is visited in increasing order. Once p has first hit at k₀, no later k can replace its minimal first depth.

---

## 3. Exact first depth

The shifts are visited in increasing order

\[
3,7,11,15,\ldots,K_I.
\]

For each generated hard prime the engine stores

\[
\boxed{
k_I^*(p)=\min\{k:\delta_k((p+k)/4)=0\}.}
\]

Optional output

```text
p<TAB>k_I*(p)
```

is produced with `--hits FILE`.

Hard primes not marked by any admissible shift through `K_I` can be written with `--residuals FILE`.

This residual is a **Lane-I residual only**. It is not automatically a production ES letter, because W, N and L are separate coordinates of the full finite grade.

---

## 4. Equivalence verification

The inverse engine has a deliberately redundant `--verify` mode.

After constructing the inverse cover for a segment, it applies the existing p-first Lane-I recognizer to every hard prime in the same finite universe.

For every target it requires both

\[
\text{inverse membership}=\text{recognition membership}
\]

and, when hit,

\[
\text{inverse first }k=\text{recognition first }k.
\]

A disagreement is printed with the target and both first-depth values, increments `verification_mismatches`, and causes a nonzero process exit.

The Fedora and Ubuntu regression interval is

```sh
./centl es cbx inverse \
  --hi 100000 \
  --i-max 80 \
  --segment 25000 \
  --verify
```

and is required to produce zero mismatches.

Finite agreement is software validation of the implementation. It is not a substitute for the mathematical equivalence stated in the theory note.

---

## 5. Output counters

The target-gated JSON summary records at least

```text
hard_primes
C_candidates
factorizations
delta_hits
skipped_non_target
skipped_covered
skipped_non_coprime
covered_hard_primes
residual_hard_primes
verification_targets
verification_mismatches
```

The important distinction is

- `C_candidates`: compatible C values **enumerated** by the inverse traversal;
- `factorizations`: C values that survive cheap exact gates and actually pay for factorization/signed-box work.

Thus enumeration overhead and expensive arithmetic are no longer conflated.

The identity

\[
\boxed{
\texttt{covered\_hard\_primes}
+
\texttt{residual\_hard\_primes}
=
\texttt{hard\_primes}
}
\]

is checked in CI.

---

## 6. The first baseline falsified the naïve speed hypothesis

The first Fedora benchmark used the strict C-first implementation at

\[
X=100{,}000,
\qquad
K_I=80.
\]

The finite target universe contained 273 Mordell-hard primes.

The result was deliberately unpleasant:

\[
\boxed{
\frac{C\text{-candidates}_{\rm strict}}
     {\text{forward factorizations}}
=20.198020
}
\]

and the observed Fedora wall ratio was

\[
\boxed{
\frac{t_{\rm strict\ inverse}}
     {t_{\rm forward}}
=11.723221.
}
\]

So the literal “factor every compatible C before target lookup” implementation is **not** competitive on that finite corpus. This result is retained because it identifies the actual waste rather than allowing the implementation to drift toward an unexplained optimization.

It directly motivated the target-gated inverse mode.

Neither ratio is an asymptotic statement.

---

## 7. Benchmark metrics after target gating

The p-first reference binary `cbx-forward-i` measures the same hard-prime finite universe and records exact signed-box factorization count.

For the optimized inverse, the primary expensive-work ratio is now

\[
\boxed{
\rho_F(X,K_I)
=
\frac{\text{inverse factorizations}}
     {\text{forward factorizations}}.
}
\]

A second ratio measures traversal overhead:

\[
\boxed{
\rho_C(X,K_I)
=
\frac{\text{inverse enumerated C candidates}}
     {\text{forward factorizations}}.
}
\]

And machine-specific timing is

\[
\boxed{
\rho_t
=
\frac{t_{\rm inverse}}{t_{\rm forward}}.
}
\]

Interpretation:

- `rho_F < 1`: target-gated inverse performs fewer expensive C factorizations;
- `rho_C > 1` can still be acceptable if most extra C candidates are rejected cheaply;
- `rho_t` tells whether those savings survive actual implementation overhead on the measured machine.

The harness is

```text
research/erdos-straus/cbx.kernel/bench_i.py
```

and alternates execution order between repeats.

Examples:

```sh
python3 bench_i.py --hi 100000 --i-max 80

python3 bench_i.py \
  --hi 100000 \
  --hi 1000000 \
  --hi 10000000 \
  --i-max 80 \
  --i-max 400 \
  --repeat 3

# reproduce the intentionally expensive baseline
python3 bench_i.py --hi 100000 --i-max 80 --strict-inverse
```

All benchmark conclusions are finite and machine-specific except the exact operation counts themselves.

---

## 8. The actual research question now

The question is no longer “can the inverse cover be implemented?” It can.

The questions are now:

1. How does `rho_F(X,K_I)` behave as X grows?
2. How does `rho_C(X,K_I)` behave as K grows?
3. At what finite regimes, if any, does target-gated inversion beat p-first recognition in wall time?
4. Can `delta_k(C)=0` itself be generated structurally instead of tested after factorization?
5. Can defect, spectrum, factor-pattern, or residue information reject more generated C values before Pollard-rho work?
6. Do some shifts deserve inverse generation while others should remain recognizers?

The last point suggests a **hybrid per-shift scheduler** may ultimately be better than demanding one global orientation.

---

## 9. Command reference

```sh
# optimized inverse Lane-I finite cover
./centl es cbx inverse --hi X --i-max K

# explicit optimized mode
./centl es cbx inverse --target-gated --hi X --i-max K

# literal C-first baseline
./centl es cbx inverse --strict-c-first --hi X --i-max K

# exact finite implementation check
./centl es cbx inverse --hi X --i-max K --verify

# bounded-memory segmentation
./centl es cbx inverse --hi X --i-max K --segment N

# save generated first depths and residuals
./centl es cbx inverse --hi X --i-max K \
  --hits hits.tsv \
  --residuals residuals.txt

# compare orientations
python3 research/erdos-straus/cbx.kernel/bench_i.py \
  --hi X --i-max K --repeat 3
```

---

Erdős–Straus remains open. Exact finite inversion is a computational tool, not a proof.