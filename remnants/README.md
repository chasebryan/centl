# Erdős–Straus Remnants Vault

This directory stores verified 3-Egyptian fraction decompositions for deep-corridor primes discovered and resolved by the **CBX Engine** (`CBX.kernel (Dual Descent Lane-I)`) in the CentL26 Multi-Engine Hunt Studio.

## What is a Remnant?
A prime $p$ is preserved as a **Remnant** (`REM-<p>`) when:
1. It is a deep-corridor survivor ($\delta > 50$) that escapes standard modular preclearance, CC linear congruences, and shallow signed-box corridors.
2. It requires the specialized **CBX Dual Descent / Kneser Defect Edge** kernel to harvest the $(p, x, y, z)$ decomposition.
3. It has an exact verified decomposition $\frac{4}{p} = \frac{1}{x} + \frac{1}{y} + \frac{1}{z}$ with $4xyz = p(yz + xz + xy)$ in $\mathbb{Z}$.

## Vault Architecture
The CentL26 Endless Algorithmic Hunt Studio isolates three distinct persistence ledgers:
- `letters/`: Central Gate Admitted Letters ($p \pmod{840} \in \{1, 121, 169, 289, 361, 529\}$ + full threshold criteria).
- `remnants/`: CBX Engine Deep Dual Descent Survivors (`REM-<p>.md`, `REM-<p>.json`).
- `escapes/`: General Corridor Escapes and intermediate decompositions (`ESC-<p>.md`, `ESC-<p>.json`).

## File Formats
- `REM-<p>.md`: Formatted mathematical certificate with LaTeX proof, witness coordinates, depth $\delta$, and engine provenance.
- `REM-<p>.json`: Structured JSON payload conforming to schema `centl26.erdos_straus.remnant/v1`.
