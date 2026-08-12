# FCF Telepathy

Status: **Mirage experimental architecture**

Daemon: `fcf-telepathyd`

Codename: **telepathic-camel**

FCF Telepathy is the carrier-independent transport boundary for CARAVAN. Its job is deliberately narrow: carry authorized FCF information over one or more replaceable roads without allowing any road to become FCF's identity, authorization authority, update authority, or source of truth.

> CARAVAN carries matter. TELEPATHY carries information. FCF supplies trust.

## Non-negotiable trust boundary

A carrier may move opaque or encrypted FCF traffic from one endpoint to another. Carrier state must never be sufficient to:

- authorize CARAVAN publication;
- change an FCF node identity;
- select or mutate preserved cargo;
- update CENTL or CARAVAN;
- modify the root-owned live generation;
- replace FCF signing keys or capability policy; or
- turn Telepathy into a general-purpose proxy.

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

## telepathic-camel: first carrier

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

The CARAVAN origin remains bound to loopback. Tor is never an FCF authorization authority. The onion address is a carrier identity, not the permanent FCF node identity.

## Gateway capability surface

Telepathy starts deny-by-default. The initial public-read capability permits only:

```text
GET  /
HEAD /
GET  /status.json
HEAD /status.json
GET  /source/INDEX.json
HEAD /source/INDEX.json
GET  /source/<approved-publication-path>
HEAD /source/<approved-publication-path>
```

The implementation must reject malformed paths, traversal, query-based routing ambiguity, non-loopback upstreams, unsupported methods, `CONNECT`, arbitrary forwarding, and carrier-supplied destination changes.

The upstream address is configuration owned by the local FCF operator. It is never selected from an incoming request.

## Carrier interface

Every carrier implementation is expected to converge on the same control vocabulary:

```text
telepathyctl carrier probe
telepathyctl carrier publish
telepathyctl carrier status
telepathyctl carrier withdraw
```

Initial carrier adapters:

```text
carrier/tor-onion       first implementation
carrier/direct          planned
carrier/fcf-relay       planned
carrier/tailscale       optional/borrowed-road candidate
```

CARAVAN must not depend on a carrier-specific address or API.

## Today milestone: TELEPATHY I-TOR

The Mirage milestone is considered demonstrably complete when all of these are true:

1. `fcf-telepathyd` starts only on a loopback listener.
2. Its upstream is a fixed loopback CARAVAN endpoint.
3. GET/HEAD for approved paths reach that endpoint.
4. POST, PUT, DELETE, PATCH, OPTIONS-as-proxy, TRACE and CONNECT cannot reach the endpoint.
5. Path traversal and absolute-form proxy requests are rejected.
6. A Tor v3 onion-service configuration can be generated for the Telepathy listener.
7. The Tor carrier can be probed, published, inspected and withdrawn without changing FCF identity.
8. Unit tests prove the negative properties without requiring Internet access or a live Tor network.
9. CI executes the Telepathy test suite on Mirage work.
10. Public deployment remains an operator action. CI tests do not publish a real onion service.

This milestone is intentionally smaller than a sovereign network. It produces a useful encrypted/federated road while preserving the escape hatch.

## Roadmap

### TELEPATHY 0

Direct CARAVAN networking. Pure path, dependent on local router/public-ingress availability.

### TELEPATHY I

FCF identity, capability policy, carrier firewall, fixed loopback CARAVAN bridge.

### TELEPATHY I-TOR: telepathic-camel

Tor v3 onion carrier. No corporate coordination service is required for the carrier identity. FCF trust remains above Tor.

### TELEPATHY II

Carrier abstraction hardened across `direct`, `tor-onion`, optional hosted carriers, and FCF relays. Carrier-independent node identity becomes an explicit compatibility contract.

### TELEPATHY III

FCF-operated relay, discovery and public-ingress infrastructure. Multi-carrier routing and policy-driven failover.

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

CARAVAN's existing volunteer carrier protocol is outbound-oriented and must stay that way. `fcf-telepathyd` is a publication boundary for an FCF-hosted CARAVAN endpoint; it does not silently turn volunteer CARAVAN carriers into public servers.

This separation is deliberate:

```text
CARAVAN:    preservation, artifact identity, verification, replication
TELEPATHY:  constrained network carriage
FCF:        trust, identity, policy, authorization
```

A future integration may let a CARAVAN role request a Telepathy capability, but the capability must remain explicit and least-privilege.
