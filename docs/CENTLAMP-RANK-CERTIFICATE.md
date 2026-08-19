# CENTLAMP rank certificate

This document defines the first research contract for explaining and replaying a
CENTLAMP result ordering. It is intentionally narrower than a production search
schema. Fields may evolve until the protocol receives a stable version.

See [CENTLAMP.md](CENTLAMP.md) for the system-level design.

## Principle

A rank certificate records enough information to explain why a bounded CENTLAMP
run produced its final ordering and to replay every deterministic step owned by
the protocol.

The certificate is not a proof that a source is true. It is a proof record of the
ranking computation under a declared corpus, metric set, profile, and trust
boundary.

## Certificate identity

A certificate must identify:

- the CENTLAMP protocol version;
- the ranking profile and profile version;
- the CENTL implementation or build identity;
- the corpus/index identity;
- the normalized query identity;
- the candidate-set identity;
- the metric-definition set;
- the deterministic resolver version;
- the resource-limit profile.

Stable implementations should use content-addressed identities wherever practical.

## Per-candidate record

For each candidate document `d`, record at least:

```text
candidate_id
source_id
canonical_location
retrieval_routes
metric_vector
metric_provenance
penalties
active_profile_dimensions
dominance_status
resolver_inputs
information_gain_inputs
final_position
```

A future machine schema may add optional fields without changing the meaning of
existing mandatory fields.

## Metric values

CENTLAMP must distinguish three broad classes of metric value.

### Exact

Examples:

- integer link counts;
- rational normalized counts;
- finite set cardinalities;
- exact timestamps or age differences;
- deterministic lexical statistics.

These should use CENTL exact value semantics.

### Bounded / interval

If a value has certified uncertainty, store the interval or enclosure instead of
silently reducing it to an unjustified point estimate.

### External estimate

Examples include neural similarity scores or third-party classifier outputs.
These must retain provenance sufficient to identify the supplying model or
component and the transformation applied before CENTLAMP consumes them.

An external estimate is not upgraded to an exact CENTL fact merely because it is
serialized as a decimal number.

## Dominance record

When a profile uses Pareto or dominance filtering, the certificate should record
which candidates dominate which others and the dimensions that establish the
relation.

For positive dimensions `P` and penalty dimensions `N`, one research definition is:

```text
a dominates b iff

for every p in P: p(a) >= p(b)
for every n in N: n(a) <= n(b)
and at least one active comparison is strict.
```

Profiles may refine this rule, especially when bounded or partially ordered
values are introduced. Any refinement must be versioned.

## Resolver record

The Pareto frontier may contain multiple incomparable candidates. The profile's
final resolver must therefore be deterministic and explicit.

A resolver record must identify:

- the frontier or layer presented to it;
- the ordered comparison rules it applied;
- any exact weights or lexicographic priorities;
- tie-breaking rules;
- the before/after ordering.

Random tie-breaking is not permitted in a replayable profile unless the random
seed and generator semantics are part of the certificate.

## Information-gain record

If result-set reranking is active, each moved candidate should record the features
that caused the movement and the already-selected result prefix against which the
information-gain decision was made.

The protocol must be able to distinguish at least:

- near-duplicate suppression;
- source-lineage diversity;
- evidence-lineage diversity;
- content or subtopic novelty;
- temporal novelty.

A profile may leave information-gain reranking disabled.

## Query-local graph record

If ranking uses a query-conditioned authority or evidence graph, the certificate
must identify the graph deterministically.

The first implementation may store the complete bounded graph. Larger systems may
store a content address plus enough canonical construction inputs to reproduce the
same graph.

The graph record should distinguish relation types such as:

```text
hyperlink
citation
same-author
same-publisher
syndication
copy/near-duplicate
references-primary-source
entity relation
```

Relation types are protocol data, not interchangeable edges.

## Penalties

Penalties must never be invisible.

If a candidate loses rank because of duplication, suspected spam, link
manipulation, source-quality rules, unsafe content filtering, or another active
policy, the certificate must identify the active penalty class and its effect on
the ranking computation.

This requirement does not imply that every anti-abuse detector must expose
sensitive internals. A production implementation may redact detector details while
still recording the protocol-level penalty class, version, and effect. Such
redaction must itself be declared.

## Minimal research serialization

The first implementation may use versioned JSON resembling:

```json
{
  "protocol": "centlamp/0",
  "profile": "research/0",
  "query": {
    "raw": "example query",
    "normalized": "example query"
  },
  "corpus_id": "...",
  "candidate_set_id": "...",
  "metrics": ["lexical", "authority", "freshness"],
  "results": [
    {
      "candidate_id": "...",
      "metrics": {
        "lexical": {"kind": "rational", "value": "97/100"},
        "authority": {"kind": "rational", "value": "4/5"},
        "freshness": {"kind": "rational", "value": "1/2"}
      },
      "dominated_by": [],
      "position": 1
    }
  ]
}
```

The example is illustrative, not a frozen schema.

## Replay contract

A certificate verifier should eventually be able to answer:

1. Does the certificate conform to its declared schema?
2. Do all referenced exact values parse and normalize under CENTL semantics?
3. Do recorded dominance relations follow from the recorded metric values?
4. Does the resolver produce the recorded intermediate ordering?
5. Does information-gain reranking produce the recorded final ordering?
6. Does the final result order match the certificate?
7. Were declared resource bounds respected?

The verifier should return a structured failure rather than guessing when required
inputs are absent.

## Organic-ranking invariant

A valid organic rank certificate cannot include an advertising payment, bid, or
sponsor relationship as an organic ranking metric. Sponsored insertion belongs to
a separate post-ranking layer and must not alter the certified organic order.

## Research status

This is a **version-zero research contract**. The purpose of the first
implementation is to discover which fields are actually necessary for replay and
which proposed ranking dimensions survive benchmark testing.
