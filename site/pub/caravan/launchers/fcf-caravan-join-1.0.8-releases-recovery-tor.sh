#!/bin/sh
set -eu

# FCF CARAVAN launcher. Static HTML/CSS download after host-policy consent.
# FCF-approved provisions: releases,recovery
# Coordinator route: tor
RELEASE_VERSION='1.0.8'
MISSIONS='releases,recovery'
TRANSPORT='tor'
ASSET_BASE='https://github.com/chasebryan/centl/releases/download/fcf-caravan-join-1.0.8'
EXPECTED_KEY_SHA256='450a55addaade128814788a02662a3f10230411f15d91d1060fa17543c288aa8'
HELPER_ASSET='fcf-signify-x86_64-glibc'
EXPECTED_HELPER_SHA256='5fb7cf62bf9f01d4957ff3b2cbed9f6137cffd5cddf9392e7d4a2eecfeb54530'
fail() { printf '%s\n' "FCF CARAVAN launcher: $*" >&2; exit 1; }
for command in python3 sha256sum tar; do command -v "$command" >/dev/null 2>&1 || fail "$command is required for signed setup"; done
work="$(mktemp -d "${TMPDIR:-/tmp}/fcf-caravan-join.XXXXXXXX")"
cleanup() { rm -rf -- "$work"; }
trap cleanup EXIT HUP INT TERM
python3 - "$work" "$ASSET_BASE" "$RELEASE_VERSION" <<'PY'
import sys
from pathlib import Path
from urllib.request import Request, urlopen

work, base, version = sys.argv[1:]
root = Path(work)
names = (
    f"fcf-caravan-join-{version}.tar.gz",
    "FCF-CARAVAN-JOIN.pub",
    "SHA256SUMS",
    "SHA256SUMS.sig",
    "fcf-signify-x86_64-glibc",
)
for name in names:
    request = Request(
        f"{base.rstrip('/')}/{name}",
        headers={
            "Accept": "application/octet-stream",
            "User-Agent": f"FCF-CARAVAN-web-launcher/{version}",
        },
    )
    output = root / name
    total = 0
    with urlopen(request, timeout=60) as response, output.open("wb") as stream:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            total += len(chunk)
            if total > 64 * 1024 * 1024:
                raise SystemExit(f"download too large: {name}")
            stream.write(chunk)
PY
actual_key_sha256="$(sha256sum "$work/FCF-CARAVAN-JOIN.pub" | awk '{print $1}')"
[ "$actual_key_sha256" = "$EXPECTED_KEY_SHA256" ] || fail "the downloaded FCF trust key fingerprint is unexpected"
signify_command="$(command -v signify 2>/dev/null || true)"
if [ -z "$signify_command" ]; then
  case "$(uname -m)" in
    x86_64|amd64)
      helper_sha256="$(sha256sum "$work/$HELPER_ASSET" | awk '{print $1}')"
      [ "$helper_sha256" = "$EXPECTED_HELPER_SHA256" ] || fail "the FCF signify helper fingerprint is unexpected"
      helper_dir="$HOME/.local/bin"
      helper_target="$helper_dir/signify"
      mkdir -p -m 0755 "$helper_dir"
      if [ -e "$helper_target" ] || [ -L "$helper_target" ]; then
        [ "$(sha256sum "$helper_target" | awk '{print $1}')" = "$EXPECTED_HELPER_SHA256" ] || fail "an unexpected user-local signify already exists"
      else
        cp "$work/$HELPER_ASSET" "$helper_target"
        chmod 0755 "$helper_target"
      fi
      signify_command="$helper_target"
      PATH="$helper_dir:$PATH"; export PATH
      ;;
    *) fail "signify is missing and this architecture has no FCF-hosted helper yet" ;;
  esac
fi
"$signify_command" -V -q -p "$work/FCF-CARAVAN-JOIN.pub" -x "$work/SHA256SUMS.sig" -m "$work/SHA256SUMS" || fail "FCF release signature verification failed"
(cd "$work" && sha256sum -c SHA256SUMS >/dev/null) || fail "FCF release checksum verification failed"
tar -xzf "$work/fcf-caravan-join-$RELEASE_VERSION.tar.gz" -C "$work" || fail "signed FCF release could not be unpacked"
signed_join="$work/fcf-caravan-join-$RELEASE_VERSION/join-caravan"
[ -f "$signed_join" ] && [ ! -L "$signed_join" ] || fail "signed join launcher is missing"
"$signed_join" --missions "$MISSIONS" --transport "$TRANSPORT"
