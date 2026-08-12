# FCF-Telepathy

Status: **optional CARAVAN transport layer; Tailscale Funnel is the first supported carrier.**

FCF-Telepathy exists for FCF-controlled machines that have a valid CARAVAN publication state but cannot receive direct Internet connections because the surrounding network is behind NAT, CGNAT, an administrator-controlled router, or another ingress boundary.

Telepathy is deliberately **not** publication authority.

> Telepathy may carry approved bytes. Telepathy may never decide which bytes are approved.

## Trust boundary

The CARAVAN pipeline remains unchanged:

```text
FCF preservation mirror
        ↓
root authorization
        ↓
networkless ingest
        ↓
root-owned approved store
        ↓
unprivileged candidate compiler
        ↓
networkless root activation
        ↓
/srv/fcf-caravan-live/current
```

Telepathy begins only after that pipeline has completed:

```text
Internet
   ↓ HTTPS
Telepathy carrier
   ↓ encrypted outbound-established path
FCF machine
   ↓ loopback only
127.0.0.1:8787
   ↓
/srv/fcf-caravan-live/current
```

The Telepathy boundary has no preservation-mirror path, no approved-store write path, no candidate write path, and no mechanism for selecting arbitrary local content.

## First carrier: Tailscale Funnel

The first carrier uses Tailscale Funnel because it can establish public HTTPS reachability through NAT without router administration or inbound port forwarding.

The Tailscale client is open source under BSD-3-Clause. Funnel provides a stable `*.ts.net` HTTPS name. Funnel relay servers carry encrypted traffic and do not receive CARAVAN publication authority.

This carrier is a pragmatic bootstrap, not an architectural dependency. A later FCF-controlled Telepathy relay may replace the carrier while keeping the same local CARAVAN boundary.

## Local publication boundary

`infra/caravan-public-origin/nginx-fcf-telepathy.conf` listens only on:

```text
127.0.0.1:8787
```

It serves only the already-activated CARAVAN generation and retains the static allowlist and method restrictions used by the direct public-origin boundary:

- GET/HEAD only;
- no directory listing;
- no upload surface;
- no CGI/FastCGI;
- no WebDAV;
- no reverse proxy;
- no arbitrary filesystem alias;
- no Git smart HTTP;
- no preservation mirror;
- unknown paths return 404.

The transport provider terminates public TLS on the same FCF machine and forwards the resulting request only to this loopback listener.

## Operator flow

FCF-Telepathy does not rebuild or reseal CARAVAN. A machine must already have a root-owned live generation.

Prepare the local boundary:

```sh
sudo bash scripts/fcf-telepathy prepare
```

Install Tailscale from a trusted source if it is not already present, then enroll the dedicated node:

```sh
sudo bash scripts/fcf-telepathy enroll fcf-caravan-001
```

The enrollment command may print or open an authentication URL. Use an FCF-controlled Tailscale account/tailnet and enable Funnel/HTTPS when prompted.

Start public transport:

```sh
sudo bash scripts/fcf-telepathy start
```

Inspect state:

```sh
sudo bash scripts/fcf-telepathy status
```

Run the hostile public transport audit:

```sh
sudo bash scripts/fcf-telepathy audit
```

The audit requires the public HTTPS endpoint to return the activated CARAVAN status and source index while rejecting mutation methods and common sensitive paths.

Disable Telepathy without altering CARAVAN cargo:

```sh
sudo bash scripts/fcf-telepathy stop
```

## Direct origin remains available

Telepathy does not remove or replace the direct-origin mode. If a machine later gains deliberate TCP 80/443 reachability, the normal `caravan-public-origin-install` TLS qualification may still be used.

A machine can therefore move between:

```text
CARAVAN prepared + Telepathy transport
```

and:

```text
CARAVAN direct public origin
```

without rebuilding the preservation mirror or changing the cargo identity.

## Future FCF-owned relay

The long-term FCF-Telepathy design should support an FCF-controlled relay implementation with these properties:

- the origin establishes the session outbound;
- mutually authenticated cryptographic node identity;
- relay sees no preservation or publication authority;
- fixed mapping from one public origin identity to one local CARAVAN listener;
- no generic SOCKS/CONNECT/VPN/file-drop behavior;
- no arbitrary destination selection;
- end-to-end authenticated transport;
- bounded resources and connection rates;
- public relay can be replaced without changing CARAVAN cargo identities;
- relay software and deployment artifacts preserved in the FCF Dependency Chest.

That future relay is a transport evolution, not a reason to postpone using the already-qualified CARAVAN publication system today.
