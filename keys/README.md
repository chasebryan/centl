# FCF release verification keys

This directory is for **public release verification keys only**.

CENTL release signing must be secure without making one person, one computer, or
one storage device a permanent single point of failure.

No CENTL or FCF release secret key may be committed to this public repository,
attached to an issue/PR, or placed in ordinary hosted CI. The secret key itself
is passphrase-protected by `signify` unless key generation explicitly uses `-n`;
FCF production keys must not use `-n`. The OpenBSD manual documents this default
passphrase protection.

## Practical production key model

The normal FCF policy is a **recoverable organizational signing key**, not a
single irreplaceable offline key.

Generate the key pair on a trusted maintainer machine or isolated signing system:

```sh
umask 077
signify -G \
  -c 'FCF CENTL release key 2026' \
  -p fcf-centl-release-2026.pub \
  -s fcf-centl-release-2026.sec
```

Use a strong passphrase when prompted.

After generation:

1. keep one protected working copy available to the release maintainer;
2. keep at least two additional encrypted backups in independent storage
   locations or services;
3. store the passphrase/recovery information in a reputable password-management
   system with its own account-recovery plan rather than relying on memory;
4. when FCF has another trusted maintainer, give at least one additional
   custodian a documented recovery path;
5. copy **only** the public `.pub` key into this directory and commit it;
6. record the active key identity and activation date in project documentation;
7. test recovery from a backup before treating the key as operationally safe.

An encrypted backup may be stored online. The goal is that theft of one storage
location does not immediately expose a usable signing key, while loss of one
machine does not prevent FCF from making future releases.

## Signing environment

Maximum isolation is not required for routine CENTL releases. The working secret
key may be used from a well-maintained FCF-controlled administrator workstation,
provided that:

- the key remains passphrase-protected;
- it is not checked into source control;
- it is not exposed to untrusted CI jobs;
- signing is an explicit maintainer action;
- the generated signature and SHA-256 manifest are reverified after signing.

A fully offline signing machine remains an available higher-assurance option for
a particularly sensitive release, not a mandatory ceremony for every release.

## Loss is recoverable

Losing every copy of a secret key does **not** invalidate releases already signed
with it. Anyone who still has the corresponding public key can continue to
verify those historical signatures.

It also does not permanently stop CENTL releases. FCF can generate a replacement
key, commit/publish its public key, record the transition, and use the new key for
future releases. What is lost is the ability to create *new* signatures under the
old identity.

For this reason, availability and recoverability are part of the key policy, not
an afterthought.

## Rotation

Keys are named by identity and generation, not silently replaced in place. A new
key is added alongside the old public key, with an explicit transition record.
Old public keys remain available for verifying historical releases.

Routine rotation may occur when maintainership changes, a key becomes difficult
to recover, or FCF simply wants a fresh release identity. Suspected compromise
requires immediate retirement and replacement.

Do not re-sign unknown historical artifacts with a replacement key merely to make
them appear continuous. Historical verification stays bound to the key that
actually signed each release.
