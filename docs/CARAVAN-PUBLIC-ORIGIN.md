# CENTL CARAVAN public origin

Status: **FCF-owned public-origin pilot tooling implemented; public volunteer enrollment remains a later phase.**

The first CARAVAN public origin is intended for an FCF-controlled GNU/Linux host, beginning with the Trisquel ThinkPad X200 pilot machine.

This role is intentionally different from a future volunteer carrier. An FCF-owned public origin may listen on public TCP 80/443 because it is Foundation-controlled infrastructure. A normal volunteer carrier remains rootless and outbound-only by default.

The public-origin rule is:

> **If a byte did not cross the FCF preservation and explicit publication boundary, the public origin has no mechanism for serving it.**

The FCF preservation mirror itself is never a web root.

## Purpose

The origin gives users a direct FCF source for explicitly authorized CENTL source snapshots and, when separately approved, preserved releases and semantic-model artifacts. It reduces download/runtime dependence on GitHub, model hubs, hosted inference providers, and other intermediaries without turning CARAVAN into general public infrastructure.

The origin is **not**:

- an upload host;
- arbitrary storage;
- a generic mirror;
- a paste/file-drop service;
- a reverse proxy;
- a CONNECT tunnel;
- a VPN or arbitrary relay;
- a shell gateway;
- CGI/FastCGI/uWSGI/SCGI hosting;
- WebDAV storage;
- a public Git smart-HTTP server;
- an anonymous-content network; or
- a public view of the FCF preservation filesystem.

## Closed-world trust pipeline

```text
FCF preservation mirror
        |
        | strict whole-mirror receipt verification
        | exact preserved project/centl.bundle
        v
root-owned source authorization
(bound to exact MIRROR-SHA256SUMS SHA-256)
        |
        | exact main / oasis / mirage commits only
        v
networkless root ingest
        |
        +-- source: preserved bundle + authorization -> source export
        +-- releases: publication-export
        +-- model: model-origin-export --check
        v
/var/lib/fcf-caravan/approved
        |
        | root-owned exact-membership receipt
        v
networkless unprivileged candidate compiler
        user: fcf-caravan
        |
        | no source URL, no GitHub ref, no network
        v
/var/lib/fcf-caravan/candidates
        |
        | shared publication lock
        v
networkless root source guard
        |
        | independent archive secret/path scan
        v
networkless root activator
        |
        | seize + freeze candidate
        | copy without following symlinks
        | byte-compare source/release/model to approved store
        | verify catalog/chunks/receipts
        v
/srv/fcf-caravan-live/current
        |
        | root-owned read-only static tree
        v
nginx GET/HEAD-only allowlist
        |
      Internet
```

The network-facing HTTP server never sees the preservation mirror. The candidate compiler is also networkless: `PrivateNetwork=yes`, `IPAddressDeny=any`, and `RestrictAddressFamilies=AF_UNIX` are part of its systemd sandbox.

The ingest and activation services are networkless root services. Ingest may read the preservation mirror but can write only the CARAVAN publication staging area. Activation may write the live root but receives no network capability.

## Public source contract

CARAVAN does **not** publish source directly from GitHub.

GitHub may be one way FCF originally acquired repository bytes for normal development/preservation, but it is not a live publication authority for the public origin.

Public source must already exist inside:

```text
<FCF preservation mirror>/project/centl.bundle
```

and that complete preservation mirror must pass the normal FCF whole-tree receipt check.

A second root-owned authorization file then names exactly three commits:

```text
main
 oasis
mirage
```

The authorization also records the SHA-256 of the mirror's `MIRROR-SHA256SUMS`. If any intentional preservation change causes that receipt identity to change, the old authorization becomes stale and source publication stops. The system does not automatically bless the new bytes.

The explicit operator command is:

```sh
sudo /usr/local/libexec/fcf-caravan/caravan-public-origin-authorize-source \
  --preservation-root /srv/centl-mirror \
  --main <commit> \
  --oasis <commit> \
  --mirage <commit>
```

The normal installer can auto-resolve those three refs from the preserved bundle and displays the exact commits before authorization.

The resulting public source objects are:

```text
/source/centl-main.tar.gz
/source/centl-oasis.tar.gz
/source/centl-mirage.tar.gz
/source/INDEX.json
```

`INDEX.json` records the exact commit IDs, archive SHA-256 values, mirror-receipt SHA-256, and source-authorization SHA-256.

The preserved Git history bundle is not served.

Before source can enter the approved tree, the source exporter rejects:

- symbolic-link entries;
- Gitlinks/submodules and other non-regular entries;
- unsafe/control-character paths;
- common secret-bearing filenames;
- private-key material;
- high-specificity credential/token patterns;
- oversized source blobs; and
- source trees above the file-count ceiling.

The networkless root source guard and primary activator then parse the generated archives independently before live activation.

## Why repository membership is not publication authority

A file being committed to CENTL does not prove it was intended for public CARAVAN distribution.

This distinction matters for accidental secrets, future research material, internal preservation objects, third-party bytes with redistribution constraints, or a compromised branch.

The required sequence is therefore:

```text
repository/development state
        -> FCF preservation
        -> complete preservation receipt
        -> explicit source/publication authorization
        -> public export
```

Skipping a stage is a failure, not a convenience path.

## Preserved release contract

The preservation mirror is never recursively copied into the public tree.

`scripts/caravan-public-origin-ingest` requires the normal FCF whole-mirror verification and then calls `scripts/publication-export`, which exports only release directories already admitted by the CENTL public-release contract.

The release exporter still refuses preservation-only classes such as raw dependency stores, Git mirrors, recovery capsules, opam/Julia state, and models without their separate public contract.

The resulting root-owned approved tree receives an exact-membership SHA-256 manifest. Extra unlisted files cause failure.

## Semantic model contract

Semantic model publication remains independently fail-closed.

The ingest service calls:

```text
model-origin-export.py <mirror> --check
```

before model bytes can enter the approved public tree. The exporter requires exact content identity, verified quantized provenance, recorded base-model identity/license, and an operator-reviewed redistribution status.

If the active model does not satisfy that contract, the model is absent. Source/release publication cannot weaken the model gate.

## CARAVAN catalog

Each generation contains:

```text
/caravan/catalog-v1.json
/caravan/CATALOG-STATUS
/caravan/INGEST-STATUS.json
```

The aggregate catalog uses `centl-caravan-catalog-v1`, whole-file SHA-256 identities, exact byte lengths, `public-approved` distribution class, and ordered 4 MiB SHA-256 chunk records.

The catalog must exactly enumerate every file beneath the public `source`, `releases`, and `semantic` cargo roots.

The raw catalog is not a trust anchor. `CATALOG-STATUS` explicitly says independent TUF authentication is required for network clients. A machine serving bytes never gains authority merely by serving a catalog file.

## Abuse resistance

Normal Internet requests have no route that can create content.

The installed nginx site:

- permits only `GET` and `HEAD`;
- has no reverse proxy directive;
- has no FastCGI/uWSGI/SCGI path;
- has no WebDAV methods;
- has no upload endpoint;
- has no arbitrary filesystem alias;
- has directory indexing disabled;
- exposes only fixed source paths, public metadata, and already-approved release/semantic subtrees;
- defaults every other path to `404`;
- rejects unknown virtual hosts;
- bounds request bodies, connection count, request rate, byte rate, and HTTP ranges; and
- disables normal access logging.

The hostile audit probes mutation methods including POST/PUT/PATCH/DELETE, CONNECT, TRACE, and OPTIONS. It also probes `.git`, traversal encodings, `/etc/passwd`, `/proc/self/environ`, directory roots, and internal CARAVAN filesystem-looking paths.

## Dedicated-host firewall

The public-origin role uses a dedicated nftables policy instead of a distro-specific firewall frontend.

Before changing the firewall, the installer saves the current nftables ruleset and relevant configuration state under a root-only backup directory.

The FCF ruleset is then applied as one validated nft transaction. Its file begins with:

```text
flush ruleset
```

and creates only the `inet fcf_caravan` table with:

- default-drop input;
- loopback;
- established/related traffic;
- ICMP/ICMPv6;
- TCP 80 for ACME/public HTTP redirect;
- TCP 443 for HTTPS; and
- detected SSH administration ports, if present.

Forwarding defaults to drop. Output remains allowed so the host can perform DNS, package maintenance, ACME, and ordinary administration.

Known competing firewall managers are disabled so they cannot later replace the FCF dedicated-host boundary.

This is intentionally a **dedicated-host** policy. Do not install the FCF public-origin role on a machine that is supposed to remain a general web server, container host, VPN gateway, or unrelated application server.

## Linux portability

The public-origin installer depends on Linux capabilities and systemd hardening, not a particular distro label.

If dependencies are missing, it understands these package-manager families:

- `apt-get` — Debian, Ubuntu, Trisquel and relatives;
- `dnf` — Fedora and current RHEL-family systems;
- `yum` — older RHEL-family systems;
- `zypper` — openSUSE/SUSE family;
- `pacman` — Arch family.

If all required commands are already installed, an otherwise unrecognized distribution may still pass.

The FCF-owned public-origin role currently requires **systemd** because `PrivateNetwork`, `ProtectSystem`, capability bounding, read/write path restrictions, and the isolated service-account model are security properties rather than packaging conveniences. An unsupported init system is rejected rather than receiving a weaker server.

This does not constrain the future ordinary volunteer carrier to systemd; the volunteer role is rootless and has a separate release/install contract.

## Data minimization

The nginx origin has access logging disabled. Warning/error logging remains available for operational diagnosis.

The public `status.json` exposes a pseudonymous node identity and publication identities, including the mirror receipt and source-authorization hashes. It does not expose usernames, the preservation path, private preservation contents, or a volunteer-home-network roster.

## Candidate and activation safety

A refresh never edits live cargo in place.

Preservation ingest, candidate compilation, and activation share:

```text
/run/lock/fcf-caravan-publication.lock
```

The lock is recreated on boot by systemd-tmpfiles with only root and the `fcf-caravan` service group able to participate.

The candidate compiler can write only its state/candidate directories and can read the root-approved tree. It cannot write the live web root.

The root activation wrapper runs an independent source guard before the primary activator. The activator then:

1. atomically moves the selected candidate into a root-only inbox;
2. recursively rejects links/special files;
3. makes the claimed tree root-owned and read-only;
4. copies it into root-owned staging without following symlinks;
5. verifies the complete public receipt;
6. reparses every source archive;
7. verifies the aggregate catalog and every chunk digest;
8. verifies the approved-store receipt;
9. byte-compares **source, releases, and semantic cargo** against the approved store; and
10. atomically switches the live `current` symlink only after all checks pass.

A failed refresh therefore leaves the previous known-good generation online.

## Host installation

From a trusted checkout containing this implementation:

```sh
sudo bash scripts/caravan-public-origin-install \
  --domain <public-caravan-hostname> \
  --email <tls-contact-address> \
  --preservation-root /srv/centl-mirror
```

The installer normally resolves `main`, `oasis`, and `mirage` from the preserved bundle, displays their exact hashes, and asks for explicit publication authorization.

For controlled non-interactive provisioning, the commits may be supplied explicitly:

```sh
sudo bash scripts/caravan-public-origin-install \
  --domain <public-caravan-hostname> \
  --email <tls-contact-address> \
  --preservation-root /srv/centl-mirror \
  --main <commit> \
  --oasis <commit> \
  --mirage <commit> \
  --yes
```

There is no mode in which a missing preservation mirror causes the origin to fall back to GitHub.

`--prepare-only` performs local hardening, authorization, ingest, candidate compilation, and activation without requesting public TLS. It prints `PREPARED`, not `SUCESS`.

## Public reachability and TLS

A public DNS name must resolve to a route that reaches the host on TCP 80 and 443. The installer cannot safely guess or mutate a router, DNS provider, ISP account, or CGNAT arrangement.

The script first exposes only the ACME HTTP challenge boundary, then uses Certbot HTTP-01 validation. If public validation fails, verified local cargo remains stored but the script does **not** print `SUCESS`.

After TLS is active, `scripts/caravan-public-origin-audit` performs certificate-valid HTTPS probes against loopback using the real hostname and audits nginx, systemd services/timers, content status, hostile methods/paths, and the dedicated nftables boundary.

## Success contract

The final banner is the last gate, not decoration.

Only after preservation verification, explicit source authorization, source/release/model publication, root activation, firewall installation, TLS validation, nginx validation, timer setup, and hostile-surface audit pass does the script print:

```text
SUCESS
Welcome to the Free Computation Foundation caravan!
```

A partial setup cannot reach that banner.

## Timers

The installed pilot defaults remain conservative:

- preservation/publication ingest: every **6 hours**, with randomized delay;
- networkless candidate compilation: every **1 hour**, with randomized delay;
- root activation sweep: every **10 minutes**.

The most important timer behavior is fail-closed: if the preservation receipt changes while its source authorization remains old, ingest fails and the existing live generation stays online.

## Volunteer join releases

The ordinary user's `join-caravan` command has a separate security contract in `docs/CARAVAN-JOIN-RELEASE.md`.

The mutable repository contains only a release template. It deliberately refuses to act as an official installer. A usable join script is created only by an explicit versioned FCF signing action, and released versions are never overwritten in place.

The volunteer role remains rootless, opens no inbound port, and does not become a public proxy or arbitrary host.

## Validation

Repository-level validation is:

```sh
sh scripts/caravan-public-origin-check
```

CI proves the candidate compiler has no mutable-source network authority, then runs the public-origin and immutable join-release adversarial suites.

The governing security posture is deliberately simple:

> **Preservation is necessary but not sufficient. Explicit FCF publication authorization is necessary too. If either is missing or stale, the bytes do not cross the CARAVAN boundary.**
