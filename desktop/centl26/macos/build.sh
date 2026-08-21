#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Build the native, host-architecture CentL26.app without fetching dependencies.

set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPOSITORY_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/../../.." && pwd)"
SOURCE_FILE="$SCRIPT_DIR/Sources/CentL26App.swift"
UPDATER_SOURCE="$SCRIPT_DIR/Sources/CentL26Updater.swift"
SUPERVISOR_SOURCE="$SCRIPT_DIR/Sources/CentL26Supervisor.c"
ATOMIC_PUBLISH_SOURCE="$SCRIPT_DIR/Sources/CentL26AtomicPublish.c"
PLIST_TEMPLATE="$SCRIPT_DIR/Info.plist"
ICON_SOURCE="$SCRIPT_DIR/Assets/CentL26Icon.png"
OUTPUT_DIRECTORY="${CENTL26_OUTPUT_DIR:-$REPOSITORY_ROOT/build/centl26/macos}"
APPLICATION="$OUTPUT_DIRECTORY/CentL26.app"
VERSION="${CENTL26_VERSION:-26.0.0}"
CONFIGURATION="${CENTL26_CONFIGURATION:-release}"
DEPLOYMENT_TARGET="${CENTL26_DEPLOYMENT_TARGET:-13.0}"
HOST_ARCHITECTURE="$(uname -m)"
TARGET_ARCHITECTURE="${CENTL26_ARCHITECTURE:-$HOST_ARCHITECTURE}"
PROVIDER_DIRECTORY="${CENTL26_PROVIDER_DIR:-$REPOSITORY_ROOT/_build/default/src}"
REQUESTED_PROVIDERS="${CENTL26_PROVIDERS:-centl,centl-chem}"
SIGN_IDENTITY="${CENTL26_SIGN_IDENTITY:--}"
NATIVE_POLICY="${CENTL26_NATIVE_POLICY:-permissive}"
SOURCE_DATE_EPOCH_VALUE="${SOURCE_DATE_EPOCH:-${CENTL26_SOURCE_DATE_EPOCH:-}}"
VERIFY_SCRIPT="$REPOSITORY_ROOT/scripts/verify-centl26-macos"

BUILD_COMMIT="${CENTL26_BUILD_COMMIT:-}"
if [ -z "$BUILD_COMMIT" ] && command -v git >/dev/null 2>&1; then
    BUILD_COMMIT="$(git -C "$REPOSITORY_ROOT" rev-parse --verify HEAD 2>/dev/null || true)"
fi
BUILD_COMMIT="${BUILD_COMMIT:-unknown}"

# Public builds keep the product version at 26.0.0. The reachable Git commit
# count strictly increases for descendants without a clock-resolution collision.
# Shallow/source-archive builds must carry the sequence in explicitly.
BUILD_SEQUENCE="${CENTL26_BUILD_SEQUENCE:-}"
if [ -z "$BUILD_SEQUENCE" ] && command -v git >/dev/null 2>&1 \
    && [[ "$BUILD_COMMIT" =~ ^[0-9a-f]{40}$ ]] \
    && git -C "$REPOSITORY_ROOT" cat-file -e "$BUILD_COMMIT^{commit}" 2>/dev/null \
    && [ "$(git -C "$REPOSITORY_ROOT" rev-parse --is-shallow-repository)" = "false" ]
then
    BUILD_SEQUENCE="$(git -C "$REPOSITORY_ROOT" rev-list --count "$BUILD_COMMIT")"
fi
if [[ ! "$BUILD_SEQUENCE" =~ ^[1-9][0-9]{0,3}$ ]]; then
    echo "CENTL26_BUILD_SEQUENCE (1-9999) is required when full Git history is unavailable." >&2
    exit 2
fi
BUILD_SEQUENCE_TEXT="$(printf '%08d' "$BUILD_SEQUENCE")"
BUNDLE_VERSION="$BUILD_SEQUENCE.0.0"
PROVIDER_BUILD_COMMIT=""
if [[ "$BUILD_COMMIT" =~ ^[0-9a-f]{40}$|^[0-9a-f]{64}$ ]]; then
    PROVIDER_BUILD_COMMIT="$BUILD_COMMIT"
fi

SOURCE_STATE="unknown"
if command -v git >/dev/null 2>&1 && git -C "$REPOSITORY_ROOT" rev-parse --verify HEAD >/dev/null 2>&1; then
    if [ -z "$(git -C "$REPOSITORY_ROOT" status --porcelain --untracked-files=normal 2>/dev/null)" ]; then
        SOURCE_STATE="clean"
    else
        SOURCE_STATE="dirty"
    fi
fi

if [ "$VERSION" != "26.0.0" ]; then
    echo "CENTL26_VERSION must remain 26.0.0 for CentL26." >&2
    exit 2
fi
if [[ ! "$DEPLOYMENT_TARGET" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]]; then
    echo "CENTL26_DEPLOYMENT_TARGET must be a numeric macOS version (for example, 13.0)." >&2
    exit 2
fi

if [[ ! "$BUILD_COMMIT" =~ ^[A-Za-z0-9_-]{1,64}$ ]]; then
    echo "CENTL26_BUILD_COMMIT must be 1-64 ASCII letters, numbers, hyphens, or underscores." >&2
    exit 2
fi
case "$NATIVE_POLICY" in
    permissive|pinned) ;;
    *) echo "CENTL26_NATIVE_POLICY must be 'permissive' or 'pinned'." >&2; exit 2 ;;
esac

NATIVE_QUALIFICATION="not-applicable"
NATIVE_GMP_VERSION="not-bundled"
NATIVE_MPFR_VERSION="not-bundled"
NATIVE_FLINT_VERSION="not-bundled"
NATIVE_GMP_SOURCE_HASH="not-bundled"
NATIVE_MPFR_SOURCE_HASH="not-bundled"
NATIVE_FLINT_SOURCE_HASH="not-bundled"

if [ -n "${CENTL26_PROVIDER_DIR:-}" ]; then
    [[ "$CENTL26_PROVIDER_DIR" = /* ]] || { echo "CENTL26_PROVIDER_DIR must be an absolute path." >&2; exit 2; }
    PROVIDER_SOURCE_MODE="external-prebuilt"
    PROVIDER_PROVENANCE="${CENTL26_PROVIDER_PROVENANCE:-}"
    if [ -n "$REQUESTED_PROVIDERS" ] && [[ ! "$PROVIDER_PROVENANCE" =~ ^[A-Za-z0-9._:-]{1,128}$ ]]; then
        echo "CENTL26_PROVIDER_PROVENANCE is required for prebuilt providers (1-128 safe provenance characters)." >&2
        exit 2
    fi
else
    PROVIDER_SOURCE_MODE="repository-offline-build"
    PROVIDER_PROVENANCE="repository:$BUILD_COMMIT"
fi

if [ -n "$SOURCE_DATE_EPOCH_VALUE" ]; then
    if [[ ! "$SOURCE_DATE_EPOCH_VALUE" =~ ^[0-9]+$ ]] || [ "$SOURCE_DATE_EPOCH_VALUE" -lt 315532800 ]; then
        echo "SOURCE_DATE_EPOCH must be an integer at or after 1980-01-01 for ZIP compatibility." >&2
        exit 2
    fi
fi

case "$CONFIGURATION" in
    release)
        CARGO_PROFILE_DIRECTORY="release"
        SWIFT_OPTIMIZATION=(-O -whole-module-optimization)
        ;;
    debug)
        CARGO_PROFILE_DIRECTORY="debug"
        SWIFT_OPTIMIZATION=(-Onone -g)
        ;;
    *)
        echo "CENTL26_CONFIGURATION must be 'release' or 'debug'." >&2
        exit 2
        ;;
esac

case "$TARGET_ARCHITECTURE" in
    arm64)
        RUST_TARGET="aarch64-apple-darwin"
        ;;
    x86_64)
        RUST_TARGET="x86_64-apple-darwin"
        ;;
    *)
        echo "Unsupported CentL26 target architecture: $TARGET_ARCHITECTURE" >&2
        exit 2
        ;;
esac

for required in cargo xcrun plutil sips tiffutil tiff2icns shasum lipo otool install_name_tool realpath; do
    if ! command -v "$required" >/dev/null 2>&1; then
        echo "Required local build tool is unavailable: $required" >&2
        exit 1
    fi
done

if [ "$(uname -s)" != "Darwin" ]; then
    echo "CentL26.app can only be assembled on macOS." >&2
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ] || [ ! -f "$UPDATER_SOURCE" ] \
    || [ ! -f "$SUPERVISOR_SOURCE" ] || [ ! -f "$ATOMIC_PUBLISH_SOURCE" ] \
    || [ ! -f "$PLIST_TEMPLATE" ] || [ ! -f "$ICON_SOURCE" ] \
    || [ ! -x "$VERIFY_SCRIPT" ]; then
    echo "CentL26 native source, verifier, Info.plist, or application icon is missing." >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIRECTORY"
STAGING_APPLICATION="$OUTPUT_DIRECTORY/.CentL26-stage-$$.app"
MODULE_CACHE="$(mktemp -d "${TMPDIR:-/tmp}/centl26-swift-module-cache.XXXXXX")"
ATOMIC_PUBLISH_HELPER="$MODULE_CACHE/centl26-atomic-publish"
SWIFT_ERROR_LOG="$OUTPUT_DIRECTORY/.swift-build-errors.$$"
ICON_WORK_DIRECTORY=""
BUILD_LOCK="$OUTPUT_DIRECTORY/.centl26-build.lock"
BUILD_LOCK_ACQUIRED=0

cleanup() {
    rm -rf -- "$STAGING_APPLICATION"
    if [ "$BUILD_LOCK_ACQUIRED" = "1" ]; then
        rmdir "$BUILD_LOCK" 2>/dev/null || true
    fi
    if [ -n "$ICON_WORK_DIRECTORY" ]; then
        rm -rf -- "$ICON_WORK_DIRECTORY"
    fi
    rm -rf -- "$MODULE_CACHE"
    rm -f -- "$SWIFT_ERROR_LOG"
}
trap cleanup EXIT INT TERM
if mkdir "$BUILD_LOCK"; then
    BUILD_LOCK_ACQUIRED=1
else
    echo "Another CentL26 build owns the output lock: $BUILD_LOCK" >&2
    exit 1
fi

rm -rf -- "$STAGING_APPLICATION"
mkdir -p \
    "$STAGING_APPLICATION/Contents/MacOS" \
    "$STAGING_APPLICATION/Contents/Helpers" \
    "$STAGING_APPLICATION/Contents/Frameworks" \
    "$STAGING_APPLICATION/Contents/Resources/bin" \
    "$STAGING_APPLICATION/Contents/Resources/providers/bin" \
    "$STAGING_APPLICATION/Contents/Resources/licenses" \
    "$MODULE_CACHE"

if [ -n "${CARGO_TARGET_DIR:-}" ]; then
    if [[ "$CARGO_TARGET_DIR" = /* ]]; then
        RESOLVED_CARGO_TARGET="$CARGO_TARGET_DIR"
    else
        RESOLVED_CARGO_TARGET="$REPOSITORY_ROOT/$CARGO_TARGET_DIR"
    fi
else
    RESOLVED_CARGO_TARGET="$REPOSITORY_ROOT/target"
fi

echo "Building embedded centl26 backend (offline, $CONFIGURATION, $TARGET_ARCHITECTURE)"
BACKEND_PROFILE_ROOT="$RESOLVED_CARGO_TARGET"
CARGO_ARGUMENTS=(build --locked --offline --bin centl26)
if [ "$CONFIGURATION" = "release" ]; then
    CARGO_ARGUMENTS+=(--release)
fi
if [ "$TARGET_ARCHITECTURE" != "$HOST_ARCHITECTURE" ]; then
    CARGO_ARGUMENTS+=(--target "$RUST_TARGET")
    BACKEND_PROFILE_ROOT="$RESOLVED_CARGO_TARGET/$RUST_TARGET"
fi
(
    cd "$REPOSITORY_ROOT"
    cargo "${CARGO_ARGUMENTS[@]}"
)

BACKEND_BINARY="$BACKEND_PROFILE_ROOT/$CARGO_PROFILE_DIRECTORY/centl26"
if [ ! -x "$BACKEND_BINARY" ]; then
    echo "Cargo completed without producing the expected backend: $BACKEND_BINARY" >&2
    exit 1
fi
install -m 0755 "$BACKEND_BINARY" "$STAGING_APPLICATION/Contents/Resources/bin/centl26"

SWIFTC="$(xcrun --find swiftc)"
CLANG="$(xcrun --find clang)"
TARGET_TRIPLE="$TARGET_ARCHITECTURE-apple-macos$DEPLOYMENT_TARGET"

SDK_CANDIDATES=()
if [ -n "${CENTL26_MACOS_SDK:-}" ]; then
    SDK_CANDIDATES+=("$CENTL26_MACOS_SDK")
else
    SDK_CANDIDATES+=("$(xcrun --sdk macosx --show-sdk-path)")
    DEVELOPER_DIRECTORY="$(xcode-select -p 2>/dev/null || true)"
    if [ -n "$DEVELOPER_DIRECTORY" ]; then
        for sdk_directory in \
            "$DEVELOPER_DIRECTORY/SDKs" \
            "$DEVELOPER_DIRECTORY/Platforms/MacOSX.platform/Developer/SDKs"
        do
            for candidate in "$sdk_directory"/MacOSX*.sdk; do
                [ -d "$candidate" ] || continue
                SDK_CANDIDATES+=("$candidate")
            done
        done
    fi
fi

echo "Building native AppKit/WebKit launcher ($TARGET_TRIPLE)"
SELECTED_SDK=""
for candidate in "${SDK_CANDIDATES[@]}"; do
    [ -d "$candidate" ] || continue
    if "$SWIFTC" \
        -parse-as-library \
        -swift-version 5 \
        -sdk "$candidate" \
        -target "$TARGET_TRIPLE" \
        -module-cache-path "$MODULE_CACHE" \
        "${SWIFT_OPTIMIZATION[@]}" \
        "$SOURCE_FILE" \
        "$UPDATER_SOURCE" \
        -framework AppKit \
        -framework CryptoKit \
        -framework WebKit \
        -o "$STAGING_APPLICATION/Contents/MacOS/CentL26" \
        2>"$SWIFT_ERROR_LOG"
    then
        SELECTED_SDK="$candidate"
        break
    fi
done

if [ -z "$SELECTED_SDK" ]; then
    echo "The installed Swift compiler could not build CentL26 with any installed macOS SDK." >&2
    cat "$SWIFT_ERROR_LOG" >&2
    exit 1
fi
echo "Using macOS SDK: $SELECTED_SDK"

echo "Building native backend ownership supervisor"
"$CLANG" \
    -std=c11 \
    -Wall \
    -Wextra \
    -Werror \
    -arch "$TARGET_ARCHITECTURE" \
    -isysroot "$SELECTED_SDK" \
    "-mmacosx-version-min=$DEPLOYMENT_TARGET" \
    "$SUPERVISOR_SOURCE" \
    -o "$STAGING_APPLICATION/Contents/Helpers/centl26-supervisor"

echo "Building native atomic publication helper"
"$CLANG" \
    -std=c11 \
    -Wall \
    -Wextra \
    -Werror \
    -arch "$TARGET_ARCHITECTURE" \
    -isysroot "$SELECTED_SDK" \
    "-mmacosx-version-min=$DEPLOYMENT_TARGET" \
    "$ATOMIC_PUBLISH_SOURCE" \
    -o "$STAGING_APPLICATION/Contents/Helpers/centl26-update-installer"

"$CLANG" \
    -std=c11 \
    -Wall \
    -Wextra \
    -Werror \
    -arch "$HOST_ARCHITECTURE" \
    -isysroot "$SELECTED_SDK" \
    "-mmacosx-version-min=$DEPLOYMENT_TARGET" \
    "$ATOMIC_PUBLISH_SOURCE" \
    -o "$ATOMIC_PUBLISH_HELPER"

cp "$PLIST_TEMPLATE" "$STAGING_APPLICATION/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$STAGING_APPLICATION/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "$STAGING_APPLICATION/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :LSMinimumSystemVersion $DEPLOYMENT_TARGET" "$STAGING_APPLICATION/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CentLBuildArchitecture $TARGET_ARCHITECTURE" "$STAGING_APPLICATION/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CentLBuildCommit $BUILD_COMMIT" "$STAGING_APPLICATION/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CentLBuildSequence $BUILD_SEQUENCE" "$STAGING_APPLICATION/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CentLBuildConfiguration $CONFIGURATION" "$STAGING_APPLICATION/Contents/Info.plist"

if [ "${CENTL26_SKIP_CODESIGN:-0}" = "1" ]; then
    SIGNING_MODE="unsigned"
    LAUNCHER_INTEGRITY="architecture-only"
elif [ "$SIGN_IDENTITY" = "-" ]; then
    SIGNING_MODE="adhoc"
    LAUNCHER_INTEGRITY="code-signature"
else
    SIGNING_MODE="developer-id"
    LAUNCHER_INTEGRITY="code-signature"
fi
/usr/libexec/PlistBuddy -c "Set :CentLSigningMode $SIGNING_MODE" "$STAGING_APPLICATION/Contents/Info.plist"
plutil -lint "$STAGING_APPLICATION/Contents/Info.plist" >/dev/null

ICON_WORK_DIRECTORY="$OUTPUT_DIRECTORY/.CentL26.icon.$$"
mkdir -p "$ICON_WORK_DIRECTORY"
for size in 16 32 48 128 256 512 1024; do
    sips -s format tiff -z "$size" "$size" "$ICON_SOURCE" \
        --out "$ICON_WORK_DIRECTORY/icon_$size.tiff" >/dev/null
done
tiffutil -catnosizecheck \
    "$ICON_WORK_DIRECTORY/icon_16.tiff" \
    "$ICON_WORK_DIRECTORY/icon_32.tiff" \
    "$ICON_WORK_DIRECTORY/icon_48.tiff" \
    "$ICON_WORK_DIRECTORY/icon_128.tiff" \
    "$ICON_WORK_DIRECTORY/icon_256.tiff" \
    "$ICON_WORK_DIRECTORY/icon_512.tiff" \
    "$ICON_WORK_DIRECTORY/icon_1024.tiff" \
    -out "$ICON_WORK_DIRECTORY/CentL26.tiff" >/dev/null
tiff2icns \
    "$ICON_WORK_DIRECTORY/CentL26.tiff" \
    "$STAGING_APPLICATION/Contents/Resources/CentL26.icns"
if [ ! -s "$STAGING_APPLICATION/Contents/Resources/CentL26.icns" ]; then
    echo "Native icon conversion did not produce CentL26.icns." >&2
    exit 1
fi
rm -rf -- "$ICON_WORK_DIRECTORY"
ICON_WORK_DIRECTORY=""

sha256_file() {
    shasum -a 256 "$1" | awk '{print $1}'
}

provider_build_target() {
    case "$1" in
        centl) echo "src/main.exe" ;;
        centl-sci) echo "src/sci_main.exe" ;;
        centl-chem) echo "src/chemistry_main.exe" ;;
        centl-cps) echo "src/cps_main.exe" ;;
        centl-mirage) echo "src/mirage_main.exe" ;;
    esac
}

native_prefix() {
    local family="$1"
    local explicit_prefix="$2"
    local family_label
    case "$family" in
        gmp) family_label="GMP" ;;
        mpfr) family_label="MPFR" ;;
        flint) family_label="FLINT" ;;
        *) return 1 ;;
    esac
    if [ -n "$explicit_prefix" ]; then
        [[ "$explicit_prefix" = /* ]] || { echo "CENTL26_${family_label}_PREFIX must be absolute." >&2; return 1; }
        [ -d "$explicit_prefix" ] || { echo "Native prefix does not exist: $explicit_prefix" >&2; return 1; }
        realpath "$explicit_prefix"
        return
    fi

    local candidate
    for candidate in "/opt/homebrew/opt/$family" "/usr/local/opt/$family"; do
        if [ -d "$candidate" ]; then
            realpath "$candidate"
            return
        fi
    done
    echo "Could not locate the local $family development prefix." >&2
    echo "Set CENTL26_${family_label}_PREFIX to its absolute, already-installed prefix." >&2
    return 1
}

toolchain_lock_value() {
    local key="$1"
    awk -v wanted_key="$key" '
        $0 == "[runtime]" { in_runtime = 1; next }
        /^\[/ { in_runtime = 0 }
        in_runtime && $1 == wanted_key && $2 == "=" {
            gsub(/^"|"$/, "", $3)
            print $3
            found = 1
            exit
        }
        END { if (!found) exit 1 }
    ' "$REPOSITORY_ROOT/toolchain.lock"
}

native_pkg_version() {
    local prefix="$1"
    local package="$2"
    PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig:$prefix/share/pkgconfig" \
    PKG_CONFIG_PATH="" \
        pkg-config --modversion "$package"
}

prepare_native_provider_toolchain() {
    [ "${NATIVE_TOOLCHAIN_PREPARED:-0}" != "1" ] || return 0

    NATIVE_GMP_PREFIX="$(native_prefix gmp "${CENTL26_GMP_PREFIX:-}")" || return 1
    NATIVE_MPFR_PREFIX="$(native_prefix mpfr "${CENTL26_MPFR_PREFIX:-}")" || return 1
    NATIVE_FLINT_PREFIX="$(native_prefix flint "${CENTL26_FLINT_PREFIX:-}")" || return 1

    [ -f "$NATIVE_GMP_PREFIX/include/gmp.h" ] \
        || { echo "Missing GMP header: $NATIVE_GMP_PREFIX/include/gmp.h" >&2; return 1; }
    [ -f "$NATIVE_MPFR_PREFIX/include/mpfr.h" ] \
        || { echo "Missing MPFR header: $NATIVE_MPFR_PREFIX/include/mpfr.h" >&2; return 1; }
    [ -f "$NATIVE_FLINT_PREFIX/include/flint/flint.h" ] \
        || { echo "Missing FLINT header: $NATIVE_FLINT_PREFIX/include/flint/flint.h" >&2; return 1; }
    [ -f "$NATIVE_FLINT_PREFIX/include/flint/arb.h" ] \
        || { echo "Missing FLINT Arb header: $NATIVE_FLINT_PREFIX/include/flint/arb.h" >&2; return 1; }

    NATIVE_GMP_LIBRARY="$(realpath "$NATIVE_GMP_PREFIX/lib/libgmp.dylib" 2>/dev/null)" \
        || { echo "Missing GMP dynamic library under $NATIVE_GMP_PREFIX/lib." >&2; return 1; }
    NATIVE_MPFR_LIBRARY="$(realpath "$NATIVE_MPFR_PREFIX/lib/libmpfr.dylib" 2>/dev/null)" \
        || { echo "Missing MPFR dynamic library under $NATIVE_MPFR_PREFIX/lib." >&2; return 1; }
    NATIVE_FLINT_LIBRARY="$(realpath "$NATIVE_FLINT_PREFIX/lib/libflint.dylib" 2>/dev/null)" \
        || { echo "Missing FLINT dynamic library under $NATIVE_FLINT_PREFIX/lib." >&2; return 1; }

    local library
    for library in "$NATIVE_GMP_LIBRARY" "$NATIVE_MPFR_LIBRARY" "$NATIVE_FLINT_LIBRARY"; do
        [ -f "$library" ] || { echo "Native provider library is missing: $library" >&2; return 1; }
        if ! grep -Eq "(^| )$TARGET_ARCHITECTURE( |$)" <<<"$(lipo -archs "$library")"; then
            echo "Native provider library lacks $TARGET_ARCHITECTURE: $library" >&2
            return 1
        fi
    done

    command -v pkg-config >/dev/null 2>&1 \
        || { echo "pkg-config is required to qualify native provider libraries." >&2; return 1; }
    NATIVE_GMP_VERSION="$(native_pkg_version "$NATIVE_GMP_PREFIX" gmp)" || return 1
    NATIVE_MPFR_VERSION="$(native_pkg_version "$NATIVE_MPFR_PREFIX" mpfr)" || return 1
    NATIVE_FLINT_VERSION="$(native_pkg_version "$NATIVE_FLINT_PREFIX" flint)" || return 1
    local version
    for version in "$NATIVE_GMP_VERSION" "$NATIVE_MPFR_VERSION" "$NATIVE_FLINT_VERSION"; do
        [[ "$version" =~ ^[0-9]+(\.[0-9]+){1,3}$ ]] \
            || { echo "Native provider reported an invalid version: $version" >&2; return 1; }
    done

    local pinned_gmp pinned_mpfr pinned_flint
    pinned_gmp="$(toolchain_lock_value gmp)" || return 1
    pinned_mpfr="$(toolchain_lock_value mpfr)" || return 1
    pinned_flint="$(toolchain_lock_value flint)" || return 1
    if [ "$NATIVE_GMP_VERSION" = "$pinned_gmp" ] \
        && [ "$NATIVE_MPFR_VERSION" = "$pinned_mpfr" ] \
        && [ "$NATIVE_FLINT_VERSION" = "$pinned_flint" ]
    then
        NATIVE_QUALIFICATION="pinned-match"
    elif [ "$NATIVE_POLICY" = "pinned" ]; then
        echo "Native toolchain does not match toolchain.lock:" >&2
        echo "  GMP:   $NATIVE_GMP_VERSION (required $pinned_gmp)" >&2
        echo "  MPFR:  $NATIVE_MPFR_VERSION (required $pinned_mpfr)" >&2
        echo "  FLINT: $NATIVE_FLINT_VERSION (required $pinned_flint)" >&2
        return 1
    else
        NATIVE_QUALIFICATION="permissive-unqualified"
        echo "Warning: native provider toolchain is development-only and not release-qualified." >&2
        echo "  GMP:   $NATIVE_GMP_VERSION (policy $pinned_gmp)" >&2
        echo "  MPFR:  $NATIVE_MPFR_VERSION (policy $pinned_mpfr)" >&2
        echo "  FLINT: $NATIVE_FLINT_VERSION (policy $pinned_flint)" >&2
    fi
    NATIVE_GMP_SOURCE_HASH="$(sha256_file "$NATIVE_GMP_LIBRARY")"
    NATIVE_MPFR_SOURCE_HASH="$(sha256_file "$NATIVE_MPFR_LIBRARY")"
    NATIVE_FLINT_SOURCE_HASH="$(sha256_file "$NATIVE_FLINT_LIBRARY")"
    NATIVE_TOOLCHAIN_PREPARED=1
}

build_provider() {
    local provider="$1"
    local target
    target="$(provider_build_target "$provider")"
    local dune_command=()
    if command -v dune >/dev/null 2>&1; then
        dune_command=(dune)
    elif command -v opam >/dev/null 2>&1; then
        dune_command=(opam exec "--switch=${CENTL26_OPAM_SWITCH:-centl}" -- dune)
    else
        return 1
    fi
    prepare_native_provider_toolchain || return 1
    echo "Building requested provider $provider (offline local toolchain)"
    (
        cd "$REPOSITORY_ROOT"
        CENTL_GMP_INCLUDE="-I$NATIVE_GMP_PREFIX/include" \
        CENTL_MPFR_INCLUDE="-I$NATIVE_MPFR_PREFIX/include" \
        CENTL_FLINT_INCLUDE="-I$NATIVE_FLINT_PREFIX/include" \
        CENTL_GMP_LIBRARY="$NATIVE_GMP_LIBRARY" \
        CENTL_MPFR_LIBRARY="$NATIVE_MPFR_LIBRARY" \
        CENTL_FLINT_LIBRARY="$NATIVE_FLINT_LIBRARY" \
        CENTL_BUILD_COMMIT="$PROVIDER_BUILD_COMMIT" \
            "${dune_command[@]}" build "$target"
    )
}

provider_source() {
    case "$1" in
        centl)
            for candidate in "$PROVIDER_DIRECTORY/centl" "$PROVIDER_DIRECTORY/main.exe"; do
                [ -x "$candidate" ] && { echo "$candidate"; return 0; }
            done
            ;;
        centl-sci)
            for candidate in "$PROVIDER_DIRECTORY/centl-sci" "$PROVIDER_DIRECTORY/sci_main.exe"; do
                [ -x "$candidate" ] && { echo "$candidate"; return 0; }
            done
            ;;
        centl-chem)
            for candidate in "$PROVIDER_DIRECTORY/centl-chem" "$PROVIDER_DIRECTORY/chemistry_main.exe"; do
                [ -x "$candidate" ] && { echo "$candidate"; return 0; }
            done
            ;;
        centl-cps)
            for candidate in "$PROVIDER_DIRECTORY/centl-cps" "$PROVIDER_DIRECTORY/cps_main.exe"; do
                [ -x "$candidate" ] && { echo "$candidate"; return 0; }
            done
            ;;
        centl-mirage)
            for candidate in "$PROVIDER_DIRECTORY/centl-mirage" "$PROVIDER_DIRECTORY/mirage_main.exe"; do
                [ -x "$candidate" ] && { echo "$candidate"; return 0; }
            done
            ;;
    esac
    return 1
}

provider_role() {
    case "$1" in
        centl) echo "formal-mathematics" ;;
        centl-sci) echo "scientific-interpretation" ;;
        centl-chem) echo "chemistry" ;;
        centl-cps) echo "chemical-process-systems" ;;
        centl-mirage) echo "development-workbench" ;;
    esac
}

non_system_dependencies() {
    local executable="$1"
    local dependency
    while IFS= read -r dependency; do
        dependency="${dependency#${dependency%%[![:space:]]*}}"
        dependency="${dependency%% *}"
        [ -n "$dependency" ] || continue
        case "$dependency" in
            /System/Library/*|/usr/lib/*) ;;
            *) echo "$dependency" ;;
        esac
    done < <(otool -L "$executable" | tail -n +2)
}

runtime_library_family() {
    case "$(basename -- "$1")" in
        libflint.*.dylib) echo "flint" ;;
        libmpfr.*.dylib) echo "mpfr" ;;
        libgmp.*.dylib) echo "gmp" ;;
        *) return 1 ;;
    esac
}

copy_runtime_library_licenses() {
    local family="$1"
    local source="$2"
    local seen
    if [ "${#BUNDLED_LICENSE_FAMILIES[@]}" -gt 0 ]; then
        for seen in "${BUNDLED_LICENSE_FAMILIES[@]}"; do
            [ "$seen" != "$family" ] || return 0
        done
    fi

    local prefix="${source%/lib/*}"
    local license_directory="$STAGING_APPLICATION/Contents/Resources/licenses/$family"
    mkdir -p "$license_directory"
    local copied=0
    local license
    while IFS= read -r license; do
        install -m 0644 "$license" "$license_directory/$(basename -- "$license")"
        copied=1
    done < <(find -H "$prefix" -maxdepth 1 -type f \( -name 'COPYING*' -o -name 'LICENSE*' \) -print | LC_ALL=C sort)
    if [ "$copied" != "1" ]; then
        echo "No distributable license text was found for $family at $prefix." >&2
        exit 1
    fi
    BUNDLED_LICENSE_FAMILIES+=("$family")
}

bundle_runtime_library() {
    local source="$1"
    local family
    if ! family="$(runtime_library_family "$source")"; then
        echo "Unsupported external provider dependency: $source" >&2
        echo "CentL26 only relocates the audited FLINT, MPFR, and GMP runtime closure." >&2
        exit 1
    fi
    [ -f "$source" ] || { echo "Provider dependency is missing: $source" >&2; exit 1; }

    local name="$(basename -- "$source")"
    [[ "$name" =~ ^[A-Za-z0-9._-]{1,128}$ ]] \
        || { echo "Runtime library has an unsafe bundle name: $name" >&2; exit 1; }
    local index
    for ((index = 0; index < ${#BUNDLED_LIBRARY_NAMES[@]}; index++)); do
        if [ "${BUNDLED_LIBRARY_NAMES[$index]}" = "$name" ]; then
            if [ "$(sha256_file "${BUNDLED_LIBRARY_SOURCES[$index]}")" != "$(sha256_file "$source")" ]; then
                echo "Conflicting runtime libraries share the bundle name $name." >&2
                exit 1
            fi
            return 0
        fi
    done

    local source_architectures
    source_architectures="$(lipo -archs "$source")"
    if ! grep -Eq "(^| )$TARGET_ARCHITECTURE( |$)" <<<"$source_architectures"; then
        echo "Runtime library $source does not contain target architecture $TARGET_ARCHITECTURE." >&2
        exit 1
    fi

    local destination="$STAGING_APPLICATION/Contents/Frameworks/$name"
    if [ "$source_architectures" = "$TARGET_ARCHITECTURE" ]; then
        install -m 0755 "$source" "$destination"
    else
        lipo "$source" -thin "$TARGET_ARCHITECTURE" -output "$destination"
        chmod 0755 "$destination"
    fi
    BUNDLED_LIBRARY_NAMES+=("$name")
    BUNDLED_LIBRARY_SOURCES+=("$source")
    BUNDLED_LIBRARY_FAMILIES+=("$family")
    copy_runtime_library_licenses "$family" "$source"
}

BUNDLED_PROVIDER_IDS=()
BUNDLED_PROVIDER_ROLES=()
BUNDLED_LIBRARY_NAMES=()
BUNDLED_LIBRARY_SOURCES=()
BUNDLED_LIBRARY_FAMILIES=()
BUNDLED_LICENSE_FAMILIES=()
if [ "$REQUESTED_PROVIDERS" = "all" ]; then
    REQUESTED_PROVIDERS="centl,centl-sci,centl-chem,centl-cps,centl-mirage"
fi
SEEN_PROVIDERS=","
for provider in ${REQUESTED_PROVIDERS//,/ }; do
    case "$provider" in
        centl|centl-sci|centl-chem|centl-cps|centl-mirage) ;;
        *)
            echo "Unknown CENTL26_PROVIDERS entry: $provider" >&2
            exit 2
            ;;
    esac
    if [[ "$SEEN_PROVIDERS" == *",$provider,"* ]]; then
        echo "Duplicate CENTL26_PROVIDERS entry: $provider" >&2
        exit 2
    fi
    SEEN_PROVIDERS+="$provider,"

    if [ "$PROVIDER_SOURCE_MODE" = "repository-offline-build" ]; then
        if ! build_provider "$provider"; then
            echo "The repository provider build failed for $provider; refusing stale Dune output." >&2
            exit 1
        fi
    fi
    if ! source_path="$(provider_source "$provider")"; then
        echo "Requested provider $provider was not found in $PROVIDER_DIRECTORY." >&2
        echo "Build it locally, or set CENTL26_PROVIDER_DIR and CENTL26_PROVIDER_PROVENANCE for audited prebuilts." >&2
        exit 1
    fi
    source_architectures="$(lipo -archs "$source_path")"
    if ! grep -Eq "(^| )$TARGET_ARCHITECTURE( |$)" <<<"$source_architectures"; then
        echo "Provider $provider does not contain target architecture $TARGET_ARCHITECTURE." >&2
        exit 1
    fi
    destination="$STAGING_APPLICATION/Contents/Resources/providers/bin/$provider"
    if [ "$source_architectures" = "$TARGET_ARCHITECTURE" ]; then
        install -m 0755 "$source_path" "$destination"
    else
        lipo "$source_path" -thin "$TARGET_ARCHITECTURE" -output "$destination"
        chmod 0755 "$destination"
    fi

    while IFS= read -r dependency; do
        [ -n "$dependency" ] || continue
        bundle_runtime_library "$dependency"
        install_name_tool -change "$dependency" \
            "@executable_path/../../../Frameworks/$(basename -- "$dependency")" \
            "$destination"
    done < <(non_system_dependencies "$source_path")
    BUNDLED_PROVIDER_IDS+=("$provider")
    BUNDLED_PROVIDER_ROLES+=("$(provider_role "$provider")")
done

# Close and relocate the runtime dependency graph. New libraries discovered
# while walking the graph are appended to the arrays and visited in turn.
for ((library_index = 0; library_index < ${#BUNDLED_LIBRARY_NAMES[@]}; library_index++)); do
    library_name="${BUNDLED_LIBRARY_NAMES[$library_index]}"
    library_source="${BUNDLED_LIBRARY_SOURCES[$library_index]}"
    library_destination="$STAGING_APPLICATION/Contents/Frameworks/$library_name"
    install_name_tool -id "@rpath/$library_name" "$library_destination"
    while IFS= read -r dependency; do
        [ -n "$dependency" ] || continue
        if [ "$(basename -- "$dependency")" = "$library_name" ]; then
            continue
        fi
        bundle_runtime_library "$dependency"
        install_name_tool -change "$dependency" \
            "@loader_path/$(basename -- "$dependency")" \
            "$library_destination"
    done < <(non_system_dependencies "$library_source")
done

if [ "${#BUNDLED_LIBRARY_NAMES[@]}" -gt 0 ] && [ "$NATIVE_QUALIFICATION" = "not-applicable" ]; then
    NATIVE_QUALIFICATION="external-unqualified"
    NATIVE_GMP_VERSION="unknown"
    NATIVE_MPFR_VERSION="unknown"
    NATIVE_FLINT_VERSION="unknown"
    for ((library_index = 0; library_index < ${#BUNDLED_LIBRARY_NAMES[@]}; library_index++)); do
        library_source="${BUNDLED_LIBRARY_SOURCES[$library_index]}"
        case "${BUNDLED_LIBRARY_FAMILIES[$library_index]}" in
            gmp) NATIVE_GMP_SOURCE_HASH="$(sha256_file "$library_source")" ;;
            mpfr) NATIVE_MPFR_SOURCE_HASH="$(sha256_file "$library_source")" ;;
            flint) NATIVE_FLINT_SOURCE_HASH="$(sha256_file "$library_source")" ;;
        esac
    done
fi

install -m 0644 "$REPOSITORY_ROOT/LICENSE" \
    "$STAGING_APPLICATION/Contents/Resources/licenses/CentL26-Apache-2.0.txt"
install -m 0644 "$REPOSITORY_ROOT/NOTICE" \
    "$STAGING_APPLICATION/Contents/Resources/licenses/NOTICE.txt"
install -m 0644 "$REPOSITORY_ROOT/THIRD_PARTY_NOTICES.md" \
    "$STAGING_APPLICATION/Contents/Resources/licenses/THIRD_PARTY_NOTICES.md"

sign_code() {
    local path="$1"
    [ "$SIGNING_MODE" != "unsigned" ] || return 0
    local arguments=(--force --sign "$SIGN_IDENTITY")
    if [ "$SIGNING_MODE" = "adhoc" ]; then
        arguments+=(--timestamp=none)
    else
        arguments+=(--options runtime)
        if [ "${CENTL26_CODESIGN_TIMESTAMP:-secure}" = "none" ]; then
            arguments+=(--timestamp=none)
        else
            arguments+=(--timestamp)
        fi
        if [ -n "${CENTL26_CODESIGN_KEYCHAIN:-}" ]; then
            arguments+=(--keychain "$CENTL26_CODESIGN_KEYCHAIN")
        fi
    fi
    codesign "${arguments[@]}" "$path"
}

if [ "$SIGNING_MODE" != "unsigned" ]; then
    command -v codesign >/dev/null 2>&1 || { echo "codesign is required for $SIGNING_MODE signing." >&2; exit 1; }
    echo "Applying $SIGNING_MODE code signatures"
fi
sign_code "$STAGING_APPLICATION/Contents/Resources/bin/centl26"
sign_code "$STAGING_APPLICATION/Contents/Helpers/centl26-supervisor"
sign_code "$STAGING_APPLICATION/Contents/Helpers/centl26-update-installer"
sign_code "$STAGING_APPLICATION/Contents/MacOS/CentL26"
if [ "${#BUNDLED_LIBRARY_NAMES[@]}" -gt 0 ]; then
    for library_name in "${BUNDLED_LIBRARY_NAMES[@]}"; do
        sign_code "$STAGING_APPLICATION/Contents/Frameworks/$library_name"
    done
fi
if [ "${#BUNDLED_PROVIDER_IDS[@]}" -gt 0 ]; then
    for provider in "${BUNDLED_PROVIDER_IDS[@]}"; do
        sign_code "$STAGING_APPLICATION/Contents/Resources/providers/bin/$provider"
    done
fi

PROVIDER_MANIFEST="$STAGING_APPLICATION/Contents/Resources/providers/providers.json"
{
    printf '{\n'
    printf '  "schema": "org.freecomputation.centl.provider-inventory/1",\n'
    printf '  "product_version": "%s",\n' "$VERSION"
    printf '  "build_commit": "%s",\n' "$BUILD_COMMIT"
    printf '  "build_sequence": %s,\n' "$BUILD_SEQUENCE"
    printf '  "integration": "explicit-environment",\n'
    printf '  "providers": ['
    for ((index = 0; index < ${#BUNDLED_PROVIDER_IDS[@]}; index++)); do
        provider="${BUNDLED_PROVIDER_IDS[$index]}"
        role="${BUNDLED_PROVIDER_ROLES[$index]}"
        provider_hash="$(sha256_file "$STAGING_APPLICATION/Contents/Resources/providers/bin/$provider")"
        [ "$index" -eq 0 ] || printf ','
        printf '\n    {'
        printf '"id":"%s","path":"bin/%s","sha256":"%s",' "$provider" "$provider" "$provider_hash"
        printf '"source":"%s","provenance":"%s",' "$PROVIDER_SOURCE_MODE" "$PROVIDER_PROVENANCE"
        case "$provider" in
            centl)
                printf '"role":"%s","capabilities":[' "$role"
                printf '"org.fcf.centl.numerics.enclose"],'
                printf '"operations":["approx"],'
                printf '"activation":"backend-adapter"}'
                ;;
            centl-chem)
                printf '"role":"%s","capabilities":[' "$role"
                printf '"org.fcf.centl.chemistry.compute"],'
                printf '"operations":["atoms","balance"],'
                printf '"activation":"backend-adapter"}'
                ;;
            *)
                printf '"role":"%s","capabilities":[],"activation":"broker-contract-required"}' "$role"
                ;;
        esac
    done
    if [ "${#BUNDLED_PROVIDER_IDS[@]}" -gt 0 ]; then
        printf '\n  '
    fi
    printf ']\n}\n'
} >"$PROVIDER_MANIFEST"
plutil -convert json -o /dev/null -- "$PROVIDER_MANIFEST"

SUPERVISOR_HASH="$(sha256_file "$STAGING_APPLICATION/Contents/Helpers/centl26-supervisor")"
UPDATE_INSTALLER_HASH="$(sha256_file "$STAGING_APPLICATION/Contents/Helpers/centl26-update-installer")"
BACKEND_HASH="$(sha256_file "$STAGING_APPLICATION/Contents/Resources/bin/centl26")"
BUILD_MANIFEST="$STAGING_APPLICATION/Contents/Resources/build-manifest.json"
PINNED_GMP_VERSION="$(toolchain_lock_value gmp)"
PINNED_MPFR_VERSION="$(toolchain_lock_value mpfr)"
PINNED_FLINT_VERSION="$(toolchain_lock_value flint)"
{
    printf '{\n'
    printf '  "schema": "org.freecomputation.centl.build/1",\n'
    printf '  "product": "CentL26",\n'
    printf '  "product_version": "%s",\n' "$VERSION"
    printf '  "bundle_identifier": "org.freecomputation.centl",\n'
    printf '  "build_commit": "%s",\n' "$BUILD_COMMIT"
    printf '  "build_sequence": %s,\n' "$BUILD_SEQUENCE"
    printf '  "source_state": "%s",\n' "$SOURCE_STATE"
    printf '  "configuration": "%s",\n' "$CONFIGURATION"
    printf '  "deployment_target": "%s",\n' "$DEPLOYMENT_TARGET"
    printf '  "architecture": "%s",\n' "$TARGET_ARCHITECTURE"
    printf '  "signing": "%s",\n' "$SIGNING_MODE"
    if [ -n "$SOURCE_DATE_EPOCH_VALUE" ]; then
        printf '  "source_date_epoch": %s,\n' "$SOURCE_DATE_EPOCH_VALUE"
    else
        printf '  "source_date_epoch": null,\n'
    fi
    printf '  "provider_manifest": "providers/providers.json",\n'
    printf '  "native_runtime": {\n'
    printf '    "policy": "%s",\n' "$NATIVE_POLICY"
    printf '    "qualification": "%s",\n' "$NATIVE_QUALIFICATION"
    printf '    "gmp": {"version":"%s","pinned_version":"%s","source_sha256":"%s"},\n' \
        "$NATIVE_GMP_VERSION" "$PINNED_GMP_VERSION" "$NATIVE_GMP_SOURCE_HASH"
    printf '    "mpfr": {"version":"%s","pinned_version":"%s","source_sha256":"%s"},\n' \
        "$NATIVE_MPFR_VERSION" "$PINNED_MPFR_VERSION" "$NATIVE_MPFR_SOURCE_HASH"
    printf '    "flint": {"version":"%s","pinned_version":"%s","source_sha256":"%s"}\n' \
        "$NATIVE_FLINT_VERSION" "$PINNED_FLINT_VERSION" "$NATIVE_FLINT_SOURCE_HASH"
    printf '  },\n'
    printf '  "runtime_libraries": ['
    for ((index = 0; index < ${#BUNDLED_LIBRARY_NAMES[@]}; index++)); do
        library_name="${BUNDLED_LIBRARY_NAMES[$index]}"
        library_family="${BUNDLED_LIBRARY_FAMILIES[$index]}"
        library_hash="$(sha256_file "$STAGING_APPLICATION/Contents/Frameworks/$library_name")"
        [ "$index" -eq 0 ] || printf ','
        printf '\n    {'
        printf '"name":"%s","path":"Frameworks/%s","sha256":"%s","family":"%s"}' \
            "$library_name" "$library_name" "$library_hash" "$library_family"
    done
    if [ "${#BUNDLED_LIBRARY_NAMES[@]}" -gt 0 ]; then
        printf '\n  '
    fi
    printf '],\n'
    printf '  "components": {\n'
    printf '    "launcher": {"path":"MacOS/CentL26","integrity":"%s"},\n' "$LAUNCHER_INTEGRITY"
    printf '    "supervisor": {"path":"Helpers/centl26-supervisor","sha256":"%s"},\n' "$SUPERVISOR_HASH"
    printf '    "update_installer": {"path":"Helpers/centl26-update-installer","sha256":"%s"},\n' "$UPDATE_INSTALLER_HASH"
    printf '    "backend": {"path":"Resources/bin/centl26","sha256":"%s"}\n' "$BACKEND_HASH"
    printf '  }\n}\n'
} >"$BUILD_MANIFEST"
plutil -convert json -o /dev/null -- "$BUILD_MANIFEST"

sign_code "$STAGING_APPLICATION"

if [ -n "$SOURCE_DATE_EPOCH_VALUE" ]; then
    NORMALIZED_TIME="$(TZ=UTC date -r "$SOURCE_DATE_EPOCH_VALUE" '+%Y%m%d%H%M.%S')"
    find "$STAGING_APPLICATION" -exec touch -h -t "$NORMALIZED_TIME" {} +
fi

RUN_BUNDLE_SELF_TEST=1
if [ "${CENTL26_SKIP_SELF_TEST:-0}" = "1" ]; then
    RUN_BUNDLE_SELF_TEST=0
fi
echo "Verifying staged application composition"
CENTL26_EXPECTED_VERSION="$VERSION" \
CENTL26_EXPECTED_ARCHITECTURE="$TARGET_ARCHITECTURE" \
CENTL26_EXPECTED_PROVIDERS="$REQUESTED_PROVIDERS" \
CENTL26_RUN_SELF_TEST="$RUN_BUNDLE_SELF_TEST" \
CENTL26_RUN_CHEMISTRY_SMOKE="$RUN_BUNDLE_SELF_TEST" \
    "$VERIFY_SCRIPT" "$STAGING_APPLICATION"

case "$APPLICATION" in
    "$OUTPUT_DIRECTORY/CentL26.app") ;;
    *)
        echo "Refusing to replace an unexpected application path: $APPLICATION" >&2
        exit 1
        ;;
esac
if [ -L "$APPLICATION" ] || { [ -e "$APPLICATION" ] && [ ! -d "$APPLICATION" ]; }; then
    echo "Refusing to replace a non-directory CentL26 application path: $APPLICATION" >&2
    exit 1
fi
if [ -d "$APPLICATION" ]; then
    "$ATOMIC_PUBLISH_HELPER" --swap "$STAGING_APPLICATION" "$APPLICATION" \
        || { echo "Atomic CentL26 application swap failed." >&2; exit 1; }
    rm -rf -- "$STAGING_APPLICATION"
else
    "$ATOMIC_PUBLISH_HELPER" "$STAGING_APPLICATION" "$APPLICATION" \
        || { echo "Exclusive CentL26 application publication failed." >&2; exit 1; }
fi
[ -d "$APPLICATION/Contents" ] && [ ! -L "$APPLICATION" ] \
    || { echo "Published CentL26 application topology is invalid." >&2; exit 1; }
[ ! -e "$STAGING_APPLICATION" ] \
    || { echo "CentL26 staging path remained after publication." >&2; exit 1; }

rmdir "$BUILD_LOCK"
BUILD_LOCK_ACQUIRED=0

trap - EXIT INT TERM
rm -rf -- "$MODULE_CACHE"
rm -f -- "$SWIFT_ERROR_LOG"

echo
echo "CentL26 is ready:"
echo "  $APPLICATION"
echo
echo "Open it with:"
echo "  open \"$APPLICATION\""
echo
echo "Validate the packaged backend lifecycle with:"
echo "  \"$APPLICATION/Contents/MacOS/CentL26\" --self-test"
echo
echo "Inspect runtime configuration with:"
echo "  \"$APPLICATION/Contents/MacOS/CentL26\" --diagnostics"
