# CENTL CARAVAN public origin

Status: **FCF-owned public-origin pilot tooling implemented; public volunteer enrollment remains a later phase.**

The first CARAVAN public origin is intended for an FCF-controlled GNU/Linux host, beginning with the Trisquel ThinkPad X200 pilot machine.

This role is intentionally different from a future volunteer home carrier. An FCF-owned public origin may listen on public TCP 80/443 because it is Foundation-controlled infrastructure. A normal volunteer carrier remains outbound-only by default.

The public-origin rule is:

> The Internet sees only a root-owned publication-compiled CENTL tree. The private preservation mirror is never a web root.

## Purpose

The origin gives users a direct FCF source for current CENTL source snapshots and, when separately approved, preserved releases and semantic-model artifacts. It reduces runtime/download dependence on GitHub, model hubs, hosted inference providers, and other intermediaries without turning CARAVAN into a general file-hosting service.

The origin is **not**:

- an upload host;
- a generic mirror;
- a paste/file-drop service;
- a reverse proxy;
- a CONNECT tunnel;
- a VPN or relay for arbitrary traffic;
- a CGI/application host;
- WebDAV storage;
- an anonymous-content network;
- a public view of the FCF preservation filesystem.

## Trust pipeline

```text
FCF preservation mirror
        |
        | strict receipt verification
        v
networkless root ingest
        |
        | releases: publication-export
        | model: model-origin-export --check
        v
/var/lib/fcf-caravan/approved       public CENTL Git heads
        |                           main / oasis / mirage
        | read-only                        |
        |                                  | exact HTTPS refspecs only
        |                                  | no tags / PR refs / history bundle
        +-------------------+--------------+
                            v
                  unprivileged candidate compiler
                        user: fcf-caravan
                            |
                            | candidate receipt + CARAVAN catalog
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
                            | exact approved-tree comparison
                            | catalog/chunk/receipt verification
                            v
                  /srv/fcf-caravan-live/current
                            |
                            | root-owned read-only static tree
                            v
                          nginx
                            |
                         Internet
```

The networked `fcf-caravan` process has no live-web-root write path and is not given the preservation-mirror path in its environment. Preservation ingest uses a separate root-only environment file and runs with `PrivateNetwork=yes` plus `IPAddressDeny=any`.

The activation service is also networkless. It alone may write `/srv/fcf-caravan-live`, and its candidate/approved inputs are read through explicitly bounded systemd paths.

## Public source contract

The source publisher is hard-bound in code to:

```text
https://github.com/chasebryan/centl.git
```

It fetches exactly:

```text
refs/heads/main
refs/heads/oasis
refs/heads/mirage
```

It does not fetch pull-request refs, miscellaneous branches, or tags. It does not publish a Git history bundle.

Public source artifacts are current branch snapshots:

```text
/source/centl-main.tar.gz
/source/centl-oasis.tar.gz
/source/centl-mirage.tar.gz
/source/INDEX.json
```

That is deliberate data minimization. A public origin needs current CENTL source, not every deleted historical object that ever existed in a repository.

Before the networked compiler can produce a candidate, it recursively inspects the selected Git trees and rejects:

- symbolic-link entries;
- Gitlinks/submodules and other non-regular entries;
- unsafe/control-character paths;
- common secret-bearing filenames;
- private-key material;
- high-specificity credential/token patterns;
- oversized source blobs;
- source trees above the file-count ceiling.

The networkless root path performs another independent archive-level scan before activation. The primary activator then re-parses the archives again while verifying the complete generation.

## Preserved release contract

The preservation mirror is never recursively copied into the public tree.

`scripts/caravan-public-origin-ingest` first requires the normal FCF whole-mirror verification. It then calls the existing `scripts/publication-export`, which exports only material already admitted by the CENTL release-publication contract.

The resulting root-owned approved tree is exact-manifested. Extra unlisted files make the candidate fail rather than becoming accidental cargo.

## Semantic model contract

Semantic model publication remains fail-closed.

The ingest service calls:

```text
model-origin-export.py <mirror> --check
```

before model bytes can enter the approved public tree. The exporter requires exact content identity, verified quantized provenance, recorded base-model identity/license, and an operator-reviewed redistribution status.

If the active model does not satisfy that contract, the model is simply absent from the public origin. Source/release publication does not weaken the model gate.

The semantic origin's own metadata, including its embedded CARAVAN catalog, is itself represented in the aggregate public CARAVAN catalog.

## CARAVAN catalog

Each generation contains:

```text
/caravan/catalog-v1.json
/caravan/CATALOG-STATUS
```

and, when preservation ingest has run:

```text
/caravan/INGEST-STATUS.json
```

The aggregate catalog uses `centl-caravan-catalog-v1`, whole-file SHA-256 identities, exact byte lengths, `public-approved` distribution class, and ordered 4 MiB SHA-256 chunk records.

The raw catalog is not a trust anchor. `CATALOG-STATUS` explicitly says independent TUF authentication is still required. A carrier/origin can provide bytes; it does not gain authority merely by serving a catalog file.

## Abuse resistance

Normal Internet requests have no route that can create content.

The installed nginx site:

- permits only `GET` and `HEAD`;
- has no `proxy_pass`;
- has no FastCGI/uWSGI/SCGI path;
- has no WebDAV methods;
- has no upload endpoint;
- has no arbitrary filesystem `alias`;
- has directory auto-indexing disabled;
- explicitly serves only the fixed source files, public metadata, and already-approved release/semantic subtrees;
- defaults every other path to `404`;
- rejects unknown virtual hosts;
- bounds request bodies, concurrent connections, request rate, byte rate, and HTTP ranges.

The host firewall is rebuilt to a known state with default-deny inbound policy. Public TCP 80/443 are admitted. If `sshd` is installed or the installer itself is running over SSH, its detected administration port is preserved with a rate-limited firewall rule.

The installer does not add a third-party tunnel just to make the machine reachable. If direct public reachability is unavailable because of DNS, NAT, CGNAT, or ISP policy, public qualification fails instead of silently changing the trust model.

## Data minimization

The nginx public origin has access logging disabled. The CARAVAN site therefore does not intentionally retain a normal per-download web access log. Nginx warning/error logging remains available for operation and fault diagnosis.

The public status document exposes the pseudonymous node identity and publication state, not usernames, private filesystem paths, private preservation contents, or a volunteer-home-network roster.

## Candidate and activation safety

A refresh never edits live cargo in place.

The candidate compiler writes a new immutable candidate under:

```text
/var/lib/fcf-caravan/candidates/
```

Candidate and activation services share a root-created lock at:

```text
/run/lock/fcf-caravan-publication.lock
```

so candidate construction cannot race the root activation gate.

The root activation wrapper runs an independent source guard, then the primary activator. The primary activator atomically moves the selected candidate out of the unprivileged candidate directory into a root-only activation inbox, recursively rejects links/special files, changes the claimed tree to root-owned read-only state, copies it into root-owned staging, and verifies the staging copy before the live pointer is changed.

Release and semantic subtrees must byte-for-byte match the separately approved root-owned ingest tree. The aggregate catalog must exactly enumerate public cargo and match every artifact length, whole-file SHA-256, and 4 MiB chunk digest.

Only after those checks pass is the root-owned `current` symlink atomically switched.

A failed refresh therefore leaves the previous known-good generation online.

## Host installation

The canonical interactive setup from a trusted checkout is:

```sh
sudo bash scripts/caravan-public-origin-install
```

For non-interactive provisioning:

```sh
sudo bash scripts/caravan-public-origin-install \
  --domain <public-caravan-hostname> \
  --email <tls-contact-address> \
  --preservation-root /srv/centl-mirror \
  --yes
```

If there is not yet an FCF preservation mirror on the machine, omit `--preservation-root`. The origin can still publish the three approved current source snapshots. Releases and model material remain absent until the preservation/publication gates provide them.

The installer refuses a preservation mirror inside a user home directory. A dedicated path such as `/srv/centl-mirror` keeps the security boundary explicit.

## Public reachability and TLS

A public DNS name must resolve to a network path that reaches the X200 on TCP 80 and 443. The script can harden the host itself, but it cannot safely guess or mutate an arbitrary router, DNS provider, ISP account, or CGNAT arrangement.

The installer initially exposes only the ACME HTTP challenge surface. It uses Certbot HTTP-01 validation to obtain the public certificate. If that public validation fails, the verified local CARAVAN generation remains stored but the full static public site is not enabled and the script does **not** print `SUCESS`.

After TLS is active, `scripts/caravan-public-origin-audit` performs local certificate-valid HTTPS probes against loopback using the real public hostname. It checks the expected source/status endpoints and deliberately probes hostile methods, traversal-like paths, `.git`, `/etc/passwd`, directory roots, unknown files, nginx dynamic directives, service-account shell state, timer state, and the default-deny firewall state.

## Success contract

The final banner is not cosmetic. It is the last gate.

Only after installation, generation activation, public TLS validation, nginx validation, service/timer setup, firewall activation, and hostile-surface audit pass does the script print:

```text
SUCESS
Welcome to the Free Computation Foundation caravan!
```

A partial setup, missing certificate, failed source scan, failed preservation receipt, unapproved semantic model, unsafe nginx surface, or failed hostile probe cannot reach that banner.

## Timers

The installed defaults are intentionally conservative for an older pilot machine:

- preservation ingest: every **6 hours**, with randomized delay;
- source candidate build: every **1 hour**, with randomized delay;
- root activation sweep: every **10 minutes**.

The source builder can fail because an upstream source is unavailable without taking the current generation offline.

## Validation

Repository-level validation is:

```sh
sh scripts/caravan-public-origin-check
```

CI additionally runs the source-publication policy against the proposed pull-request tree and the current `main`, `oasis`, and `mirage` heads.

The important security posture is deliberately simple:

> If the bytes were not produced by an explicit CENTL/FCF publication path, they do not cross the CARAVAN public-origin boundary.
