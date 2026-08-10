# FCF release verification keys

This directory is for **public release verification keys only**.

No CENTL or FCF release secret key may ever be committed to this repository,
stored in GitHub Actions secrets, copied into a hosted CI runner, attached to an
issue/PR, or generated in a public/recorded environment.

## Production key bootstrap

Generate the production key pair on an offline machine or other deliberately
isolated signing environment using OpenBSD `signify` or a compatible
implementation:

```sh
umask 077
signify -G \
  -c 'FCF CENTL release key 2026' \
  -p fcf-centl-release-2026.pub \
  -s fcf-centl-release-2026.sec
```

Use a strong passphrase when prompted. Do not use `-n` for the production secret
key.

After generation:

1. make at least two encrypted/offline backups of `fcf-centl-release-2026.sec`;
2. keep the working secret key offline except during an intentional release
   signing ceremony;
3. copy **only** `fcf-centl-release-2026.pub` into this directory and commit it;
4. independently record the public-key fingerprint/identity in FCF operational
   records and at least one publication channel outside the release host;
5. test signing and verification before declaring the key active.

The production secret key should never be available to a normal build or CI
process. CI builds unsigned candidate artifacts. An offline maintainer signs the
final `SHA256SUMS` only after the candidate has passed the required gates.

## Rotation

Keys are named by identity and generation, not silently replaced in place. A new
key is added alongside the old public key, with an explicit transition record.
Old public keys remain available for verifying historical releases.

Compromise or suspected compromise requires immediate retirement of the affected
key and a documented replacement. Historical signatures do not become valid
under a replacement key merely because the filename is similar.
