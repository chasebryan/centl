# FCF local preservation drills

Status: local operational infrastructure for CENTL preservation.

GitHub Actions is useful public CI, but it should not be the only scheduler or
executor capable of checking CENTL's preservation state. This directory provides
a simple systemd user timer that runs the FCF preservation checks on an
FCF-controlled Linux machine.

The scheduled path is intentionally local. If GitHub Actions is unavailable, the
primary mirror, independent copy, saved OCI capsule, and these local checks still
exist and can be exercised without hosted CI.

## Drill modes

`scripts/preservation-drill` supports two modes.

`verify` performs:

1. `scripts/supply-chain audit` against the primary mirror;
2. strict whole-mirror receipt verification;
3. strict primary/secondary comparison when a secondary path is configured;
4. recording the current regular-file and symbolic-link receipt identities.

`full` performs all of the above and then runs the saved OCI capsule through
`scripts/capsule-run`, which executes the no-network CENTL rebuild/test/differential
recovery gate.

Reports are written outside the mirror. The drill refuses to place its report
directory inside either preservation copy because writing a report there would
invalidate the whole-mirror receipt. The containment check occurs before the
report directory is created, so an invalid configuration does not mutate the
mirror merely by failing.

## Manual execution

With explicit paths:

```sh
CENTL_DRILL_REPORT_DIR="$HOME/.local/state/centl/preservation" \
  sh scripts/preservation-drill verify \
    /srv/centl-mirror \
    /mnt/fcf-backup/centl-mirror
```

Run the complete no-network recovery drill with:

```sh
CENTL_DRILL_REPORT_DIR="$HOME/.local/state/centl/preservation" \
  sh scripts/preservation-drill full \
    /srv/centl-mirror \
    /mnt/fcf-backup/centl-mirror
```

The same values may be supplied through the environment variables documented in
`preservation.env.example`.

## Install the weekly user timer

Create the user configuration directories:

```sh
mkdir -p "$HOME/.config/centl" "$HOME/.config/systemd/user"
```

Copy and edit the environment file:

```sh
cp infra/preservation/preservation.env.example \
  "$HOME/.config/centl/preservation.env"
```

Set real absolute paths in that file. Then install the user units:

```sh
cp infra/preservation/centl-preservation.service \
  "$HOME/.config/systemd/user/centl-preservation.service"
cp infra/preservation/centl-preservation.timer \
  "$HOME/.config/systemd/user/centl-preservation.timer"

systemctl --user daemon-reload
systemctl --user enable --now centl-preservation.timer
```

The supplied timer runs weekly with a small randomized delay. `Persistent=true`
means a missed run can execute after the user session becomes available again.
The cadence can be changed locally without changing CENTL source.

## Test immediately after installation

Do not wait for the first scheduled run to learn that a path or mount is wrong:

```sh
systemctl --user start centl-preservation.service
systemctl --user status centl-preservation.service
```

Inspect timer state with:

```sh
systemctl --user list-timers centl-preservation.timer
```

The detailed durable report is written to `CENTL_DRILL_REPORT_DIR`; systemd's
journal provides the local service log as well.

## Recommended cadence

For the current project scale, a weekly `verify` drill is a reasonable default.
A `full` capsule recovery is heavier because it performs an actual isolated
rebuild and test suite. Run it after material toolchain/preservation changes and
periodically thereafter—for example monthly or before release promotion.

The frequency is operational policy, not a cryptographic property. A modest
schedule that is actually maintained is preferable to an elaborate schedule that
is routinely disabled.

## Failure handling

A failed drill exits non-zero and records the failed step in its report. Treat a
failure as a preservation incident until explained.

Do not respond to a failed checksum or mirror comparison by regenerating receipts.
First determine whether the cause is an intentional update, an incomplete copy,
storage corruption, or some other known event. Only intentionally accepted bytes
receive a new receipt.

## Independence boundary

The systemd timer removes GitHub Actions from the recurring preservation-check
path. The local machine still needs access to the FCF-controlled storage paths
and, for `full` mode, a working Podman installation capable of loading the saved
OCI archive.

No public network is required by `mirror-receipt compare` or by the saved capsule
recovery run. The capsule run itself uses `--network none`.
