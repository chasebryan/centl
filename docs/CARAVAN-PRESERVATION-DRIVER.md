# FCF CARAVAN preservation driver

Status: **implemented for FCF-controlled preservation/origin hosts.**

The manual bring-up of the first Trisquel ThinkPad X200 exposed an operational problem: after every legitimate repository repair, the operator had to repeat a long sequence of source-manifest, bundle, audit, capsule, and receipt commands by hand. That is error-prone and turns the human operator into a fragile orchestration layer.

The supported operator path is now:

```sh
scripts/caravan-preserve
```

After the driver exists in a checkout, that same command is used for normal updates, retries after a failed qualification, and recovery after an interrupted source-only refresh.

## Contract

The driver is conservative about expensive preserved cargo.

On its normal path it:

1. requires a clean tracked worktree;
2. switches to `main`, fetches `origin/main`, and accepts only a fast-forward update;
3. re-executes the freshly updated copy of itself so preservation policy cannot change underneath a running old script;
4. serializes local runs with a preservation lock;
5. verifies the prior whole-mirror receipt before unsealing a previously finalized mirror;
6. recognizes the narrowly defined first-node interrupted state where only `project/centl.bundle`, `SOURCE-COMMIT`, `SOURCE-SHA256SUMS`, and its checksum changed after the prior seal, and authenticates every other old receipt path before accepting that state;
7. reuses the existing dependency cargo and OCI recovery capsule when they are complete;
8. refreshes the CENTL source manifest, supply-chain lock, Git bundle, source checksum receipt, and exact source commit;
9. audits and verifies the refreshed source snapshot;
10. runs the saved OCI capsule with networking disabled;
11. creates the whole-mirror receipt only after the no-network recovery proof succeeds; and
12. independently verifies the newly created whole-mirror receipt.

A failed cycle does not delete the preservation mirror, downloaded artifacts, opam snapshot, Julia depot, Git mirrors, or saved OCI capsule. The driver reports the failed phase and instructs the operator to run the same command again after the repository repair lands.

## Full path

If the mirror does not exist, the saved capsule is incomplete, or the operator explicitly requests it, the driver escalates to the full preservation path:

```sh
scripts/caravan-preserve --full
```

That path runs the repository's complete `supply-chain-preserve` target and builds the recovery capsule before attempting the no-network qualification. Existing downloads and package caches are reused where their underlying tools permit it.

The operator may select a non-default mirror with:

```sh
scripts/caravan-preserve --mirror /path/to/centl-mirror
```

`/srv/centl-mirror` remains the default FCF origin-preservation location.

## Failure semantics

A failed run prints:

```text
CARAVAN PRESERVATION PAUSED
phase: <failed phase>
mirror: <mirror path>
```

The mirror remains deliberately unsealed if the failure occurred after a controlled mutation. It must not be treated as finalized publication authority until a later run reaches the no-network PASS and recreates the whole-mirror receipt.

The driver never uses `git reset --hard`, `git clean`, or recursive mirror deletion as a recovery strategy.

## Security boundary

Automation does not weaken the preservation contract.

The driver does not turn GitHub into publication authority. GitHub is only used during the acquisition/update stage for the FCF-controlled checkout. The public-origin publication path still consumes only a finalized preservation mirror, exact root authorization, networkless export/ingest stages, and the existing approved-store activation contract.

The no-network capsule proof remains mandatory. A mirror is not resealed merely because source synchronization succeeded.

## First-node transition

The initial X200 bring-up predates this driver and therefore may contain a stale whole-mirror receipt created before one of the manually performed source-only refreshes. The driver has one intentionally narrow recovery rule for that transition: the old receipt checksum and symlink receipt must authenticate, and every old regular-file path except the four known source-refresh files must still match the old manifest exactly.

Anything outside those four paths that disagrees with the old receipt is a hard failure. The script will not silently bless a generally corrupted mirror.

Once the first successful automated cycle completes, subsequent preservation work should use the driver rather than repeating the underlying commands manually.
