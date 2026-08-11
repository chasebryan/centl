# CENTL Oasis promotion path

Oasis promotion is deliberately split into two proof stages.

## 1. Promotion-candidate proof

A pull request targeting `oasis` runs the repository's default-branch
`Oasis promotion qualification` workflow. It executes the adversarial Oasis
policy tests and the complete candidate convergence engine against the proposed
merge state with the pinned proof, native, OCaml, Julia/Nemo, and CARAVAN
toolchains.

A promotion PR is not merged merely because GitHub reports it mergeable. The
promotion convergence must complete successfully or its failure must be repaired
at source and re-run.

## 2. Authoritative-head proof

After promotion lands, the `oasis` branch runs `Oasis qualification` again on the
exact authoritative commit. That push run additionally:

- preserves the exact release archive produced by the full convergence engine;
- checks the release-blocking GitHub security state;
- binds final hosted proof to the exact Oasis SHA.

Only the release artifact created by that successful authoritative push is eligible
for tag publication.

## Tag publication

A `vX.Y.Z` tag is publication authority only when it points to the exact current
`origin/oasis` head, the tag matches the authoritative source version, all mandatory
hosted Oasis checks for that SHA are authentic GitHub Actions successes, no pull
request still targets `oasis`, and the matching successful qualification run contains
exactly one unexpired qualified release artifact.

The release workflow downloads and revalidates those exact bytes. It does not build
a replacement archive during publication.

This ordering keeps the declaration meaningful:

```text
mirage / feature work
        |
        v
promotion PR -> candidate convergence
        |
        v
      oasis -> authoritative convergence + security + release artifact
        |
        v
 final declaration commit -> requalification
        |
        v
     vX.Y.Z -> exact qualified-byte publication
```

No earlier point is sufficient to state that a release is Oasis.
