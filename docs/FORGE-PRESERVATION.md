# CENTL forge metadata preservation

Status: optional but recommended project-history preservation.

A complete Git bundle preserves CENTL source history, tags, branches visible to
the checkout, and repository objects. It does **not** preserve the collaboration
state that lives in a hosted forge database: issue discussions, pull-request
metadata, comments, issue events, release-page metadata, milestones, labels, or
workflow-list metadata.

FCF therefore supports a separate public GitHub metadata snapshot. This is not a
replacement for the Git bundle and it is not part of the trusted mathematical
runtime. It preserves development context that would otherwise disappear if the
forge vanished.

## Snapshot command

After the FCF preservation mirror exists:

```sh
python3 scripts/forge-snapshot.py /srv/centl-mirror
```

The default repository is `chasebryan/centl` and the default API is GitHub's
public HTTPS API.

For authenticated API rate limits, set a normal GitHub token in the environment:

```sh
GITHUB_TOKEN=... \
  python3 scripts/forge-snapshot.py /srv/centl-mirror
```

The token is used only in the HTTP `Authorization` header. It is not written to
the snapshot, receipt, or status output.

A read-only token is sufficient for the public metadata captured here. Do not use
a broad administrative token merely for preservation.

## Preserved datasets

The current snapshot stores normalized JSON for:

- repository metadata;
- issues and pull-request issue records;
- issue comments;
- repository issue events;
- pull requests;
- pull-request review comments;
- releases and release-page metadata;
- tags;
- branches;
- labels;
- milestones;
- contributors; and
- workflow-list metadata.

Git source/commit objects are intentionally not duplicated into these JSON files;
the preservation mirror's `project/centl.bundle` remains the source-history
recovery object.

The snapshot also stores `SNAPSHOT.json` with the repository, capture time,
preservation source commit when available, API base, request count, rate-limit
state, dataset counts, and whether a token was used. It records only the boolean
fact that authentication was used, never the credential.

## Layout

```text
centl-mirror/
  forge/
    github/
      repository.json
      issues.json
      issue-comments.json
      issue-events.json
      pulls.json
      pull-review-comments.json
      releases.json
      tags.json
      branches.json
      labels.json
      milestones.json
      contributors.json
      workflows.json
      SNAPSHOT.json
      FORGE-SHA256SUMS
      FORGE-SHA256SUMS.sha256
```

The forge receipt covers the exact regular-file contents of the snapshot except
its own receipt pair. The command verifies this tree before activation.

After activation, `scripts/forge-snapshot.py` regenerates the strict top-level FCF
mirror receipt, so the forge snapshot becomes part of the same independently
copy-verifiable preservation tree as source, models, capsule, releases, and other
accepted recovery material.

## Corrupted-mirror safeguard

If the mirror already has a whole-mirror receipt, the forge snapshot command
verifies that receipt **before contacting GitHub or replacing forge metadata**.

A corrupted finalized mirror is therefore not silently "healed" by a fresh forge
snapshot. Investigate the preservation failure first.

## Network boundary

Forge capture is inherently an online **capture-time** operation: it copies
metadata from GitHub while GitHub is available. It is not needed for disaster
recovery after the JSON snapshot has been preserved.

Loss of GitHub later does not remove the captured issue/PR/release context from
FCF storage. New collaboration activity obviously cannot be captured after the
upstream forge itself is gone.

For that reason, run forge snapshots periodically and before major migration or
repository-hosting changes. A weekly or release-time cadence is adequate for the
current project scale; this need not become a high-frequency polling system.

## Scope and limitations

The snapshot deliberately avoids claiming to reproduce GitHub itself. It does not
currently preserve:

- every GitHub Actions run log/artifact;
- repository/organization billing or account data;
- private credentials/secrets;
- branch-protection/settings state that requires administrative APIs;
- external image/file attachments hosted outside the repository metadata APIs;
- notification/subscription state; or
- GitHub-internal search indexes and derived UI state.

Those are not required to rebuild or run CENTL. If a specific hosted-forge
feature becomes operationally important, add it as an explicit preservation
dataset rather than widening this snapshot indiscriminately.

## Privacy/security boundary

The CENTL repository is public, and this command snapshots public repository
metadata. Do not generalize the tool to private repositories without a separate
review of what data would be copied into FCF storage.

The forge snapshot belongs in the **private preservation mirror**, not in the
public release export. `scripts/publication-export` allowlists release directories
and therefore does not publish `forge/`.

## Verification

Verify the complete FCF mirror normally:

```sh
sh scripts/mirror-receipt verify /srv/centl-mirror
```

The forge-local receipt can also be inspected independently:

```sh
python3 scripts/integrity.py verify \
  /srv/centl-mirror/forge/github/FORGE-SHA256SUMS.sha256 \
  --root /srv/centl-mirror/forge/github

python3 scripts/integrity.py tree-verify \
  /srv/centl-mirror/forge/github/FORGE-SHA256SUMS \
  --root /srv/centl-mirror/forge/github \
  --ignore FORGE-SHA256SUMS \
  --ignore FORGE-SHA256SUMS.sha256
```

As with every preservation receipt, a mismatch is investigated rather than
normalized by rewriting expected hashes.
