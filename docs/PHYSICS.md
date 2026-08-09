# CENTL physics engine

Status: experimental physics engine foundation on the development path after 0.11.0.

CENTL Physics extends the exact-first mathematical kernel with typed physical
quantities and deterministic particle simulation. Rational inputs remain exact
through unit conversion, force evaluation, collision formulas, and fixed-step
time evolution. A physics result is not silently coerced across incompatible
physical dimensions.

The engine is available as the `Centl_physics` OCaml module, through the
`centl-physics` command-line executable and its versioned JSON Lines server, and
through the read-only `centl_physics` MCP tool.

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
`W`, `V`, `N/m`, `kg/s`, `J*s`, `J/K`, and `1/mol`.

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

CENTL provides an ideal one-dimensional perfectly elastic collision primitive
for two positive masses with exact rational arithmetic.

It also provides `elastic_collision_3d_at_contact`, an exact rational,
frictionless three-dimensional contact-response primitive for two particles.
The caller supplies two particles already known to be at an instantaneous
contact with distinct centers. CENTL projects relative velocity onto the
line of centers without normalizing that line, so rational positions,
velocities, and masses stay rational and no square root is introduced merely
to compute the collision normal.

If the particles are approaching along the contact normal, CENTL applies the
ideal elastic normal impulse. If they are separating or stationary along that
normal, it returns `separating_or_stationary` and applies no impulse. The result
includes both final particle states and exact whole-pair checks for vector
momentum and kinetic-energy conservation.

The machine result records the trust boundary explicitly as
`caller_supplied_contact_with_distinct_centers`.

These are collision-response primitives, not geometric collision detection or
a general rigid-body solver. The 3D operation does not infer radii, establish
that contact occurred, correct penetration, model spin or torque, or apply
friction.

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

## Machine interfaces

`centl-physics --serve` exposes the implemented physics operations through a
versioned, stateless JSON Lines protocol. The main `centl --mcp` server exposes
the same deterministic physics semantics through one read-only, idempotent
`centl_physics` tool. The MCP adapter delegates to the typed physics protocol;
it does not implement a second evaluator.

Capability discovery advertises the exact supported actions, including the 1D
collision operation and `elastic_collision_3d_at_contact`. Physics simulation
calls retain deterministic request, step, trajectory, and cancellation limits.

## Numerical contract

The physics engine follows CENTL's exact-first philosophy:

1. Decimal and rational inputs are parsed as exact rationals.
2. Rational unit scales are exact.
3. Dimension mismatches are errors, not implicit coercions.
4. The fixed-step engine evolves rational states using exact rational arithmetic.
5. Discrete simulation results are identified as results of the chosen
   integrator; they are not claimed to equal a closed-form continuous solution.
6. Collision response is distinguished from contact detection, and the 3D
   contact assumption is returned explicitly.
7. No measured quantity is silently promoted to mathematical exactness.

## Current boundary

The engine is now real, but it is intentionally small. The following are not
implemented yet:

- rigid-body orientation and angular inertia tensors
- geometric broad-phase or narrow-phase collision detection
- continuous collision detection
- penetration correction or contact manifolds
- constraints and joints
- frictional contact solvers
- adaptive or higher-order ODE integrators
- rigorous enclosure propagation for truncation error
- measured-constant uncertainty propagation
- relativistic, quantum, continuum, fluid, or field solvers
- a physics surface in the main `centl` expression grammar

Those are future engine layers. The present implementation is a deterministic,
dimension-safe, exact-rational particle mechanics foundation with library, CLI,
JSON Lines, and MCP interfaces.

## Validation

`dune runtest` exercises:

- exact unit conversion
- dimension mismatch rejection
- vector algebra
- an exact ten-step gravity trajectory
- spring force and potential energy
- kinetic energy
- ideal 1D elastic-collision momentum and energy conservation
- exact 3D head-on and oblique contact response
- separating-contact no-impulse behavior
- coincident-center rejection
- JSON and MCP 3D collision surfaces and the explicit contact trust boundary
- exact physical constants
- CLI success and failure behavior

The repository-level randomized `./executeme` gauntlet remains complementary:
it stresses mathematical physics identities, while these tests exercise the
actual stateful physics engine implementation.
