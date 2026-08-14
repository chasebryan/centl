# Prior-art matrix for WS-CAND-003

**Search date:** 2026-08-14

**Status:** working research record. A negative search result is not proof of novelty or priority.

This file records the targeted primary-literature pass used to calibrate claims around `C_AB`, exact trap cardinality, and congruence-layer shadowing.

## Primary sources reviewed

### Miguel Angel López, 2024

*A Complete Congruence System for the Erdos-Straus Conjecture*  
https://arxiv.org/abs/2404.01508

Relevant prior art:

- Type A and Type B solution classes;
- congruence characterizations involving `4dn-1`;
- conjecture that every prime has a Type A or Type B solution;
- relation to Type II solutions and classical Mordell restrictions;
- experimental Type A/B coverage reported for the first 10,000 primes.

Not claimed by FCF: Type A, Type B, their basic congruence formulas, or the general idea of using congruence systems to attack Erdős-Straus.

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

6. an irredundant-core reduction of the López Type A/B congruence system based on those shadow relations.

The targeted searches did not surface these exact objects under the terminology above. That result is encouraging but insufficient for a priority claim because equivalent ideas could exist under different notation, in non-arXiv literature, theses, books, conference material, computational notes, or unpublished work.

## Current claim boundary

The strongest responsible wording remains:

> FCF has identified a potentially novel structural framework for measuring and reducing López Type A/B congruence systems in the Erdős-Straus problem, centered on minimal witness depth and congruence-layer shadowing.

Do not replace `potentially novel` with `new`, `first`, `discovered`, or an equivalent priority claim until a broader literature review and independent mathematical review are complete.

## Next prior-art work

A publication-grade review should expand beyond keyword search and trace citations backward and forward from López 2022/2024, Salez, Mordell-related congruence results, Monks/Velingker, Elsholtz/Tao, and modern divisor parametrizations. Search terms should include covering systems, congruence inclusion, redundant congruence classes, minimal parameter/product, nested moduli, first-hit sieves, residue-class containment, and divisor-generated modular systems.
