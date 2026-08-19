# CENTLAMP

**CENTL Authority & Metric Protocol**

CENTLAMP is the search, retrieval, authority, and ranking research program inside
CENTL. It exists to test whether CENTL's exact-first, contract-oriented design can
produce an open information-retrieval system whose ranking decisions are
inspectable, reproducible, and experimentally defensible.

CENTLAMP is not a separate flagship and is not a claim that CENTL already
outperforms commercial search engines. It is a CENTL capability track. Any claim
of superior ranking quality must be earned against public benchmarks and
reproducible evaluations.

## North-star contract

CENTL's numerical rule is that the system must not manufacture mathematical
certainty. CENTLAMP extends the same discipline to information retrieval:

> A search result should never occupy a rank that the system cannot explain.

A CENTLAMP result therefore has two outputs:

1. the ordered result set;
2. a machine-readable **rank certificate** describing the evidence and rules that
   produced the ordering.

The certificate is part of the result, not optional debugging metadata.

## Scope

CENTLAMP is responsible for the mathematical and protocol layer of search:

- candidate retrieval contracts;
- lexical and semantic relevance measurements;
- query-conditioned authority;
- evidence-lineage and independence measurements;
- source-type and primary-source signals;
- freshness and temporal relevance;
- originality and duplication measurements;
- spam and manipulation penalties;
- multidimensional dominance and ranking;
- result-set diversity and information-gain reranking;
- deterministic ranking profiles;
- rank certificates and replay;
- public evaluation against fixed corpora and judged query sets.

Crawling, distributed storage, rendering, and large-scale serving may use other
components, but they must not silently change CENTLAMP ranking semantics.

## Initial architecture

The first research architecture is deliberately modular:

```text
query
  |
  v
query interpretation
  |
  v
candidate union
  |-- lexical retrieval
  |-- semantic retrieval
  |-- entity retrieval
  |-- graph retrieval
  `-- temporal retrieval
  |
  v
metric evaluation
  |
  v
query-local authority/evidence graph
  |
  v
multidimensional candidate vectors
  |
  v
Pareto / dominance filtering
  |
  v
profile-specific deterministic resolver
  |
  v
information-gain reranking
  |
  v
results + rank certificates
```

No individual retrieval backend has sole veto power over the candidate set unless
a ranking profile explicitly declares that behavior.

## Candidate model

For query `q` and document `d`, CENTLAMP begins with a vector rather than a single
opaque score:

```text
V_q(d) = (
  L,  lexical relevance
  S,  semantic relevance
  A,  query-conditioned authority
  E,  evidence independence
  P,  primary-source value
  F,  freshness / temporal relevance
  O,  originality
  Q,  content-quality evidence
  X   penalties / risk signals
)
```

The exact final dimensions are research subjects. Names, meanings, normalization,
and admissible ranges must be versioned before any profile is considered stable.

Where a metric can be represented exactly, CENTLAMP should prefer exact integers,
rationals, finite sets, graph counts, or interval-bounded values. Outputs from
statistical or neural systems must retain their provenance and uncertainty rather
than being promoted into unexplained mathematical facts.

## Query-conditioned authority

CENTLAMP does not assume that global popularity is equivalent to authority.
Authority should be evaluated relative to the query or inferred topic whenever
possible.

A first formulation is:

```text
A(d | q)
```

rather than merely:

```text
A(d)
```

The implementation may construct a bounded query-local graph from candidate
pages, citations, links, authors, referenced entities, primary sources, and other
explicit relations. The graph-building rule must itself be versioned and replayable.

## Evidence topology

Repeated claims do not automatically count as independent evidence.

CENTLAMP should attempt to distinguish independent evidence lineages from copied,
syndicated, recursively cited, or otherwise dependent material. A document may
therefore carry both source count and evidence-independence information.

The first research objective is not to solve epistemology. It is to make evidence
dependence explicit enough that ten copies of one source do not automatically
behave like ten independent sources.

## Dominance before arbitrary collapse

The initial ranking research should avoid prematurely collapsing every dimension
into one weighted scalar.

If candidate `a` is no worse than candidate `b` on every active positive metric,
no worse on every active penalty metric, and strictly better on at least one
active dimension, then `a` may dominate `b` under that profile.

This permits a Pareto-frontier stage before final tie-breaking and exposes which
tradeoffs are real rather than hiding them inside one coefficient soup.

The final ordering still needs a deterministic resolver. Its rules must be public,
versioned, and included in the rank certificate.

## Information gain

Ranking quality is a property of the result set, not only of individual pages.
After high-quality candidates are identified, CENTLAMP should prefer results that
add useful information instead of filling the page with near-duplicates.

A later result may therefore receive value for adding a primary source, distinct
evidence lineage, technical explanation, materially different interpretation,
dataset, or new temporal development not already represented above it.

The diversity objective must never become an excuse to promote low-quality or
irrelevant material merely because it is different.

## Ranking profiles

CENTLAMP should support public ranking profiles over one protocol rather than
secretly changing the meaning of search.

Candidate early profiles include:

- `general`
- `research`
- `primary`
- `code`
- `recent`
- `small-web`
- `diverse`

Each profile must declare its active metrics, normalization rules, dominance
policy, resolver, penalties, bounds, and version.

## Rank certificates

A CENTLAMP rank certificate should eventually contain at least:

```text
protocol version
ranking profile
query identity / normalized query
corpus or index identity
candidate-set identity
metric definitions and versions
per-document metric values
metric provenance
active penalties
query-local graph identity
Pareto / dominance relations
resolver decisions
information-gain decisions
final ordering
resource limits
implementation identity
```

A verifier should be able to replay the deterministic portion of the ranking from
this information and detect a mismatched result.

## Separation from advertising

Organic CENTLAMP ranking and advertising are separate systems.

An advertising system must not modify an organic document's CENTLAMP metrics,
rank certificate, dominance relations, or organic order. If an interface displays
sponsored material, insertion happens after organic ranking and remains visibly
identified as a separate class of result.

This separation is an architectural invariant, not a UI preference.

## Evaluation discipline

CENTLAMP must compete by measurement.

Initial evaluation should use fixed public or redistributable corpora where
possible, judged query sets, and reproducible runs. Useful measurements include:

- nDCG at fixed cutoffs;
- mean reciprocal rank;
- recall at fixed candidate depths;
- primary-source recovery;
- duplicate rate;
- source and evidence-lineage diversity;
- spam/manipulation resistance;
- freshness where the benchmark supports it;
- rank-certificate replay success;
- latency and resource cost.

Comparisons with external engines must record query date, query text, location or
other relevant context, and the limits of reproducibility. CENTLAMP documentation
must distinguish observed benchmark results from general claims.

## Trust boundary

CENTLAMP may consume external models, embeddings, crawlers, graph builders, and
classifiers, but every such component belongs to an explicit trust boundary.

CENTL itself should own the protocol semantics, normalization, deterministic
ranking rules, certificate structure, bounded resource model, and verification of
replayable claims.

A model prediction is evidence supplied to CENTLAMP. It is not a proof merely
because a model emitted a number.

## Initial non-goals

The foundation phase does not require:

- web-scale crawling;
- a Google-sized index;
- production advertising;
- personalized behavioral profiling;
- a universal truth score;
- a single permanent ranking formula;
- claims of superiority before benchmark evidence exists.

The first win is a small, rigorous search system whose decisions can be inspected
and replayed end to end.

## First vertical slice

The first useful CENTLAMP demonstration should operate on a bounded local corpus
and support:

1. deterministic corpus ingestion;
2. lexical candidate retrieval;
3. a small explicit metric vector;
4. a bounded link/citation graph;
5. deterministic dominance and final ordering;
6. machine-readable rank certificates;
7. certificate replay;
8. a fixed judged-query benchmark.

Semantic retrieval, neural reranking, evidence-lineage inference, and larger graph
methods should be added only after this baseline is measurable.

## Status

**Foundation / research design.** No ranking profile is stable yet. No performance
or quality superiority claim is currently part of the CENTL contract.
