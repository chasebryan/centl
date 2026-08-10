# CENTL-SCi runtime preservation

Status: required recovery infrastructure for the local-model CENTL-SCi path.

Preserving a GGUF model without preserving a compatible inference runtime is not
a complete recovery plan. CENTL-SCi therefore treats three objects as one
recoverable local-model stack:

1. the exact GGUF model bytes;
2. the exact qualified `llama.cpp` source commit; and
3. a tested Linux recovery environment containing `llama-cli` built from that
   preserved source.

The model remains untrusted semantic input. This preservation layer does not
change CENTL's mathematical trust boundary.

## Qualified runtime identity

The current reference qualification documented in `docs/SCI-ENGINE.md` uses:

```text
llama.cpp commit 687e7789271ec1276e3470f158428e11a4f80b6f
build b10330
```

`supply-chain/sources.lock` stores the full commit. The build-capsule process does
not hard-code a second independent interpretation of the build number: it derives
that number from the preserved Git history using llama.cpp's own upstream rule,
`git rev-list --count <commit>`, and requires the result to match the documented
qualified build.

This matters because a source archive alone has no `.git` directory from which
llama.cpp can reconstruct its normal build identity. The capsule therefore passes
the verified commit and build number explicitly to CMake.

## Build only from the FCF Git mirror

After `scripts/supply-chain` has populated the mirror, the capsule builder reads:

```text
centl-mirror/git/llama.cpp.git
```

and exports the locked commit with `git archive`. It does not clone or fetch
llama.cpp during capsule construction.

The resulting source tar is a temporary build input. The durable source authority
remains the bare Git mirror, which retains the commit and its history.

## Reduced recovery build

The FCF recovery capsule builds the qualified `llama-cli` CPU path with a reduced
configuration intended for scientific local inference rather than generic llama.cpp
product surfaces.

The build explicitly disables:

- host-specific `GGML_NATIVE` tuning;
- OpenMP;
- BLAS;
- llamafile integration;
- tests and generic examples;
- the unified app;
- embedded/prebuilt web UI;
- OpenSSL integration;
- subprocess support; and
- LLGuidance.

`LLAMA_BUILD_SERVER` remains enabled because the pinned upstream CMake graph builds
`llama-cli` through the CLI/server implementation subtree. The final requested
build target is still `llama-cli`; the capsule is not exposing a network server
as the recovery product.

`BUILD_SHARED_LIBS=OFF` keeps llama.cpp/ggml project libraries inside the built
executable rather than requiring a separately preserved set of those project
shared objects. Normal system ABI libraries still come from the preserved OCI
capsule environment.

## Capsule outputs

A successful capsule build now preserves both the portable OCI environment and an
explicit SCi runtime record:

```text
centl-mirror/
  capsule/
    centl-build-capsule.oci.tar
    centl-build-capsule.oci.tar.sha256
    IDENTITY
    ...
  sci-runtime/
    llama-cli
    llama-cli.sha256
    LLAMA-COMMIT
    LLAMA-BUILD-NUMBER
    LLAMA-VERSION
```

The exported standalone `llama-cli` bytes are useful evidence and an additional
recovery artifact. The saved OCI capsule remains the authoritative portable
execution environment because the binary may rely on the capsule's Linux
libc/libstdc++ ABI.

The whole FCF mirror receipt is regenerated after these artifacts are written.

## No-network model recovery test

`scripts/offline-rebuild` always performs the ordinary CENTL source/toolchain/test
and Nemo differential recovery gates.

When `models/ACTIVE.sha256` is present, it additionally:

1. validates the preserved runtime checksum and identity metadata;
2. requires the runtime commit to match `supply-chain/sources.lock`;
3. executes `llama-cli --version` and checks the pinned commit/build identity;
4. locates the preserved active GGUF through its model manifest; and
5. runs the real `exact_decimal_addition` CENTL-SCi fixture with
   `--force-model` using `scripts/sci-model-eval.py`.

The capsule itself is already running under Podman `--network none`. A passing
model recovery case therefore demonstrates that the preserved model/runtime pair
can cross the real CENTL-SCi process boundary without contacting a model host,
GitHub, llama.cpp upstream, or another network service.

The single forced-model fixture is a recovery test, not a replacement for the
full model-quality corpus. Full qualification remains a separate release/development
activity.

## Host-only recovery

The lower-level `scripts/offline-rebuild` can still run outside the OCI capsule.
If an active model is preserved, it selects `llama-cli` in this order:

1. `CENTL_SCI_LLAMA_CLI` when explicitly provided;
2. `/opt/centl-sci/bin/llama-cli` inside the FCF capsule;
3. the exported `centl-mirror/sci-runtime/llama-cli`; or
4. `llama-cli` from `PATH`.

Whichever executable is selected must report the preserved qualified
commit/build identity. A model existing in the mirror is not accepted as
recoverable merely because some unrelated `llama-cli` happens to be installed.

## Claim boundary

This layer establishes recoverability for the current Linux x86_64 reference
model/runtime pair. It does not claim that the exported CLI binary is universally
portable across arbitrary Linux distributions or CPUs.

That is why the SHA-protected OCI capsule is preserved alongside the binary and
why the recovery test executes inside that capsule.
