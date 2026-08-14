# Joining the FCF CARAVAN manually

Status: normative operator/user procedure. Public volunteer network enrollment is still gated; the signed join release currently prepares a carrier without starting network service.

CARAVAN exists to preserve and distribute authenticated Free Computation Foundation material without turning volunteer computers into general-purpose servers. A person may join with the signed `join-caravan` release, or may follow the same steps manually for audit, research, recovery, or environments where automation is undesirable.

The ordinary volunteer path is intentionally different from an FCF-owned public origin. A volunteer carrier is rootless, outbound-only, resource-bounded, and never publishes arbitrary local files. The FCF public-origin role is Foundation-operated infrastructure and is documented separately in `CARAVAN-PUBLIC-ORIGIN.md`.

## 1. The trust rule

Never join CARAVAN by running a mutable branch script such as:

```text
curl https://.../main/join-caravan | sh
```

An official join installer is a versioned, immutable FCF-signed release artifact. The release version, archive SHA-256, FCF signing-key identity, inner exact-membership manifest, and signatures are part of the installation identity.

The mutable file `scripts/caravan-join-template` is development source only and deliberately refuses to act as the official installer.

A user must obtain the trusted FCF CARAVAN join public key independently of the release being verified. The public key should be cross-published by FCF through multiple controlled channels. No script can cryptographically manufacture trust in its own signing key.

## 2. What a normal volunteer may choose to preserve

During initialization, the volunteer selects one or more CARAVAN missions. These are filters over authenticated FCF `public-approved` catalog entries. Selecting a mission never grants the machine authority to add a local file, arbitrary URL, arbitrary digest, or unapproved artifact to the network.

The mission classes are:

| Mission | Preserves | Notes |
| --- | --- | --- |
| `source` | Approved CENTL source snapshots | Exact authorized branch snapshots and source metadata, not private Git history. |
| `releases` | Signed FCF/CENTL release artifacts | Immutable public release archives and adjacent authenticated manifests. |
| `semantic` | Redistribution-approved semantic artifacts | Only models/engines that pass the FCF semantic-origin redistribution gate. |
| `recovery` | Public-approved recovery/toolchain artifacts | Recovery capsules or toolchain material only when FCF has explicitly admitted them to the public catalog. |
| `all` | All of the above | Convenience selector; still restricted to `public-approved` catalog identities. |

A volunteer can change mission preferences later through an authenticated configuration update, but already installed immutable executable release bytes are never edited in place.

The guided join release installs the current FCF Oasis distribution after consent, verifies its adjacent SHA-256 before activation, places `centl`, `centl-physics`, and `centl-sci` in `~/.local/bin`, and records the version in the private carrier receipt. A user may pass `--no-oasis` when they intentionally want the carrier without the Oasis command-line tools.

## 3. Resource and privacy invariants

A normal carrier must retain all of these properties:

- runs as the user's account, not as root;
- opens no inbound port by default;
- is not advertised in The Bazaar by home IP or hostname;
- cannot accept arbitrary uploads;
- cannot act as a proxy, VPN, tunnel exit, shell gateway, generic web host, Git host, or directory share;
- stores only content-addressed objects admitted by authenticated FCF metadata;
- enforces a storage ceiling and minimum free-space reserve;
- enforces outbound bandwidth, concurrency, queue, and transfer limits;
- supports explicit withdrawal and credential rotation;
- does not silently self-update;
- exposes no home directory to CARAVAN;
- reports only the minimum census information required to count the carrier privately.

The coordinator may necessarily observe a source network address while accepting an HTTPS connection, but CARAVAN policy forbids persisting that address in census records or publishing it. Web/access logging for census endpoints must be disabled or scrubbed accordingly.

## 4. Supported Linux strategy

The official installer is capability-first rather than branding-first. If required commands already exist, an unfamiliar Linux distribution may proceed without being rejected merely because its `/etc/os-release` name is unknown.

The compatibility target includes the major Linux package families:

- Debian, Ubuntu, Trisquel, Linux Mint and derivatives (`apt`);
- Fedora, RHEL, Rocky, Alma, CentOS and derivatives (`dnf`/`yum`);
- openSUSE and SUSE derivatives (`zypper`);
- Arch, Manjaro, EndeavourOS and derivatives (`pacman`);
- Alpine (`apk`);
- Void (`xbps-install`);
- Gentoo (`emerge`);
- NixOS and other immutable/package-declarative systems through a capability-present path rather than forced host mutation.

Before a CARAVAN `1.0.0` join release is signed, each supported family must have an automated clean-container/VM installation test and at least one real-host smoke test. A distro name in documentation is not proof of support.

The normal carrier must not require systemd. Systemd is a security boundary for the separate FCF public-origin role, not a universal volunteer requirement.

## 5. Obtain an immutable join release

An official release directory has this shape:

```text
fcf-caravan-join-X.Y.Z/
  fcf-caravan-join-X.Y.Z.tar.gz
  FCF-CARAVAN-JOIN.pub
  SHA256SUMS
  SHA256SUMS.sig
```

Keep a separately acquired trusted FCF join public key outside this directory.

From a trusted CENTL checkout, an operator can use the independent verifier:

```sh
scripts/caravan-join-verify \
  /path/to/fcf-caravan-join-X.Y.Z \
  /trusted/fcf-caravan-join.pub
```

The verifier requires the bundled public key to be byte-for-byte identical to the separately trusted key, verifies the outer FCF signature, checks exact release membership, safely extracts the archive, then verifies the inner signed exact-membership manifest.

If verification fails, stop. Do not repair, re-download from an untrusted alternate URL, or replace expected digests merely to make the check pass.

## 6. Extract and inspect before execution

After independent verification, extract the archive into a temporary directory and inspect the release metadata if desired:

```sh
mkdir -p "$HOME/tmp/fcf-caravan-join"
tar -xzf fcf-caravan-join-X.Y.Z.tar.gz \
  -C "$HOME/tmp/fcf-caravan-join"
cd "$HOME/tmp/fcf-caravan-join/fcf-caravan-join-X.Y.Z"
cat RELEASE.json
```

The extracted `join-caravan` script performs the inner signature and exact-membership checks again before it installs anything.

## 7. Choose preservation missions

Interactive installation is the preferred human path:

```sh
./join-caravan
```

The installer asks which mission classes the user wants to support and displays the resulting configuration before writing it.

For reproducible/non-interactive setup, specify the missions explicitly:

```sh
./join-caravan \
  --missions source,releases \
  --storage-gib 25 \
  --upload-mibps 4 \
  --yes
```

Examples:

```sh
# Small source/release carrier
./join-caravan --missions source,releases --storage-gib 10

# Semantic preservation volunteer
./join-caravan --missions semantic --storage-gib 100

# Broad preservation node
./join-caravan --missions all --storage-gib 250
```

Mission selection is not a publication authorization. A `semantic` carrier, for example, still receives nothing unless the active semantic artifact has passed exact provenance and redistribution approval.

## 8. Local layout

The normal rootless installation uses XDG user directories:

```text
~/.config/fcf-caravan/
  config.json

~/.local/share/fcf-caravan/
  store/

~/.local/state/fcf-caravan/
  identity/
  census/

~/.local/lib/fcf-caravan/releases/
  X.Y.Z/
```

The executable release directory is installed read-only. Mutable configuration, content-addressed cargo, local identity material, and runtime state are kept separate from release bytes.

The installer must reject symbolic-link tricks at security-sensitive roots and must never accept a user home path as publishable cargo.

## 9. Current network status

Until the production authenticated enrollment protocol passes the gates tracked in issue #167, a signed join release records:

```json
"network_mode": "disabled-until-authenticated-enrollment"
```

That means the current release can prepare a carrier and record its selected missions, but it must not start pretending to be a live public CARAVAN participant.

No inbound listener, public advertisement, heartbeat, content request, or coordinator connection should occur before a later FCF-signed release explicitly enables the production protocol.

## 10. Production enrollment contract

When public volunteer enrollment is promoted, the same one-command installer experience will perform these operations after release authentication:

1. detect capabilities and the Linux package family;
2. acquire any strictly necessary host dependency through the native package manager only after the authenticated release has been established;
3. display the preservation mission picker;
4. display storage/bandwidth/privacy terms;
5. create owner-only local state and a high-entropy carrier enrollment token;
6. enroll over authenticated TLS without publishing the home address/hostname;
7. fetch authenticated TUF/catalog metadata;
8. accept only `public-approved` content identities matching the selected missions;
9. start an outbound-oriented carrier worker using the best available user-service mechanism for that Linux environment;
10. begin privacy-minimized census heartbeats;
11. print the carrier's local status and exact immutable release identity.

The production script must be safe to re-run. It may inspect existing state and offer an authenticated upgrade or configuration change, but it must never overwrite an existing immutable release version.

## 11. Manual configuration audit

After preparation, inspect the carrier configuration:

```sh
python3 -m json.tool "$HOME/.config/fcf-caravan/config.json"
```

Required properties include:

```text
rootless carrier
inbound_listen = false
arbitrary_content = false
selected missions explicitly recorded
bounded storage
bounded outbound rate
network enrollment disabled until an authenticated production release enables it
```

Any configuration claiming an arbitrary local path, public inbound listener, proxy, tunnel, or generic upload role is not a valid normal CARAVAN carrier configuration.

## 12. Census and the public camel counter

Production carriers participate in the privacy-preserving census described in `CARAVAN-CENSUS.md`.

The public website receives aggregate counts only. It may display:

```text
Active Camels 🐪
Lost Camels 🐪
```

It must not publish a list of carrier IDs, IP addresses, hostnames, usernames, emails, coordinates, or exact per-node mission combinations.

An explicitly withdrawn carrier is not a Lost Camel. Lost means a previously enrolled carrier whose authenticated heartbeat has been absent beyond the defined loss window and which has not deliberately withdrawn or been revoked.

## 13. Withdraw from CARAVAN

The production client must provide an explicit withdrawal operation. Withdrawal must:

1. authenticate the request with the carrier's existing enrollment credential;
2. mark the carrier withdrawn at the coordinator;
3. stop future CARAVAN work;
4. prevent the carrier from being counted as Lost;
5. offer deletion of local cargo and identity state separately;
6. leave immutable historical release bytes untouched unless the user explicitly asks to remove them.

A machine that simply disappears remains eligible for Lost Camel accounting after the loss threshold.

## 14. Uninstall locally

Before the production service is enabled, a prepared carrier can be removed by deleting its user-owned CARAVAN configuration/state/data and, if desired, immutable release directories. Do not use a privileged recursive deletion against arbitrary paths.

A future signed production release will ship a dedicated `leave-caravan`/uninstall command that validates every removal path against the fixed XDG CARAVAN roots before deleting anything.

## 15. FCF public-origin operators

Foundation-operated public origins are not installed through the volunteer join path. They require a finalized FCF preservation mirror, explicit source authorization, root-managed networkless publication stages, a dedicated-host nftables boundary, nginx static publication, TLS, hostile probes, and the public-origin audit.

Use:

```text
docs/PRESERVATION-OPERATIONS.md
docs/CARAVAN-PUBLIC-ORIGIN.md
scripts/caravan-public-origin-install
```

A volunteer machine must never become an FCF public origin merely because the user chose `all` missions.

## 16. Release engineering requirement

The goal is one cohesive Linux `join-caravan` entry point, but cryptographic trust bootstrap cannot be wished away. The user-facing script may automate platform detection, dependency installation, mission selection, resource policy, enrollment, service integration, census, verification, and status. The immutable release still has to be authenticated against a separately trusted FCF public key before it is granted that authority.

Convenience is allowed to remove repetitive work. It is not allowed to remove the independent trust anchor.
