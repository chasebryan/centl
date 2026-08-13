# X200 CARAVAN handoff for Codex

Status: operator handoff for the X200 machine. Read this document completely before changing the machine.

This document is an execution runbook for preparing one Linux X200 as a Free Computation Foundation (FCF) CARAVAN carrier. It follows the existing CARAVAN contracts. It does not authorize a new protocol, a public server, a public machine listing, or a fabricated census value.

## 1. Mission

Prepare the X200 to become a normal volunteer CARAVAN carrier when FCF's authenticated production enrollment release is available.

The intended role is:

- rootless;
- outbound-only;
- resource-bounded;
- content-addressed;
- limited to authenticated FCF \x60public-approved\x60 cargo;
- aggregate-only for the public census;
- never a public web server or general-purpose storage service.

The X200 must never become:

- a public inbound listener;
- a proxy, VPN, tunnel exit, or shell gateway;
- a generic upload host;
- a Git host or directory share;
- an arbitrary file mirror;
- a source of public hostnames, IP addresses, usernames, email addresses, serial numbers, MAC addresses, or location data.

## 2. Read these repository contracts first

From the repository root, read:

\x60\x60\x60text
docs/CARAVAN-X200-CODEX-HANDOFF.md
docs/CARAVAN-JOIN-MANUAL.md
docs/CARAVAN-CENSUS.md
docs/CARAVAN-JOIN-RELEASE.md
docs/CARAVAN-PHASE1.md
scripts/caravan-join-verify
scripts/caravan-join-template
\x60\x60\x60

Also inspect the current production-enrollment gate:

\x60\x60\x60text
GitHub issue #167:
https://github.com/chasebryan/centl/issues/167
\x60\x60\x60

The mutable file \x60scripts/caravan-join-template\x60 is development source only. It is not an installer and must not be executed as the enrollment mechanism.

## 3. Current state and stop condition

The current repository design intentionally keeps public enrollment disabled until the authenticated production gates in issue #167 pass.

The current expected network mode is:

\x60\x60\x60text
disabled-until-authenticated-enrollment
\x60\x60\x60

Therefore, the normal action on the X200 today is preparation and audit only:

- do not open an inbound port;
- do not start a CARAVAN background service;
- do not send a heartbeat;
- do not publish an enrollment token;
- do not add the X200 to the website by editing \x60site/pub/centl/caravan/census-v1.json\x60;
- do not write \x60active_camels: 1\x60 or any other guessed count;
- do not create a new Cloudflare Worker, endpoint, schema, or authentication flow;
- do not claim that the X200 is Active until the coordinator has accepted a real authenticated heartbeat.

If no immutable FCF-signed join release and separately trusted FCF join public key are available, stop after the preflight audit and report:

\x60\x60\x60text
BLOCKED: no independently verifiable FCF CARAVAN join release is available.
The X200 remains prepared-only; no public enrollment or census heartbeat was attempted.
\x60\x60\x60

Do not manufacture a release key, replace a missing digest, or turn the mutable repository template into an official release.

## 4. Safe preflight audit

Run the following as the ordinary X200 user. Do not use \x60sudo\x60 for the normal carrier path.

\x60\x60\x60sh
set -eu

printf 'kernel='
uname -srm
printf 'architecture='
uname -m
printf 'python='
python3 --version
printf 'sha256sum='
command -v sha256sum
printf 'package-manager='
for command_name in apt-get dnf yum zypper pacman apk xbps-install emerge nix; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '%s' "$command_name"
    break
  fi
done
printf '\n'

id -u
\x60\x60\x60

The final \x60id -u\x60 must be non-zero. If it is zero, stop and do not run the carrier installer.

Check capabilities and local capacity without printing sensitive machine identity:

\x60\x60\x60sh
command -v python3
command -v sha256sum
command -v signify || true
df -h "$HOME"
\x60\x60\x60

Do not include these values in a public report:

- hostname;
- username;
- home-directory path;
- IP address;
- MAC address;
- serial number;
- machine-id;
- exact physical location.

A private handoff report may state the Linux family, architecture, available storage class, release version, and pass/fail results. Redact the fields above before sending the report anywhere.

## 5. Verify an immutable join release

Only use an official versioned release directory supplied through an FCF-controlled channel. It must have the form:

\x60\x60\x60text
fcf-caravan-join-X.Y.Z/
  fcf-caravan-join-X.Y.Z.tar.gz
  FCF-CARAVAN-JOIN.pub
  SHA256SUMS
  SHA256SUMS.sig
\x60\x60\x60

The trusted FCF CARAVAN join public key must have been obtained independently of the release directory. Keep it outside the release directory.

From a trusted checkout of this repository, verify the release:

\x60\x60\x60sh
scripts/caravan-join-verify \
  /path/to/fcf-caravan-join-X.Y.Z \
  /path/to/separately-trusted/FCF-CARAVAN-JOIN.pub
\x60\x60\x60

The verifier must pass all outer signature, exact-membership, extraction, and inner-manifest checks.

If verification fails, stop. Do not:

- run the archive anyway;
- re-download from an untrusted alternate location;
- replace the expected public key;
- edit \x60SHA256SUMS\x60;
- replace a digest;
- repair the release manually.

## 6. Inspect the verified release

After verification succeeds, extract it into a temporary directory and inspect its metadata:

\x60\x60\x60sh
temporary_root="$(mktemp -d)"
trap 'rm -rf -- "$temporary_root"' EXIT

tar -xzf /path/to/fcf-caravan-join-X.Y.Z/fcf-caravan-join-X.Y.Z.tar.gz \
  -C "$temporary_root"

release_root="$temporary_root/fcf-caravan-join-X.Y.Z"
cat "$release_root/RELEASE.json"
"$release_root/join-caravan" --help
\x60\x60\x60

Confirm that:

- the release version is immutable and matches the verified directory;
- the release identifies the trusted FCF join key;
- the release says the ordinary carrier is rootless;
- the release says no systemd dependency is required for the volunteer role;
- the release says enrollment/network mode is disabled unless a later authenticated release explicitly enables it;
- no arbitrary local path, upload endpoint, proxy, tunnel, or inbound listener is requested.

If the release metadata conflicts with the repository contracts, stop and report the exact conflict. Do not silently reinterpret it.

## 7. Prepare the X200 carrier

Use the verified release's own installer. Do not execute a copy from the mutable repository.

For an interactive preparation:

\x60\x60\x60sh
"$release_root/join-caravan"
\x60\x60\x60

For a reproducible preparation, choose missions with the X200 owner first. The documented mission vocabulary is:

\x60\x60\x60text
source
releases
semantic
recovery
all
\x60\x60\x60

A conservative source/release preparation example is:

\x60\x60\x60sh
"$release_root/join-caravan" \
  --missions source,releases \
  --storage-gib 25 \
  --upload-mibps 4 \
  --yes
\x60\x60\x60

Use a different storage or bandwidth limit only when the X200 owner has chosen it. Mission selection is an eligibility filter; it does not authorize local files or arbitrary digests.

The installer must:

- refuse root execution;
- keep release bytes read-only;
- keep configuration and state owner-only;
- keep cargo content-addressed;
- avoid opening inbound ports;
- avoid exposing the home directory;
- avoid starting public network service while enrollment is disabled;
- record the disabled network mode explicitly.

If the installer asks to use \x60sudo\x60, open an inbound port, expose a directory, enable a proxy/tunnel, or accept arbitrary files, stop.

## 8. Audit the prepared configuration

The expected local paths are:

\x60\x60\x60text
~/.config/fcf-caravan/config.json
~/.local/share/fcf-caravan/store/
~/.local/state/fcf-caravan/identity/
~/.local/state/fcf-caravan/census/
~/.local/lib/fcf-caravan/releases/
\x60\x60\x60

Inspect the configuration:

\x60\x60\x60sh
python3 -m json.tool "$HOME/.config/fcf-caravan/config.json"
\x60\x60\x60

The configuration must show the existing contract values:

\x60\x60\x60text
network_mode = disabled-until-authenticated-enrollment
inbound_listen = false
arbitrary_content = false
mission_authority = authenticated-fcf-public-approved-only
census mode = aggregate-only
public node listing = false
public IP addresses = false
public hostnames = false
systemd required = false
\x60\x60\x60

Check that the release directory is not writable by the carrier process:

\x60\x60\x60sh
find "$HOME/.local/lib/fcf-caravan/releases" -maxdepth 3 -type f -print
\x60\x60\x60

Do not alter release files in place. A changed release requires a new authenticated version.

## 9. Do not perform production enrollment early

Do not create or transmit a production enrollment token until all of these are true:

1. issue #167's production gates are complete;
2. an immutable FCF-signed release explicitly enables authenticated enrollment;
3. the release documents the designated coordinator and authenticated catalog/TUF path;
4. the X200 owner has accepted the displayed policy and resource limits;
5. the release's own instructions provide the exact enrollment command.

When those conditions eventually hold, follow the later signed release and its documentation exactly. Do not guess endpoint URLs, request fields, heartbeat fields, authentication headers, service commands, or withdrawal commands.

A production heartbeat must use the existing contract vocabulary:

\x60\x60\x60json
{
  "schema": "fcf-caravan-heartbeat-v1",
  "release_version": "X.Y.Z",
  "missions": ["source", "releases"],
  "protocol_version": 1
}
\x60\x60\x60

Authentication is separate from that payload. Never put the enrollment token, hostname, username, IP address, or location into the public heartbeat payload.

## 10. Census rules

The website's public document is aggregate-only and must match:

\x60\x60\x60text
schema: fcf-caravan-census-v1
Active: recent authenticated heartbeat within 1800 seconds
Lost: enrolled carrier beyond 259200 seconds without withdrawal/revocation
individual_nodes_public: false
ip_addresses_public: false
\x60\x60\x60

The public site may display:

\x60\x60\x60text
Active Camels 🐪
Lost Camels 🐪
\x60\x60\x60

It must not display:

- X200 as a named public node;
- carrier IDs;
- IP addresses;
- hostnames;
- usernames;
- email addresses;
- hardware identifiers;
- locations;
- exact per-node mission combinations.

A prepared X200 is not an Active Camel. A machine becomes Active only after the production coordinator accepts its authenticated heartbeat. A withdrawn or revoked carrier is not counted as ordinary Lost.

## 11. Required handoff report

At the end of this run, report to the X200 owner privately:

\x60\x60\x60text
X200 CARAVAN preparation
------------------------
Linux family/architecture: <non-identifying value>
Verified release: <X.Y.Z or BLOCKED>
Trusted release verification: PASS/FAIL
Prepared configuration: PASS/FAIL
Network mode: disabled-until-authenticated-enrollment
Inbound listener opened: NO
Background CARAVAN service started: NO
Public enrollment attempted: NO
Public census heartbeat sent: NO
Public node identity published: NO
Blocking item: <exact reason, if any>
\x60\x60\x60

Do not attach \x60config.json\x60, enrollment tokens, private identity files, logs containing source addresses, or machine-identifying data to a public issue, website, or chat.

## 12. Completion definition

This handoff is complete when one of these outcomes is recorded:

### Prepared-only outcome

The X200 has a verified immutable release and audited rootless configuration, with network mode still disabled. No public enrollment or heartbeat was attempted.

### Blocked outcome

The X200 could not proceed because an independently verifiable FCF release, trusted key, required capability, or production enrollment gate is missing. The machine was left unchanged or safely prepared-only.

### Production-enrolled outcome

Only a later authenticated FCF-signed release may produce this outcome. It requires a successful authenticated enrollment, a real accepted heartbeat, and a coordinator-backed census document. Do not claim this outcome from local configuration alone.
