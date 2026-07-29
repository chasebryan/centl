# Install CENTL

Ordinary users install a verified prebuilt release. They do not need F*, OPAM,
OCaml, Dune, a C compiler, or development headers.

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install
less install
sh install
```

The installer downloads the current release, verifies its SHA-256 checksum,
and installs entirely below `~/.local` without `sudo`. Run it again with a new
release to upgrade the `~/.local/bin/centl` link.

Install a specific release or another prefix with:

```sh
sh install --version 0.6.0
sh install --prefix "$HOME/software"
```

The first binary target is Linux x86_64 with glibc 2.35 or newer. The release
contains CENTL and its FLINT, GMP, and MPFR runtime libraries. Those libraries
are private to CENTL and do not replace system libraries.

Linux x86_64 is the first target, not a permanent platform boundary. Native
macOS and Windows packages will follow with the same numerical behavior,
versioned archive layout, verification checks, and clean-machine tests.

## Verify an offline archive

Keep the archive and its adjacent `.sha256` file together, then run:

```sh
sh install --archive ./centl-linux-x86_64.tar.gz
```

## Build from source

Contributors still use the verified source toolchain described in
[TOOLCHAIN.md](TOOLCHAIN.md). A source build intentionally requires F*, the
`centl` OPAM switch, FLINT development files, and the native compiler toolchain.

```sh
make test
```

Maintainers build the same archive locally with:

```sh
make release VERSION=0.6.0-dev
```

Tagged `v*` commits run the release workflow on Ubuntu 22.04, verify pinned F*
and FLINT downloads, run the complete test suite, and publish the archive and
checksum. Manual workflow runs produce an artifact without publishing a GitHub
release.
