# Direct-Shadow Completeness: candidatewise finite attack

**Status:** strong finite theorem-certificate result; universal theorem remains open  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this document does not claim the Erdős-Straus conjecture, López Type A/B coverage, or universal Direct-Shadow Completeness has been proved.

This record follows the synthesis in [DIAMOND.md](DIAMOND.md) and attacks its strongest immediate structural conjecture at the **individual candidate-class level**, not merely at the layer level.

Related records:

- [WS-CAND-003](../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md)
- [DIAMOND.md](DIAMOND.md)
- [THEORY.md](THEORY.md)
- [DEPTH-SPECTRUM.md](DEPTH-SPECTRUM.md)
- [SURVIVOR-DENSITY.md](SURVIVOR-DENSITY.md)
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md)
- [COMPOSITE-CORE.md](COMPOSITE-CORE.md)
- [RESULTS-2026-08-14.md](RESULTS-2026-08-14.md)

Automation:

- [`direct_shadow_completeness_probe.py`](direct_shadow_completeness_probe.py)
- [`verify_direct_shadow_completeness.py`](verify_direct_shadow_completeness.py)
- [GitHub Actions workflow](../../.github/workflows/erdos-straus-direct-shadow-completeness.yml)

---

## 1. The conjecture being attacked

For a Type A/B layer

\[
m_k=4k-1,
\qquad
T_k=\{-e,-4e\pmod{m_k}:e\mid k\},
\]

fix a Mordell-hard residue class `h mod 840` and an admissible target residue `t in T_k`.

The pair `(h,t)` defines a CRT candidate progression

\[
x\equiv h\pmod{840},
\qquad
x\equiv t\pmod{m_k},
\]

or equivalently

\[
x=r+Ls,
\qquad
L=\operatorname{lcm}(840,m_k).
\]

For every earlier layer `j<k`, the hit condition induces a forbidden parameter set

\[
R_j\subseteq\mathbb Z/q_j\mathbb Z,
\qquad
q_j=\frac{m_j}{\gcd(L,m_j)},
\]

such that

\[
r+Ls\bmod m_j\in T_j
\iff
s\bmod q_j\in R_j.
\]

A **direct shadow** occurs when one earlier `j` alone forbids the entire parameter space. A **union shadow** would occur if no single `j` does so, but the union of the proper forbidden systems from several earlier layers nevertheless covers every integer `s`.

The candidatewise form of Direct-Shadow Completeness is:

> If an admissible Type A/B candidate is not directly shadowed by any single earlier layer, then the collection of earlier layers does not jointly cover it.

A stronger prime-realization form asks for an avoiding parameter `s0` for which

\[
\gcd(r+Ls_0,LQ)=1,
\qquad
Q=\operatorname{lcm}\{q_j:R_j\ne\varnothing\}.
\]

Such a reduced avoiding class yields infinitely many primes of exact depth `k` by Dirichlet.

---

## 2. Why the previous `k <= 300` result was not enough

The depth-spectrum run through `k=300` showed that every **layer** fell into one of three bins:

- no admissible hard-prime candidate;
- every candidate directly shadowed;
- at least one candidate carrying a reduced exact-depth realization certificate.

That was strong evidence, but it did **not** establish candidatewise completeness. A layer could contain one realizable candidate and another directly novel candidate that is nevertheless jointly covered by several earlier layers.

The present experiment tests every directly novel candidate separately.

---

## 3. Finite attack through `k <= 600`

The automated run used:

- all six Mordell-hard classes modulo `840`;
- every Type A/B layer through `k=600`;
- every prime-compatible target residue at every layer;
- parameter search `0 <= s <= 250000`;
- a separate reduced-progression search;
- an independent verifier that recomputes trap sets, CRT data, direct-shadow status, earlier-layer avoidance, periods, and gcd conditions;
- CENTL exact polynomial certification of the hardest CRT progression identities.

The result was:

```text
admissible candidates:             25,566
directly shadowed candidates:       6,550
directly novel candidates:         19,016
integer avoiding witnesses:        19,016
reduced avoiding witnesses:        19,016
unresolved integer candidates:          0
unresolved reduced candidates:          0
```

Therefore, in the entire tested candidate space,

\[
\boxed{
\text{every directly novel candidate through }k=600
\text{ is explicitly not union-shadowed.}
}
\]

More strongly,

\[
\boxed{
\text{every directly novel candidate through }k=600
\text{ has a reduced avoiding progression.}
}
\]

Hence each of the `19,016` directly novel candidates has a certificate that its progression contains infinitely many primes whose first Type A/B hit occurs at that candidate's layer.

This is a finite-range theorem-certificate statement, not an extrapolation from sampling.

---

## 4. Independent verification

The independent verifier rechecked all `19,016` candidate records and returned:

```json
{
  "direct_novel_candidates_checked": 19016,
  "integer_witnesses_verified": 19016,
  "k_limit": 600,
  "reduced_witnesses_verified": 19016,
  "unresolved_integer_candidates": 0,
  "unresolved_reduced_candidates": 0,
  "verdict": "VERIFIED"
}
```

The verifier is deliberately separate from the discovery code. It reconstructs the CRT candidate, checks that no single earlier layer directly shadows it, evaluates the witness against every earlier trap set, reconstructs the full parameter period, and verifies the reduced gcd condition.

---

## 5. CENTL certification

The discovery program selected the hardest reduced witnesses, ranked by the first avoiding parameter `s`, and generated symbolic CRT progression identities for CENTL.

For each selected record, CENTL verified identities of the form

\[
r+Ls
=
h+840(A+Bs)
\]

and

\[
r+Ls
=
t+(4k-1)(C+Ds),
\]

showing exactly that the whole parameterized progression remains in both the intended hard class and target Type A/B trap class.

All generated CENTL contracts verified successfully. Number-theoretic avoidance is intentionally left to the independent modular verifier rather than being smuggled into an algebraic identity checker.

---

## 6. Hardest witnesses in the first run

The largest reduced-avoiding parameters found included:

| k | h | t | first reduced `s` | `x=r+Ls` |
|---:|---:|---:|---:|---:|
| 500 | 529 | 1979 | 190724 | 320257173289 |
| 596 | 289 | 2234 | 173132 | 346562802049 |
| 568 | 529 | 2239 | 151716 | 96473785489 |
| 600 | 289 | 2099 | 143641 | 289461350929 |
| 568 | 169 | 2269 | 134161 | 85310616889 |
| 578 | 121 | 2310 | 131035 | 254371635961 |
| 600 | 361 | 2351 | 128874 | 259702188001 |
| 582 | 289 | 2303 | 127262 | 248757880009 |
| 570 | 169 | 2159 | 126662 | 242477648449 |
| 590 | 121 | 2319 | 124720 | 35306018281 |

The existence of relatively late witnesses is useful: the test is not succeeding merely because every candidate has an immediate tiny escape parameter.

---

## 7. What this rules out in the tested range

Through `k=600`, there is **no** example of the following phenomenon:

1. every earlier layer fails to cover a candidate individually;
2. several earlier layers together cover the candidate completely.

That is exactly the counterexample shape we set out to find.

The search did not find one because every directly novel candidate instead carries an explicit avoiding integer. Every such candidate also carries a reduced avoiding class.

Thus the finite evidence has moved from

> every apparently useful layer seems realizable

into the much stronger statement

> every individual directly novel hard-compatible candidate tested is infinitely prime-realizable.

---

## 8. What this does **not** prove

The universal implication

\[
\text{directly novel}
\Longrightarrow
\text{reduced avoiding class}
\]

remains unproved.

A counterexample might first occur above `k=600`. The bounded parameter search also would have reported an unresolved candidate rather than proving union coverage if a witness existed only beyond the search limit.

The zero-unresolved result is strong precisely because every tested candidate has a positive certificate. It must not be converted into a universal theorem without a proof.

---

## 9. The sharpened theorem target

The result suggests separating two statements.

### DSC-0: union-shadow collapse

For every admissible candidate,

\[
\boxed{
\text{not directly shadowed}
\Longrightarrow
\text{not union-shadowed}.
}
\]

### DSC-P: prime realization

Under the same compatibility assumptions,

\[
\boxed{
\text{not directly shadowed}
\Longrightarrow
\text{there exists a reduced avoiding parameter class}.
}
\]

DSC-P implies DSC-0 and, by Dirichlet, gives infinitely many exact-depth primes in every directly novel candidate.

The `k<=600` certificate bundle verifies both statements for every candidate in that finite range.

---

## 10. Why this materially enlarges the diamond

If DSC-P is proved in general, the global exact-depth problem changes dramatically.

The difficult finite covering question

\[
\bigcup_{j<k}R_j=\mathbb Z
\quad ?
\]

would collapse to the local question

\[
\exists j<k:\ R_j=\mathbb Z/q_j\mathbb Z
\quad ?
\]

In words: collective coverage would add no new obstruction beyond a single direct shadow.

Then the hard-class minimal-depth spectrum would be read directly from the local shadow graph. Each surviving candidate would automatically generate an infinite Dirichlet family of exact-depth primes.

That would turn the shadow graph from a computational redundancy map into a complete obstruction theory for Type A/B first-hit realizability.

This is now one of the highest-value theorem targets in the FCF/CENTL program.

---

## 11. Next attack

The next work should proceed on two fronts simultaneously:

1. **Push the candidatewise falsification range upward**, preserving explicit reduced witnesses and independent verification.
2. **Search for the theorem mechanism**, especially a structural reason that the special forbidden systems `R_j` cannot form a covering system unless one constituent already covers the entire parameter space.

The proof search should compare the Type A/B parameter-cover system with classical covering-system obstructions, but any general covering-system theorem must be specialized carefully to the moduli and residue sets arising here.

The target is no longer merely to observe that no counterexample appears. It is to identify the arithmetic invariant that makes a counterexample impossible, or else to find the first counterexample and learn exactly where the local-shadow model breaks.

---

## 12. Current conclusion

The direct-shadow completeness conjecture survived its first candidatewise exhaustive structural attack:

\[
\boxed{
19,016/19,016
\text{ directly novel candidates through }k=600
\text{ have independently verified reduced avoiding progressions.}
}
\]

That result substantially strengthens the empirical foundation of the `DIAMOND.md` theorem program while leaving the universal theorem honestly open.
