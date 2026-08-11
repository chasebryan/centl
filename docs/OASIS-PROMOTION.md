# CENTL Oasis promotion path

Oasis promotion is deliberately bound to one exact source identity from final candidate qualification through publication.

## 1. Exact candidate proof

A pull request targeting `oasis` enters the default-branch CARAVAN/Oasis qualification workflow when its relevant stable-boundary paths are changed. For an Oasis-targeted PR, that workflow checks out the **literal pull-request head SHA**, not GitHub's synthetic merge commit, and requires:

- `Identity, integrity, catalog, policy, and outbound transport gates`;
- `Adversarial engine self-test`;
- `Full stable-product convergence`;
- `Release security state`.

The full convergence runs the pinned proof/native/OCaml/Julia-Nemo/CARAVAN toolchain and stamps the release build with that exact PR-head SHA. A successful run preserves the exact release archive, checksum, and Oasis evidence under artifact names containing the same source identity.

A missing, skipped, neutral, pending, failed, or look-alike mandatory hosted check is not qualification.

## 2. Unchanged promotion to `oasis`

The final declaration candidate is not squash-merged or rebased after qualification. Once every mandatory exact-SHA check is successful, the authoritative `oasis` ref is fast-forwarded to the already-qualified commit **without changing its SHA**.

This prevents the common release gap where one commit is tested and a different merge commit is declared stable.

Any source change after qualification creates a new candidate and requires the complete gate again.

## 3. Publication latch

After the exact green SHA is the current `origin/oasis` head, the final qualification pull request is closed. The authoritative release latch then requires:

- the closed PR head to equal the exact current `origin/oasis` head;
- the source version to determine the exact `vX.Y.Z` tag;
- authentic successful mandatory Oasis checks on that SHA;
- zero remaining open pull requests targeting `oasis`;
- exactly one unexpired qualified release artifact for the exact successful qualification run;
- a valid archive checksum;
- embedded semantic version and build-manifest commit matching the source;
- GNU/Linux x86_64 package identity and the required F* verification attestation.

Only after those conditions hold may the exact SemVer tag and GitHub release be created.

## 4. Qualified-byte publication

Publication consumes the archive that already passed full convergence. It does **not** perform a replacement build.

After upload, the release latch downloads the published archive and checksum again, verifies the checksum, and compares the published archive digest to the already-qualified archive digest.

The intended v0.14.0 path is therefore:

```text
mirage / integrated work
        |
        v
final Oasis PR head SHA
        |
        | exact-SHA hosted qualification
        v
same SHA fast-forwarded to oasis
        |
        | close qualification PR / release latch
        v
same SHA tagged v0.14.0
        |
        v
exact qualified bytes published + reverified
```

Only after the complete chain closes is the declaration authoritative:

> **CENTL v0.14.0 is an Oasis release.**
