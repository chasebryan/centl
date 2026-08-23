# Erdős–Straus Corridor Escapes Vault

This directory stores exact 3-Egyptian fraction decompositions for primes discovered by the CentL26 Multi-Engine Hunt Studio (`CC`, `CBAP`, `CBIS`, `CBX`, `bb`) that were evaluated and rejected from genuine letter admission by the Central Authoritative Admission Gate.

## Why are these stored as Escapes?
A prime is archived in `escapes/` when:
1. It has an exact verified decomposition $\frac{4}{p} = \frac{1}{x} + \frac{1}{y} + \frac{1}{z}$, BUT
2. It failed the central letter admission gate (e.g. non-Mordell residue $p \not\equiv \{1, 121, 169, 289, 361, 529\} \pmod{840}$, preclearance match, or search depth $\delta < \text{threshold}$).

Historical discoveries are never deleted; non-letters are safely migrated to `escapes/` preserving complete mathematical provenance.

## File Format
- `ESC-<p>.md` / `L-<p>.md`: Markdown proof and witness record with explicit rejection reason.
- `ESC-<p>.json` / `L-<p>.json`: Machine-readable structured payload.
