# fcf-telepathyd deployment runbook

Status: **Mirage deployment procedure**

This runbook turns an already-qualified CARAVAN host into a Tor-reachable FCF Telepathy node without making Tor, systemd, or the local network part of FCF's trust root.

The installed path is:

```text
/srv/fcf-caravan-live/current
        |
        | immutable, root-owned, read-only
        v
fcf-telepathyd
127.0.0.1:8790
        |
        v
managed Tor v3 onion service
        |
        v
Tor network
```

`fcf-telepathyd` never receives preservation write authority. Its system account can read the already-activated public CARAVAN generation, while its only persistent writable state is its private Tor carrier directory.

## Before installation

The CARAVAN activation path must already exist:

```sh
test -L /srv/fcf-caravan-live/current
test -r /srv/fcf-caravan-live/current/status.json
```

The live generation is expected to have been produced by CARAVAN's networkless activation path and frozen root-owned/read-only before `current` was switched.

## Install offline first

From a `mirage` checkout containing `fcf-telepathyd`:

```sh
git switch mirage
git pull --ff-only
sudo bash scripts/fcf-telepathyd-install
```

The default installer deliberately **does not start or enable** Telepathy. It:

1. runs the dedicated `fcf-telepathyd` test suite;
2. checks the activated CARAVAN live generation;
3. ensures the Tor executable exists, installing the distribution Tor package when necessary;
4. creates the unprivileged `fcf-telepathyd` account;
5. installs the daemon/package beneath `/usr/local/libexec/fcf-telepathyd`;
6. installs and verifies the hardened systemd unit; and
7. leaves the service offline until the operator explicitly activates it.

If the installer itself has to install Tor, it disables the distribution's default Tor service instances after installation. `fcf-telepathyd` then owns the dedicated Tor process it launches with `SocksPort 0`. An already-existing Tor installation is not disabled or reconfigured.

## Explicit activation

When the node is meant to become publicly reachable over Tor:

```sh
sudo bash scripts/fcf-telepathyd-install --enable-now
```

Or, after an offline installation:

```sh
sudo systemctl enable fcf-telepathyd.service
sudo systemctl start fcf-telepathyd.service
```

Inspect local state:

```sh
sudo systemctl status --no-pager fcf-telepathyd.service
sudo cat /var/lib/fcf-telepathyd/tor/hidden-service/hostname
```

A valid carrier identity is a 56-character v3 onion host followed by `.onion`.

## What `--enable-now` proves

The installer does not call success merely because systemd accepted a unit file. It requires:

- `fcf-telepathyd.service` to remain active;
- `HEAD /status.json` on `127.0.0.1:8790` to return HTTP 200;
- the response to identify itself as `fcf-telepathyd`; and
- the managed Tor process to create a syntactically valid v3 onion hostname.

Those checks prove the local publication boundary and the local Tor onion-service bootstrap.

They do **not** by themselves prove that a remote Tor client can complete a rendezvous with the node. The final qualification is a remote onion read from a second Tor client/network context.

## Final remote smoke test

From a separate machine or Tor client with SOCKS access, retrieve the published onion endpoint. For example, where the client supplies a SOCKS proxy on `127.0.0.1:9050`:

```sh
ONION='replace-with-the-hostname-printed-by-the-X200.onion'
curl --fail --show-error --silent \
  --socks5-hostname 127.0.0.1:9050 \
  "http://$ONION/status.json"
```

Then prove a representative immutable artifact can be read and ranged:

```sh
curl --fail --show-error --silent \
  --socks5-hostname 127.0.0.1:9050 \
  -H 'Range: bytes=0-63' \
  "http://$ONION/source/INDEX.json"
```

Do not use a public web gateway for qualification. The test should traverse a real Tor client so the carrier path being qualified is the path FCF intends to operate.

## Service sandbox

The supplied unit deliberately runs as `fcf-telepathyd`, not root. It applies:

- empty capability and ambient-capability sets;
- `NoNewPrivileges=true`;
- `ProtectSystem=strict` and `ProtectHome=true`;
- read-only exposure of `/srv/fcf-caravan-live`;
- private `/var/lib/fcf-telepathyd` state via `StateDirectory`;
- private temporary and device namespaces;
- kernel/control-group/clock/hostname protections;
- restricted namespace creation, realtime, SUID/SGID, and address families;
- a 0077 umask; and
- `KillMode=mixed` so normal shutdown gives the daemon time to withdraw its managed Tor child before systemd force-cleans the service cgroup.

The service cannot use `PrivateNetwork=true`: Tor must make outbound Internet connections to build circuits. That outbound requirement is carrier reachability, not publication authority.

## Withdraw the carrier

Temporarily remove Tor reachability without touching CARAVAN preservation or its approved live generation:

```sh
sudo systemctl stop fcf-telepathyd.service
```

Prevent automatic startup as well:

```sh
sudo systemctl disable fcf-telepathyd.service
```

The onion-service key material is intentionally retained under `/var/lib/fcf-telepathyd/tor/hidden-service`, so an ordinary stop/start can preserve the carrier address. Deleting that private state is a separate identity-rotation operation and should not be done casually.

After withdrawal:

```text
FCF preservation        intact
CARAVAN approved cargo  intact
FCF identity/signatures intact
Tor reachability        offline
```

That asymmetry is the point of Telepathy.
