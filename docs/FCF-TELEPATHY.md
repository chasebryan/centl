# FCF Telepathy

Status: **Mirage experimental architecture and implementation**

Software: **`fcf-telepathyd`**

`fcf-telepathyd` is the carrier-independent transport boundary for CARAVAN. Its job is deliberately narrow: carry authorized FCF information over replaceable roads without allowing any road to become FCF's identity, authorization authority, update authority, or source of truth.

> CARAVAN carries matter. Telepathy carries information. FCF supplies trust.

## One software name

The daemon and operator command are both `fcf-telepathyd`. There is no separate Telepathy control executable.

The initial command surface is:

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

The initial publishing topology is:

```text
FCF preservation / approved state
            |
            v
CARAVAN live publication
127.0.0.1:8787
            |
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

The CARAVAN endpoint remains bound to loopback. `fcf-telepathyd` also binds to loopback. Tor maps an onion-service virtual port to the `fcf-telepathyd` loopback listener.

Tor's documented onion-service model uses `HiddenServiceDir` for service state and keys and `HiddenServicePort` to map the onion virtual port to a local service. Tor creates the v3 onion hostname in the hidden-service directory. The service keys must remain private.

Upstream references:

- https://community.torproject.org/onion-services/setup/
- https://spec.torproject.org/rend-spec-v3
- https://spec.torproject.org/address-spec

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
- absolute-form proxy targets;
- query- or fragment-driven routing;
- percent-encoded routing;
- traversal, backslashes, control characters, and non-canonical paths;
- non-loopback listener or upstream addresses;
- arbitrary Host or forwarding headers from the requester;
- multiple/non-canonical byte ranges; and
- upstream redirects that could turn the fixed origin into an external navigation primitive.

The upstream address is local operator configuration. It is never selected from an incoming request.

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

## Operator flow

Probe for Tor:

```sh
python3 scripts/fcf-telepathyd carrier probe
```

Run the policy gateway without publishing a carrier:

```sh
python3 scripts/fcf-telepathyd serve \
  --listen-host 127.0.0.1 \
  --listen-port 8790 \
  --upstream-host 127.0.0.1 \
  --upstream-port 8787
```

Run the gateway and publish the Tor onion carrier in one process-owned lifecycle:

```sh
python3 scripts/fcf-telepathyd serve \
  --upstream-host 127.0.0.1 \
  --upstream-port 8787 \
  --carrier tor-onion \
  --publish
```

The combined `serve --publish` path is preferred because the daemon that started Tor also owns its child-process handle and withdraws it during normal shutdown.

Standalone carrier publication is also available for controlled operator workflows:

```sh
python3 scripts/fcf-telepathyd carrier publish
python3 scripts/fcf-telepathyd carrier status
python3 scripts/fcf-telepathyd carrier withdraw
```

Standalone publication refuses to proceed unless the configured loopback gateway is already reachable.

## Today milestone: TELEPATHY I-TOR

The Mirage milestone is demonstrably complete when all of these are true:

1. `fcf-telepathyd` is the only Telepathy software/command name.
2. The gateway starts only on a loopback listener.
3. Its upstream is a fixed loopback CARAVAN endpoint.
4. GET/HEAD for approved paths reach that endpoint.
5. Unsupported verbs cannot reach the endpoint.
6. Absolute proxy targets, encoded routing, traversal, queries, request bodies, and unsafe ranges are rejected.
7. Client-supplied forwarding/authorization headers cannot escape the gateway filter.
8. Tor configuration uses a private dedicated state directory and v3 onion service.
9. Tor publication refuses a dead `fcf-telepathyd` gateway.
10. A fake/offline Tor process can prove publish, status, persistence, and withdrawal behavior in tests without Internet access.
11. A stale or unrelated PID cannot be killed through the carrier state file.
12. CI executes the `fcf-telepathyd` tests for Mirage changes.
13. Public deployment remains an explicit FCF operator action. CI never publishes a real onion service.

This milestone is intentionally smaller than a sovereign network. It produces a useful federated road while preserving the escape hatch.

## Roadmap

### TELEPATHY 0

Direct CARAVAN networking. Pure path, dependent on local router/public-ingress availability.

### TELEPATHY I

FCF identity, capability policy, carrier firewall, fixed loopback CARAVAN bridge.

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

CARAVAN's volunteer carrier protocol remains outbound-oriented. `fcf-telepathyd` is a constrained publication boundary for an explicitly configured FCF CARAVAN endpoint; it does not silently turn volunteer CARAVAN carriers into public servers.

```text
CARAVAN:        preservation, artifact identity, verification, replication
fcf-telepathyd: constrained network carriage
FCF:            trust, identity, policy, authorization
```

A future CARAVAN role may request an `fcf-telepathyd` capability, but that capability must remain explicit and least-privilege.
