# FCF Telepathy

Status: **Mirage experimental architecture and implementation**

Software: **`fcf-telepathyd`**

`fcf-telepathyd` is the carrier-independent transport boundary for CARAVAN. Its job is deliberately narrow: carry authorized FCF information over replaceable roads without allowing any road to become FCF's identity, authorization authority, update authority, publication authority, or source of truth.

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
- modify the root-owned CARAVAN live generation;
- replace FCF signing keys or capability policy;
- choose an arbitrary local or remote destination;
- expose the private preservation mirror; or
- turn `fcf-telepathyd` into a general-purpose proxy or filesystem server.

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

The production topology is:

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

There is intentionally no intermediate `127.0.0.1:8787` HTTP origin. `fcf-telepathyd` reads the already activated CARAVAN generation directly. This removes an unnecessary reverse-proxy hop and leaves no request-controlled upstream destination anywhere in Telepathy.

Nginx, public TCP 80/443, router configuration, DNS, and public TLS remain independent CARAVAN direct/public-origin concerns. They are not prerequisites for the Tor carrier path.

`fcf-telepathyd` itself remains IPv4-loopback-only. Tor maps one onion-service virtual port to that loopback listener.

Tor's documented onion-service model uses `HiddenServiceDir` for service state and keys and `HiddenServicePort` to map the onion virtual port to a local service. Tor creates the v3 onion hostname in the hidden-service directory. The service keys must remain private.

Upstream references:

- https://community.torproject.org/onion-services/setup/
- https://spec.torproject.org/rend-spec-v3
- https://spec.torproject.org/address-spec

## CARAVAN live-generation backend

The only serving backend is the activated CARAVAN live generation. The command-line default is:

```text
/srv/fcf-caravan-live/current
```

An alternate absolute path may be supplied explicitly with:

```text
--caravan-live-root /absolute/path/to/current
```

The command-line deployment path requires the resolved generation and every served object to be owned by UID 0. The gateway is still intended to run unprivileged. It needs read access to the public live generation and write access only to its own private carrier state directory.

The backend deliberately depends on CARAVAN's existing activation invariants rather than recreating publication authority inside Telepathy.

For each request, `fcf-telepathyd`:

1. applies the closed-world public-read capability policy;
2. resolves CARAVAN's top-level atomic `current` pointer to one generation;
3. requires the resolved generation to be an immutable directory with the configured trusted owner;
4. traverses only canonical policy-approved path components;
5. rejects symbolic links anywhere inside the generation;
6. requires every intermediate component to be an immutable directory;
7. requires the final object to be an immutable regular file;
8. opens that exact object read-only;
9. verifies that device, inode, mode, owner, group, size, and modification-time identity still match the pre-open inspection; and
10. streams only that inspected object.

CARAVAN activation freezes live generations as root-owned `0555` directories and `0444` files before switching the `current` pointer. Telepathy independently checks the properties it relies on before serving any object.

The top-level `current` symlink is allowed because CARAVAN uses it as the atomic generation selector. Symlinks beneath the resolved generation are forbidden.

The private preservation mirror is never a Telepathy root. Telepathy has no code path that compiles, activates, approves, or mutates CARAVAN cargo.

## Gateway capability surface

`fcf-telepathyd` starts deny-by-default and exposes only the intentionally public CARAVAN surface.

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
- expectation requests;
- ambiguous duplicate content lengths or range headers;
- absolute-form proxy targets;
- query- or fragment-driven routing;
- percent-encoded routing;
- traversal, backslashes, control characters, and non-canonical paths;
- non-IPv4-loopback listener addresses;
- non-canonical or multiple byte ranges;
- writable live objects;
- wrong-owner live objects;
- internal symbolic links;
- special/non-regular final objects; and
- missing live objects.

Incoming requests cannot choose a filesystem root, an upstream address, another local service, a preservation object, or a carrier destination.

Client `Host`, authorization, forwarding, and similar headers are never used to select cargo and are never forwarded anywhere because `fcf-telepathyd` has no HTTP upstream client.

The gateway supports bounded single byte ranges, `HEAD`, ETags, and `If-None-Match` revalidation directly over approved regular files. Responses add conservative browser-facing security headers and close the connection after each request.

## Tor carrier isolation

The Tor adapter is intentionally not a general Tor client.

Its generated configuration:

- disables the SOCKS listener with `SocksPort 0`;
- uses a dedicated `DataDirectory` beneath the `fcf-telepathyd` state directory;
- creates a dedicated v3 `HiddenServiceDir`;
- maps exactly one onion virtual port to the loopback `fcf-telepathyd` listener; and
- stores onion-service state outside CARAVAN preservation and publication trees.

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

Start the complete Tor publication path:

```sh
python3 scripts/fcf-telepathyd serve \
  --carrier tor-onion \
  --publish
```

The default live root is `/srv/fcf-caravan-live/current`, so no second local web service is required. An alternate root can be named explicitly with `--caravan-live-root` for a deliberately different deployment.

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
3. The daemon reads only an activated root-owned immutable CARAVAN live generation.
4. The CARAVAN `current` pointer may change atomically without making internal generation symlinks acceptable.
5. GET/HEAD for approved paths can read approved live objects.
6. Unsupported verbs cannot mutate or reach any other backend because no other backend exists.
7. Absolute proxy targets, encoded routing, traversal, queries, request bodies, ambiguous framing, and unsafe ranges are rejected.
8. Client-supplied routing, authorization, and forwarding headers cannot select or escape the live-generation boundary.
9. Writable, wrong-owner, symlink, non-regular, or missing live-generation objects fail closed.
10. File identity is rechecked after open before bytes are streamed.
11. Tor configuration uses a private dedicated state directory and v3 onion service.
12. Tor publication refuses a dead `fcf-telepathyd` gateway.
13. A fake/offline Tor process can prove publish, status, persistence, and withdrawal behavior in tests without Internet access.
14. A stale or unrelated PID cannot be killed through the carrier state file.
15. CI executes the `fcf-telepathyd` tests through the existing Mirage test gate.
16. Public deployment remains an explicit FCF operator action. CI never publishes a real onion service.

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

CARAVAN's volunteer carrier protocol remains outbound-oriented. `fcf-telepathyd` is a constrained publication boundary over an explicitly activated FCF CARAVAN live generation; it does not silently turn volunteer CARAVAN carriers into public servers.

```text
CARAVAN:        preservation, artifact identity, verification, replication
fcf-telepathyd: constrained network carriage
FCF:            trust, identity, policy, authorization
```

A future CARAVAN role may request an `fcf-telepathyd` capability, but that capability must remain explicit and least-privilege.
