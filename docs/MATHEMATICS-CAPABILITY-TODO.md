# CENTL Mathematics Capability Program

Status: active strategic backlog for mathematical breadth.

This document is the long-horizon capability inventory for CENTL mathematics.
`CENTL-TODO.md` remains the short-term working checklist. A capability is not
considered implemented merely because CENTL can parse a similar expression or a
backend can numerically evaluate one example.

The inventory is informed by public mathematical capability guides from mature
computer-algebra systems, especially the Wolfram Language documentation, but it
is **not** an API-cloning plan. CENTL chooses its own syntax, representations,
algorithms, refusal semantics, provenance model, and assurance boundaries.
Public documentation is used only as a breadth benchmark.

Every unchecked item must satisfy
[MATHEMATICS-IMPLEMENTATION-STANDARD.md](MATHEMATICS-IMPLEMENTATION-STANDARD.md)
before it is checked.

## Status key

- `[x]` means the specifically stated CENTL slice exists now.
- `[ ]` means the stated slice is not yet admitted as a completed CENTL capability.
- A checked narrow slice does not imply that the surrounding mathematical field
  is complete.
- Unsupported inputs must remain explicit until a conforming implementation lands.

## Priority order

The preferred order is structural, not promotional:

1. **P0 — scalar and algebraic substrate:** complex values, algebraic numbers,
   multivariate polynomial algebra, matrices, general linear systems.
2. **P1 — analysis and number theory:** limits, series, broader integration,
   transforms, finite fields, analytic and algebraic number theory.
3. **P2 — tensors, geometry, optimization, probability/statistics, differential
   equations, and special functions.**
4. **P3 — advanced symbolic/numerical breadth and science-specific certified
   models built on the completed mathematical substrate.**

A lower-priority capability may land earlier when it has a narrow exact contract
and does not distort the architecture. Cherenkov radiation is an example: its
threshold and cone relation form a small exact-rational certificate.

---

# A. Core numerical and symbolic domains

## A1. Exact scalar arithmetic

- [x] Unbounded integers.
- [x] Exact rational arithmetic with normalized fractions.
- [x] Finite decimal literals interpreted as exact rationals.
- [x] Exact comparisons over represented exact scalars.
- [ ] Gaussian integer scalar domain.
- [ ] General exact complex rational scalar domain.
- [ ] Exact complex algebraic scalar domain.
- [ ] Complex rigorous enclosures with explicit branch/domain semantics.
- [ ] Signed infinity and directed infinity values with audited algebraic rules.
- [ ] Extended-real value domain with explicit indeterminate cases.

## A2. Rigorous approximation

- [x] Real rigorous enclosure evaluation for admitted constants and elementary
  functions.
- [x] Justified decimal rendering from proven enclosing intervals.
- [x] Precision escalation with bounded resource limits.
- [ ] Complex ball/enclosure arithmetic as a first-class result model.
- [ ] Certified relative-error requests.
- [ ] Certified absolute-error requests independent of decimal rendering.
- [ ] Interval-valued inputs and interval propagation.
- [ ] Rigorous root isolation for general admitted univariate functions.
- [ ] Rigorous numerical quadrature with returned error/enclosure evidence.
- [ ] Rigorous numerical differentiation with returned error/enclosure evidence.

## A3. Mathematical constants

- [x] Exact symbolic constants such as `pi` where a symbolic exact form is
  appropriate.
- [x] Exact SI defining constants in CENTL Physics where their decimal values are
  definitions rather than measurements.
- [ ] Catalog metadata for common mathematical constants.
- [ ] Algebraic-constant recognition where exact identity can be established.
- [ ] Constant relationship queries with explicit proof/evidence status.

## A4. Elementary functions

- [x] Rigorous approximation path for admitted elementary transcendental
  functions.
- [x] Exact differentiation rules for admitted trigonometric, inverse
  trigonometric, hyperbolic, exponential, logarithmic, and square-root forms.
- [ ] First-class exact complex semantics for exponential and logarithm.
- [ ] First-class exact complex semantics for trigonometric and hyperbolic
  functions.
- [ ] Branch-aware inverse functions.
- [ ] Piecewise functions as a canonical symbolic value.
- [ ] `min`/`max`/absolute-value simplification under explicit assumptions.
- [ ] Function property engine for parity, periodicity, zeros, poles,
  singularities, monotonicity, injectivity, and sign where decidable.

## A5. Generalized and distribution-valued functions

- [ ] Heaviside step function with explicit convention at the origin.
- [ ] Dirac delta as a symbolic distribution, never a pointwise ordinary
  function.
- [ ] Dirac comb.
- [ ] Principal-value symbolic objects.
- [ ] Distributional differentiation rules.
- [ ] Distribution-aware transforms and integration.

---

# B. Algebra and equation solving

## B1. Symbolic manipulation

- [x] Bounded simplification of admitted exact expressions.
- [x] Bounded polynomial expansion.
- [x] Initial exact factorization classes for rational univariate polynomials.
- [x] Exact substitution.
- [x] Explicit local assumptions retained in results.
- [ ] Canonical rational-function normalization.
- [ ] Partial-fraction decomposition.
- [ ] Assumption-aware simplification across inequalities and sign conditions.
- [ ] Algebraic transformation receipts showing conditions introduced or used.
- [ ] Expression complexity metrics used to prevent simplification blowups.

## B2. Polynomial algebra

- [x] Canonical rational-coefficient univariate polynomials.
- [x] Canonical multivariate polynomials.
- [x] Coefficient extraction and coefficient arrays.
- [x] Polynomial content and primitive-part decomposition.
- [x] Polynomial quotient and remainder.
- [x] Polynomial GCD and extended GCD.
- [x] Square-free factorization.
- [ ] General exact factorization over the rationals.
- [ ] Factorization over finite fields.
- [ ] Factorization over algebraic extensions.
- [ ] Resultants.
- [ ] Discriminants.
- [ ] Subresultant sequences.
- [ ] Groebner bases with explicit monomial ordering.
- [ ] Ideal-membership / polynomial-reduction certificates.
- [ ] Symmetric polynomial reduction.
- [ ] Cyclotomic polynomials.
- [ ] Sum-of-squares polynomial certificates where supported.

## B3. Algebraic numbers

- [x] Equation-local exact real quadratic root representation.
- [ ] General algebraic-number scalar representation.
- [ ] Minimal polynomials.
- [ ] Isolating intervals / regions.
- [ ] Algebraic-number equality and ordering on the real subdomain.
- [ ] Algebraic arithmetic with canonical reduction.
- [ ] Root objects for irreducible polynomial roots.
- [ ] Root-to-radicals conversion when mathematically available and requested.
- [ ] Algebraic extension fields.
- [ ] Roots of unity as exact algebraic values.

## B4. Equations and inequalities

- [x] Exact admitted linear equations.
- [x] Exact real quadratic equations with rational coefficients.
- [ ] General exact linear systems.
- [ ] Polynomial systems over rationals/reals/complexes.
- [ ] General univariate polynomial root isolation.
- [ ] Exact cubic and quartic solving where a justified representation exists.
- [ ] Higher-degree algebraic solutions through root objects.
- [ ] Numeric root finding with rigorous enclosures.
- [ ] Systems of inequalities over the reals.
- [ ] Cylindrical algebraic decomposition.
- [ ] Quantifier elimination over admitted real polynomial formulas.
- [ ] Integer linear equations and inequalities.
- [ ] Diophantine polynomial equation support with explicit completeness class.
- [ ] `find-instance` style witness production with a witness certificate.
- [ ] Symbolic parameter conditions for solvability.

## B5. Recurrences and functional equations

- [x] Bounded first-order recurrence evaluation.
- [ ] Exact linear recurrence solving.
- [ ] Characteristic-polynomial recurrence methods.
- [ ] Rational generating-function derivation for admitted recurrences.
- [ ] Asymptotic recurrence solutions.
- [ ] Functional-equation solving for narrowly certified families.

---

# C. Calculus and analysis

## C1. Differentiation

- [x] Exact symbolic differentiation for the admitted scalar grammar.
- [ ] Partial derivatives of multivariate functions.
- [ ] Total derivatives with dependency declarations.
- [ ] Implicit differentiation.
- [ ] Higher derivatives with canonical simplification.
- [ ] Jacobians.
- [ ] Hessians.
- [ ] Directional derivatives.
- [ ] Derivatives of piecewise functions with domain annotations.
- [ ] Distributional derivatives.

## C2. Integration

- [x] Exact indefinite rational-univariate-polynomial integration.
- [x] Exact definite rational-univariate-polynomial integration over rational
  bounds.
- [ ] Rational-function symbolic integration.
- [ ] Elementary-function symbolic integration with explicit residuals.
- [ ] Special-function antiderivatives where the returned representation is
  supported.
- [ ] Multivariate iterated integration.
- [ ] Improper integrals with convergence conditions.
- [ ] Principal-value integration.
- [ ] Rigorous numerical quadrature.
- [ ] Region integration.
- [ ] Parameterized integration with explicit validity conditions.

## C3. Limits and asymptotics

- [ ] One-sided limits.
- [ ] Two-sided limits.
- [ ] Limits at infinity.
- [ ] Multivariate limits with path sensitivity surfaced explicitly.
- [ ] Series expansion about regular points.
- [ ] Laurent series.
- [ ] Puiseux series for admitted algebraic functions.
- [ ] Asymptotic series.
- [ ] Series algebra and composition.
- [ ] Series inversion/reversion.
- [ ] Asymptotic equivalence and dominant-balance tools.

## C4. Vector calculus

- [ ] Gradient.
- [ ] Divergence.
- [ ] Curl.
- [ ] Laplacian.
- [ ] Jacobian determinant for coordinate transforms.
- [ ] Line integrals.
- [ ] Surface integrals.
- [ ] Flux integrals.
- [ ] Coordinate-chart aware vector calculus.
- [ ] Exact verification of selected vector-calculus identities.

## C5. Integral and summation transforms

- [ ] Fourier transform and inverse transform.
- [ ] Fourier sine/cosine transforms.
- [ ] Fourier series and coefficients.
- [ ] Laplace transform and inverse transform.
- [ ] Bilateral Laplace transform.
- [ ] Mellin transform and inverse transform.
- [ ] Hankel transform and inverse transform.
- [ ] Z transform and inverse transform.
- [ ] Discrete Fourier transform.
- [ ] Discrete cosine/sine transforms.
- [ ] Wavelet transforms.
- [ ] Transform-domain condition reporting for convergence and branches.

## C6. Differential equations

- [ ] Exact first-order ODE families.
- [ ] Exact linear ODE systems.
- [ ] Higher-order ODE solving for admitted classes.
- [ ] Initial-value and boundary-value problem representation.
- [ ] Rigorous numerical ODE integration with enclosure/error semantics.
- [ ] Event handling with mathematically explicit event-location semantics.
- [ ] Differential-algebraic equations.
- [ ] Delay differential equations.
- [ ] Symbolic PDE support for narrowly admitted families.
- [ ] Rigorous numerical PDE methods only after discretization and truncation
  contracts are explicit.
- [ ] Wronskian and linear-independence diagnostics.

---

# D. Linear algebra and tensors

## D1. Vectors and matrices

- [ ] First-class exact vectors and matrices in the mathematics engine.
- [ ] Dense matrix construction and indexing.
- [ ] Sparse matrix representation.
- [ ] Matrix addition and scalar multiplication.
- [ ] Matrix multiplication.
- [ ] Dot products and norms.
- [ ] Transpose and conjugate transpose.
- [ ] Trace.
- [ ] Determinant.
- [ ] Exact matrix inverse when invertible.
- [ ] Row reduction / reduced row echelon form.
- [ ] Rank.
- [ ] Null space.
- [ ] Column and row spaces.
- [ ] Exact linear solve.
- [ ] Least squares with exact or certified-numeric semantics by input domain.
- [ ] Pseudoinverse.
- [ ] Matrix powers and matrix exponential.
- [ ] Matrix predicates: symmetry, Hermitian, orthogonal/unitary, triangular,
  definiteness, diagonalizability.

## D2. Decompositions and spectral computation

- [ ] LU decomposition.
- [ ] QR decomposition.
- [ ] Cholesky decomposition.
- [ ] Singular-value decomposition.
- [ ] Schur decomposition.
- [ ] Eigenvalues.
- [ ] Eigenvectors and eigenspaces.
- [ ] Exact characteristic and minimal polynomials.
- [ ] Certified numeric eigenvalue enclosures where exact algebraic output is not
  practical.
- [ ] Principal-component decomposition with explicit statistical semantics.

## D3. Tensors

- [ ] General-rank tensor representation.
- [ ] Tensor dimensions and rank.
- [ ] Inner and outer products.
- [ ] Tensor products.
- [ ] Tensor contraction.
- [ ] Tensor transposition / index permutation.
- [ ] Symmetric and antisymmetric tensor declarations.
- [ ] Kronecker delta and Levi-Civita tensors.
- [ ] Canonicalization under tensor symmetries.
- [ ] Wedge product.
- [ ] Hodge dual after metric/orientation semantics are explicit.
- [ ] Sparse tensors.

---

# E. Number theory

## E1. Integer structure

- [x] GCD/LCM primitives in the mathematics system.
- [x] Fibonacci primitive.
- [ ] Extended GCD.
- [ ] Divisibility and coprimality predicates.
- [ ] Exact integer factorization API with stated algorithm/resource boundary.
- [ ] Primality testing with deterministic/certificate status exposed.
- [ ] Next/previous prime.
- [ ] Prime counting.
- [ ] Prime factor multiplicity functions.
- [ ] Divisors and divisor sums.
- [ ] Euler phi.
- [ ] Moebius function.
- [ ] Mangoldt function.
- [ ] Carmichael lambda.
- [ ] Perfect/powerful/square-free/prime-power predicates.

## E2. Modular arithmetic

- [ ] Modular inverse.
- [ ] Modular exponentiation.
- [ ] Chinese remainder theorem.
- [ ] Multiplicative order.
- [ ] Primitive roots.
- [ ] Jacobi symbol.
- [ ] Kronecker symbol.
- [ ] Modular square roots.
- [ ] General polynomial congruence solving for admitted classes.

## E3. Additive and combinatorial number theory

- [ ] Integer partitions and partition counts.
- [ ] Representations as sums of squares.
- [ ] Representations as sums of powers.
- [ ] Frobenius number / coin problem.
- [ ] Bernoulli numbers.
- [ ] Stirling numbers.
- [ ] Bell numbers.

## E4. Continued fractions and recognition

- [ ] Continued-fraction expansion.
- [ ] Reconstruction from continued fractions.
- [ ] Rational reconstruction.
- [ ] Algebraic-number recognition from rigorous numeric enclosures.
- [ ] Integer-relation algorithms with certificate/verification step.

## E5. Finite fields

- [ ] Prime fields.
- [ ] Extension finite fields.
- [ ] Finite-field elements as typed exact values.
- [ ] Irreducible polynomial generation/testing.
- [ ] Primitive polynomial testing.
- [ ] Finite-field embeddings.
- [ ] Polynomial factorization over finite fields.

## E6. Analytic number theory

- [ ] Riemann zeta function.
- [ ] Hurwitz zeta function.
- [ ] Prime zeta function.
- [ ] Dirichlet characters.
- [ ] Dirichlet L-functions.
- [ ] Lerch transcendent where the special-function layer permits it.
- [ ] Prime-distribution approximants such as logarithmic integral/Riemann R.
- [ ] Certified zeta-zero evaluation/isolation for stated regions.
- [ ] Riemann-Siegel Z evaluation with rigorous numerical semantics.

## E7. Algebraic number theory

- [ ] Number fields.
- [ ] Ring of integers / integral basis.
- [ ] Field discriminant.
- [ ] Norm and trace.
- [ ] Field signature.
- [ ] Units and fundamental units.
- [ ] Regulator.
- [ ] Roots of unity in a number field.
- [ ] Class number for admitted fields.
- [ ] Ideal arithmetic only after a canonical ideal representation is specified.

---

# F. Discrete mathematics, combinatorics, and graphs

## F1. Sets, tuples, and combinatorics

- [ ] Cartesian products / tuples.
- [ ] Subsets and combinations.
- [ ] Permutations.
- [ ] Permutation sign/parity.
- [ ] Set union/intersection/difference.
- [ ] Multisets.
- [ ] Compositions and integer partitions.
- [ ] Enumeration with exact counts.
- [ ] Combinatorial ranking/unranking where useful.

## F2. Group theory

- [ ] Permutation groups.
- [ ] Group order.
- [ ] Group element membership.
- [ ] Generated subgroups.
- [ ] Cosets.
- [ ] Normal subgroups.
- [ ] Group homomorphisms for admitted finite groups.
- [ ] Conjugacy classes.
- [ ] Basic finite-group invariants.

## F3. Graph theory

- [ ] Graph value model with deterministic vertex/edge identity.
- [ ] Directed and undirected graphs.
- [ ] Weighted graphs.
- [ ] Connectivity and components.
- [ ] Paths and cycles.
- [ ] Shortest paths.
- [ ] Minimum spanning trees.
- [ ] Planarity tests.
- [ ] Graph coloring.
- [ ] Matchings.
- [ ] Network flows.
- [ ] Graph isomorphism / canonical labeling with explicit algorithm boundary.
- [ ] Spectral graph quantities after matrix support lands.
- [ ] Standard graph invariants.

## F4. Discrete calculus and sequences

- [x] Exact bounded sums.
- [x] Exact bounded products.
- [x] Exact bounded sequences.
- [ ] Finite differences.
- [ ] Indefinite summation for admitted hypergeometric/rational families.
- [ ] Symbolic product evaluation for admitted families.
- [ ] Generating functions.
- [ ] Sequence recognition with evidence and non-uniqueness warnings.

---

# G. Geometry

## G1. Exact geometric primitives

- [ ] Points, vectors, lines, rays, segments.
- [ ] Circles and spheres.
- [ ] Polygons and polyhedra.
- [ ] Affine subspaces.
- [ ] Exact distances and squared distances where possible.
- [ ] Angles with exact trigonometric representation.
- [ ] Intersections with explicit multiplicity/degeneracy handling.
- [ ] Areas and volumes.
- [ ] Orientation predicates.

## G2. Geometric transformations

- [ ] Translation.
- [ ] Scaling.
- [ ] Rotation in 2D/3D and n-dimensional matrix form.
- [ ] Reflection.
- [ ] Shearing.
- [ ] Affine transforms.
- [ ] Composition and inversion of transformations.
- [ ] Euler-angle and roll/pitch/yaw conversions with convention encoded.

## G3. Computational geometry

- [ ] Convex hull.
- [ ] Nearest-neighbor search.
- [ ] Voronoi diagrams.
- [ ] Delaunay triangulation.
- [ ] Point-in-region predicates.
- [ ] Region union/intersection/difference.
- [ ] Region measures.
- [ ] Mesh representation and exact/rigorous predicates where feasible.
- [ ] Curve and surface reconstruction only with explicit approximation semantics.

## G4. Algebraic and differential geometry

- [ ] Affine algebraic varieties from polynomial systems.
- [ ] Dimension and component information for admitted algebraic sets.
- [ ] Tangent-space/Jacobian calculations.
- [ ] Parametric curves and surfaces.
- [ ] Curvature for admitted smooth curves/surfaces.
- [ ] Metric tensor support after tensor semantics land.
- [ ] Geodesic equations as explicit differential-equation problems.

---

# H. Probability and statistics

## H1. Probability foundations

- [ ] Symbolic discrete distributions.
- [ ] Symbolic continuous distributions.
- [ ] Probability of predicates/events.
- [ ] Expectations.
- [ ] Moments and central moments.
- [ ] Variance/covariance/correlation.
- [ ] Conditional distributions and conditional expectation.
- [ ] Transformations of random variables.
- [ ] Distribution convolution.
- [ ] Characteristic and moment-generating functions.

## H2. Random generation

- [ ] Deterministically seedable pseudorandom generator interface.
- [ ] Exact random integers.
- [ ] Random rationals from explicitly finite distributions.
- [ ] Random variates for supported distributions.
- [ ] Random sampling/choice with provenance sufficient to reproduce a run.
- [ ] Cryptographic randomness kept separate from mathematical simulation RNG.

## H3. Descriptive statistics

- [ ] Mean, median, mode.
- [ ] Quantiles and quartiles.
- [ ] Variance and standard deviation.
- [ ] Skewness and kurtosis.
- [ ] Covariance and correlation matrices.
- [ ] Robust statistics.
- [ ] Weighted statistics.

## H4. Statistical inference and models

- [ ] Maximum-likelihood estimation with explicit optimization/evidence boundary.
- [ ] Method-of-moments estimation.
- [ ] Confidence intervals with declared assumptions.
- [ ] Classical hypothesis tests with exact test definition and returned p-value
  semantics.
- [ ] Linear regression.
- [ ] Generalized linear models.
- [ ] Nonlinear regression.
- [ ] Model diagnostics.
- [ ] Distribution fitting.
- [ ] Bayesian posterior calculations for narrowly admitted conjugate models
  before general sampling engines.

## H5. Stochastic processes

- [ ] Markov chains.
- [ ] Random walks.
- [ ] Poisson processes.
- [ ] Brownian motion with explicit stochastic/numerical semantics.
- [ ] Time-series model primitives after statistical foundations land.

---

# I. Optimization and operations research

## I1. Exact and symbolic optimization

- [ ] Exact linear programming over rational data where certificates can be
  checked.
- [ ] Exact rational feasibility certificates.
- [ ] Symbolic univariate polynomial extrema under explicit domain assumptions.
- [ ] Convexity predicates for admitted symbolic classes.

## I2. Numerical optimization

- [ ] Local unconstrained optimization with rigorous or explicitly heuristic
  status.
- [ ] Local constrained optimization.
- [ ] Global optimization with explicit completeness/certification class.
- [ ] Nonlinear least squares.
- [ ] Bound-constrained optimization.

## I3. Convex optimization

- [ ] Linear optimization.
- [ ] Quadratic optimization.
- [ ] Second-order cone optimization.
- [ ] Semidefinite optimization.
- [ ] General conic optimization.
- [ ] Parametric convex optimization.
- [ ] Robust convex optimization.

## I4. Discrete/combinatorial optimization

- [ ] Integer linear programming.
- [ ] Mixed-integer programming.
- [ ] Knapsack.
- [ ] Traveling-salesperson problem.
- [ ] Assignment problems.
- [ ] Minimum-cost flow.
- [ ] Constraint-satisfaction problems with explicit solver status.

---

# J. Special functions

Each family requires both symbolic-domain semantics and rigorous numerical
semantics before broad claims are made.

- [ ] Gamma and log-gamma.
- [ ] Beta and incomplete beta.
- [ ] Polygamma.
- [ ] Error functions.
- [ ] Exponential integrals.
- [ ] Sine/cosine integrals.
- [ ] Fresnel integrals.
- [ ] Bessel functions.
- [ ] Airy functions.
- [ ] Struve functions.
- [ ] Orthogonal polynomials: Legendre, Hermite, Laguerre, Chebyshev, Jacobi.
- [ ] Hypergeometric functions.
- [ ] Confluent hypergeometric functions.
- [ ] Elliptic integrals.
- [ ] Elliptic functions.
- [ ] Elliptic theta functions.
- [ ] Polylogarithms.
- [ ] Spherical harmonics.
- [ ] Mathieu-family functions.
- [ ] Meijer G / Fox H only after branch and numerical-enclosure semantics are
  sufficiently mature.

---

# K. Logic, finite mathematics, and proof-adjacent computation

- [ ] Boolean expression normalization.
- [ ] Satisfiability for propositional formulas.
- [ ] Exact finite-domain constraint solving.
- [ ] Quantified Boolean formulas only with explicit completeness limits.
- [ ] Symbolic predicates for mathematical domains (`integer`, `real`, `positive`,
  etc.) integrated with assumptions.
- [ ] Theorem-style closed claim checking extended beyond current arithmetic
  relations while preserving `verified/refuted/unknown/invalid`.
- [ ] Machine-checkable witnesses or counterexamples whenever the solver can
  produce them.
- [ ] No general theorem-prover claim until a proof object or independently
  checkable certificate model supports it.

---

# L. Certified scientific mathematics and physics

CENTL Physics is not required to reproduce a general-purpose physics package.
The rule is narrower: public scientific relations that admit a useful, explicit,
mathematically honest contract can become certified operations.

## L1. Existing foundation

- [x] Seven-base SI dimensional model.
- [x] Exact rational unit conversion for admitted rational unit scales.
- [x] Dimension-safe 3D vectors.
- [x] Exact-rational particle mechanics foundation.
- [x] Uniform gravity, constant force, Hooke spring, and linear drag models.
- [x] Deterministic symplectic-Euler stepping.
- [x] Exact elastic collision primitives and bounded sphere-contact certificates.
- [x] Exact rational Cherenkov threshold and cone-cosine certificate:
  `v > c/n`, `beta = v/c`, and `cos(theta) = 1/(beta*n)`.

## L2. Next certified formula families

- [ ] Relativistic beta/gamma/energy-momentum identities with exact or algebraic
  preservation where possible.
- [ ] Doppler shift relations with frame and sign convention explicit.
- [ ] Snell's law and critical-angle certificates.
- [ ] Brewster-angle relation.
- [ ] Thin-lens and mirror equations with sign convention encoded.
- [ ] Diffraction/grating relations with exact trigonometric representation.
- [ ] Classical wave relations: wavelength, frequency, phase/group velocity.
- [ ] Blackbody/Planck-law evaluation using measured/defined constant provenance.
- [ ] Ideal-gas and thermodynamic state relations with unit/dimension checks.
- [ ] Electrostatic/Coulomb relations after measured-constant uncertainty policy
  is available where needed.
- [ ] Lorentz-force relation with vector/tensor semantics.
- [ ] Basic circuit relations as dimension-checked algebraic systems.
- [ ] Orbital two-body relations only with a declared model and gravitational
  constant uncertainty/provenance.

## L3. Major physics domains gated on deeper mathematics

- [ ] Electromagnetic field equations after vector calculus/PDE support.
- [ ] Special-relativistic tensor mechanics after tensor support.
- [ ] Quantum linear algebra after complex matrices and spectral computation.
- [ ] Quantum dynamics after complex ODE/PDE support.
- [ ] Continuum mechanics after tensor calculus and PDE support.
- [ ] Fluid dynamics after PDE/discretization error contracts.
- [ ] General relativity only after differential geometry, tensors, and PDE
  semantics are independently mature.

---

# M. Cross-domain implementation work

These are capabilities required repeatedly across the breadth program.

- [ ] General exact complex value schema.
- [ ] General algebraic-number value schema.
- [ ] Matrix value schema.
- [ ] Tensor value schema.
- [ ] Piecewise/conditional value schema.
- [ ] Set/region value schema.
- [ ] Distribution value schema.
- [ ] Graph value schema.
- [ ] Optimization result/certificate schema.
- [ ] Differential-equation solution schema.
- [ ] Transform result schema with convergence conditions.
- [ ] Uniform condition/assumption representation across symbolic domains.
- [ ] Uniform algorithm provenance block across math/physics machine outputs.
- [ ] Independent differential-oracle harnesses by domain.
- [ ] Per-domain adversarial resource corpora.
- [ ] Per-domain metamorphic identity suites.

---

# Benchmark sources

The breadth categories above were cross-checked against public Wolfram Language
mathematics guides, including:

- Mathematical Functions: https://reference.wolfram.com/language/guide/MathematicalFunctions.html
- Elementary Functions: https://reference.wolfram.com/language/guide/ElementaryFunctions.html
- Polynomial Algebra: https://reference.wolfram.com/language/guide/PolynomialAlgebra.html
- Equation Solving: https://reference.wolfram.com/language/guide/EquationSolving.html
- Calculus: https://reference.wolfram.com/language/guide/Calculus.html
- Differential Equations: https://reference.wolfram.com/language/guide/DifferentialEquations.html
- Integral Transforms: https://reference.wolfram.com/language/guide/IntegralTransforms.html
- Matrices and Linear Algebra: https://reference.wolfram.com/language/guide/MatricesAndLinearAlgebra.html
- Tensors: https://reference.wolfram.com/language/guide/Tensors.html
- Symbolic Tensors: https://reference.wolfram.com/language/guide/SymbolicTensors.html
- Number Theory: https://reference.wolfram.com/language/guide/NumberTheory.html
- Number Theoretic Functions: https://reference.wolfram.com/language/guide/NumberTheoreticFunctions.html
- Analytic Number Theory: https://reference.wolfram.com/language/guide/AnalyticNumberTheory.html
- Algebraic Number Theory: https://reference.wolfram.com/language/guide/AlgebraicNumberTheory.html
- Discrete Mathematics: https://reference.wolfram.com/language/guide/DiscreteMathematics.html
- Computational Geometry: https://reference.wolfram.com/language/guide/ComputationalGeometry.html
- Probability and Statistics: https://reference.wolfram.com/language/guide/ProbabilityAndStatistics.html
- Optimization: https://reference.wolfram.com/language/guide/Optimization.html
- Special Functions: https://reference.wolfram.com/language/guide/SpecialFunctions.html

These references identify public capability classes. CENTL implementation must be
independently designed and must obey CENTL's stricter exactness, evidence, and
refusal contracts.