# FCF-approved preservation nodes

Status: normative FCF internal-operations role.

An **FCF-approved preservation node** is a machine deliberately placed under Free Computation Foundation control for the purpose of maintaining, verifying, and recovering the Foundation's own preservation state.

This role is **not downstream** and is not the ordinary public `join-caravan` volunteer role. It is also not automatically a public CARAVAN origin. An approved preservation node may remain entirely private and offline except when an operator intentionally refreshes it.

The standard operator entry point is:

```sh
scripts/caravan-preserve
```

That command is the canonical resumable preservation driver for FCF-controlled Linux machines.

## Role boundaries

Three CARAVAN machine classes must remain distinct:

| Role | Authority | Network posture | Standard entry point |
| --- | --- | --- | --- |
| FCF-approved preservation node | Maintains the complete private FCF preservation mirror and recovery state | Private by default; may fetch approved upstream inputs during controlled refresh | `scripts/caravan-preserve` |
| FCF public origin | Publishes only explicitly approved, compiled public cargo from an FCF preservation mirror | Dedicated public TCP 80/443 host with hardened closed-world publication | `scripts/caravan-public-origin-install` |
| Downstream volunteer carrier | Stores and serves only authenticated `public-approved` CARAVAN cargo selected by mission | Rootless and outbound-oriented by default | immutable signed `join-caravan` release |

A machine does not cross these boundaries merely because it has the software installed. FCF must deliberately authorize the role.

## Preservation driver contract

On an existing FCF preservation machine, normal operation is:

```sh
cd /path/to/centl
scripts/caravan-preserve
```

The driver:

1. requires a clean tracked checkout;
2. fast-forwards to `origin/main` unless `--no-update` is requested;
3. re-executes the freshly updated preservation policy;
4. acquires a single-run local lock;
5. reuses an existing dependency mirror and OCI recovery capsule whenever they remain valid;
6. refreshes only the CENTL source snapshot when a full dependency rebuild is unnecessary;
7. performs the no-network recovery proof;
8. recreates the whole-mirror receipt only after the recovery proof succeeds; and
9. independently verifies the resulting receipt before reporting PASS.

A failed cycle does not intentionally delete preserved cargo. After the repository or environment is repaired, the operator runs the same command again.

## First use on a newly approved FCF machine

A new FCF preservation node may begin with an empty mirror or with a separately verified copy of an existing FCF mirror.

For a fresh build:

```sh
cd /path/to/centl
scripts/caravan-preserve --full
```

If the default preservation path does not apply:

```sh
scripts/caravan-preserve --mirror /path/to/fcf-preservation --full
```

The machine must have the required host capabilities for the full preservation path, including Git, Python, make, Podman, opam, and the pinned Julia runtime used by the active preservation procedure.

For a node seeded from another FCF-controlled copy, first prove the copy with `scripts/mirror-receipt compare` while the source mirror is available. After that verified copy is installed at the intended preservation path, `scripts/caravan-preserve` becomes the normal maintenance command.

## Fixed-snapshot and disconnected operation

`--no-update` prevents the driver from contacting `origin/main` before a preservation cycle:

```sh
scripts/caravan-preserve --no-update
```

This is useful when proving a deliberately fixed checkout or operating in a disconnected environment. It does not disable the no-network recovery proof itself; that proof remains mandatory.

A full first-time dependency acquisition cannot be conjured from an empty machine without the required inputs. FCF's long-term Dependency Chest is intended to reduce and eventually eliminate live third-party acquisition from Oasis/recovery operations by supplying authenticated immutable crates.

## FCF approval rule

Possession of this script does not make a machine FCF infrastructure.

An FCF-approved preservation node must be deliberately designated by the Foundation and operated under Foundation-controlled administrative access. At minimum, FCF should record:

- an internal node label that does not expose a private hostname publicly;
- the operator or custody owner;
- the preservation root used by the machine;
- the latest successfully sealed source commit and mirror receipt identity;
- the date of the latest successful no-network recovery proof; and
- whether the node is also authorized for any additional role, such as public origin.

Those records are operational inventory, not a public volunteer census. Private FCF node identifiers, hostnames, IP addresses, hardware serials, and administrative details must not be published through the CARAVAN camel counter.

## Copies and independent verification

An FCF preservation node should not be treated as useful merely because `/srv/centl-mirror` exists on it. The mirror must have a valid whole-tree receipt and must periodically prove that receipt.

Use:

```sh
sh scripts/mirror-receipt verify /srv/centl-mirror
```

For a second FCF-controlled copy:

```sh
sh scripts/mirror-receipt compare \
  /srv/centl-mirror \
  /mnt/fcf-backup/centl-mirror
```

Encrypted removable storage is appropriate for independent offline copies when the encryption recovery material is itself backed up separately.

## Promotion to public origin

A private FCF preservation node does not become a public server by running `scripts/caravan-preserve`.

Public-origin promotion is a separate explicit operation with its own dedicated-host, source-authorization, nftables, nginx, TLS, networkless ingest/candidate/activation, and hostile-audit requirements documented in `CARAVAN-PUBLIC-ORIGIN.md`.

This separation is intentional: preserving the Foundation's complete private cargo and publishing a deliberately minimized public tree are different trust boundaries.
