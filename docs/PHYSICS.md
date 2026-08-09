# CENTL physics engine

Status: experimental physics engine foundation on the development path after 0.11.0.

CENTL Physics extends the exact-first mathematical kernel with typed physical
quantities and deterministic particle simulation. Rational inputs remain exact
through unit conversion, force evaluation, collision formulas, contact
classification, and fixed-step time evolution. A physics result is not silently
coerced across incompatible physical dimensions.

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

### Multi-particle world and exact sphere contact classification

The library has a bounded deterministic world layer for ordered particle state.
A world accepts at most 256 particles, requires every particle identifier to be
non-empty and unique, preserves particle order across a step, and exposes exact
whole-world vector momentum and kinetic-energy diagnostics.

`step_world_symplectic_euler` applies the existing exact particle transition to
each particle using the supplied force models. This first world transition does
not implicitly detect or resolve collisions and does not invent pairwise force
models. Contact processing remains a separate operation.

For contact geometry, a particle may be paired with a positive exact-rational
sphere radius. CENTL classifies each sphere pair as exactly one of:

- `separated`
- `touching`
- `overlapping`

The classifier compares the exact squared center distance with the exact square
of the summed radii. It therefore needs no square-root normalization and keeps
rational positions and radii rational. The bounded sphere-world operation
enumerates unordered pairs deterministically and can return only exactly
`touching` pairs when requested.

`overlapping` is a first-class result. CENTL does not silently move penetrated
particles apart or reinterpret overlap as an instantaneous contact suitable for
an elastic impulse. Likewise, `touching` identifies geometric contact only; the
separate collision-response primitive still decides whether the relative normal
motion requires an impulse.

### Exact isolated contact composition

`resolve_isolated_elastic_touching_contacts` composes exact sphere contact
detection with the existing exact 3D elastic response under a deliberately
narrow world-level contract.

The operation first classifies every unordered sphere pair. Its decision rules
are deterministic:

1. If any pair is `overlapping`, the entire operation returns `Deferred` with
   `overlap_detected`. No particle is modified. Overlap has precedence over any
   other contact condition.
2. Otherwise, if any particle belongs to more than one simultaneous `touching`
   pair, the entire operation returns `Deferred` with
   `ambiguous_simultaneous_contacts`. No particle is modified.
3. Otherwise the touching pairs form a disjoint matching. Each pair is passed to
   `elastic_collision_3d_at_contact` independently, and the resulting velocities
   are installed while preserving sphere order, positions, masses, identifiers,
   and radii.
4. If there are no touching pairs, the operation completes with the unchanged
   world and an empty pair-response list.

A completed result returns the per-pair `resolved` or
`separating_or_stationary` response status plus exact whole-world momentum and
kinetic-energy conservation flags.

The disjoint-matching restriction is an assurance boundary, not a claim that
simultaneous multi-contact physics has a unique pairwise solution. CENTL does
not choose an arbitrary impulse order for a contact graph such as A-B-C, and it
does not reinterpret an already penetrated configuration as a valid contact
state. This operation is also not part of the time integrator: detection and
response remain explicit operations.

The world/contact and isolated-composition layers are machine-facing through
the version-1 JSON Lines physics protocol and the read-only `centl_physics` MCP
tool. `analyze_sphere_contacts` exposes exact geometry and evidence without
mutation. `resolve_isolated_elastic_sphere_contacts` exposes the partial exact
resolver and returns an explicit `deferred` verdict when CENTL cannot justify a
unique operation. These are not automatic time-step hooks and are not separate
human CLI subcommands.

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

These are collision-response primitives, not a general rigid-body solver. The
3D response operation does not infer radii, establish contact by itself, correct
penetration, model spin or torque, or apply friction.

### Certified bounded continuous sphere contact

`certify_linear_sphere_contact` certifies whether two exact-rational spheres
make contact during a bounded interval when both centers follow constant
exact-rational velocity throughout that interval.

For initial relative center position `r`, relative velocity `v`, and summed
radius `R`, CENTL reasons exactly about

```text
f(t) = |r + v t|^2 - R^2
     = a t^2 + b t + c
```

where `a = v·v`, `b = 2(r·v)`, and `c = r·r - R^2`. Since the quadratic is
convex, CENTL can minimize it exactly on `[0,duration]` and certify contact or
non-contact over the whole admitted interval without time sampling.

The certificate returns one of five statuses:

- `initially_overlapping`
- `touching_at_start`
- `no_contact_in_interval`
- `tangent_contact`
- `crossing_contact`

For a crossing, an exact rational first-contact time is returned when the
quadratic discriminant is a perfect rational square. When the first-contact time
is quadratic irrational, CENTL does not manufacture a decimal or rational
timestamp: it preserves the exact polynomial and discriminant and returns a
certified rational bracket for the algebraic event.

A zero bounded minimum is not automatically treated as tangency. If first
contact occurs exactly at the interval endpoint and the discriminant is
positive, the certificate reports `crossing_contact`; true tangency requires a
repeated root.

The operation requires distinct particle identifiers, positive sphere radii,
dimension-checked position and velocity, and a nonnegative duration carrying
the time dimension. It does not mutate either sphere or apply a collision
impulse.

This is a narrow certified continuous-contact contract, not a general CCD
engine. It does not reason about acceleration or force-integrated trajectories,
guarantee that a symplectic-Euler step follows the admitted linear path, resolve
penetration, order simultaneous contact events, or solve friction/spin/rigid-body
contact. See [PHYSICS_LINEAR_CONTACT.md](PHYSICS_LINEAR_CONTACT.md) for the
formal boundary.

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

Capability discovery advertises the exact supported machine actions, including
`elastic_collision_1d`, `elastic_collision_3d_at_contact`,
`analyze_sphere_contacts`, `resolve_isolated_elastic_sphere_contacts`, and
`certify_linear_sphere_contact`. Contact-world requests are bounded to 4,096
unordered sphere pairs. Detailed world analysis expands only non-separated
pairs while the summary still counts every pair.

A resolver `deferred` result is a successful exact physics verdict, not a
malformed request or MCP tool error. It means CENTL exactly identified a valid
world outside the current solver's justified response domain. Overlap and
shared simultaneous-contact ambiguity return the original world unchanged, so
machine callers do not have to infer whether a partial impulse was applied.

The continuous contact action exposes its exact polynomial evidence, closest
time, minimum clearance, discriminant, and typed first-contact representation.
Its trust boundary explicitly records constant velocity, exact sphere geometry,
no time sampling, no floating-point root finding, no force integration, no
automatic response, and no simultaneous-contact solving.

Physics simulation calls retain deterministic request, step, trajectory, and
cancellation limits. Sphere/contact requests remain stateless and bounded and
do not create persistent physical worlds inside the server.

## Numerical contract

The physics engine follows CENTL's exact-first philosophy:

1. Decimal and rational inputs are parsed as exact rationals.
2. Rational unit scales are exact.
3. Dimension mismatches are errors, not implicit coercions.
4. Fixed-step particle and world transitions preserve rational state using
   exact rational arithmetic.
5. Discrete simulation results are identified as results of the chosen
   integrator; they are not claimed to equal a closed-form continuous solution.
6. Sphere contact classification uses exact squared-distance comparisons and
   distinguishes separation, contact, and overlap.
7. World-level elastic composition is admitted only for disjoint exact touching
   pairs; overlap and shared simultaneous contacts defer without mutation.
8. Collision response remains distinct from contact detection, and the direct
   3D machine response reports its caller-supplied contact assumption explicitly.
9. Machine-facing contact evidence exposes the exact geometric basis of a
   touching or overlapping verdict rather than only a human-readable label.
10. Bounded continuous sphere contact is certified only for the declared
    constant-velocity pair model; irrational first-contact time remains an
    algebraic certificate instead of being rounded into a fake rational time.
11. No measured quantity is silently promoted to mathematical exactness.

## Current boundary

The engine is now real, but it is intentionally small. The following are not
implemented yet:

- rigid-body orientation and angular inertia tensors
- spatial broad-phase collision acceleration
- general-shape narrow-phase collision detection
- general or force-driven continuous collision detection
- penetration correction or contact manifolds
- simultaneous multi-contact event ordering or impulse solving
- automatic collision processing inside world time stepping
- constraints and joints
- frictional contact solvers
- adaptive or higher-order ODE integrators
- rigorous enclosure propagation for truncation error
- measured-constant uncertainty propagation
- relativistic, quantum, continuum, fluid, or field solvers
- a physics surface in the main `centl` expression grammar

Those are future engine layers. The present implementation is a deterministic,
dimension-safe, exact-rational particle mechanics foundation with library, CLI,
JSON Lines, and MCP interfaces. Multi-particle world state, exact discrete sphere
contact classification, isolated exact contact resolution, and bounded
constant-velocity continuous sphere-contact certificates now cross the machine
boundary while remaining deliberately separate from automatic time stepping.

The next difficult boundary is certified event-aware evolution: composing event
evidence with state advancement and exact response without silently changing the
integrator, rounding algebraic event time, or inventing semantics for
force-driven or simultaneous multi-contact cases.

## Validation

`dune runtest` exercises:

- exact unit conversion
- dimension mismatch rejection
- vector algebra
- an exact ten-step gravity trajectory
- spring force and potential energy
- kinetic energy
- exact multi-particle world momentum and kinetic energy
- deterministic ordered world stepping
- duplicate world-identifier rejection
- exact separated, touching, and overlapping sphere classification
- fractional exact contact without square-root normalization
- deterministic sphere-pair ordering
- isolated touching-pair elastic composition
- separating touching-pair no-impulse composition
- no-contact world completion without mutation
- overlap deferral without mutation
- shared simultaneous-contact deferral without mutation
- deterministic resolution of multiple disjoint touching pairs
- overlap precedence over simultaneous-contact ambiguity
- exact whole-world conservation checks after completed contact composition
- ideal 1D elastic-collision momentum and energy conservation
- exact 3D head-on and oblique contact response
- separating-contact no-impulse behavior
- coincident-center rejection
- rational continuous first-contact time
- first contact exactly at the bounded interval endpoint
- exact tangent contact
- quadratic-irrational first-contact certification and rational bracketing
- short-interval continuous no-contact certification
- parallel and stationary continuous-contact misses
- continuous contact at time zero and initial overlap
- distinct-ID and duration-dimension enforcement for continuous contact
- JSON and MCP 3D collision surfaces and the explicit contact trust boundary
- JSON Lines exact sphere-contact analysis and squared-distance evidence
- JSON Lines completed isolated sphere-contact resolution and conservation flags
- JSON Lines overlap and simultaneous-contact deferral semantics
- JSON Lines rational, irrational, endpoint, and no-contact continuous certificates
- MCP sphere-contact analysis and resolution
- MCP `deferred` verdicts remaining successful tool results
- MCP rational and quadratic-irrational continuous-contact certificates
- strict MCP rejection of unknown sphere/contact arguments
- the 4,096-pair machine-interface contact ceiling
- exact physical constants
- CLI success and failure behavior

The repository-level randomized `./executeme` gauntlet remains complementary:
it stresses mathematical physics identities, while these tests exercise the
actual stateful physics engine implementation and its typed machine boundaries.
