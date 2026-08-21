#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# CentL26 Linux Desktop & Package Builder (Debian, Ubuntu, Fedora, RHEL, Arch)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT_DIR"

echo "=== Building CentL26 for Linux ==="

# 1. Build release binaries
cargo build --release --bin centl26

DIST_DIR="$ROOT_DIR/build/centl26/linux"
mkdir -p "$DIST_DIR/bin" "$DIST_DIR/share/applications" "$DIST_DIR/share/icons/hicolor/scalable/apps"

# 2. Copy binary
cp "$ROOT_DIR/target/release/centl26" "$DIST_DIR/bin/centl26"

# 3. Copy icons across all standard hicolor dimensions
for size in 16 24 32 48 64 128 256 512 1024; do
    icon_dir="$DIST_DIR/share/icons/hicolor/${size}x${size}/apps"
    mkdir -p "$icon_dir"
    if [[ -f "$ROOT_DIR/desktop/centl26/linux/icons/centl26_${size}x${size}.png" ]]; then
        cp "$ROOT_DIR/desktop/centl26/linux/icons/centl26_${size}x${size}.png" "$icon_dir/centl26.png"
    fi
done
cp "$ROOT_DIR/desktop/centl26/linux/CentL26Icon.svg" "$DIST_DIR/share/icons/hicolor/scalable/apps/centl26.svg"

# 4. Copy Desktop launcher
cp "$ROOT_DIR/desktop/centl26/linux/CentL26.desktop" "$DIST_DIR/share/applications/centl26.desktop"

# 5. Create runner script
cat <<'RUNNER' > "$DIST_DIR/CentL26"
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$SCRIPT_DIR/bin:$PATH"
exec "$SCRIPT_DIR/bin/centl26" "$@"
RUNNER
chmod +x "$DIST_DIR/CentL26"

# 6. Package portable tarball
TARBALL="$ROOT_DIR/build/centl26/CentL26-Linux-x86_64.tar.gz"
mkdir -p "$ROOT_DIR/build/centl26"
tar -czf "$TARBALL" -C "$ROOT_DIR/build/centl26/linux" .

echo "CentL26 Linux build complete:"
echo "  Staging directory: $DIST_DIR"
echo "  Portable archive:  $TARBALL"
echo "  Launch with:       $DIST_DIR/CentL26"
