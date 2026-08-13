# CARAVAN Telepathy private pilot

Status: **implemented private-pilot path for the X200 first origin; not general public enrollment**.

The X200 is Camel #1 and remains the FCF-owned lead origin. It publishes the activated, root-owned CARAVAN generation through the existing loopback-only `fcf-telepathyd` service and a Tor v3 onion service. Supporter machines are volunteer camels: they seed selected `public-approved` artifacts from Camel #1, keep them in a user-owned content-addressed store, and may publish their selected immutable subset through their own loopback-only Telepathy/Tor service.

This private-pilot path needs no router administration, port forwarding, public DNS, public TCP 80/443, upload endpoint, proxy, or exposed home directory.

Public volunteer enrollment is governed separately by issue #167 and must remain closed until its production transport, authentication, resource, withdrawal, portability, and security gates pass.

## X200 operator: create an invite

From the active checkout on Camel #1:

```sh
scripts/fcf-leadcaravan invite > /tmp/fcf-caravan-invite.json
```

The invite contains only:

- the public X200 Tor origin hostname;
- the exact SHA-256 of the activated CARAVAN catalog; and
- the exact SHA-256 and version of the accepted host policy.

Transmit the invite through a channel the supporter already trusts. It is a private-pilot bootstrap pin, not a replacement for the eventual signed FCF release/TUF trust root. The invite contains no carrier private key, username, local path, or hardware secret.

## Supporter prerequisites

The current private-pilot implementation expects:

- Linux;
- Python 3;
- `curl`;
- Tor with a SOCKS listener, by default `127.0.0.1:9050`;
- OpenSSL; and
- a working systemd user manager if the camel will be started immediately.

The future production volunteer path is intentionally capability-first and is not permitted to require systemd merely because this private pilot currently uses a user service.

## Supporter: join as a volunteer camel

Use an authenticated private-pilot payload or a deliberately reviewed checkout. Do not present mutable branch bytes as an official public installer.

Run:

```sh
scripts/joincaravan join \
  --invite /path/to/fcf-caravan-invite.json \
  --missions source,releases \
  --storage-gib 10 \
  --upload-mibps 4 \
  --accept-policy FCF-CARAVAN-HOST-v1 \
  --yes
```

The command:

1. validates the invite shape and the exact local policy digest;
2. reads the X200 status over Tor and requires the FCF-owned read-only publication boundary;
3. fetches the pinned catalog and rejects a digest mismatch;
4. selects only requested `public-approved` catalog objects;
5. verifies object length and SHA-256 before promotion into immutable content-addressed storage;
6. creates an owner-only local carrier identity and exact policy receipt;
7. creates a read-only local CARAVAN generation;
8. writes a bounded, loopback-only Telepathy user service; and
9. starts the supporter service unless `--no-start` was requested.

The volunteer service can serve only its selected immutable generation. It cannot accept POST/PUT uploads, proxy requests, arbitrary paths, or publish a volunteer home directory.

### Prepare without starting service

Use `--no-start` when the machine should be seeded and configured but remain offline:

```sh
scripts/joincaravan join \
  --invite /path/to/fcf-caravan-invite.json \
  --missions source \
  --accept-policy FCF-CARAVAN-HOST-v1 \
  --yes \
  --no-start
```

### Inspect or withdraw locally

```sh
scripts/joincaravan status
scripts/joincaravan leave
```

`leave` stops and disables the private-pilot user service but retains verified cargo, the local carrier identity, and the Tor identity. Deleting retained state is a separate operator action.

## Public Camel monitor

The public Pages monitor probes the published X200 lead onion through Tor and publishes aggregate status only.

Its three public health states are:

- **Active**: the latest probe passed.
- **Hungry**: the monitor could not obtain a sufficiently fresh probe result, so current health cannot be proven.
- **Lost**: a fresh probe ran and the X200 lead origin was unreachable.

The monitor does not publish a volunteer roster, node ID, hardware detail, hostname, username, email address, IP address, or location. Supporter-camel enrollment and authenticated heartbeats remain a separate production coordinator feature and must not be falsely counted by the X200 probe alone.

## Security boundary

The X200 onion hostname is public discovery data in this pilot. Security does not depend on hiding it. Security depends on:

- the invite pinning the exact catalog and policy bytes;
- every artifact being checked against the catalog's exact length and SHA-256;
- only authenticated catalog entries marked `public-approved` being eligible;
- user-owned private identity state remaining owner-only;
- the Telepathy gateway binding only to IPv4 loopback;
- the local generation being immutable and symlink-free;
- Tor carrying reachability without home-router port forwarding; and
- the served surface remaining read-only, catalog-bound, and non-proxying.

The private pilot does not claim a production coordinator, production TUF enrollment path, public volunteer roster, downloader privacy relay, or general availability. Those remain separately gated. Public census data must remain aggregate-only.
