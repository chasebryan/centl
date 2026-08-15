# Coordinator directives for Operator-02

**Coordinator:** Operator-01 / primary research lead  
**Parallel lane:** Operator-02  
**Date:** 2026-08-15  
**Canonical coordinator ledger:** [`../OPERATOR-COORDINATION.md`](../OPERATOR-COORDINATION.md)

This file is an inbound work queue. Historical Operator-02 notes are preserved unchanged for provenance.

## Immediate correction

The parent theorem

\[
\lambda_j(T_j)=\eta_j+V_j
\]

is an image statement, not an exact characterization of trap residues by signature.

Use the hierarchy

\[
\boxed{
T_j
\subseteq
\lambda_j^{-1}(\eta_j+V_j)
\subseteq
\{x:(x/m_j)=-1\}.
}
\]

Therefore:

- outside the signature coset preimage => **certified exact-safe**;
- inside the signature coset preimage => **undecided**, finer multiplicative/exact residue analysis required;
- do not use "equivalently" between signature-coset membership and exact `T_j` membership.

Please record the correction in a new Operator-02 follow-up note rather than rewriting the historical diamond files.

## Priority O2-A: full k<=1500 active-core census

Use the frozen candidatewise bundle from workflow run `31849103304` / artifact `9238241616`.

For all `53,240` directly novel candidates, record:

1. `|N_{k,r}|`;
2. `|N^act_{k,r}|` where `q_j>1`;
3. Class-A fixed-prime valuation excess versus Class-B even-powered free-prime excess;
4. final fiber-kernel support;
5. which residual primes are sourced by `N^act` and which arise only from other surviving exact rows.

Do not infer a universal theorem from the finite census.

## Priority O2-B: active-core x multiplicative defect

For each active fixed-negative square-lift row with ancestor `a`, compute

\[
\mathcal M_a=K_a/D_a.
\]

Map the Class-A/Class-B residual primes to their multiplicative defect classes.

Main question:

> Do the active valuation witnesses collapse into a small catalogue of minimal zero-product atom types in `M_a`?

Cross-reference:

- `../MULTIPLICATIVE-DEFECT-QUOTIENT.md`
- `../DEFECT-ZERO-SUM-ATOMS.md`
- `../CLASS-C-RESIDUAL-CORE.md`

## Priority O2-C: bounded mixed-box support falsification

Primary found the first exact mixed-only square-lift projection failure at

\[
j=696,
\]

where all one-prime-power axes are safe but a two-direction product escapes the ancestor signed box.

Attack the conjecture:

> If exact signed-box containment fails after every individual prime-power axis passes, then some failing divisor uses at most two distinct prime directions.

Search for the smallest support-3 counterexample.

- If found: freeze it immediately with full factorization/residue certificate.
- If not found: report exact search range, number of mixed failures tested, and verifier logic. Do not call it a theorem.

Cross-reference: `../MIXED-BOX-OBSTRUCTION.md`.

## Priority O2-D: atom-to-shadow census

For every minimal zero-product atom observed in `M_a`:

1. construct its neutral divisor residue modulo ancestor `d`;
2. test exact membership in ancestor `T_a`;
3. if it misses `T_a`, search all earlier layers for a direct shadow/trap explanation;
4. classify the first layer that removes it, if any.

Question:

> Is every multiplicatively neutral atom that escapes the ancestor exact two-box trap already killed by another earlier layer?

This is the highest-value Operator-02 route toward universal DSC-P.

## Priority O2-E: smallest exact Class-C systems

Independently solve or falsify the smallest coordinated Class-C systems, prioritizing:

- `|N^act|=1`;
- fiber-kernel size 2;
- fiber-kernel size 3;
- cyclic `M_a`;
- mixed-box support 2.

Every proposed rule must include an explicit exact-trap falsifier. A coarse quadratic signature failure is not an exact obstruction.

## Reporting protocol

Every completed item must include:

- exact scope;
- proof versus finite-certificate label;
- counterexample condition;
- parent references;
- prior-art boundary where classical theory is used;
- raw counts/certificates needed for coordinator review.

Create new files under `operator-02/` only. Do not alter parent theorem files.

The coordinator will promote, revise, reject, or merge results through `../OPERATOR-COORDINATION.md`.

**Repository first. Chat second.**
