# FCF CARAVAN Camel #1 Qualification Record

Status: **QUALIFIED**

Date: **2026-08-12 (America/Chicago)**

Node: **`fcf-caravan-001` / Camel #1**

## Physical node

- Hardware: Lenovo ThinkPad X200
- Firmware: Coreboot
- Operating system: Trisquel GNU/Linux
- Kernel policy: Linux-libre
- Telepathy software: `fcf-telepathyd`
- CARAVAN backend: `/srv/fcf-caravan-live/current`
- Carrier: Tor v3 onion service
- Local gateway: `http://127.0.0.1:8790`
- Qualified carrier endpoint:
  `http://7c7o2anhcwebqb6xyrxcl3ux6xi7jqgodnrdl63ngctlq5e7co6cyqid.onion/`

The onion address is carrier identity, not the permanent FCF node identity or an
artifact-signing identity.

## Field qualification evidence

Camel #1 was qualified on the physical X200 after installation of the hardened
`fcf-telepathyd.service`.

The operator session established all of the following:

1. `tests/test_fcf_telepathyd.py` completed with 17 tests passing.
2. `tests/test_fcf_telepathyd_install.py` completed with 11 tests passing before
   activation.
3. `scripts/fcf-telepathyd-install --enable-now` completed all seven installer
   stages and printed `FCF TELEPATHY ACTIVE`.
4. The service created a valid Tor v3 onion hostname.
5. A Tor client reached `/status.json` through the onion service and received a
   successful HTTP response.
6. The local `/status.json` and the Tor-delivered `/status.json` were retrieved
   independently.
7. `sha256sum` was run over both retrieved files.
8. `cmp -s` confirmed that the local and Tor-delivered files were byte-for-byte
   identical.
9. The operator-observed qualification result was:

```text
CARAVAN REMOTE QUALIFICATION: PASS
```

The exact SHA-256 digest values were not copied into this repository record, so
this document does not invent them. The preserved claim is the observed
byte-for-byte equality and successful end-to-end Tor delivery.

## Startup defect found during first deployment

The first physical activation exposed a deterministic startup-order defect in
the `serve --publish` path.

The old sequence bound the loopback socket with `gateway.start()`, then called
the Tor carrier's publication path. Tor publication deliberately verifies that
the local service is an actual `fcf-telepathyd` gateway. Because
`gateway.serve_forever()` did not begin until after publication returned, the
identity/readiness probe connected to a bound socket that had no request-serving
loop and timed out.

The security probe was correct to fail closed. The fix is to make the gateway
serve in a background thread before the carrier performs its publication probe,
then keep the daemon's main thread alive until shutdown.

The installer also now waits for the identified loopback gateway with a bounded
readiness loop rather than assuming a `Type=simple` systemd service is ready for
HTTP immediately after `systemctl restart`.

## Qualification meaning

This record proves a demonstrated end-to-end read path:

```text
root-owned activated CARAVAN generation
              |
              v
      fcf-telepathyd
       127.0.0.1:8790
              |
              v
      Tor v3 onion service
              |
              v
          Tor client
```

It does not grant the carrier publication authority, CARAVAN mutation
authority, signing authority, or FCF identity authority. Those remain above the
carrier boundary.

It also does not claim perpetual availability. A future outage can remove
reachability without invalidating the fact that the node completed this
qualification on 2026-08-12.

## Reproduction

On the X200:

```sh
sudo bash scripts/fcf-telepathyd-install --enable-now
systemctl is-active fcf-telepathyd
sudo cat /var/lib/fcf-telepathyd/tor/hidden-service/hostname
```

Through a Tor SOCKS client:

```sh
ONION=7c7o2anhcwebqb6xyrxcl3ux6xi7jqgodnrdl63ngctlq5e7co6cyqid.onion

curl --socks5-hostname 127.0.0.1:9050 \
  --max-time 60 \
  -fsS "http://$ONION/status.json"
```

For the byte-identity check:

```sh
curl -fsS http://127.0.0.1:8790/status.json \
  -o /tmp/fcf-local-status.json

curl --socks5-hostname 127.0.0.1:9050 \
  --max-time 60 \
  -fsS "http://$ONION/status.json" \
  -o /tmp/fcf-tor-status.json

sha256sum /tmp/fcf-local-status.json /tmp/fcf-tor-status.json

cmp -s /tmp/fcf-local-status.json /tmp/fcf-tor-status.json \
  && echo "CARAVAN REMOTE QUALIFICATION: PASS" \
  || echo "CARAVAN REMOTE QUALIFICATION: FAIL"
```

For the stronger reusable policy-and-carrier qualification already provided by
the Mirage operator helper, run from a second Tor client context:

```sh
scripts/x200-camel-online verify \
  7c7o2anhcwebqb6xyrxcl3ux6xi7jqgodnrdl63ngctlq5e7co6cyqid.onion
```

That helper additionally exercises bounded range reads and confirms that write
methods and forbidden filesystem paths remain denied over the carrier.

## Milestone

**Camel #1 is the first physically demonstrated FCF CARAVAN node with an
end-to-end `fcf-telepathyd` Tor carrier path.**

CARAVAN is no longer only a design, test fixture, or deployment plan. A physical
machine has carried activated FCF material over the network through the
Telepathy boundary.
