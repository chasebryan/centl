# CENTL physics engine

Status: experimental physics engine foundation on the development path after 0.11.0.

CENTL Physics extends the exact-first mathematical kernel with typed physical
quantities and deterministic particle simulation. Rational inputs remain exact
through unit conversion, force evaluation, collision formulas, and fixed-step
time evolution. A physics result is not silently coerced across incompatible
physical dimensions.

The initial engine is available as the `Centl_physics` OCaml module and through
the `centl-physics` command-line executable.

## Implemented now

### Dimensions and units

The engine represents all seven SI base dimensions:

- length
- mass
- time
- electric current
- thermodynamic temperature
- amount of substance
- luminous intensity

Derived dimensions are composed algebraically. Addition and subtraction require
identical dimensions. Multiplication and division compose dimensions. Unit
conversion is exact when the unit scale is rational.

The initial unit catalog includes `m`, `cm`, `mm`, `km`, `s`, `ms`, `min`, `h`,
`kg`, `g`, `A`, `K`, `mol`, `cd`, `m/s`, `m/s^2`, `N`, `J`, `Pa`, `Hz`, `C`,
`W`, `V`, `N/m`, `kg/s`, `m^2`, `J*s`, `J/K`, and `1/mol`.

For example:

```sh
centl-physics convert 100 cm m
```

prints:

```text
1
```

An incompatible conversion fails instead of producing a number:

```sh
centl-physics convert 1 m s
```

### Vectors

Three-dimensional vectors carry a physical dimension. The engine implements
addition, subtraction, scalar scaling, dot products, cross products, and exact
squared norms. Vector addition and subtraction reject mismatched dimensions.

### Particle state

A particle has:

- a stable identifier
- positive mass
- three-dimensional position
- three-dimensional velocity

Mass, position, and velocity are dimension-checked when the particle is
constructed.

### Forces

The initial force-model interface supports composable state-dependent forces.
Built-in models are:

- constant force
- uniform gravity
- Hooke-law spring force about a fixed anchor
- linear velocity drag

Net force is accumulated exactly before acceleration is derived from `F / m`.

### Deterministic time evolution

The first integrator is fixed-step symplectic Euler. For each step CENTL
computes acceleration from the current state, updates velocity, then updates
position with the new velocity.

With rational mass, state, force parameters, and time step, every intermediate
state is represented by an arbitrary-precision rational. The engine does not
introduce binary floating-point rounding into this path.

A safety limit rejects simulations longer than 1,000,000 steps in one call.

Example:

```sh
centl-physics gravity 2 0,0,10 1,0,0 0,0,-10 1/10 10
```

prints:

```text
integrator=symplectic-euler
steps=10
position=1,0,9/2 m
velocity=1,0,-10 m/s
```

The `9/2` position is the exact result of the documented discrete integrator;
it is not presented as the analytic continuous-time solution.

### Diagnostics

The library exposes exact momentum and kinetic-energy calculations, uniform
gravity potential energy, spring potential energy, and exact invariant
comparison. An invariant report distinguishes exact equality from a nonzero
delta.

### Elastic collisions

The initial collision primitive solves ideal one-dimensional perfectly elastic
collisions for two positive masses with exact rational arithmetic. It preserves
the algebraic momentum and kinetic-energy identities of that model.

### Sphere worlds and exact contact composition

The bounded world layer accepts at most 256 particles, requires non-empty
unique identifiers, and exposes exact whole-world momentum and kinetic-energy
diagnostics. Sphere worlds are additionally bounded to 4,096 unordered contact
pairs.

Sphere pairs are classified exactly as `separated`, `touching`, or
`overlapping` by comparing squared center distance with the squared sum of
radii. No square root, floating-point normalization, or penetration correction
is introduced.

The JSONL service exposes `analyze_sphere_contacts` and
`resolve_isolated_elastic_sphere_contacts`. Resolution is failure-atomic:
overlap is deferred, and a world in which one particle belongs to multiple
simultaneous touching pairs is deferred as
`ambiguous_simultaneous_contacts`. Disjoint touching pairs are passed to the
exact frictionless 3D elastic response independently, with exact momentum and
kinetic-energy checks.

The contract deliberately excludes continuous collision detection, penetration
correction, friction, spin, and general rigid-body contact graphs. The
`scripts/centl_contact_demo.py` script exercises the live JSONL contract.

The 3D response remains a collision-response primitive: it assumes the caller
has supplied distinct-center contact geometry and does not infer radii itself.

### Physical constants

The first constant catalog deliberately contains only exact SI defining or
conventional values:

- speed of light in vacuum, `c`
- Planck constant, `h`
- elementary charge, `e`
- Boltzmann constant, `k_B`
- Avogadro constant, `N_A`
- standard acceleration of gravity, `g0`

Each entry carries provenance text and an explicit exact-value flag. Measured
constants such as the Newtonian gravitational constant are intentionally not
included until CENTL has a first-class uncertainty/provenance representation.

Example:

```sh
centl-physics constant c
```

## Numerical contract

The physics engine follows CENTL's exact-first philosophy:

1. Decimal and rational inputs are parsed as exact rationals.
2. Rational unit scales are exact.
3. Dimension mismatches are errors, not implicit coercions.
4. The fixed-step engine evolves rational states using exact rational arithmetic.
5. Discrete simulation results are identified as results of the chosen
   integrator; they are not claimed to equal a closed-form continuous solution.
6. No measured quantity is silently promoted to mathematical exactness.

## Current boundary

The engine is now real, but it is intentionally small. The following are not
implemented yet:

- rigid-body orientation and angular inertia tensors
- general geometric broad-phase collision detection
- continuous collision detection
- constraints, joints, and contact manifolds
- frictional contact solvers
- adaptive or higher-order ODE integrators
- rigorous enclosure propagation for truncation error
- measured-constant uncertainty propagation
- relativistic, quantum, continuum, fluid, or field solvers
- a physics surface in the main `centl` expression grammar, JSON protocol, or MCP

Those are future engine layers. The present implementation is a deterministic,
dimension-safe, exact-rational particle mechanics foundation with a public CLI
and library API.

## Validation

`dune runtest` exercises:

- exact unit conversion
- dimension mismatch rejection
- vector algebra
- an exact ten-step gravity trajectory
- spring force and potential energy
- kinetic energy
- ideal elastic-collision momentum and energy conservation
- exact physical constants
- CLI success and failure behavior

The repository-level randomized `./executeme` gauntlet remains complementary:
it stresses mathematical physics identities, while these tests exercise the
actual stateful physics engine implementation.
