# CentL26 native macOS application

This directory packages the dedicated `centl26` Cargo target in a native,
standalone macOS application. AppKit owns the window and lifecycle, WebKit
renders the private loopback IDE, and the bundled Rust executable remains the
authoritative host. A small native supervisor makes backend ownership survive
abnormal GUI termination.

The build path does not fetch dependencies. The finished application does not
need a package manager, JavaScript runtime, external browser, CDN, or Homebrew
installation at runtime.

## Local build

Requirements:

- macOS 13 or newer;
- Apple Command Line Tools or Xcode with Swift, AppKit, and WebKit;
- an installed Rust toolchain with this repository's locked crates available;
- for the default mathematics and chemistry providers, the repository's local OCaml/opam build
  environment and its installed FLINT, MPFR, and GMP libraries.

From the repository root:

```sh
./scripts/build-centl26-macos
```

The command performs an offline Rust build, builds or locates `centl` and
`centl-chem`, relocates their audited FLINT/MPFR/GMP closure into the app, signs
nested code in dependency order, verifies bundle composition, and runs lifecycle,
rigorous-numerics, and chemistry smoke tests. It emits:

```text
build/centl26/macos/CentL26.app
```

Open it with Finder or:

```sh
open build/centl26/macos/CentL26.app
```

Useful commands:

```sh
# Static composition and packaged runtime checks
make centl26-app-verify

# Backend ownership/readiness and rigorous numerics without a window
build/centl26/macos/CentL26.app/Contents/MacOS/CentL26 --self-test

# Exercise the bundled chemistry adapter end to end
build/centl26/macos/CentL26.app/Contents/MacOS/CentL26 --self-test-chemistry

# Validate the offline automatic-update manifest/installer contract
build/centl26/macos/CentL26.app/Contents/MacOS/CentL26 --self-test-updater

# Print bundle, build, state, log, and provider locations
build/centl26/macos/CentL26.app/Contents/MacOS/CentL26 --diagnostics
```

Common build overrides:

```sh
CENTL26_CONFIGURATION=debug ./scripts/build-centl26-macos
CENTL26_OUTPUT_DIR=/absolute/output/path ./scripts/build-centl26-macos
CENTL26_MACOS_SDK=/absolute/path/to/MacOSX.sdk ./scripts/build-centl26-macos
CENTL26_ARCHITECTURE=x86_64 ./scripts/build-centl26-macos
CENTL26_PROVIDERS=centl,centl-chem,centl-sci ./scripts/build-centl26-macos
CENTL26_PROVIDER_DIR=/absolute/prebuilt/provider/directory \
CENTL26_PROVIDER_PROVENANCE=sha256:… ./scripts/build-centl26-macos
CENTL26_NATIVE_POLICY=pinned ./scripts/build-centl26-macos
CENTL26_GMP_PREFIX=/absolute/gmp-prefix CENTL26_MPFR_PREFIX=/absolute/mpfr-prefix \
CENTL26_FLINT_PREFIX=/absolute/flint-prefix ./scripts/build-centl26-macos
SOURCE_DATE_EPOCH=1787184000 ./scripts/build-centl26-macos
CENTL26_SKIP_SELF_TEST=1 ./scripts/build-centl26-macos
CENTL26_SKIP_CODESIGN=1 ./scripts/build-centl26-macos
```

The bundle's internal version remains `26.0.0` throughout the mutable CentL26
channel; the source commit and build manifest identify its exact composition.
The stable bundle identifier is `org.freecomputation.centl`.

The default provider set is `centl,centl-chem`. Both executables have explicit
backend adapters: `centl` owns rigorous `approx(...)` enclosures and `centl-chem`
owns atom counting and reaction balancing. `CENTL26_PROVIDERS=all` inventories
the additional `centl-sci`, `centl-cps`, and `centl-mirage` executables when
compatible local builds are available. Those additional binaries are deliberately
marked `broker-contract-required` in `providers.json`; bundling them does not
pretend that an unimplemented UI/runtime adapter exists.

Only the audited FLINT, MPFR, and GMP dynamic-library families are eligible for
relocation. An unknown external dependency, missing target architecture,
missing license text, conflicting library basename, or residual build-machine
path fails the build. Corresponding license files and the repository's third-
party notices ship in `Contents/Resources/licenses`.

Repository-owned providers are rebuilt on every app build; stale Dune output is
never accepted. An external provider directory must be absolute and accompanied
by `CENTL26_PROVIDER_PROVENANCE`. The builder discovers native headers and
libraries from audited prefixes, sets all six Dune native-toolchain variables,
and records exact pkg-config versions and source-library hashes. The default
`permissive` policy labels a mismatched local toolchain
`permissive-unqualified`; `CENTL26_NATIVE_POLICY=pinned` fails unless GMP, MPFR,
and FLINT exactly match `toolchain.lock`.

## Runtime contract

1. The launcher starts only its bundled `centl26 PORT` service through the
   bundled ownership supervisor.
2. The preferred endpoint is `http://127.0.0.1:2626`. If occupied, the launcher
   tries only `2627` through `2635` and reports the selected fallback.
3. A port is accepted only while the owned process is alive and the expected
   readiness marker is returned from `/__centl26`.
4. WebKit main-frame navigation is restricted to that exact loopback origin.
5. Normal quit terminates the service. If the GUI is force-killed, the
   supervisor detects loss of its original parent and terminates the service.
6. The child receives a small, explicit environment rather than inheriting
   shell secrets or dynamic-loader variables.
7. The Update control posts `{action: "check"}` only to the native
   `centl26Update` WebKit handler. An ordinary browser reports that automatic
   updates require the macOS app; it never redirects to a repository page.
8. A release build reads only the exact GitHub release tagged `centl26` and
   titled `CentL26`, then requires its complete architecture-specific asset set.
   The same build commit reports up to date. A different build is downloaded
   only after user confirmation, verified, then handed to the atomic installer
   for replacement and relaunch.

Persistent project/session state lives at:

```text
~/Library/Application Support/Free Computation Foundation/CentL26
```

Launcher diagnostics rotate under that directory in `Logs/launcher.log`.
`CENTL26_STATE_DIR` may override the location for isolated automation only when
it is an absolute, dedicated path. Existing components are opened without
following symlinks; broad, foreign-owned, or group/world-writable targets are
refused without changing their permissions.

## Bundle layout

```text
CentL26.app/
└── Contents/
    ├── Info.plist
    ├── MacOS/CentL26
    ├── Helpers/
    │   ├── centl26-supervisor
    │   └── centl26-update-installer
    ├── Frameworks/
    │   ├── libflint…dylib
    │   ├── libmpfr…dylib
    │   └── libgmp…dylib
    └── Resources/
        ├── CentL26.icns
        ├── build-manifest.json
        ├── bin/centl26
        ├── licenses/
        └── providers/
            ├── providers.json
            └── bin/
                ├── centl
                └── centl-chem
```

The icon is packaged from `Assets/CentL26Icon.png`, the rendered cobalt-and-
white C26 instrument mark. `Assets/CentL26Icon.svg` remains the editable vector
source.

## Signing, archive, and notarization

Local builds receive an ad-hoc signature by default. A Developer ID build uses
the same composition path with hardened runtime enabled:

```sh
CENTL26_SIGN_IDENTITY="Developer ID Application: Free Computation Foundation (…)" \
CENTL26_CODESIGN_KEYCHAIN=/absolute/path/to/build.keychain-db \
./scripts/build-centl26-macos
```

Create a verified ZIP, checksum, and machine-readable release manifest with:

```sh
./scripts/package-centl26-macos
```

Public release packaging is admitted only for a clean, immutable source build
with Developer ID signing and a pinned native-runtime match. To exercise the
archive machinery with an ad-hoc or permissive development build, opt in
explicitly; its name is permanently marked `-local`:

```sh
CENTL26_ALLOW_UNQUALIFIED_PACKAGE=1 ./scripts/package-centl26-macos
```

The three artifacts are published together in one immutable `.release`
directory using a no-clobber atomic rename. Reusing the same version succeeds
only if the complete existing artifact set is byte-identical.

For notarization, first configure an Apple `notarytool` keychain profile outside
the repository, then opt into the network submission:

```sh
CENTL26_NOTARIZE=1 \
CENTL26_NOTARY_KEYCHAIN_PROFILE=fcf-centl-release \
CENTL26_REQUIRE_DEVELOPER_ID=1 \
./scripts/package-centl26-macos
```

The packaging script refuses notarization for a non-Developer-ID bundle,
waits for Apple's result, staples and validates the ticket, runs Gatekeeper
assessment, re-verifies the bundle, and only then publishes archive artifacts.
Credentials are never accepted as command-line values or written into output.

### Automatic-update publication

CentL26 stays publicly named **CentL26** and keeps internal version `26.0.0`.
Automatic updates use the immutable `build_commit` inside the release manifest;
they do not create a numbered public suffix or another product name.

For each architecture, the published GitHub release tagged `centl26` and titled
`CentL26` must contain this exact qualified asset set:

```text
CentL26-26.0.0-macos-arm64.zip
CentL26-26.0.0-macos-arm64.zip.sha256
CentL26-26.0.0-macos-arm64.release.json
```

Use `x86_64` in all three names for that architecture. The updater ignores
drafts, prereleases, incomplete sets, `-local` packages, and differently named
assets. It also requires the manifest to say clean source, pinned native
runtime, Developer ID signing, and notarization; it verifies both published
digest records, the extracted app/build identities, Gatekeeper acceptance, and
the same Developer ID team as the installed copy.

After the notarized package command above succeeds, publish its exact bytes with:

```sh
./scripts/publish-centl26-macos-update
```

The publisher revalidates the local asset topology and bytes. It reuses the
remote triplet only when all three files are byte-identical. For a different
qualified build it removes the old manifest first, replaces the old archive and
checksum, uploads the new manifest last, and reads all three assets back. A
failed replacement is therefore incomplete and invisible to the updater rather
than mixed-generation. The current
`CentL26-26.0.0-controls-macos-arm64` local assets do not satisfy this contract
and are intentionally not auto-installable.

At install time, the app must live in a user-writable parent directory. The
installer waits for the running app to exit, atomically swaps the verified app
on the same volume, and relaunches it. If the swap fails, the destination is
unchanged and the helper reopens the known-good installed copy. If launching
the new copy fails after a swap, the helper swaps the old copy back and reopens
it. Ad-hoc, dirty, unpinned, unsigned, or unstapled local builds report
automatic updating as unavailable rather than masquerading as a publishable
update.

## Release limitations

- Each build is one architecture. Cross-architecture assembly requires the
  matching Rust target plus matching prebuilt provider and dynamic-library
  slices. A universal release should merge separately qualified arm64 and
  x86_64 outputs in controlled release automation; this script does not claim
  to manufacture missing slices.
- `SOURCE_DATE_EPOCH` normalizes bundle timestamps and stabilizes local archive
  inputs, but Apple notarization tickets and compiler/linker provenance are
  external inputs. Bit-for-bit reproducibility still requires pinned matching
  toolchains on clean builders.
- Ad-hoc signing is for local validation. Passing the verifier does not by
  itself confer Developer ID trust, notarization, or public release approval.
