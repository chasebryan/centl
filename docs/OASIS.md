# The CENTL Oasis Release Standard

**Status:** authoritative project release policy  
**Applies to:** stable-product qualification on the `oasis` branch  
**SemVer effect:** none

## Definition

An **Oasis release** is a CENTL release that has been deliberately reconciled, organized, hardened, validated, and established as a cohesive stable baseline.

The lowercase `oasis` branch is CENTL's authoritative standard-product line. Oasis is not a version suffix or a one-time codename. Stable tags remain ordinary Semantic Versioning, for example `v0.14.0`.

Before qualification, a proposed stable release is an **Oasis candidate**. After the complete gate closes on one exact commit, the declaration uses this form:

> **CENTL vX.Y.Z is an Oasis release.**

The canonical branch roles are defined in [RELEASE-POLICY.md](RELEASE-POLICY.md).

## Branch relationship

Oasis is the steadily advanced stable snapshot of current `main` and
`mirage`. The ordinary cycle is:

```text
feature / research work
         |
         v
      mirage          laboratory; installable; never a full release
         |
         | inhabit / integrate
         v
       main           developer distribution; current Camp stay
         |
         | when that tree is the current stable product:
         |   start at origin/oasis so Oasis does not regress
         |   overlay the current main tree (mirage must match)
         |   write the SemVer identity
         |   one linear commit whose only parent is the oasis tip
         |   PR to oasis → exact-SHA qualify → fast-forward oasis → tag
         v
       oasis          steadily advanced stable snapshot
         |
         v
 continue development on mirage and main
```

`mirage` is the development and research laboratory. `main` is the
comprehensive developer and research distribution. Neither is an Oasis
declaration merely because it contains the same files as `oasis`.

> **Oasis is a promotion state of one exact snapshot, not a property of every commit on main or mirage.**

Assurance does not inherit. The Oasis product **is** made from the
stable main/mirage tree. Those are different sentences.

Inspect the official snapshot with:

```sh
./scripts/oasis --snapshot
```

When a checkout cannot honestly close the gate, FCF occupies a
[Camp](FCF-CAMPS.md). A Camp is a stay. It does not close Oasis, inherit
Oasis, or replace the official snapshot path.

## Oasis does not regress

A later candidate must not drop, weaken, or replace the already-published Oasis product.

- `origin/oasis` must be an ancestor of any promotion candidate.
- Existing Oasis tests, installer channels, qualification machinery, and supported command surfaces stay.
- New work is added **on top of** Oasis, not instead of it.
- If laboratory history diverged, rebuild the candidate as a linear snapshot on the oasis tip: check out `origin/oasis`, overlay the current stable `main` tree, write the identity, and commit once. Do not merge (`required_linear_history` forbids merge commits). Do not force-push oasis.
- Gates are not weakened, skipped, or rewritten to obtain a green result.

`scripts/oasis.py --inspect` reports a blocker when HEAD does not contain the current oasis tip. That blocker is a non-regression check, not a declaration.

## Stable release boundary

An Oasis release must state exactly what is supported and what is not.

- Intended stable capabilities are present on the reviewed candidate.
- Partially integrated, superseded, experimental, or laboratory surfaces are retired or explicitly kept outside the stable runtime boundary.
- Platform support and installed command claims match the actual package.
- Experimental systems cannot inherit verified or stable assurance by proximity.
- Deferred work is named as deferred.

For v0.14.0, the standard native package is GNU/Linux x86_64 and installs `centl`, `centl-physics`, and `centl-sci`. MIRAGE and CARAVAN Phase 1 are admitted only under the source/laboratory boundaries documented for the release; neither becomes an additional native public command merely because its source is present.

## Repository coherence

The release gate requires agreement across:

- `src/ocaml/centl_version.ml`;
- `CHANGELOG.md`;
- `docs/releases/VERSION.md`;
- the Oasis README current-release section;
- the version-specific section in this document;
- platform, installer, package, security, and release claims.

Obsolete one-shot release machinery and abandoned active-state artifacts must not remain in the supported release path. Pull requests targeting `oasis` that could alter the release must be reconciled before publication.

Historical branches may remain when they preserve unique work. Historical ref count alone does not defeat Oasis qualification.

## Security convergence

An Oasis release requires source remediation rather than alert suppression.

- No known unresolved **release-blocking** security finding remains.
- GitHub Actions use least-privilege permissions and immutable action identities.
- Installer, archive, update, publication, dependency, and artifact-authentication boundaries are reviewed.
- Applicable filesystem, parser, process, protocol, native-library, model, MIRAGE, and CARAVAN trust boundaries are reviewed.
- Hostile or attacker-controlled inputs have realistic resource ceilings.
- High/critical release-blocking code-scanning or dependency alerts block the release.
- Any open secret-scanning alert blocks the release.

Oasis does not mean vulnerability-free. It means the defined release security review completed without knowingly concealing a release-blocking defect.

## Validation convergence

The final candidate must pass every applicable required gate, including:

- executing toolchain identity against `toolchain.lock`;
- release metadata coherence;
- canonical formatting and whitespace integrity;
- F* verification;
- fresh generated-core extraction identity;
- repository quality, licensing, installer-interface, integrity, and supply-chain checks;
- native unit, integration, regression, and protocol tests;
- repository Python tests, including CARAVAN automation coverage;
- mandatory sanitizer-backed hardening;
- adversarial, fuzz, metamorphic, and performance gates;
- Julia/Nemo differential validation;
- CENTL-SCi interface validation;
- release packaging;
- hostile release-archive validation;
- isolated installed-binary smoke tests.

A missing required gate is a failure. A skipped, neutral, pending, failed, or look-alike hosted check cannot be used as proof of Oasis qualification.

## Executable convergence engine

The authoritative local command is:

```sh
./scripts/oasis
```

Verification-only convergence without canonical-format repair is:

```sh
./scripts/oasis --no-repair
```

The engine is fail-closed. Canonical formatting is the only automatic source repair it may perform. It does not rewrite semantic code, weaken tests, suppress security policy, choose a release identity, merge branches, or convert skipped work into success.

Every executed gate has a hard timeout. Complete logs and SHA-256 identities are preserved beneath `_build/oasis/` in an atomic evidence record.

See [OASIS-ENGINE.md](OASIS-ENGINE.md).

## Hosted exact-SHA proof

Local success alone is not enough for the final release.

The exact final source SHA must receive authentic GitHub Actions successes named:

- `Adversarial engine self-test`;
- `Full stable-product convergence`;
- `Release security state`.

The checks must belong to the exact source SHA, be produced by GitHub Actions, link to an Actions run, and complete successfully. Missing or look-alike checks fail closed.

For v0.14.0, the full hosted convergence checks out the literal proposed branch head SHA rather than relying on a synthetic pull-request merge ref. The release build is stamped with that same source commit.

## Installation and archive integrity

The release package must satisfy all of the following:

- package version matches the authoritative source version;
- package build identity names the exact qualified commit;
- generated-core identity matches the verified source snapshot;
- the archive checksum verifies;
- absolute, parent-traversal, non-canonical, duplicate, linked, special, and unsafe-permission archive members are rejected;
- required command surfaces are present;
- staged installation succeeds without activating unvalidated bytes;
- exact arithmetic, rigorous approximation, physics, and scientific-interface smoke probes pass where applicable.

## Qualified-byte publication

A release must publish the bytes that were actually qualified.

The successful exact-SHA full convergence uploads the release archive and checksum as an artifact named for the qualified commit. Publication is not permitted to perform a fresh substitute build.

The final release latch requires:

1. the exact green source SHA is the current `origin/oasis` head;
2. the source version determines the exact `vX.Y.Z` tag;
3. all mandatory hosted Oasis checks are authentic successes for that SHA;
4. no open pull request still targets `oasis`;
5. exactly one unexpired qualified release artifact exists for the successful exact-SHA convergence run;
6. archive checksum, embedded version, build-manifest commit, platform, architecture, and verification attestation all match;
7. the tag points to the exact qualified `oasis` SHA;
8. only those already-qualified bytes are attached to the GitHub release;
9. the published bytes are downloaded and reverified after publication.

If any step fails, the release is not complete.

See [OASIS-PROMOTION.md](OASIS-PROMOTION.md).

## Documentation and trust honesty

Stable-product documentation must not overstate capability, platform support, network deployment, proof strength, autonomous behavior, or assurance.

Generated, external, model-produced, laboratory, and local-extension results remain visibly separated from verified-core claims. Parser success does not imply mathematical proof. A local model is not mathematical authority. CARAVAN carrier availability does not define artifact trust. MIRAGE candidate generation does not confer activation authority.

## Evidence record

Qualification evidence must preserve the exact commit identity and applicable gate results. A green badge alone is insufficient if known release-blocking work remains unresolved.

Conversely, unfinished Mirage research, non-shipped laboratory capabilities, or irrelevant historical refs do not invalidate a qualified Oasis release when they lie outside the declared stable-product boundary.

## Independence between releases

Oasis status never carries forward automatically. Every release must independently satisfy the standard. The next Oasis is a new snapshot of the then-current stable main/mirage tree, parented on the previous oasis tip.

A later-discovered vulnerability does not rewrite the historical fact that a release passed its defined gate, but it must be handled through normal security advisories, fixes, and supported-version decisions. Oasis does not mean permanently supported, invulnerable, or mathematically complete.

## v0.15.0

CENTL v0.15.0 is the official snapshot of the current stable main and
mirage trees, placed on the current oasis tip so Oasis does not regress.
After this snapshot is promoted, development continues on `mirage` and
`main`.

The final declaration carried by the exact release candidate is:

> **CENTL v0.15.0 is an Oasis release.**

This declaration becomes authoritative only if this exact candidate SHA
passes every applicable local and hosted gate, is promoted unchanged to
`oasis`, receives the exact `v0.15.0` tag, and publishes and reverifies
the already-qualified release bytes. Any source change after
qualification creates a new candidate and requires the gate again.

The installed product remains GNU/Linux x86_64 with `centl`,
`centl-physics`, and `centl-sci`. Laboratory surfaces do not inherit
Oasis by sitting in the same tree.

### Historical v0.14.0

CENTL v0.14.0 is the first release prepared under this complete Oasis standard.

The final declaration carried by the exact release candidate is:

> **CENTL v0.14.0 is an Oasis release.**

This declaration becomes authoritative only if this exact candidate SHA passes every applicable local and hosted gate, is promoted unchanged to `oasis`, receives the exact `v0.14.0` tag, and publishes and reverifies the already-qualified release bytes. Any source change after qualification creates a new candidate and requires the gate again.
