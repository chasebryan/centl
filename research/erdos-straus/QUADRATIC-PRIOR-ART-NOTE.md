# Quadratic-character prior-art note

**Date:** 2026-08-14  
**Purpose:** claim calibration for [`QUADRATIC-TRAP-SIGNATURE.md`](QUADRATIC-TRAP-SIGNATURE.md)  
**Status:** primary-source correction and novelty boundary

The quadratic-character branch must be stated carefully.

## López 2024 already contains an essential part

Miguel Angel López, *A Complete Congruence System for the Erdos-Straus Conjecture* (arXiv:2404.01508), explicitly invokes Mordell's restriction that a residue class supporting a polynomial Erdős-Straus identity cannot be a quadratic residue modulo the identity modulus.

More specifically, López's Corollary 1 states for Type B parameters `d,n` that

\[
\left(\frac{-n}{4dn-1}\right)=-1.
\]

Therefore the Type B half of the FCF/CENTL observation that trap residues have Jacobi sign `-1` is **prior art** and must not be claimed as an FCF discovery.

The current FCF theorem packages both Type B residues `-e` and Type A residues `-4e` for every divisor `e|k` into one trap-set statement

\[
T_k=\{-e,-4e:e\mid k\}
\subseteq
\{u:(u/(4k-1))=-1\}.
\]

The Type A half is elementary from the same reciprocity calculation and is also consonant with Mordell's general quadratic-residue restriction. It should therefore be treated as a useful unification/lemma, not advertised as a major standalone novelty claim.

## Stronger candidate contribution

The potentially novel object is not merely the sign of one trap residue. It is the use of that sign inside the **minimal-depth / shadow framework** to construct a simultaneous character avoidance system.

For a target candidate `x=r mod L`, FCF introduces one Legendre-sign variable for each free odd prime coordinate and imposes, for every earlier modulus `m_j`, the linear condition over `F_2` forcing

\[
\left(\frac{x}{m_j}\right)=+1.
\]

A solution to that finite linear system produces a reduced arithmetic progression that avoids every earlier Type A/B trap simultaneously and therefore gives infinitely many exact-depth primes by Dirichlet.

Targeted searching on 2026-08-14 did not locate this exact **simultaneous character-shield construction for López Type A/B minimal witness depth**, but that negative result does not establish priority.

## Safe claim language

Safe:

> López already records the quadratic-nonresidue property for Type B congruences. FCF is investigating a broader Type-A/B trap-set formulation and, more importantly, a simultaneous quadratic-character shield that turns exact-depth avoidance into a finite linear system over `F_2` inside the `C_AB`/shadow framework.

Unsafe:

> FCF discovered that López Type B residues are quadratic nonresidues.

## Primary source

- Miguel Angel López, *A Complete Congruence System for the Erdos-Straus Conjecture*, arXiv:2404.01508, especially the introduction's discussion of Mordell and Corollary 1 following the Type B perfect-square theorem.

This note should be consulted before any public novelty claim involving quadratic residues, Jacobi symbols, or the character shield.
