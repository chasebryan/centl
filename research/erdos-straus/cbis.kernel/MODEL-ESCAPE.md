# cbis.kernel model-escape contract

## Purpose

CBIS must be able to use Type A/B aggressively without silently assuming
that Type A/B is complete.

The kernel therefore separates two questions:

1. **Cover question:** did one of the current W/I/N/L algorithms mark `p`?
2. **Model question:** has a Type A/B witness actually been found through
   the audited depth `K`?

These questions are related but are not interchangeable.

## Non-negotiable invariants

### 1. Type A/B completeness is not an axiom

For a prime `p`, failure to find a Type A/B witness through finite depth
`K` means only

    C_AB(p) > K  or  C_AB(p) = infinity.

CBIS must not choose between those alternatives from a finite search.

### 2. The audit does not participate in the cover

`cbis-audit` is a sidecar observer. It must not:

- mark W/I/N/L;
- change whether a number is an `ES-LETTER-v1` letter;
- advance sweep or home state;
- mutate the letter journal;
- reinterpret an old letter after a deeper audit.

A later audit may add knowledge about a prime. It does not rewrite the
identity of the earlier search event.

### 3. Lane L and full Type A/B are distinct objects

The current L lane checks López **prime-modulus** traps. The complete
bounded Type A/B audit checks every layer

    m = 4k - 1,   1 <= k <= K,

including composite `m`.

Therefore

    L miss

does not imply

    no Type A/B witness through K.

The audit exists partly to prevent that accidental inference.

## Audit states

For a hard prime `p` at depth `K`, CBIS may report:

### AB_EXPLAINED_THROUGH_K

A Type A or Type B witness has been found at some `k <= K`.

This is a positive exact result.

### AB_UNSEEN_THROUGH_K_NON_AB_COVER_HIT

No Type A/B witness was found through `K`, but W, I, or N marks the prime.

This is a **model-escape candidate at depth K**. It says that the present
CBIS cover can explain the prime before the bounded Type A/B model does.
It does not say that no deeper Type A/B witness exists.

### AB_UNSEEN_THROUGH_K_CURRENT_LETTER

No Type A/B witness was found through `K`, and the current W/I/N/L cover
also misses the prime.

This is simultaneously a letter at the current cover bound and an A/B
survivor through the audit bound. It is not an Erdős-Straus
counterexample.

## Why 9,658,489 is a regression case

The known minimal Type B witness for

    p = 9,658,489

occurs at

    k = 2,622.

Therefore an audit at `K=400` must be allowed to say

    A/B unseen through 400

without treating that as evidence that Type A/B is false. An audit at
`K=3000` should recover the Type B witness.

This is the canonical guard against the finite-depth fallacy.

## Next integration phase

The next model-escape layer should operate only on high-value residuals,
not on every prime in the sweep.

Candidate inputs:

- newly collected letters;
- W/I/N-covered primes for which full Type A/B remains unseen through a
  deliberately larger audit depth;
- record `C_AB` frontier primes;
- user-selected primes via an explicit audit command.

For those candidates, a future general-solution observer may search the
full Erdős-Straus equation

    4xyz = p(xy + xz + yz)

without assuming a Type A/B parametrization. Any exact general witness
found while Type A/B remains unseen through the audited depth should be
stored as evidence about model coverage, never as proof of Type A/B
failure.

## Research rule

CBIS may use a conjectured model as a microscope.
It may not quietly promote the microscope into the object being studied.
