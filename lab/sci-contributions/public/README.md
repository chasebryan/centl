# Public reviewed contribution corpus

Files committed in this directory are public.

Do not copy raw `pending.jsonl` files here automatically. A record should be admitted only after explicit contributor authorization for public release, human review for sensitive material, and conversion into a stable reviewed data format with a stated data license or other explicit permission.

The preferred long-term flow is:

```text
local opt-in capture
        -> explicit export
        -> contributor review
        -> private maintainer staging
        -> redaction/deduplication
        -> independently checked expected behavior
        -> public reviewed fixture
```

Public contribution data may inform tests, deterministic admission, model evaluation, or training/distillation only under the permissions attached to that contribution.
