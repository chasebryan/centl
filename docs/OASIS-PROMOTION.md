# CENTL Oasis promotion path

Oasis promotion is deliberately bound to one exact source identity from final candidate qualification through publication.

## 0. Official snapshot from main and mirage

Oasis represents the current stable `main` and `mirage` trees. It is
steadily advanced; it does not regress. After a snapshot is promoted,
development continues on `mirage` and `main`.

Build the candidate as a linear descendant of the current oasis tip:

```text
origin/oasis
        |
        | overlay current origin/main
        | (origin/mirage must have the same tree)
        | write SemVer identity
        v
one linear commit   ← this is the Oasis candidate
        |
        | exact-SHA hosted qualification
        v
same SHA fast-forwarded to oasis
        |
        v
continue development on mirage and main
```

Do not squash-merge that pull request. Do not create a merge commit. Do
not force-push `oasis`, `main`, or `mirage`. If histories have diverged
through squash-landing, overlay the stable tree onto the oasis tip
instead of merging.

`./scripts/oasis --snapshot` reports whether the current checkout matches
this procedure. It never declares Oasis.

## 1. Exact candidate proof

A pull request targeting `oasis` enters the hardened exact-SHA target qualification path. The trusted workflow definition lives on the repository default branch, admits only a same-repository candidate authored by the repository owner, and executes candidate code with read-only repository permissions. For the Oasis candidate it checks out the **literal pull-request head SHA**, not GitHub's synthetic merge commit, and requires:

- `Identity, integrity, catalog, policy, and outbound transport gates`;
- `Adversarial engine self-test`;
- `Full stable-product convergence`;
- `Release security state`.

The full convergence runs the pinned proof/native/OCaml/Julia-Nemo/CARAVAN toolchain and stamps the release build with that exact PR-head SHA. A successful run preserves the exact release archive, checksum, and Oasis evidence under artifact names containing the same source identity.

Write authority is separated from candidate execution: only a post-qualification attestation job, which does not check out or execute candidate code, may publish the mandatory exact-SHA GitHub check attestations and final qualification status.

A missing, skipped, neutral, pending, failed, or look-alike mandatory hosted check is not qualification.

Once the final candidate is conflict-free, its qualifying synchronization is treated as the freeze point: no further source edit is admissible without creating a new candidate SHA and restarting the complete gate.

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

The intended path is therefore:

```text
current stable main / mirage tree
        |
        | linear snapshot on the oasis tip
        v
final Oasis PR head SHA
        |
        | exact-SHA hosted qualification
        v
same SHA fast-forwarded to oasis
        |
        | close qualification PR / release latch
        v
same SHA tagged vX.Y.Z
        |
        v
exact qualified bytes published + reverified
        |
        v
development continues on mirage and main
```

Only after the complete chain closes is the declaration authoritative:

> **CENTL vX.Y.Z is an Oasis release.**
