# FCF CARAVAN public coordinator

The public coordinator is a loopback-bound Python service behind a TLS edge.
Supporters do not need Tailscale membership. The public bootstrap document at
`site/pub/centl/caravan/coordinator-v1.json` contains the current HTTPS edge;
the signed join release resolves that document immediately before enrollment.
This lets the administrator replace an edge without issuing a new trust key or
inventing a new caravan number.

The administrator machine uses a dedicated named Cloudflare Tunnel as that
edge because the local Tailscale Funnel anycast route is not serving external
TLS connections. The tunnel connects outbound from the administrator machine;
the coordinator remains loopback-only and the public hostname is stable.

It exposes only:

- `GET /healthz` for an operator health check;
- `GET /census-v1.json` for the aggregate Active, Hungry, Lost, and Cargo Loads
  document;
- `POST /v1/enroll` for a signed host-policy receipt;
- the proof-of-possession session endpoints;
- authenticated heartbeat and withdrawal endpoints.

The service rejects other paths, limits request size and concurrency, binds only
to loopback, suppresses default access logging, and never serves the SQLite
database, a directory, arbitrary uploads, or a per-carrier roster. The durable
database stores the pseudonymous Ed25519 identity, policy/release metadata,
heartbeat state, and first-enrollment CARAVAN number. It does not store a
supporter's IP address as census data.

The first accepted enrollment allocates the next durable CARAVAN number inside
the coordinator transaction. Re-enrollment of the same identity returns the
same number. The join release prints the coordinator's number only after the
first heartbeat succeeds, so a supporter sees a real live position rather than
a locally invented count.
