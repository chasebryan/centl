# CENTL preservation operations

Status: required operational procedure for FCF-controlled preservation storage.

The preservation mirror is useful only if its copies are complete and can be
verified independently. A directory existing on another disk is not sufficient
evidence that a multi-gigabyte model, OCI capsule, source archive, package
snapshot, or symbolic-link layout copied correctly.

CENTL therefore supports a whole-mirror SHA-256 receipt in addition to the
resource-specific checks already performed by `scripts/supply-chain audit`.

## Receipt files

A finalized mirror receives:

```text
MIRROR-SHA256SUMS
MIRROR-SHA256SUMS.sha256
MIRROR-SYMLINKS
MIRROR-SYMLINKS.sha256
```

`MIRROR-SHA256SUMS` contains one standard SHA-256 entry for every regular file in
the mirror except the receipt files themselves. It therefore covers the
preserved source bundle, dependency archives, Git mirrors, opam material,
Julia/Nemo depot, CENTL-SCi model bytes, OCI capsule, and other preservation
material present when the receipt is created.

`MIRROR-SYMLINKS` records every symbolic-link path by the SHA-256 of its literal
link-target string. Links are not dereferenced during this check. This preserves
package/runtime layouts such as versioned shared-library links without trusting
or reading a target outside the mirror.

The two `.sha256` files record the SHA-256 values of those manifests themselves.

The process does not invent a new digest algorithm. Every content identity is
standard SHA-256; the project-owned procedure defines which preservation objects
must be covered and how regular files and symbolic links are checked separately.

## Finalize a primary mirror

First complete and audit the normal preservation work:

```sh
make supply-chain-preserve \
  MIRROR=/srv/centl-mirror \
  MODEL=/path/to/active-centl-sci-model.gguf

make capsule-build MIRROR=/srv/centl-mirror
make capsule-run MIRROR=/srv/centl-mirror
```

Then create the whole-mirror receipt:

```sh
sh scripts/mirror-receipt create /srv/centl-mirror
```

The command immediately re-verifies the generated receipts. It rejects unsupported
special filesystem objects and any mismatch between the recorded tree and the
actual tree.

A mirror should be considered finalized for copying only after this command
passes.

## Verify the primary later

```sh
sh scripts/mirror-receipt verify /srv/centl-mirror
```

Strict verification checks all of the following:

1. every listed regular file still has the recorded SHA-256;
2. the mirror contains exactly the recorded regular-file set;
3. every recorded symbolic link still exists;
4. every symbolic link still has the recorded target string; and
5. no unexpected symbolic links have appeared.

Missing files, unexpected extra files, changed link targets, and unsupported file
types are failures. This is intentionally stricter than ordinary
`sha256sum -c`, which verifies listed regular files but does not normally prove
the complete filesystem membership of a preservation tree.

## Create and prove an independent copy

Copy the complete finalized mirror with a mechanism that preserves symbolic links.
For a simple local example:

```sh
cp -a /srv/centl-mirror /mnt/fcf-backup/centl-mirror
```

Then prove the copy against the primary receipts:

```sh
sh scripts/mirror-receipt compare \
  /srv/centl-mirror \
  /mnt/fcf-backup/centl-mirror
```

`compare` first verifies the primary, requires all receipt files themselves to
match in the secondary copy, and then checks every secondary regular file and
symbolic link against the primary manifests with exact tree-membership
enforcement.

A successful file-copy command is not treated as proof of a successful backup.
The `compare` result is the proof used by the FCF preservation process.

## Large artifacts

The whole-tree receipt intentionally includes large GGUF model files and the OCI
capsule archive. Those are among the hardest resources to recover if an upstream
host disappears, so excluding them merely to make verification faster would
defeat the purpose of the preservation layer.

Re-hashing a large mirror takes real I/O time. That cost is acceptable for a
preservation boundary and should not be hidden by a weaker check.

## Mutation rule

Any intentional mirror mutation makes the previous whole-tree receipt stale.
Examples include:

- changing a pinned dependency;
- refreshing the opam or Julia snapshot;
- changing the active CENTL-SCi model;
- rebuilding the OCI capsule;
- adding a preserved release.

After such a change:

1. run the resource-specific preservation/audit gates;
2. run the no-network capsule recovery gate when applicable;
3. regenerate the primary whole-mirror receipt;
4. update each independent copy;
5. run `mirror-receipt compare` for every copy.

Do not regenerate a receipt merely because verification failed. A failure must be
explained first; otherwise a new manifest would simply bless unknown bytes.

## Integrity versus authentication

The mirror receipt establishes integrity relative to the trusted primary receipt.
It does not, by itself, prove publisher identity. This is the same distinction
CENTL makes for release checksums.

Public release material uses the documented `signify` authentication layer. An
internal preservation receipt does not need to become a separate high-ceremony
signing system merely to be useful: independent storage, ordinary access control,
standard SHA-256, and tested recovery are the primary operational goals.

## Minimum FCF storage policy

For the current project scale, the practical minimum is:

- one primary FCF-controlled preservation mirror;
- at least one independent second copy;
- current regular-file and symbolic-link receipts;
- successful strict comparison after each material update;
- periodic re-verification of stored copies;
- a saved OCI build capsule inside the mirror;
- recoverable release-signing key backups kept separately from the mirror.

Additional copies and public mirrors are useful, but they do not replace proving
that the copies already held by FCF are complete.
