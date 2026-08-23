# Erdős–Straus Letters Vault

This directory stores authoritative **LETTER** findings admitted by the CentL26 Central Letter Admission Gate.

## Authoritative Mathematical Letter Invariant
A candidate prime $p$ is admitted into the genuine letter ledger if and only if:
1. **Primality**: $p$ is prime.
2. **Mordell-Hard Residue**: $p \pmod{840} \in \{1, 121, 169, 289, 361, 529\}$ (Strict fail-closed constraint).
3. **Preclearance Survival**: $p$ is not cleared by standard modular congruences ($4p+3$, $3p+2$, $8p+5$).
4. **Search Depth**: Search depth $\delta \ge \text{threshold}$ (surpasses shallow corridor limits).
5. **Exact Proof**: Passes arbitrary-precision 100% $\mathbb{Q}$ rational identity verification:
   $$4xyz = p(yz + xz + xy)$$

## File Format
- `L-<p>.md`: Human-readable mathematical certificate with 3-fraction identity, witness coordinates $(x, y, z)$, and SHA-256 certificate.
- `L-<p>.json`: Machine-readable structured payload with cryptographic certificate hash and engine provenance.
