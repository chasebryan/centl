# CARAVAN Telepathy private pilot

Status: **implemented private-pilot path for the X200 first origin; not general public enrollment**.

The X200 is Camel #1 and remains the FCF-owned origin. It publishes the activated,
root-owned CARAVAN generation through the existing loopback-only `fcf-telepathyd`
service and a Tor v3 onion service. Supporter machines are lesser volunteer camels:
they seed selected `public-approved` artifacts from Camel #1, keep them in a
user-owned content-addressed store, and may publish their selected subset through
their own loopback-only Telepathy/Tor service.

This path needs no router administration, port forwarding, public DNS, public TCP
80/443, upload endpoint, proxy, or exposed home directory.

## X200 operator: create an invite

From the active Mirage checkout on Camel #1:

```sh
scripts/fcf-leadcaravan invite > /tmp/fcf-caravan-invite.json
```

The invite contains only:

- the public X200 Tor origin hostname;
- the exact SHA-256 of the activated CARAVAN catalog; and
- the exact SHA-256 and version of the accepted host policy.

Transmit the invite through a channel the supporter already trusts. It is a
bootstrap pin, not a replacement for the eventual signed FCF release/TUF trust
root. The invite contains no carrier private key, username, local path, or
hardware secret.

## Supporter: join as a lesser camel

Obtain the authenticated `joincaravan` release or run the checked-out command
from this repository. After installing Tor and ensuring a local Tor SOCKS client
is available on `127.0.0.1:9050`, run:

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

1. verifies the invite shape and local policy digest;
2. reads the X200 status over Tor and requires the FCF-owned read-only boundary;
3. fetches the pinned catalog and rejects a digest mismatch;
4. downloads only selected `public-approved` catalog objects;
5. hashes each download and promotes it into immutable content-addressed storage;
6. writes an owner-only Ed25519 identity and exact policy receipt;
7. creates a read-only local CARAVAN generation; and
8. starts a user-level `fcf-caravan.service` with a loopback listener and a
   dedicated Tor v3 onion service.

The volunteer service can serve only its selected immutable generation. It cannot
accept POST/PUT uploads, proxy requests, traverse paths, read the home directory,
or alter the X200 origin.

Use `--no-start` to prepare without publishing a supporter onion yet:

```sh
scripts/joincaravan join --invite invite.json \
  --missions source --accept-policy FCF-CARAVAN-HOST-v1 --yes --no-start
```

Inspect or withdraw locally:

```sh
scripts/joincaravan status
scripts/joincaravan leave
```

`leave` stops the user service but retains verified cargo, the local identity, and
the Tor identity so a later restart can preserve the supporter onion. Deletion is
a separate operator decision.


separate authenticated coordinator feature and are not falsely counted here.
hardware detail, hostname, or IP address. Supporter-camel heartbeats remain a

ot commit probe results to the repository. It publishes no roster, node ID,
The monitor has read-only repository access and deploys a Pages artifact; it does

  prove whether the camel is active or lost.
- **Hungry** — the published probe document itself is stale, so the site cannot
- **Lost** — a fresh probe ran and X200 was unreachable.
- **Active** — the latest probe passed.

	hrough Tor and publishes aggregate status only. Its three states are:
The public Pages monitor probes the published X200 lead onion every five minutes

## Public Camel monitor
## Security boundary

The X200 onion hostname is public discovery data in this pilot. Security does not
depend on hiding it. Security depends on:

- the invite pinning the exact catalog and policy bytes;
- every artifact being checked against the catalog's exact length and SHA-256;
- user-owned private identity state remaining owner-only;
- the Telepathy gateway binding only to IPv4 loopback;
- the local generation being immutable and symlink-free;
- Tor mapping one virtual port to that loopback gateway; and
- the public surface remaining read-only, catalog-bound, and non-proxying.

The private pilot does not yet claim a production coordinator, automatic public
census heartbeat, public volunteer roster, downloader privacy relay, or general
availability. Those remain separate Phase 2/3 deployment work. Public census data
must remain aggregate-only.
