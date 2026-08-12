# FCF Telepathy

Status: **Mirage experimental architecture and implementation**

Software: **`fcf-telepathyd`**

`fcf-telepathyd` is the carrier-independent transport boundary for CARAVAN. Its job is deliberately narrow: carry authorized FCF information over replaceable roads without allowing any road to become FCF's identity, authorization authority, update authority, or source of truth.

> CARAVAN carries matter. Telepathy carries information. FCF supplies trust.

## One software name

The daemon and operator command are both `fcf-telepathyd`. There is no separate Telepathy control executable.

The command surface is:

```text
fcf-telepathyd serve
fcf-telepathyd carrier probe
fcf-telepathyd carrier publish
fcf-telepathyd carrier status
fcf-telepathyd carrier withdraw
```

Carrier lifecycle controls remain subcommands of the same program so FCF does not grow a second public identity for the same boundary.

## Non-negotiable trust boundary

A carrier may move FCF traffic from one endpoint to another. Carrier state must never be sufficient to:

- authorize CARAVAN publication;
- change an FCF node identity;
- select or mutate preserved cargo;
- update CENTL or CARAVAN;
- modify the root-owned live generation;
- replace FCF signing keys or capability policy;
- choose an arbitrary local or remote destination; or
- turn `fcf-telepathyd` into a general-purpose proxy.

Loss of every carrier may remove reachability. It must not destroy preservation, approved state, CARAVAN artifacts, FCF identities, or signing keys.

## Identity layering

Carrier identity is disposable. FCF identity is not.

```text
FCF node identity:     fcf-caravan-001
FCF public identity:   FCF-managed key/fingerprint
FCF capability:        caravan-public-read
carrier:               tor-onion
carrier identity:      <v3-onion-address>.onion
```

Changing `carrier=tor-onion` to `carrier=direct`, `carrier=fcf-relay`, or another implementation must not change the FCF node identity.

An onion-service key authenticates the onion service. It does not replace FCF artifact signatures, FCF node identity, CARAVAN authorization, or preservation receipts.

## Realms

```text
                         FCF TELEPATHY
                  +-----------------------+
                  |       FCF CORE        |
                  | identity / signing    |
                  | capability policy     |
                  | CARAVAN verification  |
                  | hostile audit         |
                  +-----------+-----------+
                              |
              +---------------+---------------+
              |               |               |
              v               v               v
        BORROWED REALM   FEDERATED REALM  SOVEREIGN REALM
        hosted carrier       Tor          FCF-operated
        infrastructure      network       relays/ingress
```

A realm describes who operates the road. It does not change the FCF trust root.

## First carrier: Tor v3 onion service

The first first-class carrier is `tor-onion`.

The production-path topology is now:

```text
FCF preservation / authorization
            |
            v
CARAVAN networkless activation
            |
            v
/srv/fcf-caravan-live/current
root-owned immutable approved generation
            |
            | read-only
            v
fcf-telepathyd policy gateway
127.0.0.1:8790
            |
            v
Tor v3 onion service
            |
            v
Tor network
```

The earlier `127.0.0.1:8787` assumption is retained only as an optional laboratory HTTP backend. The actual CARAVAN public-origin implementation activates a root-owned immutable generation at `/srv/fcf-caravan-live/current`; production `fcf-telepathyd` can consume that approved generation directly instead of requiring another local web server.

This keeps nginx, public TCP 80/443, router configuration, DNS, and public TLS outside the Tor publication path. They can continue to serve a direct/public CARAVAN role independently when available.

`fcf-telepathyd` itself remains loopback-only. Tor maps one onion-service virtual port to that loopback listener.

Tor's documented onion-service model uses `HiddenServiceDir` for service state and keys and `HiddenServicePort` to map the onion virtual port to a local service. Tor creates the v3 onion hostname in the hidden-service directory. The service keys must remain private.

Upstream references:

- https://community.torproject.org/onion-services/setup/
- https://spec.torproject.org/rend-spec-v3
- https://spec.torproject.org/address-spec

## CARAVAN live-generation backend

The preferred deployment backend is explicit:

```text
--caravan-live-root /srv/fcf-caravan-live/current
```

It is read-only and deliberately depends on CARAVAN's existing activation invariants rather than recreating publication authority inside Telepathy.

The backend:

- allows CARAVAN's atomic top-level `current` symlink to select the active generation;
- resolves that pointer to one generation for each request;
- requires the resolved generation and every traversed object to have the configured trusted owner (UID 0 in the command-line deployment path);
- rejects any write bit on the resolved generation, intermediate directories, or served file;
- rejects symbolic links anywhere inside the generation;
- requires intermediate components to be directories and the final object to be a regular file;
- verifies the opened file still has the device/inode identity that was inspected before streaming;
- reads only paths already admitted by the Telepathy public-read policy; and
- never receives a filesystem path from the requester outside that fixed policy surface.

CARAVAN activation already freezes live generations as root-owned `0555` directories and `0444` files before switching the `current` pointer. `fcf-telepathyd` independently checks the properties it depends on before serving an object.

The daemon should run unprivileged. It needs read access to the public CARAVAN live generation and write access only to its own private carrier state directory.

The private preservation mirror is never a Telepathy root.

## Gateway capability surface

`fcf-telepathyd` starts deny-by-default and mirrors only the intentionally public CARAVAN origin surface.

Exact paths:

```text
/
/index.html
/robots.txt
/status.json
/SHA256SUMS
/source/INDEX.json
/source/centl-main.tar.gz
/source/centl-oasis.tar.gz
/source/centl-mirage.tar.gz
/caravan/catalog-v1.json
/caravan/CATALOG-STATUS
/caravan/INGEST-STATUS.json
```

Approved publication trees:

```text
/releases/<approved-path>
/semantic/<approved-path>
```

Only `GET` and `HEAD` are permitted.

The implementation rejects:

- POST, PUT, DELETE, PATCH, TRACE, CONNECT, and other unsupported methods;
- request bodies and transfer-encoded requests;
- ambiguous duplicate content lengths or range headers;
- absolute-form proxy targets;
- query- or fragment-driven routing;
- percent-encoded routing;
- traversal, backslashes, control characters, and non-canonical paths;
- non-IPv4-loopback listener or laboratory upstream addresses;
- arbitrary Host or forwarding headers from the requester;
- multiple/non-canonical byte ranges; and
- laboratory-upstream redirects that could turn the fixed origin into an external navigation primitive.

Incoming requests cannot choose the CARAVAN live root, an upstream address, or another local service.

The direct live-root backend implements bounded single byte ranges and `HEAD` without introducing a general filesystem server.

## Laboratory HTTP backend

For isolated tests and development, `fcf-telepathyd` can still forward to a fixed IPv4 loopback HTTP origin:

```sh
python3 scripts/fcf-telepathyd serve \
  --upstream-host 127.0.0.1 \
  --upstream-port 8787
```

This is not the preferred X200 production path. It exists so the transport boundary can be tested against synthetic origins and future explicitly managed loopback services.

## Tor carrier isolation

The Tor adapter is intentionally not a general Tor client.

Its generated configuration:

- disables the SOCKS listener with `SocksPort 0`;
- uses a dedicated `DataDirectory` beneath the `fcf-telepathyd` state directory;
- creates a dedicated v3 `HiddenServiceDir`;
- maps exactly one onion virtual port to the loopback `fcf-telepathyd` listener; and
- stores the onion-service state outside CARAVAN preservation and publication trees.

Publishing fails closed if the loopback `fcf-telepathyd` listener is not reachable.

A persisted Tor PID is not trusted by itself. Linux can recycle PIDs, so `fcf-telepathyd` verifies the live process command line against both the configured Tor executable and the exact managed torrc before signaling a process recovered from state. If that identity cannot be proven, withdrawal refuses to signal it.

Stopping Tor does not delete the onion-service keys. Reusing the same protected state directory therefore preserves the carrier address across ordinary restarts. Those carrier keys still do not become FCF identity keys.

## X200 operator path

First prove Tor is installed and visible:

```sh
python3 scripts/fcf-telepathyd carrier probe
```

Then prove that CARAVAN has an activated live generation:

```sh
test -L /srv/fcf-caravan-live/current
test -r /srv/fcf-caravan-live/current/status.json
```

Start the complete Tor publication path with one command:

```sh
python3 scripts/fcf-telepathyd serve \
  --caravan-live-root /srv/fcf-caravan-live/current \
  --carrier tor-onion \
  --publish
```

The daemon prints the generated v3 `.onion` endpoint after Tor publishes it.

The combined `serve --publish` path is preferred because the daemon that started Tor owns its child-process handle and withdraws it during normal shutdown.

Standalone carrier lifecycle controls remain available for controlled operator workflows:

```sh
python3 scripts/fcf-telepathyd carrier publish
python3 scripts/fcf-telepathyd carrier status
python3 scripts/fcf-telepathyd carrier withdraw
```

Standalone publication refuses to proceed unless the configured loopback Telepathy gateway is already reachable.

## Today milestone: TELEPATHY I-TOR

The Mirage milestone is demonstrably complete when all of these are true:

1. `fcf-telepathyd` is the only Telepathy software/command name.
2. The network listener starts only on IPv4 loopback.
3. Production mode reads only an activated root-owned immutable CARAVAN live generation.
4. The CARAVAN `current` pointer may change atomically without making internal generation symlinks acceptable.
5. GET/HEAD for approved paths can read approved live objects.
6. Unsupported verbs cannot reach a backend.
7. Absolute proxy targets, encoded routing, traversal, queries, request bodies, ambiguous framing, and unsafe ranges are rejected.
8. Client-supplied forwarding/authorization headers cannot escape the laboratory gateway filter.
9. Writable, wrong-owner, symlink, non-regular, or missing live-generation objects fail closed.
10. Tor configuration uses a private dedicated state directory and v3 onion service.
11. Tor publication refuses a dead `fcf-telepathyd` gateway.
12. A fake/offline Tor process can prove publish, status, persistence, and withdrawal behavior in tests without Internet access.
13. A stale or unrelated PID cannot be killed through the carrier state file.
14. CI executes the `fcf-telepathyd` tests through the existing Mirage test gate.
15. Public deployment remains an explicit FCF operator action. CI never publishes a real onion service.

This milestone is intentionally smaller than a sovereign network. It produces a useful federated road while preserving the escape hatch.

## Roadmap

### TELEPATHY 0

Direct CARAVAN networking. Pure path, dependent on local router/public-ingress availability.

### TELEPATHY I

FCF identity, capability policy, carrier firewall, and constrained CARAVAN publication bridge.

### TELEPATHY I-TOR

Tor v3 onion carrier. No corporate coordination service is required for the carrier identity. FCF trust remains above Tor.

### TELEPATHY II

Carrier abstraction hardened across `direct`, `tor-onion`, optional hosted carriers, and FCF relays. Carrier-independent node identity becomes an explicit compatibility contract.

### TELEPATHY III

FCF-operated relay, discovery, and public-ingress infrastructure. Multi-carrier routing and policy-driven failover.

### TELEPATHY SOVEREIGN

FCF can operate the entire runtime path without a third-party carrier. Tor remains available as an independent federated/privacy path rather than being removed.

Preferred long-term ordering:

```text
preferred:  direct
alternate:  fcf-sovereign
privacy:    tor-onion
emergency:  explicitly approved borrowed carrier
```

## Separation from CARAVAN transport

CARAVAN's volunteer carrier protocol remains outbound-oriented. `fcf-telepathyd` is a constrained publication boundary for an explicitly configured FCF CARAVAN live generation; it does not silently turn volunteer CARAVAN carriers into public servers.

```text
CARAVAN:        preservation, artifact identity, verification, replication
fcf-telepathyd: constrained network carriage
FCF:            trust, identity, policy, authorization
```

A future CARAVAN role may request an `fcf-telepathyd` capability, but that capability must remain explicit and least-privilege.
