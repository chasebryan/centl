# CENTL CARAVAN authenticated catalog

Status: **Phase 1 laboratory profile; not a public network protocol**.

CARAVAN does not ask volunteer carriers to decide which files are legitimate.
The Phase 1 catalog boundary uses **The Update Framework (TUF)** through
`python-tuf` 7.0.0. The trusted bootstrap root is distributed with an
authenticated CARAVAN/FCF software release, not learned from a carrier.

> A carrier may provide bytes, but a carrier may never define which bytes are trusted.

## Authentication chain

The laboratory repository uses the normal TUF top-level roles:

```text
trusted root
    |
    v
 timestamp
    |
    v
 snapshot
    |
    v
 targets
    |
    v
 caravan/catalog-v1.json
```

The TUF client verifies metadata signatures, versions, expiry, snapshot/targets
consistency, and the length/SHA-256 identity of the catalog target before CARAVAN
parses any artifact declarations from it.

The laboratory repository builder uses a single Ed25519 key per top-level role.
Those generated keys are ephemeral test keys. They are not a production FCF key
scheme and must not be shipped with volunteer carriers.

## CARAVAN catalog target

The authenticated target path is:

```text
caravan/catalog-v1.json
```

The application schema is `centl-caravan-catalog-v1`. It contains a positive
catalog version and an ordered list of artifact records.

Each artifact record contains exactly:

```text
logical_path
artifact_id
length
distribution
chunks
```

`artifact_id` is the existing CENTL content identity:

```text
sha256:<64 lowercase hexadecimal characters>
```

`logical_path` is descriptive/routing metadata only. It must already be a
canonical relative POSIX path. Absolute paths, backslashes, `.`/`..` traversal,
and duplicate logical paths are rejected.

## Distribution boundary

The schema recognizes four classes:

- `public-approved`
- `revoked`
- `pending-review`
- `fcf-preservation-only`

Only `public-approved` artifacts may be advertised or selected for volunteer
serving. `revoked` entries may cross into coordinator state only so an existing
identity can be disabled. `pending-review` and `fcf-preservation-only` entries
never become volunteer-routing targets.

No carrier advertisement can create a catalog target or change its expected
SHA-256.

## Authenticated chunks

Phase 1 uses fixed **4 MiB (4,194,304-byte)** chunks. A chunk record contains:

```text
offset
length
sha256
```

The parser requires:

- offsets start at zero and are contiguous;
- chunks are in exact order;
- every non-final chunk is exactly 4 MiB;
- the final chunk is at most 4 MiB;
- chunk SHA-256 values are canonical lowercase hexadecimal;
- the complete chunk sequence covers exactly the declared artifact length;
- a non-empty artifact has at least one chunk;
- a zero-length artifact has no chunks.

These authenticated chunk identities allow later transfer code to reject bad
pieces early. They never replace the mandatory whole-file SHA-256 and exact
length verification at successful-download completion.

## URL and bootstrap policy

The normal catalog client accepts HTTPS metadata and target base URLs. Plain HTTP
is allowed only when the caller explicitly enables loopback laboratory mode and
the host is loopback (`localhost`, `127.0.0.1`, or `::1`).

The TUF bootstrap root is mandatory. There is no "trust the first carrier" path.

## Phase 1 laboratory repository

`caravan/tuf_lab.py` creates a fresh local repository for tests with:

```text
metadata/
  1.root.json
  timestamp.json
  snapshot.json
  targets.json
targets/
  caravan/catalog-v1.json
```

For readability the local repository currently uses
`consistent_snapshot=false`; this does not skip the TUF root/timestamp/snapshot/
targets verification chain. Production repository/key/rotation policy remains a
later gate.

## Negative evidence

The laboratory suite verifies rejection of at least:

- catalog target bytes altered after signing;
- targets metadata altered after signing;
- traversal paths;
- duplicate artifact identities;
- missing chunks;
- reordered chunks;
- duplicated chunks;
- incomplete/appended-length coverage;
- non-HTTPS non-loopback catalog endpoints;
- `pending-review` artifacts entering coordinator routing.

The next Phase 1 boundary after this catalog work is the outbound-only carrier
session, including live proof of possession of the carrier Ed25519 identity.
