# The Type A/B depth-spectrum diamond

**Status:** active synthesis and theorem-program document  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Research status:** Wellspring Candidate, not a claim that the Erdős-Straus conjecture is solved  
**Priority status:** potentially novel framework; literature priority remains under active review

This document records the point at which the FCF/CENTL Erdős-Straus work stopped being a collection of computational observations and became a coherent theorem program.

The central object is no longer a single difficult prime or a single congruence family. It is the exact arithmetic geometry of **minimal López Type A/B witness depth**: its spectrum, its survivor process, its shadow relations, an infinite prime-modulus backbone, and the zero-density composite-modulus core where the remaining pointwise difficulty is concentrated.

The project nickname **diamond** refers to this combined structure. It is not a formal mathematical term and must not be used as a novelty claim by itself.

---

## 1. Research lineage

This synthesis is built from the earlier FCF/CENTL work and should be read together with the following records.

### Primary Wellspring candidate

- [WS-CAND-003: Erdős-Straus Type A/B shadow structure](../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md)
- [Public research page](../../site/research-erdos-straus.html)

### Computational and structural foundation

- [THEORY.md](THEORY.md) — trap sets, shadow relations, modulus ancestry and proved local structure
- [RESULTS-2026-08-14.md](RESULTS-2026-08-14.md) — automated hard-prime frontier, shadow map, independent verification and CENTL certification
- [PRIOR-ART.md](PRIOR-ART.md) — current novelty boundary and literature comparison

### Depth-spectrum work

- [DEPTH-SPECTRUM.md](DEPTH-SPECTRUM.md) — exact minimal-depth realization, structural versus finite-latency gaps, and the `k=104` resolution
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md) — infinite prime-modulus exact-depth family
- [SURVIVOR-DENSITY.md](SURVIVOR-DENSITY.md) — exact finite-depth density, mass and conditional hazard
- [COMPOSITE-CORE.md](COMPOSITE-CORE.md) — reduction of the remaining pointwise Type A/B problem to a zero-density composite rescue core

### Cryptology side investigation

- [CRYPTOLOGY.md](CRYPTOLOGY.md)
- [CRYPTOLOGY-THEORY.md](CRYPTOLOGY-THEORY.md)
- [CRYPTOLOGY-RESULTS-2026-08-14.md](CRYPTOLOGY-RESULTS-2026-08-14.md)

The cryptology experiments are useful because they forced stronger controls and exposed survival-history dependence. They have **not** demonstrated a cryptographic break. The strongest mathematical outcome from that branch is the threshold-shadow viewpoint and the discovery that direct-shadow compression removes much of the apparent late-layer dependence induced by conditioning on large `C_AB`.

### Automation

- [Erdős-Straus research workflow](../../.github/workflows/erdos-straus-research.yml)
- [Cryptology workflow](../../.github/workflows/erdos-straus-cryptology.yml)
- [Depth-spectrum workflow](../../.github/workflows/erdos-straus-depth-spectrum.yml)

CENTL is used to certify exact rational and polynomial identities while independent Python verifiers separately check the finite number-theoretic certificates.

---

## 2. Starting point: López Type A/B congruences

The Type A/B solution forms are due to Miguel Angel López and are **not** an FCF novelty.

For a prime `p`, a Type A/B witness may be expressed through congruences of the form

\[
p\equiv -e\quad\text{or}\quad p\equiv -4e\pmod{4k-1},
\qquad e\mid k.
\]

Define

\[
m_k=4k-1,
\]

and the trap set

\[
T_k=\{-e,-4e\pmod{m_k}:e\mid k\}.
\]

López conjectures that every prime is eventually captured by the Type A/B system.

FCF's work asks a different set of questions about the internal structure of that system.

---

## 3. Minimal Type A/B witness depth

Define

\[
\boxed{
C_{AB}(p)=\min\{k\ge1:p\bmod m_k\in T_k\},
}
\]

with `C_AB(p)=infinity` if no Type A/B witness exists.

This turns the Type A/B system from a yes/no coverage question into an ordered arithmetic process.

A prime with `C_AB(p)=k` survives every layer `j<k` and first enters the Type A/B system at layer `k`.

### Certified hard-prime frontier through `10^7`

The automated finite experiment over the Mordell-hard residue classes modulo `840` selected `20,513` primes. All were resolved by `k<=3000`. The independently checked record frontier is

```text
1009       -> C_AB 3
1201       -> C_AB 8
2521       -> C_AB 22
3361       -> C_AB 25
9601       -> C_AB 28
33289      -> C_AB 45
76441      -> C_AB 70
83449      -> C_AB 170
1095481    -> C_AB 245
1423321    -> C_AB 1050
2031121    -> C_AB 1403
4728649    -> C_AB 1435
9658489    -> C_AB 2622
```

For the current finite-search record,

\[
\boxed{C_{AB}(9658489)=2622.}
\]

Its finite minimality certificate rejects every smaller Type A/B layer and CENTL separately verifies the exact Egyptian-fraction identity and the parameterized polynomial family.

The frontier is computational evidence about the growth of first-hit depth. It is not itself a proof of any asymptotic law.

---

## 4. Exact trap cardinality

The trap set has exact size

\[
\boxed{
|T_k|=2\tau(k)-1-\mathbf1_{4\mid k}\tau(k/4).
}
\]

This formula converts the raw Type A/B target at layer `k` into an exact arithmetic quantity depending only on divisor structure.

It later becomes the closed-form numerator of the exact hazard on the prime-modulus backbone.

---

## 5. Congruence shadowing

The next structure is **shadowing**.

Fix a Mordell hard class `h mod 840`, a target layer `k`, and an admissible trap residue `t in T_k`. The pair determines a CRT progression

\[
x\equiv h\pmod{840},
\qquad
x\equiv t\pmod{m_k}.
\]

Let this be

\[
x\equiv r\pmod L,
\qquad
L=\operatorname{lcm}(840,m_k).
\]

For an earlier layer `j<k`, put

\[
g=\gcd(L,m_j).
\]

The residues modulo `m_j` attained by the entire candidate progression are exactly the fibre

\[
\{u\bmod m_j:u\equiv r\pmod g\}.
\]

Therefore the candidate is directly shadowed by `j` exactly when

\[
\boxed{
\{u\bmod m_j:u\equiv r\pmod g\}\subseteq T_j.
}
\]

In that case every integer in the later candidate progression already hits the earlier layer. The later candidate contributes no possible new minimal-depth prime.

### Exact example: `14 <- 3`

For the relevant hard-prime system, all admissible candidates at

\[
k=14,\qquad m_{14}=55
\]

are already captured by

\[
k=3,\qquad m_3=11.
\]

Thus the absence of first hits at `k=14` is not statistical. It is forced by congruence geometry.

### Automated shadow map through `k=3000`

The first complete automated run found

- `460` fully directly shadowed layers;
- `1,108` completely direct-fresh layers;
- `875` partially directly shadowed layers;
- `3,544` unique direct-shadow layer edges;
- `1,808` shadow edges explained by modulus divisibility ancestry;
- `1,736` shadow edges requiring more than simple modulus divisibility.

The shadow graph is therefore a genuine dependency structure, not merely a collection of nested moduli.

---

## 6. Modulus ancestry

The moduli obey

\[
\gcd(4j-1,4k-1)=\gcd(4j-1,k-j).
\]

When

\[
4j-1\mid4k-1,
\]

there exists `s>=0` with

\[
\boxed{k=(4s+1)j-s.}
\]

The strongest finite ancestry family observed so far has quotient `5`:

\[
4k-1=5(4j-1),
\qquad
\boxed{k=5j-1.}
\]

The first automated map contained `130` observed uniform full-shadow points in this quotient family, but also partial and absent shadows. Therefore the mathematical target is a necessary-and-sufficient arithmetic condition for when an ancestry relation forces full shadowing.

---

## 7. Structural gaps versus finite-search latency

The depth framework distinguishes two phenomena that ordinary finite searches conflate.

### Structural gap

A depth cannot occur when it has no prime-compatible admissible candidate, or when all admissible candidates are already covered by earlier Type A/B layers.

### Latency gap

A depth may be realizable by infinitely many primes while its first prime lies beyond a finite search cutoff.

The decisive example is `k=104`.

In the original hard-prime sweep through `10^7`, layer `104` had zero first hits and was the first substantial zero not explained by compatibility or direct shadowing.

The depth-realization analysis found

\[
\boxed{p=11035249}
\]

with

\[
\boxed{C_{AB}(11035249)=104.}
\]

This prime lies just beyond the old cutoff. More strongly, an avoiding parameter class plus Dirichlet's theorem proves that infinitely many primes have exact depth `104`.

This is a major methodological success: the framework predicted that a finite zero was latency rather than impossibility and produced an explicit realization.

---

## 8. Exact candidate realization

For a fixed admissible candidate `(k,h,t)`, write its CRT progression as

\[
x=r+Ls.
\]

For every earlier `j<k`, the earlier hit condition induces a finite forbidden residue set

\[
R_j\subseteq\mathbb Z/q_j\mathbb Z,
\qquad
q_j=\frac{m_j}{\gcd(L,m_j)},
\]

such that

\[
r+Ls\bmod m_j\in T_j
\quad\Longleftrightarrow\quad
s\bmod q_j\in R_j.
\]

Let

\[
Q=\operatorname{lcm}\{q_j:R_j\ne\varnothing,\ j<k\}.
\]

If an `s_0` avoids every forbidden class and

\[
\gcd(r+Ls_0,LQ)=1,
\]

then Dirichlet gives infinitely many primes

\[
p=r+Ls_0+LQz
\]

with

\[
\boxed{C_{AB}(p)=k.}
\]

Thus exact-depth realization for a fixed candidate reduces to a finite modular decision problem.

---

## 9. The hard-class minimal-depth spectrum

Define

\[
\mathcal D_H
=
\{k:\text{infinitely many hard-class primes have }C_{AB}(p)=k\}.
\]

The spectrum asks **which first-hit depths genuinely exist**, not merely whether Type A/B solutions exist.

The depth-spectrum computation through `k=300` found

- `66` layers with no admissible hard-prime candidate;
- `39` layers whose admissible candidates were completely directly shadowed;
- `195` layers carrying explicit infinite-prime realization certificates.

At that range there were no unexplained non-shadowed failures.

This motivates the **Direct-Shadow Completeness Conjecture**:

> After prime compatibility is imposed, every admissible candidate that is not completely covered by a single earlier shadow admits a reduced avoiding class and hence infinitely many exact-depth primes.

Equivalent formulations may need refinement. This is a theorem target, not an established result.

If proved, it would identify the support of the minimal-depth spectrum from the direct shadow graph alone and collapse a potentially complicated union-cover problem into a local arithmetic criterion.

---

## 10. Exact finite-depth survivor density

For fixed `K`, define

\[
M_K=\operatorname{lcm}(m_1,\ldots,m_K)
\]

and the reduced survivor set

\[
S_K=\{a\in(\mathbb Z/M_K\mathbb Z)^\times:
a\bmod m_j\notin T_j\text{ for every }j\le K\}.
\]

By equidistribution of primes in reduced residue classes modulo fixed `M_K`, the exact relative density among primes of surviving through layer `K` is

\[
\boxed{
\delta_K=\frac{|S_K|}{\varphi(M_K)}.
}
\]

Define the exact minimal-depth mass

\[
\boxed{
\mu_k=\delta_{k-1}-\delta_k.
}
\]

Then

\[
\boxed{
k\in\mathcal D\iff\mu_k>0.}
\]

The minimal-depth spectrum is therefore exactly the support of the density drop.

---

## 11. Exact survival-history hazard

Whenever `delta_(k-1)>0`, define

\[
\boxed{
h_k=\frac{\mu_k}{\delta_{k-1}}
=1-\frac{\delta_k}{\delta_{k-1}}.}
\]

This is the exact asymptotic conditional probability that a prime hits layer `k` given survival through every earlier Type A/B layer.

This replaces the earlier raw-hazard and prime-conditioned heuristic models. It automatically incorporates

- hard residue compatibility;
- prime compatibility;
- direct shadows;
- partial dependencies;
- joint shadow closure;
- all finite CRT interactions among the first `k` layers.

A structural gap is exactly a zero-hazard layer:

\[
\boxed{h_k=0\iff\mu_k=0.}
\]

---

## 12. Prime-modulus backbone

Suppose

\[
q=m_k=4k-1
\]

is prime.

Because `q` exceeds all previous moduli, it is coprime to the entire preceding sieve modulus. It therefore creates an independent CRT coordinate.

The exact hazard becomes

\[
\boxed{
h_k=\frac{|T_k|}{q-1}.}
\]

Using trap cardinality,

\[
\boxed{
h_k=
\frac{2\tau(k)-1-\mathbf1_{4\mid k}\tau(k/4)}{4k-2}
\qquad(4k-1\text{ prime}).}
\]

Even more strongly, if `q=4k-1>7` is prime, CRT plus Dirichlet gives infinitely many primes in the hard class

\[
p\equiv1\pmod{840}
\]

with

\[
\boxed{C_{AB}(p)=k.}
\]

This gives an infinite **prime-modulus backbone** inside the exact-depth spectrum.

Since there are infinitely many primes `q == 3 mod 4`, finite values of `C_AB` are themselves unbounded.

---

## 13. Density decay and what is not novel by itself

The prime-modulus backbone alone forces survivor density to zero. A conservative bound is

\[
\delta_K
\le
\prod_{\substack{q\le4K-1\\q\equiv3\pmod4\\q>7}}
\left(1-\frac3{q-1}\right),
\]

hence

\[
\boxed{\delta_K\to0}
\]

and, using Mertens-type estimates in arithmetic progressions,

\[
\boxed{\delta_K\ll(\log K)^{-3/2}.}
\]

Therefore a relative density-one set of primes has a López Type A or Type B solution.

**This density-one conclusion is not, standing alone, an FCF novelty.** Classical work already shows that almost all integers satisfy Erdős-Straus, and simple known sufficient criteria such as the presence of a `3 mod 4` prime divisor of `p+1` already cover density one.

The research candidate lies in the finer structure attached specifically to minimal Type A/B witness depth: the spectrum, exact depth mass, survival-history hazard, shadow quotient, realization certificates, backbone/core decomposition and their interaction.

---

## 14. The composite rescue core

Define the prime-modulus survivor core

\[
\mathcal C_{\rm pm}
=
\{p\text{ prime}:p\text{ escapes every Type A/B layer with }4k-1\text{ prime}\}.
\]

The backbone gives

\[
\boxed{\overline d_{\mathbb P}(\mathcal C_{\rm pm})=0.}
\]

Any prime in this set that eventually receives a Type A/B witness must therefore receive its minimal witness at a **composite** modulus `4k-1`.

Call this event a **composite rescue**.

The López universal Type A/B coverage conjecture can then be reorganized as

\[
\boxed{
\text{Every prime in }\mathcal C_{\rm pm}\text{ receives a composite rescue.}
}
\]

This does not make the pointwise conjecture easier automatically. It does isolate its remaining difficulty inside a zero-density, dependency-rich residue population.

The prime `2521` is a canonical finite example:

\[
C_{AB}(2521)=22,
\qquad
m_{22}=87=3\cdot29.
\]

Its minimal witness is already a composite rescue.

---

## 15. The diamond

The combined framework is

\[
\boxed{
\begin{array}{c}
\text{López Type A/B congruences}\\[1mm]
\downarrow\\
C_{AB}\text{ minimal witness depth}\\[1mm]
\downarrow\\
\text{trap sets and exact cardinality}\\[1mm]
\downarrow\\
\text{shadow graph and modulus ancestry}\\[1mm]
\downarrow\\
\text{exact depth spectrum }\mathcal D\\[1mm]
\downarrow\\
\delta_K,\ \mu_k,\ h_k\\[1mm]
\downarrow\\
\text{prime-modulus independent backbone}\\
+\\
\text{composite dependency core}\\[1mm]
\downarrow\\
\text{pointwise composite-rescue problem}
\end{array}
}
\]

The important shift is conceptual:

> The Type A/B system is an exact arithmetic survival process whose first-hit distribution has a dependency graph, an infinite independent backbone, and a residual composite core.

That statement is substantially richer than the original finite-search observation that some primes require large Type A/B parameters.

---

## 16. How large is the novelty candidate?

As of this record, the novelty candidate should be separated into four levels.

### Level A — established background, not ours

- the Erdős-Straus conjecture;
- Mordell hard congruence classes;
- López Type A/B solution forms and congruence system;
- general density-one / sparse-exception results for Erdős-Straus;
- classical CRT and Dirichlet arguments;
- known sufficient conditions involving factors of `p+1`.

These are foundations or prior art.

### Level B — likely useful repackaging, priority uncertain

- viewing Type A/B layers as an ordered first-hit process;
- the prime-modulus/composite-modulus organizational split;
- calling later congruence classes redundant or shadowed.

Similar ideas may exist under covering-system, sieve-redundancy or congruence-implication language. Priority must be searched broadly, not only under our terminology.

### Level C — strong novelty candidates

The current strongest candidates for genuinely new mathematical structure are the **combined, Type-A/B-specific** objects:

1. the minimal witness-depth invariant `C_AB(p)` as a primary object of study;
2. the exact hard-class record frontier with independently verifiable minimality certificates;
3. the Type A/B shadow relation and its directed redundancy graph;
4. the exact trap-cardinality formula in this framework;
5. the hard-class exact-depth spectrum `D_H`;
6. the finite modular realization certificate for exact depth;
7. the exact survivor-density/mass/hazard triple `(delta_K, mu_k, h_k)` attached specifically to López Type A/B minimal depth;
8. the prime-modulus exact-depth backbone combined with the shadow spectrum;
9. the structural-gap versus latency-gap distinction, demonstrated concretely by the predicted and then located `C_AB=104` prime;
10. threshold pre-shadow load and its connection to conditional survivor geometry.

Each item may have analogues elsewhere in sieve theory. The strongest priority claim, if one survives review, is likely to concern the **integrated framework** rather than any isolated elementary lemma.

### Level D — potentially paper-defining theorem targets

These are not proved yet, but successful proofs would enlarge the diamond substantially:

- **Direct-Shadow Completeness:** direct non-shadowing implies exact-depth prime realizability after compatibility conditions;
- a necessary-and-sufficient classification of full shadowing in modulus-ancestry families, especially `k=5j-1`;
- a structural characterization of the complement of the exact-depth spectrum;
- a quotient description of the irredundant Type A/B sieve;
- quantitative composite-core hazard laws;
- a proof that every prime in the zero-density prime-modulus survivor core receives a composite rescue.

The last item would establish universal López Type A/B coverage and therefore imply Erdős-Straus for primes. It is far beyond what has currently been proved.

---

## 17. Why the `k=104` event matters disproportionately

The discovery of `p=11035249` with exact depth `104` is not important because the number itself is large. It matters because it tests the explanatory power of the framework.

Before the depth-realization analysis:

- the finite search showed zero first hits at `104`;
- direct shadowing did not explain the zero;
- a naive interpretation could have promoted `104` to a structural gap.

The modular realization framework instead said that `104` should be prime-realizable. The first hard-class realization appeared immediately outside the old search window.

That is exactly the behavior expected from a useful mathematical abstraction: it distinguished two causes that looked identical in finite data and correctly predicted which one was present.

---

## 18. Cryptology impact, current boundary

The cryptology track has **not** demonstrated an attack on RSA or another deployed cryptosystem.

Controlled experiments showed:

- unmasked Type A/B fingerprints can strongly detect deliberately planted modular structure;
- after the planted structure is masked, the public toy-RSA signal falls to chance;
- selecting factors by high `C_AB` creates later-layer dependence at the factor level;
- direct-shadow compression removes most of that post-selection signal;
- the corresponding controlled public-modulus signal remains near chance.

The cryptologic value today is therefore methodological and structural: the Type A/B shadow system is a new candidate arithmetic fingerprint / sieve-compression object worth testing, but no cryptographic weakness is established.

If a future public-key distinguisher survives proper arithmetic controls, it must be reported first as a source-distribution distinguisher, not as a key-recovery result.

---

## 19. Immediate research program

The next work should prioritize theorem extraction rather than merely increasing prime-search bounds.

1. **Attempt Direct-Shadow Completeness.** Search for a counterexample first. If none is found, identify the CRT/covering obstruction that would be required for joint partial shadows to cover a candidate without one direct shadow doing so.
2. **Classify ancestry families.** Derive exact conditions for full, partial and absent shadowing when `4j-1 | 4k-1`, beginning with quotient `5` and `k=5j-1`.
3. **Compute exact shadow closure on selected composite-core candidates.** Produce finite certificates of union coverage or avoiding classes.
4. **Develop composite-rescue invariants.** Relate rescue depth to the factorization of `4k-1`, `p+n`, and `p+4d` in López's parameterizations.
5. **Strengthen prior-art review.** Search covering systems, modular sieves, minimal congruence depth, first-hit distributions, nested congruence redundancy and Egyptian-fraction parameterizations, not merely papers using the words Type A/B.
6. **Turn proofs into a paper skeleton.** Separate unconditional theorems, finite certificate theorems, conjectures, and empirical observations.
7. **Keep CENTL as certifier, not oracle.** Discovery code, independent verification and exact CENTL identities must remain separate.

---

## 20. Proposed paper shape

A defensible paper built from the currently proved material could be organized as:

**Minimal Type A/B Witness Depths in the Erdős-Straus Equation: Spectrum, Shadowing, and an Exact Survival Process**

1. López Type A/B background and notation
2. Minimal witness depth `C_AB`
3. Trap cardinality
4. Shadow relation and redundancy graph
5. Exact-depth realization by finite congruence avoidance
6. Hard-class depth spectrum and `k=104`
7. Prime-modulus exact-depth backbone
8. Exact finite-depth density, mass and conditional hazard
9. Composite rescue core
10. Certified computations and independent verification
11. Conjectures: direct-shadow completeness and composite-core structure
12. Prior-art comparison and claim boundaries

The cryptology experiments should probably remain a separate note unless they produce a mathematically independent theorem or controlled public-key distinguisher.

---

## 21. Claim discipline

Until a broader literature review and independent mathematical review are complete, use language such as:

> FCF has identified a potentially novel structural framework for López Type A/B congruences in the Erdős-Straus problem, centered on minimal witness depth, congruence-layer shadowing, an exact depth spectrum and survival process, and a prime-modulus/composite-core decomposition.

Do **not** state that FCF has solved Erdős-Straus.

Do **not** claim that density-one solvability is new.

Do **not** claim that congruence redundancy is a new general mathematical idea.

Do **not** claim cryptographic impact beyond what controlled experiments establish.

The strongest current scientific position is that the project appears to have uncovered a coherent new **Type-A/B-specific invariant-and-structure program** whose individual elementary ingredients have classical analogues but whose combined minimal-depth/shadow/spectrum/hazard formulation has not yet been located in the targeted literature review.

---

## 22. Bottom line

The diamond is not one theorem.

It is the fact that several independently discovered pieces now lock together:

\[
\boxed{
C_{AB}
+T_k
+\text{shadowing}
+\mathcal D
+(\delta,\mu,h)
+\text{prime backbone}
+\text{composite core}.
}
\]

The strongest proved content already goes beyond finite experimentation: exact local shadow theorems, exact-depth realization certificates, an infinite family of exact finite `C_AB` depths, exact finite-depth asymptotic densities and hazards, and a successful prediction of a delayed depth realization.

The strongest unproved target is to show that the local shadow graph completely controls exact-depth realizability, and then to understand the zero-density composite rescue core pointwise.

That is the research frontier.