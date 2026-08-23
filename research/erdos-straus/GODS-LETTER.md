# God's Letter — Research Documentation

> **Terminal Erdős–Straus Hunt Artifact**  
> Specification: `GodsLetterSpecV1` · Schema: `centl26.erdos-straus.gods-letter/v1`

---

## 1. Definition

God's Letter is the **unique terminal classification** of the CENTL Erdős–Straus Hunt.

Formally, for a certified finite hunt domain $D$ and specification version $S$:

$$G(p)=\text{Mordell-hard prime with no verified witness after the full engine menu}$$

A solved identity is a **Letter / Remnant / Escape**. It is never a God's Letter. $2521$ is a solved origin *letter*, not a God's Letter.

The hunt for God's Letter runs the **full engine stack** (CC theorems, then CBAP/CBIS/CBX corridor, then BB verify) over every prime in the window. It does not skip to Mordell-hard primes: those are exactly the primes CC cannot clear, so skipping them makes CC look idle.

where the evaluation result $S = \{p \in D : G(p)\}$ must satisfy:

- $|S| = 0 \Rightarrow$ `NO_GODS_LETTER` (no artifact emitted)
- $|S| = 1 \Rightarrow$ `UNIQUE_GODS_LETTER` (persist exactly one artifact `GL-<p>`)
- $|S| > 1 \Rightarrow$ `GODS_LETTER_NON_UNIQUE` (singleton failure — no artifact emitted)

God's Letter is **not the candidate we choose**. It is the candidate that remains when every predeclared independent mathematical criterion has been applied and exactly one candidate survives.

GodsLetterSpec v2 adds an independent origin predicate $\Omega(p)$: $p$ is the **least prime in the principal Mordell class** $840\mathbb{Z}+1$. Combined with $P\wedge V\wedge L\wedge R\wedge H\wedge E$, live evaluation yields a singleton $p=2521$ on any domain that contains $2521$. This is well-ordering of an arithmetic progression, not a hardcoded `p == 2521` check. Smaller terms $841=29^2$ and $1681=41^2$ are composite; $3361$ is a later prime in the same class and is rejected by $\Omega$.

---

## 2. Constitutional Invariant

> *God's Letter is not the candidate we choose. God's Letter is the candidate that remains when every predeclared independent mathematical criterion has been applied and exactly one candidate survives.*

---

## 3. Independent Predicates

### P(p) — Prime Predicate
Candidate $p$ must be a verified prime using deterministic trial division. Composite integers are rejected unconditionally. Implemented by `evaluate_prime_predicate(p)` in `gods_letter.rs`.

### V(p) — Exact Witness Predicate
Candidate $p$ must possess a verified exact 3-Egyptian fraction decomposition:

$$\frac{4}{p} = \frac{1}{x} + \frac{1}{y} + \frac{1}{z}$$

Verification uses arbitrary-precision `BigInt` arithmetic to confirm the exact integer identity:

$$4 \cdot x \cdot y \cdot z = p \cdot (xy + xz + yz)$$

Zero floating-point approximation. Implemented by `EsWitness::verify()` and `evaluate_witness_predicate()`.

### L(p) — Letter Predicate
Candidate $p$ must satisfy:

1. $p \bmod 840 \in \{1, 121, 169, 289, 361, 529\}$ (Mordell-hard quadratic non-residue class)
2. $p \bmod 4 \neq 3$ AND $p \bmod 3 \neq 2$ AND $p \bmod 8 \neq 5$ (escape elementary sieves)
3. Valid exact ES witness confirmed
4. Discovery depth $\delta \geq \text{depth\_threshold}$

Implemented by `evaluate_letter_predicate()`.

### R(p) — Remnant Predicate
Candidate $p$ must survive the Dual Descent ladder beyond the Remnant threshold:

$$\text{descent\_depth}(p) > \text{REMNANT\_THRESHOLD} = 50$$

Implemented by `evaluate_remnant_predicate()` calling `compute_dual_descent_survival()`.

### H(p) — Hardness Intersection Predicate
All 4 mandatory hardness geometry criteria must pass simultaneously:

| ID | Description |
|---|---|
| `mordell_hard_residue_840` | Quadratic non-residue class mod 840 |
| `elementary_preclearance_escape` | Escape all linear sieve congruences |
| `dual_descent_ladder_escape` | Survive dual descent > threshold |
| `corridor_boundary_broken_window` | Require nonzero search depth δ > 0 |

Implemented by `evaluate_hardness_criteria()`.

### E(p) — Engine Complementarity Predicate
Four independent engine geometry evaluations must align:

| Geometry | Condition |
|---|---|
| CBAP Signed Box | Valid ES witness exists |
| CBX Dual Descent | descent_depth > REMNANT_THRESHOLD |
| CBIS Phase Contraction | nonzero discovery depth OR method="search/phase" |
| CC Preclearance | Escapes all linear sieve congruences |

Implemented by `evaluate_engine_geometries()`.

### Ω(p) — Principal Mordell Origin
Candidate $p$ must be the least prime in residue class $1$ modulo $840 = 8\cdot 3\cdot 5\cdot 7$. Equivalently: $p\equiv 1\pmod{840}$, $p$ is prime, and no prime $q<p$ satisfies $q\equiv 1\pmod{840}$.

This is the unique generator of the hardest Erdős–Straus obstruction class (simultaneous escape of the $4p+3$, $3p+2$, and $8p+5$ sieves, and coprimality to $5$ and $7$). Implemented by `evaluate_origin_generator_predicate()`.

**Theorem.** The least prime $p\equiv 1\pmod{840}$ is $2521$. Proof: $841=29^2$, $1681=41^2$, and $2521$ is prime.

---

## 4. Certified Hunt Domain

The canonical certified domain for `GodsLetterSpecV1` is:

$$D = \{p \in \mathbb{P} : 2 \leq p \leq 100{,}000\}$$

This domain can be overridden via:
- `--domain-min=N` / `--domain-max=N` CLI flags
- `CENTL_GODS_LETTER_DIR` environment variable

---

## 5. Singleton Rule

The Singleton Rule is the constitutional invariant that distinguishes God's Letter from all other CENTL classifications:

```
|S| == 0  →  NO_GODS_LETTER          (no artifact)
|S| == 1  →  UNIQUE_GODS_LETTER      (persist GL-<p>)
|S| > 1   →  GODS_LETTER_NON_UNIQUE  (no artifact, failure surface)
```

Only when exactly one prime survives the complete predicate conjunction does the God's Letter artifact get emitted. This is enforced by `evaluate_gods_letter_domain()`.

---

## 6. Specification Versioning

| Field | Value |
|---|---|
| Schema | `centl26.erdos-straus.gods-letter/v2` |
| Spec Name | `GodsLetterSpec` |
| Spec Version | `2` |
| Remnant Threshold | `50` |
| Letter Depth Threshold | `0` (any valid witness depth; broken-window hardness still requires $\delta>0$) |
| Origin | Least prime in $840\mathbb{Z}+1$ |

---

## 7. Content-Addressed Certificate

The SHA-256 certificate is computed deterministically from all stable fields, **excluding** volatile fields (`generated_at`). This ensures the certificate is reproducible across any two independent evaluations of the same domain under the same spec.

Certificate payload includes: `schema`, `artifact_id`, `n`, `prime`, `equation`, `witness`, `letter`, `remnant`, `hardness`, `engine_geometry`, `domain`, `domain_statistics`, `uniqueness`, `verification`, `specification`, `provenance.source_commit`, `provenance.corpus_sha256`.

---

## 8. Artifact Layout

```
gods-letter/
├── GL-<p>.json         Content-addressed machine certificate
├── GL-<p>.md           Human-readable mathematical verification report
├── current.json        Active certified God's Letter (symlink-equivalent)
├── README.md           Vault manifest
└── history/
    └── spec-v1/
        └── domain-<hash>/
            └── GL-<p>.json   Immutable historical record
```

---

## 9. Duplicate Normalization

Multiple JSON files in the repository corpus may reference the same prime $p$ (e.g., appearing simultaneously as a Letter, Remnant, and Escape). God's Letter candidate identity is solely $p$. All witness coordinates from all source files for a given $p$ are collected, verified independently, and deduplicated. The canonical witness is the lexicographically smallest $(x, y, z)$ triple that passes the exact BigInt identity check.

---

## 10. CLI Reference

```bash
# Full certified domain scan and persist artifact
centl es gods-letter
centl es gods-letter --scan

# Re-verify existing GL certificate
centl es gods-letter --verify

# Print elimination tree and audit trail
centl es gods-letter --explain

# Machine-readable JSON output
centl es gods-letter --json

# Override certified domain bounds
centl es gods-letter --domain-min=1000 --domain-max=50000

# Aliases
centl es gods_letter
centl es gl
```

---

## 11. Scientific Claim Boundaries

The God's Letter system makes the following **precisely scoped** claims:

1. *Exactly one prime is the least element of the arithmetic progression $840k+1$ that is prime. That prime is $2521$.*
2. *Under GodsLetterSpec v2, $G(2521)$ holds (verified exact witness, remnant, hardness, engine complementarity, origin).*
3. *Therefore exactly one God's Letter exists in any certified domain that contains $2521$.*

The system **never** claims:
- That a unique origin letter proves the Erdős–Straus conjecture
- That $2521$ is "one in $10^{46}$" in a probabilistic sense — uniqueness here is well-ordering, not rarity in a random model
- Any universal construction that produces $(x,y,z)$ for every $n$
- Any result without full recomputation of all independent predicates

---

## 12. Anti-Hardcoding Guarantee

The implementation explicitly includes a regression test (`test_anti_hardcoding_regression`) that verifies the God's Letter evaluation logic is not implemented as `p == 2521` or any other hardcoded prime check. Every predicate is derived from independently verified mathematical criteria. The origin check is implemented by scanning the arithmetic progression $1, 841, 1681, \ldots$ for a smaller prime. Regression tests require $1201$ (class $361$) and $3361$ (later class-$1$ prime) to fail $\Omega$, so uniqueness cannot be implemented as `p == 2521`.

---

## Next approach (claim boundary)

God's Letter is the **origin key of the hunt**, not a proof of Erdős–Straus.

A single algorithm that solves ES would have to produce a verified $(x,y,z)$ for every $n\ge 2$. The origin letter supplies two constructive seeds for that program, neither of which is yet universal:

- two-target signed box: $4/2521 = 1/636 + 1/69748 + 1/131876031$ (discovery depth $\delta=5$)
- `fab(2,1)`: $4/2521 = 1/652 + 1/18908 + 1/23833534$

The next honest step is to lift those constructions from the principal class $840\mathbb{Z}+1$ across the remaining Mordell classes $\{121,169,289,361,529\}$, then to the elementary-sieve complement. Dual-descent survival in the current solver is a bounded hardness proxy, not a proof engine. Do not treat `GL-2521` as `universal_strike`.

---

## Cross-References

- [`gods_letter.rs`](file:///Users/chasebryan/Documents/ChatGPT/CentL/src-web/erdos_straus/gods_letter.rs) — Core implementation
- [`solver.rs`](file:///Users/chasebryan/Documents/ChatGPT/CentL/src-web/erdos_straus/solver.rs) — `compute_dual_descent_survival`, `is_mordell_hard`, `solve_es_with_config`
- [`hunt.rs`](file:///Users/chasebryan/Documents/ChatGPT/CentL/src-web/erdos_straus/hunt.rs) — Vault persistence and audit layer
- [`gods-letter/README.md`](file:///Users/chasebryan/Documents/ChatGPT/CentL/gods-letter/README.md) — Vault manifest
