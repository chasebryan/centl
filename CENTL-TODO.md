# CENTL short-term work

This is a working checklist. Product sequencing and release themes live in
[`docs/ROADMAP.md`](docs/ROADMAP.md); canonical dependency pins live in
[`toolchain.lock`](toolchain.lock).

## Infrastructure completed for the next development cycle

- [x] Add a reproducible contributor bootstrap and exact opam dependency
  manifest.
- [x] Make formatting, compiler checks, package linting, and pin consistency
  part of `make quality`.
- [x] Keep pull-request validation to one Linux verify/test/differential job;
  reserve all-platform native packaging for `main`, tags, and manual runs.
- [x] Run the seeded Julia/Nemo differential suite in pull-request CI.
- [x] Cancel superseded branch workflow runs while preserving tagged releases.
- [x] Exercise GMP with a large exact integer in the Core 2 compatibility smoke
  test.

## Calculator experience

- [x] Add interactive completion and bounded in-session history.
- [x] Support multiline input without weakening script semantics.
- [x] Give parse diagnostics precise file or input line, column, and caret
  context.
- [x] Add bounded exact sequences and recurrence evaluation.
- [x] Persist interactive history across calculator processes.
- [ ] Carry source spans through evaluation so runtime mathematical failures can
  point back to their originating subexpression.

## Math contracts (0.12.0 path)

- [x] Structured verify / check / assert surfaces.
- [x] Discharge every F* zero-difference soundness obligation before enabling
  `verified_core` polynomial equality.
- [x] Finish bounded, replayable receipts with resolved session dependencies.
- [x] Add release `BUILD_MANIFEST.json` identity validation across every
  platform.
- [ ] Run the all-platform RC workflow and confirm all four manifests pass the
  cross-platform identity gate.
- [x] Validate the reusable `centl-check` GitHub Action and passing
  example contracts.
- [ ] Publish the final 0.12.0 tag after RC validation with stamped release
  identity and the conformance CI gate.
- [ ] Pilot three external contract repositories.

Keep this file limited to actionable near-term work; remove or check items when
the implementation lands instead of duplicating completed CI or setup tasks.
