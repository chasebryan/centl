#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# CentL26 Automated Linux Installer (Debian, Ubuntu, Fedora, RHEL, Arch)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "=== CentL26 Linux Installation ==="

# Check/Install Rust toolchain if missing
if ! command -v cargo >/dev/null 2>&1; then
    echo "Rust toolchain not detected. Installing via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Build release binary
echo "Compiling CentL26..."
cargo build --release --bin centl26

# Local user directories
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_BASE="$HOME/.local/share/icons/hicolor"

mkdir -p "$BIN_DIR" "$APP_DIR" "$ICON_BASE/scalable/apps"

# Install binary
cp "$ROOT_DIR/target/release/centl26" "$BIN_DIR/centl26"
chmod +x "$BIN_DIR/centl26"

# Install icons
for size in 16 24 32 48 64 128 256 512 1024; do
    mkdir -p "$ICON_BASE/${size}x${size}/apps"
    if [[ -f "$ROOT_DIR/desktop/centl26/linux/icons/centl26_${size}x${size}.png" ]]; then
        cp "$ROOT_DIR/desktop/centl26/linux/icons/centl26_${size}x${size}.png" "$ICON_BASE/${size}x${size}/apps/centl26.png"
    fi
done
cp "$ROOT_DIR/desktop/centl26/linux/CentL26Icon.svg" "$ICON_BASE/scalable/apps/centl26.svg"

# Install desktop launcher with absolute path to binary
cat <<DESKTOP > "$APP_DIR/centl26.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=CentL26
GenericName=Scientific Computing Workbench
Comment=Exact-first mathematics, physics, chemistry, and offline STEM computing environment
Exec=$BIN_DIR/centl26
Icon=centl26
Terminal=false
Categories=Science;Math;Education;Development;
Keywords=math;physics;chemistry;exact;symbolic;computation;science;
StartupNotify=true
StartupWMClass=centl26
DESKTOP

# Update icon and desktop databases if available
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APP_DIR" || true
command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -f -t "$ICON_BASE" || true

echo ""
echo "=== CentL26 Installed Successfully ==="
echo "Binary:  $BIN_DIR/centl26"
echo "Desktop: $APP_DIR/centl26.desktop"
echo "Launch from your application menu or run: centl26"
