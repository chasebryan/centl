# CENTL CARAVAN public origin

Status: **FCF-owned public-origin pilot tooling implemented; public volunteer enrollment remains a later phase.**

The first CARAVAN public origin is intended for an FCF-controlled GNU/Linux host, beginning with the Trisquel ThinkPad X200 pilot machine.

This role is deliberately different from a future volunteer home carrier. An FCF-owned origin may listen publicly on TCP 80/443 because it is Foundation-controlled infrastructure. A normal volunteer carrier remains a separate, outbound-oriented role.

The public-origin rule is simple:

> The Internet sees only a root-owned publication-compiled CENTL tree. The private FCF preservation mirror is never a web root, and repository/network availability is never publication authority.

## Closed-world publication model

The public origin has **no direct GitHub publication fallback**.

GitHub may be one input used earlier when FCF creates a preservation snapshot, but the public node does not chase GitHub branches and does not decide that newly visible repository bytes are safe to publish. Source publication begins only after those bytes already exist inside a finalized FCF preservation mirror.

The trust pipeline is:

```text
FCF preservation mirror
        |
        | strict whole-mirror receipt verification
        |
        +-----------------------------+
        |                             |
        | project/centl.bundle        | preserved releases / models
        |                             |
        | root operator authorization | existing publication contracts
        | bound to exact mirror       |
        | receipt + exact commits     |
        |                             |
        v                             v
networkless source export       networkless release/model export
        |                             |
        +--------------+--------------+
                       v
          /var/lib/fcf-caravan/approved
             root-owned, read-only,
               exact SHA-256 receipt
                       |
                       | read-only
                       v
          networkless candidate compiler
              user: fcf-caravan
                       |
                       v
         /var/lib/fcf-caravan/candidates
                       |
                       | shared publication lock
                       v
             networkless root guards
                       |
                       | seize candidate into
                       | root-only activation inbox
                       | rescan source archives
                       | verify catalog/chunks/receipts
                       | compare approved bytes exactly
                       v
           /srv/fcf-caravan-live/current
              root-owned, read-only
                       |
                       v
                     nginx
                       |
                    Internet
```

No network-facing process is given a path that can turn arbitrary local files into public cargo.

## Source authorization

CENTL source is exported only from:

```text
<FCF preservation mirror>/project/centl.bundle
```

The private Git bundle itself is **not** served.

Before source can cross the publication boundary, a root-owned authorization record must name exactly one preserved commit for each public branch role:

```text
main
oasis
mirage
```

The authorization is also bound to the SHA-256 identity of the finalized mirror receipt.

This creates a useful fail-closed property:

1. FCF finalizes a preservation snapshot.
2. The operator explicitly authorizes exact preserved `main`, `oasis`, and `mirage` commits.
3. Source export is generated from those exact commits only.
4. If the preservation mirror changes, its receipt identity changes.
5. The old source authorization becomes stale.
6. Automated publication freezes until the changed snapshot is deliberately reviewed and re-authorized.

A new file appearing in preservation therefore does **not** automatically become public.

## Public source artifacts

The public node exposes only snapshot archives and their authorization index:

```text
/source/centl-main.tar.gz
/source/centl-oasis.tar.gz
/source/centl-mirage.tar.gz
/source/INDEX.json
```

`INDEX.json` binds each archive to:

- the exact preserved commit;
- its SHA-256 digest;
- the exact FCF preservation receipt identity; and
- the root-owned source-authorization identity.

No pull-request refs, miscellaneous branches, arbitrary refs, or complete Git history bundle are served.

That is deliberate data minimization. CARAVAN provides intentionally approved source states, not every historical object that happened to exist in a repository.

## Source safety scans

Before an authorized source commit can become public, the source exporter rejects:

- symbolic links;
- Gitlinks/submodules and other non-regular entries;
- absolute, traversal, malformed, or control-character paths;
- common secret-bearing filenames such as `.env`, private-key filenames, credential files, and password databases;
- private-key material;
- high-specificity credential/token patterns;
- oversized source objects; and
- source trees above the configured file-count ceiling.

The networkless root activation path independently reopens and rescans the resulting source archives before changing the live generation.

The public status metadata, source index, source archive hashes, source authorization identity, and preservation receipt identity must all agree. Metadata disagreement is an activation failure.

## Preserved release contract

The preservation mirror is never recursively copied into the public tree.

`scripts/caravan-public-origin-ingest` first requires the normal whole-mirror FCF receipt verification. It then uses the existing `scripts/publication-export` contract for preserved releases.

That exporter deliberately excludes preservation-only classes such as raw dependency mirrors, Git mirrors, build capsules, recovery material, opam/Julia state, and other internal recovery objects.

Only release material that independently satisfies its public release contract can enter `/approved/releases`.

## Semantic model contract

Semantic publication remains fail-closed and separate from source authorization.

The ingest service runs the existing semantic-origin check before model bytes can enter public cargo:

```text
model-origin-export.py <mirror> --check
```

The semantic exporter requires exact content identity, bound provenance, verified quantized-source identity, base-model licensing metadata, and explicit operator-reviewed redistribution approval.

If the preserved active model does not satisfy that contract, the model is simply absent from the public origin. Source and release availability do not weaken the model gate.

## Exact approved store

The networkless ingest stage produces:

```text
/var/lib/fcf-caravan/approved/
  source/
  releases/        # when public release exports exist
  semantic/        # only when semantic redistribution gates pass
  INGEST-STATUS.json
  APPROVED-SHA256SUMS
  APPROVED-SHA256SUMS.sha256
```

The manifest proves exact regular-file membership. An unexpected extra object is a failure, not additional cargo.

The approved tree is root-owned and made read-only before promotion.

## Candidate compiler

The candidate compiler runs as the unprivileged `fcf-caravan` service account.

It has:

- `PrivateNetwork=yes`;
- `IPAddressDeny=any`;
- only `AF_UNIX` address-family access;
- read-only access to the approved store;
- no preservation-mirror path in its environment; and
- no permission to write the live web root.

It can only compile a candidate from the already approved tree.

This is intentionally boring. The candidate builder has no upstream source authority at all.

## Root activation

The root activation service is also networkless.

It:

1. serializes publication with the shared publication lock;
2. independently scans source archives;
3. atomically moves the selected candidate into a root-only activation inbox;
4. rejects links and special files;
5. freezes the claimed candidate as root-owned read-only data;
6. copies it into a root-owned staging generation without following symlinks;
7. verifies the public-tree SHA-256 receipt;
8. revalidates the source index and source archives;
9. requires public status metadata to match the same source index and preservation authorization;
10. verifies the aggregate CARAVAN catalog and every chunk record;
11. compares source, release, and semantic trees byte-for-byte against the root-owned approved store; and
12. only then atomically switches the live `current` pointer.

A failed refresh leaves the previous known-good generation online.

## CARAVAN catalog

Each live generation contains:

```text
/caravan/catalog-v1.json
/caravan/CATALOG-STATUS
/caravan/INGEST-STATUS.json
```

The aggregate catalog uses:

- schema `centl-caravan-catalog-v1`;
- whole-file SHA-256 identities;
- exact byte lengths;
- distribution class `public-approved`; and
- ordered 4 MiB SHA-256 chunk records.

The raw catalog is still not a trust anchor. `CATALOG-STATUS` records that independent TUF authentication is required for clients that consume CARAVAN metadata as authority.

An origin can provide bytes. It does not gain the right to redefine trusted bytes merely because it is reachable.

## Abuse resistance

The public origin is intentionally unsuitable for third-party content hosting.

There is no supported operation that lets an Internet user create or select arbitrary served content:

- no uploads;
- no WebDAV;
- no CGI, FastCGI, uWSGI, or SCGI application path;
- no reverse proxy;
- no `CONNECT` tunnel;
- no generic relay;
- no arbitrary filesystem alias;
- no Git smart-HTTP service;
- no arbitrary Git ref lookup;
- no directory listing; and
- no network-visible preservation filesystem.

The final nginx site permits only `GET` and `HEAD`. It exposes exact metadata/source endpoints plus only the already approved release/semantic trees. Every unrelated path defaults to denial.

Hostile qualification probes deliberately test mutation methods, `CONNECT`, `TRACE`, `OPTIONS`, traversal encodings, `.git`, `/etc/passwd`, `/proc/self/environ`, internal CARAVAN paths, directory roots, and unknown objects.

No software can make exploitation mathematically impossible. The goal here is stronger and more practical: remove the useful generic-hosting primitives from the design, minimize the network surface, fail closed on publication ambiguity, and keep the operating system patched.

## Dedicated-host firewall

The X200 pilot is treated as a dedicated public-origin host.

The installer backs up the previous firewall state and installs an nftables ruleset transactionally. The FCF ruleset:

- defaults inbound traffic to drop;
- drops forwarding;
- permits loopback and established/related traffic;
- permits required ICMP/IPv6 ICMP;
- permits public TCP 80/443;
- preserves detected SSH administration ports with a rate limit; and
- leaves outbound host traffic available for normal administration, package updates, DNS/NTP, and certificate operations.

The publication compiler and activation services remain networkless even though the host itself can perform ordinary outbound administration.

The installer does not install a third-party tunnel to bypass NAT, CGNAT, DNS, or ISP policy. Public reachability must be deliberately provisioned outside the CARAVAN trust boundary.

## Nginx boundary

The installed web surface is static and deny-by-default:

- `GET`/`HEAD` only;
- unknown virtual hosts rejected;
- directory auto-indexing disabled;
- request bodies bounded;
- connection/request/byte rates bounded;
- only one HTTP range accepted;
- access logging disabled by default;
- warning/error logging retained for operations; and
- security headers enabled.

The live document root is a root-owned read-only generation. The private preservation mirror is never mounted as the nginx root.

## Installation

The installer requires a finalized FCF preservation mirror. There is no source-only bypass.

Interactive setup from a trusted CENTL checkout:

```sh
sudo bash scripts/caravan-public-origin-install
```

If `/srv/centl-mirror` exists and is finalized, it is selected automatically. Otherwise specify it explicitly:

```sh
sudo bash scripts/caravan-public-origin-install \
  --domain <public-caravan-hostname> \
  --email <tls-contact-address> \
  --preservation-root /srv/centl-mirror \
  --yes
```

The installer normally resolves the preserved `main`, `oasis`, and `mirage` heads from the bundle and displays their exact commit IDs before authorization. Explicit `--main`, `--oasis`, and `--mirage` values are available when branch-head resolution is ambiguous.

The preservation mirror must live outside normal user home directories. `/srv/centl-mirror` is the reference location.

## Public reachability and TLS

A public DNS name must route TCP 80/443 to the X200. The script does not guess or mutate arbitrary router, registrar, ISP, or CGNAT configuration.

During qualification nginx exposes only the ACME HTTP challenge surface. Certbot obtains the certificate through HTTP-01. If real public certificate qualification fails, the machine does not receive the success declaration.

After TLS becomes active, the final hostile audit validates the HTTPS surface locally using the real hostname and certificate.

## Success contract

The final banner is a gate, not decoration.

Only after preservation verification, exact source authorization, networkless publication, root activation, firewall installation, TLS qualification, nginx validation, timer setup, and hostile HTTP auditing all pass does the installer print:

```text
SUCESS
Welcome to the Free Computation Foundation caravan!
```

A partial setup cannot reach that banner.

## Timers

The pilot defaults are intentionally conservative for an older X200:

- preservation ingest: every **6 hours**, with randomized delay;
- candidate recompilation: every **1 hour**, with randomized delay;
- activation sweep: every **10 minutes**.

These timers do **not** chase upstream GitHub state. They re-verify and recompile only the preservation-authorized snapshot already held by FCF.

If the mirror is intentionally changed and re-finalized, the existing source authorization becomes stale and automatic ingest stops until a new exact authorization is made.

## Validation

Repository-level validation is:

```sh
sh scripts/caravan-public-origin-check
```

CI additionally proves that the candidate compiler contains no mutable GitHub source authority, that ingest fails closed without preservation, that publication services are networkless, and that the adversarial public-origin test suite passes.

The governing invariant is:

> If bytes were not produced by an explicit FCF/CENTL preservation and publication path, they do not cross the CARAVAN public-origin boundary.
