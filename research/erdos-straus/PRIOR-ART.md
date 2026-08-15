# Prior-art matrix for WS-CAND-003

**Search date:** 2026-08-14

**Status:** working research record. A negative search result is not proof of novelty or priority.

This file records the targeted primary-literature pass used to calibrate claims around `C_AB`, exact trap cardinality, congruence-layer shadowing, the depth-spectrum / survival-process framework, and the later character, multiplicative-quotient, and infinite-shadow-family results.

## Primary sources reviewed

### Miguel Angel López, 2024

*A Complete Congruence System for the Erdos-Straus Conjecture*  
https://arxiv.org/abs/2404.01508

Relevant prior art:

- Type A and Type B solution classes;
- congruence characterizations involving `4dn-1`;
- conjecture that every prime has a Type A or Type B solution;
- relation to Type II solutions and classical Mordell restrictions;
- experimental Type A/B coverage reported for the first 10,000 primes;
- quadratic-nonresidue observations in the Type A/B setting;
- mutual-inverse behavior of the two divisor residue families.

Not claimed by FCF: Type A, Type B, their basic congruence formulas, the general use of congruence systems, the classical quadratic-residue restrictions, or the inverse relationship itself.

### Miguel Angel López, 2022

*Structure and form of the solutions of the Erdos-Straus conjecture*  
https://arxiv.org/abs/2206.10319

Relevant prior art:

- structural classification of solution forms;
- solutions of the form `(du,dv,duv)`;
- structural treatment of difficult primes including 1009.

### Serge E. Salez, 2014

*The Erdős-Straus conjecture: New modular equations and checking up to N=10^17*  
https://arxiv.org/abs/1406.6307

Relevant prior art:

- modular equations and optimized computational sieving;
- verification of the original Erdős-Straus conjecture through `10^17`.

Consequence for WS-CAND-003: the `10^7` finite run is not a novelty claim about the verification range of Erdős-Straus itself.

### Christian Elsholtz and Terence Tao, 2011

*Counting the number of solutions to the Erdos-Straus equation on unit fractions*  
https://arxiv.org/abs/1107.1010

Relevant prior art:

- analytic study of the number and distribution of Erdős-Straus solutions over primes;
- solution-counting framework and asymptotic bounds.

### Christian Elsholtz and Stefan Planitzer, 2018

*The number of solutions of the Erdős-Straus Equation and sums of k unit fractions*  
https://arxiv.org/abs/1805.02945

Relevant prior art:

- bounds and algorithms for enumerating unit-fraction decompositions;
- distributional results in reduced residue classes.

### R. C. Vaughan, 1970

*On a problem of Erdős, Straus and Schinzel*, Mathematika 17 (1970), 193-198.

Relevant prior art:

- classical sparse-exception / almost-all results for Erdős-Straus;
- large-sieve methods showing that the unresolved population is very thin.

Consequence for the current program: a density-one solvability statement is not, by itself, a novelty claim.

### Christian Elsholtz, 2001

Parametric-solution work strengthening sparse-exception bounds for generalized unit-fraction problems.

Relevant prior art:

- parametric families can yield strong upper bounds for exceptional sets;
- asymptotic sparsity of failures is classical territory.

### Bernd R. Schuh, 2025

*The Erdös-Straus Conjecture and Pythagorean Primes*  
https://arxiv.org/abs/2503.11672

Relevant prior art:

- additional structured parametrizations and congruence restrictions for a prime subclass;
- algorithmic determination of parameters in those forms.

### Xiaoping Xu, 2026

*Congruence Classes of Supporting the Erdös-Straus Conjecture I: Tame Solutions*  
https://arxiv.org/abs/2605.23601

Relevant prior art:

- current congruence-class research;
- tame/wild solution classification for primes of the form `24m+1`;
- parametrized congruence families supporting solutions.

### M. Bello-Hernández, M. Benito, E. Fernández, 2026

*A Divisor Parametrization for the Erdős--Straus Conjecture*  
https://arxiv.org/abs/2606.10922

Relevant prior art:

- divisor-based parametrization of unit-fraction decompositions;
- comparison with established Type I/II descriptions.

## Targeted novelty questions

The search specifically looked for prior definitions or equivalent constructions corresponding to:

1. the first-hit invariant

   `C_AB(p) = min { k >= 1 : p mod (4k-1) in {-d,-4d : d | k} }`;

2. a record sequence for the minimum product `dn` among López Type A/B witnesses;

3. the exact trap-set cardinality

   `|T_k| = 2*tau(k) - 1 - 1_{4|k}*tau(k/4)`;

4. an explicit partial order, graph, or inclusion theory in which one Type A/B congruence layer is redundant because its complete hard-class-compatible CRT fibre is already contained in an earlier Type A/B trap layer;

5. a distinction between direct shadowing and collective union-shadowing of Type A/B congruence classes;

6. an irredundant-core reduction of the López Type A/B congruence system based on those shadow relations;

7. the exact-depth spectrum

   `D = { k : infinitely many primes satisfy C_AB(p)=k }`;

8. an exact finite-depth survivor process for López Type A/B minimal depth with

   `delta_K`, `mu_k = delta_(k-1)-delta_k`, and `h_k = mu_k/delta_(k-1)`;

9. a prime-modulus exact-depth backbone in which `4k-1` prime makes the target layer an independent CRT coordinate and gives a closed conditional hazard;

10. a structural-gap versus finite-latency distinction for minimal Type A/B depth, including finite modular certificates proving infinite exact-depth realization;

11. a prime-modulus survivor core whose remaining finite Type A/B witnesses must occur at composite target moduli, organized as a composite-rescue problem;

12. threshold pre-shadow load measuring how conditioning on early survival deletes later admissible Type A/B candidate classes;

13. a vector-valued Legendre-signature formulation in which the complete Type A/B trap signature is one affine subspace `eta_k+V_k`;

14. character-level or signature-level direct-shadow completeness, in which collective character obstruction collapses to direct immutable layers;

15. a multiplicative subgroup envelope `T_k subset -H_k` generated by the prime divisors of `k`, together with a quotient factorization separating quadratic-signature and higher-order multiplicative information;

16. a higher-codimension proper-Jacobi-ancestor theorem for Type A/B signature layers;

17. an infinite exact power-of-two shadow lattice based on `T_{2^a}=-<2>` modulo `2^(a+2)-1` and the divisibility relation `a+2 | b+2`;

18. the resulting infinite family, and density-one subsequence statement, of structurally impossible power-of-two minimal depths;

19. the binary-versus-odd-prime-power trap-coset dichotomy.

The targeted searches did not surface these exact objects as an integrated Type-A/B-specific framework. A second search specifically using combinations of “Erdős-Straus”, powers of two, `4k-1`, Mersenne moduli, Type A/B, shadow/redundancy, and congruence containment likewise did not surface the exact Mersenne shadow-lattice theorem recorded here.

That is encouraging but insufficient for a priority claim. Equivalent ideas could exist under different notation, in non-arXiv literature, theses, books, conference material, computational notes, or unpublished work.

## Important novelty exclusions

The following must **not** be advertised as FCF discoveries by themselves:

- density-one solvability of Erdős-Straus;
- the fact that simple divisor/congruence criteria solve almost all integers or primes;
- general sieve survival probabilities;
- general congruence redundancy or covering-system ideas;
- CRT independence for a new coprime modulus;
- Dirichlet realization of a reduced arithmetic progression;
- elementary group-index factorization or character duality in isolation;
- the classical identity `2^u-1 | 2^v-1 iff u|v` in isolation;
- quadratic reciprocity or Jacobi-symbol facts in isolation.

The candidate novelty is the way these ingredients arise as a coherent obstruction theory inside the López Type A/B minimal-depth system.

## Current strongest candidate

The strongest responsible mathematical novelty statement is now broader than the original shadow-only wording:

> FCF has identified a potentially novel Type-A/B-specific minimal-depth framework for the Erdős-Straus problem, combining `C_AB`, congruence-layer shadowing, exact-depth spectra and arrival, exact survivor mass/hazard, a prime-modulus backbone, character and multiplicative quotient structure, and explicit infinite structural-gap families.

This should still be described as **potentially novel** until a publication-grade literature review and external mathematical review are complete.

## Integration record

The current synthesis is [`DIAMOND.md`](DIAMOND.md). The moving edge is [`CURRENT-FRONTIER.md`](CURRENT-FRONTIER.md).

New theorem records include:

- [`CHARACTER-SHIELD-COMPLETENESS.md`](CHARACTER-SHIELD-COMPLETENESS.md)
- [`QUADRATIC-SIGNATURE-COSET.md`](QUADRATIC-SIGNATURE-COSET.md)
- [`PROPER-JACOBI-ANCESTOR.md`](PROPER-JACOBI-ANCESTOR.md)
- [`MULTIPLICATIVE-TRAP-COSET.md`](MULTIPLICATIVE-TRAP-COSET.md)
- [`TRAP-QUOTIENT-FACTORIZATION.md`](TRAP-QUOTIENT-FACTORIZATION.md)
- [`SQUARE-LIFT-CORE.md`](SQUARE-LIFT-CORE.md)
- [`MERSENNE-SHADOW-LATTICE.md`](MERSENNE-SHADOW-LATTICE.md)
- [`PRIME-POWER-TRAP-DICHOTOMY.md`](PRIME-POWER-TRAP-DICHOTOMY.md)

## Next prior-art work

A publication-grade review should expand beyond keyword search and trace citations backward and forward from López 2022/2024, Salez, Mordell-related congruence results, Monks/Velingker, Vaughan, Elsholtz/Tao, Elsholtz/Planitzer, and modern divisor parametrizations.

The new group/character results also warrant searching broader literature under:

- multiplicative characters of divisor-generated subgroups;
- quadratic-signature affine subspaces;
- subgroup coset coverings;
- Mersenne divisibility lattices in congruence sieves;
- redundant congruence systems with `2^n-1` moduli;
- covering systems and subgroup-generated residue sets;
- stopping depths / first-hit times in arithmetic sieves.
