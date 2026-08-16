# cbis.kernel model-escape contract

## Purpose

CBIS must be able to use Type A/B aggressively without silently assuming
that Type A/B is complete.

The subsystem separates three questions:

1. **Cover question:** did one of the current W/I/N/L algorithms mark `p`?
2. **Model question:** has a Type A/B witness actually been found through
   the audited depth `K`?
3. **Equation question:** can the full Erdős–Straus equation be solved by an
   exact search that does not assume Type A/B coordinates?

These questions are related but are not interchangeable.

## Non-negotiable invariants

### 1. Type A/B completeness is not an axiom

For a prime `p`, failure to find a Type A/B witness through finite depth
`K` means only

    C_AB(p) > K  or  C_AB(p) = infinity.

CBIS must not choose between those alternatives from a finite search.

### 2. The observers do not participate in the cover

`cbis-audit` and `cbis_escape.py` are sidecar observers. They must not:

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

### 4. General ES search is independent of A/B parametrization

For an ordered solution

    4/p = 1/x + 1/y + 1/z,    x <= y <= z,

it is necessary that

    floor(p/4)+1 <= x <= floor(3p/4).

For each such x, write

    a/b = 4/p - 1/x

in lowest terms. Then

    1/y + 1/z = a/b

is equivalent to

    (a y - b)(a z - b) = b^2.

Thus enumerating the divisors of `b^2` is a complete exact search for the
remaining two denominators at that x. `cbis_escape.py` implements exactly
this construction and verifies every emitted witness again by integer
cross multiplication.

The general observer does not call Type A/B to produce its witness.

### 5. A complete general no-witness result is claim-sensitive

If the observer exhausts the entire canonical x-domain and finds no exact
witness, the result is mathematically much stronger than an ordinary
bounded miss. The software must not auto-file or auto-publish such a result
as an Erdős–Straus counterexample.

It must instead report

    COMPLETE_GENERAL_SEARCH_NO_WITNESS_REQUIRES_INDEPENDENT_VERIFICATION

and require an independent implementation and certificate review.

## Audit states

For a hard prime `p` at depth `K`, the C audit may report:

### AB_EXPLAINED_THROUGH_K

A Type A or Type B witness has been found at some `k <= K`.

This is a positive exact result.

### AB_UNSEEN_THROUGH_K_NON_AB_COVER_HIT

No Type A/B witness was found through `K`, but W, I, or N marks the prime.

This is a **cover-escape candidate at depth K**. It says that the present
CBIS cover can explain the prime before the bounded Type A/B model does.
It does not say that no deeper Type A/B witness exists.

### AB_UNSEEN_THROUGH_K_CURRENT_LETTER

No Type A/B witness was found through `K`, and the current W/I/N/L cover
also misses the prime.

This is simultaneously a letter at the current cover bound and an A/B
survivor through the audit bound. It is not an Erdős–Straus
counterexample.

## General observer states

### GENERAL_ES_WITNESS_AB_UNSEEN_THROUGH_K

An exact general Erdős–Straus witness has been found, while no Type A/B
witness is known through the recorded finite K.

This is the primary **bounded model-escape candidate**. It demonstrates
that the equation is already solved at the observed prime without needing
an A/B witness inside the current audit depth.

It does **not** demonstrate that no deeper A/B witness exists.

### AB_EXPLAINED_THROUGH_K

The same general search may still find a witness, but Type A/B has already
been found through K. The prime is therefore not a model-escape candidate
at that K.

### AB_UNSEEN_THROUGH_K_GENERAL_SEARCH_INCOMPLETE

Neither Type A/B through K nor the bounded general x-search has produced a
witness. The general search has not exhausted the canonical x-domain, so
no global conclusion is permitted.

### COMPLETE_GENERAL_SEARCH_NO_WITNESS_REQUIRES_INDEPENDENT_VERIFICATION

The canonical x-domain was exhausted without a witness. This is a
high-severity research event, not an automatic claim.

## Dual A/B implementation rule

`cbis-audit` implements bounded A/B in C. `cbis_escape.py` independently
implements the same bounded A/B classification in Python.

When the C binary is present, the observer compares the two results. A
mismatch is classified as

    AUDIT_DISAGREEMENT

and the evidence writer refuses to record a model-escape candidate until
the discrepancy is resolved.

This deliberate duplication is a verification feature, not accidental
code duplication.

## Evidence rules

Only exact general witnesses with A/B unseen through finite K may be
recorded as `ES-MODEL-ESCAPE-v1` evidence.

A record must contain:

- prime `p`;
- finite A/B audit bound `K`;
- exact `x,y,z`;
- the exact general-search remainder data;
- the Type A/B bounded result;
- C/Python audit agreement when C audit is available;
- an explicit claim boundary.

Evidence is content-addressed and stored separately from letters. It never
changes W/I/N/L or `ES-LETTER-v1` identity.

## Why 9,658,489 is the canonical regression case

The known minimal Type B witness for

    p = 9,658,489

occurs at

    k = 2,622,
    d = 69,
    n = 38,
    m = 10,487.

Therefore an audit at `K=400` must report

    A/B unseen through 400

without treating that as evidence that Type A/B is false.

At the same shallow K, the independent general observer finds and exactly
verifies

    4/9658489
      = 1/2414624
      + 1/3331659906339
      + 1/62813018687490942976992.

This is a real bounded model-escape event: the full equation has a witness
while A/B remains unseen through 400.

At `K=3000`, the Type B witness at `k=2622` must be recovered and the same
prime must cease to be classified as a model-escape candidate at that
larger audit depth.

That single prime therefore tests both sides of the epistemic boundary.

## High-value inputs

The general observer is intentionally not inserted into every W/I/N/L
sweep cell. Its intended targets are:

- newly collected letters;
- W/I/N-covered primes for which full Type A/B remains unseen through a
  deliberately chosen audit depth;
- record `C_AB` frontier primes;
- user-selected primes;
- batches of existing letters via `cbis_escape.py letters`.

This preserves the speed and meaning of the live cover while giving CBIS a
separate instrument for discovering structure outside the assumed model.

## Research rule

CBIS may use a conjectured model as a microscope.
It may not quietly promote the microscope into the object being studied.
