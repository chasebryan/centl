#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# CentL26 Universal Installer (macOS & Linux)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

OS_NAME="$(uname -s)"

echo "=== Installing CentL26 on $OS_NAME ==="

if [[ "$OS_NAME" == "Darwin" ]]; then
    # macOS
    echo "Running macOS native build and application bundle setup..."
    ./desktop/centl26/macos/build.sh
    echo ""
    echo "CentL26 is ready at: build/centl26/macos/CentL26.app"
    echo "To launch: open build/centl26/macos/CentL26.app"
elif [[ "$OS_NAME" == "Linux" ]]; then
    # Linux (Debian/Fedora/Arch/etc.)
    ./scripts/install-linux.sh
else
    echo "Unsupported OS: $OS_NAME. Please use cargo run --release --bin centl26."
    cargo run --release --bin centl26
fi
