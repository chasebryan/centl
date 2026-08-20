# CENTLAMP research TODO

This is the staged research and implementation checklist for
[CENTLAMP](CENTLAMP.md), the CENTL Authority & Metric Protocol.

Immediate tasks that belong in the active development cycle are mirrored in
[`../CENTL-TODO.md`](../CENTL-TODO.md). This file keeps the complete CENTLAMP
research program so the short-term CENTL checklist remains useful.

## Phase 0: freeze the experiment boundary

- [ ] Freeze the version-zero vocabulary: query, candidate, corpus, retrieval
  route, metric, penalty, profile, dominance relation, resolver, result set, and
  rank certificate.
- [ ] Specify the canonical normalized-query representation for the first local
  corpus experiment.
- [ ] Specify deterministic corpus and candidate-set identities.
- [ ] Define which metric values are exact, bounded, or external estimates.
- [ ] Freeze `centlamp/0` rank-certificate JSON for the first executable slice.
- [ ] Define resource limits for document count, token count, graph size,
  candidate count, and certificate size.
- [ ] Document the trust boundary for tokenization, parsing, model outputs, and
  graph extraction.

Exit condition: two independent implementations can read the same version-zero
fixture and agree on its identities and exact fields.

## Phase 1: bounded deterministic search

- [ ] Build deterministic ingestion for a small local corpus.
- [ ] Normalize documents into stable internal records with content identities.
- [ ] Implement a simple inverted index.
- [ ] Implement lexical candidate retrieval without neural dependencies.
- [ ] Define the first exact lexical metrics using integer/rational arithmetic
  where practical.
- [ ] Implement a minimal explicit link/citation graph.
- [ ] Emit per-candidate metric vectors.
- [ ] Implement deterministic dominance testing.
- [ ] Implement a simple public final resolver.
- [ ] Emit `centlamp/0` rank certificates.
- [ ] Implement certificate replay and structured verification failures.

Exit condition: a fixed corpus and query produce byte-for-byte stable deterministic
ranking evidence on repeated runs under the same implementation identity.

## Phase 2: benchmark harness

- [ ] Create a fixed judged-query corpus suitable for repository tests.
- [ ] Record relevance judgments independently from CENTLAMP output.
- [ ] Implement nDCG at fixed cutoffs.
- [ ] Implement mean reciprocal rank.
- [ ] Implement recall at fixed candidate depths.
- [ ] Measure duplicate rate and source diversity.
- [ ] Add rank-certificate replay success as a mandatory correctness metric.
- [ ] Record latency, peak memory, index size, and certificate size.
- [ ] Establish a baseline lexical system that CENTLAMP must beat before adding
  complexity.

Exit condition: every ranking change can be evaluated against the same fixed
baseline instead of being judged by screenshots or anecdotes.

## Phase 3: query-conditioned authority

- [ ] Define the first bounded query-local graph-construction rule.
- [ ] Distinguish graph edge types instead of treating all links as equivalent.
- [ ] Implement an exact or reproducibly bounded authority calculation over the
  local graph.
- [ ] Compare query-conditioned authority against a global-authority baseline.
- [ ] Record graph identity and authority derivation in rank certificates.
- [ ] Add adversarial fixtures for link farms, circular citation, and duplicated
  authority sources.

Exit condition: query-local authority improves a predeclared benchmark metric or
is rejected/reworked.

## Phase 4: evidence topology

- [ ] Define source lineage versus evidence lineage.
- [ ] Detect exact duplicate and deterministic near-duplicate classes.
- [ ] Represent explicit citation/reference ancestry.
- [ ] Define a conservative evidence-independence metric.
- [ ] Create adversarial corpora where many pages repeat one underlying source.
- [ ] Verify that repeated dependent sources cannot masquerade as equivalent
  independent evidence under the research profile.
- [ ] Record lineage decisions and their provenance in the certificate.

Exit condition: CENTLAMP can distinguish a repeated evidence chain from multiple
independent evidence chains on controlled fixtures.

## Phase 5: result-set information gain

- [ ] Define result-prefix state for reranking.
- [ ] Implement exact-duplicate suppression first.
- [ ] Add source-lineage diversity.
- [ ] Add evidence-lineage diversity.
- [ ] Experiment with subtopic/content novelty.
- [ ] Define safeguards preventing novelty from promoting irrelevant material.
- [ ] Record every reranking movement in the rank certificate.

Exit condition: diversity improves result-set usefulness on judged queries without
reducing the declared minimum relevance floor.

## Phase 6: semantic retrieval

- [ ] Define a model-provider-neutral semantic retrieval interface.
- [ ] Preserve model name/version/hash and transformation provenance.
- [ ] Keep neural similarity as an external estimate unless a stronger contract
  exists.
- [ ] Union semantic candidates with lexical candidates rather than silently
  replacing lexical retrieval.
- [ ] Measure semantic-retrieval recall gains separately from final-ranker gains.
- [ ] Add deterministic fixture substitutes so core protocol tests do not depend
  on network model services.

Exit condition: semantic retrieval produces a measured recall or ranking gain and
its non-exact evidence remains clearly outside the verified mathematical core.

## Phase 7: ranking profiles

- [ ] Freeze the first `general` research profile.
- [ ] Define `research` and `primary` profiles only after the baseline metrics are
  stable.
- [ ] Version active dimensions, normalization, dominance, resolver, penalties,
  and reranking rules together.
- [ ] Make profiles serializable and inspectable.
- [ ] Add profile-differential tests showing that profile changes alter only the
  declared ranking semantics.

Exit condition: the same candidate evidence can be replayed under two declared
profiles and produce deterministic, explainable differences.

## Phase 8: manipulation resistance

- [ ] Build synthetic keyword-stuffing fixtures.
- [ ] Build link-farm and circular-authority fixtures.
- [ ] Build copied-content and mass-syndication fixtures.
- [ ] Build freshness-manipulation fixtures.
- [ ] Define penalty classes without hiding their effect on certified organic
  ordering.
- [ ] Separate detector internals from protocol-visible penalty evidence.
- [ ] Benchmark false-positive cost, not only spam suppression.

Exit condition: known manipulations can be penalized without converting the rank
certificate into an opaque blacklist.

## Phase 9: larger corpora and distributed boundaries

- [ ] Separate protocol semantics from crawler/index implementation details.
- [ ] Define stable corpus snapshots for larger experiments.
- [ ] Define incremental-index update identities.
- [ ] Define distributed graph-partition invariants.
- [ ] Keep deterministic replay possible for bounded sampled or snapshotted runs.
- [ ] Measure where exact-first ranking mathematics becomes computationally
  expensive and document the tradeoffs instead of hiding them.

Exit condition: scale changes implementation strategy without silently changing
ranking meaning.

## Phase 10: external comparison

- [ ] Pre-register query sets and metrics before comparing against external search
  engines.
- [ ] Record comparison date, locale, query, interface, and other material context.
- [ ] Blind relevance judgments where practical.
- [ ] Compare result quality, source diversity, primary-source recovery, duplicate
  rate, latency, and resource cost.
- [ ] Publish negative results and regressions as well as wins.
- [ ] Prohibit general superiority claims that exceed the measured experiment.

Exit condition: any public statement that CENTLAMP is better than another system
can point to a reproducible experiment defining exactly what "better" means.

## Permanent invariants to test

- [ ] Organic rank never depends on an advertising payment or bid.
- [ ] Exact metrics remain exact through serialization and replay.
- [ ] External estimates retain provenance.
- [ ] Penalties affecting rank are visible at the protocol level.
- [ ] Deterministic profiles reproduce the same ordering from the same certified
  inputs.
- [ ] Missing evidence produces an explicit unresolved or unavailable state rather
  than a fabricated metric.
- [ ] A result cannot claim a valid rank certificate when replay disagrees with
  its recorded ordering.
