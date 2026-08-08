# CENTL Physics

Status: **design only** — not scheduled for implementation until the claim
verification foundation (0.12 contracts) is finished, released, and green.

A CENTL physics engine is feasible, but the right first product is a
**unit-safe, deterministic mechanics engine** — not a real-time rigid-body or
game engine.

CENTL currently lacks first-class dimensions, units, vectors, matrices,
coordinate frames, ODE solvers, and collision handling. The product path in
[DESIGN_PATH.md](DESIGN_PATH.md) and breadth guidance in
[ROADMAP.md](ROADMAP.md) require finishing mathematical contracts and selecting
one certified domain before adding ODE breadth. A full physics engine now would
combine several major semantic changes at once and must not be mixed into the
claim-verification development branch.

## Recommended product boundary

Build “CENTL Physics” initially for:

- Dimensionally checked physical quantities.
- Exact unit conversion.
- Newtonian point-mass mechanics.
- Deterministic, bounded 1D simulation.
- Exact discrete state updates when inputs are rational.
- Rigorous enclosures when inputs contain uncertainty.
- Physics contract verification and replayable simulation receipts.

Do **not** include initially:

- Rigid-body rotation or contact.
- Collision detection and constraint solvers.
- Fluids, relativity, electromagnetism, or quantum mechanics.
- General ODE solving.
- Claims that a numerically exact discrete update is the exact continuous
  trajectory.

That last distinction is essential. A velocity-Verlet step performed with
rational arithmetic can be exact for the **discrete update rule** while still
approximating the continuous physical system.

## Core value model

Add a separate `Centl.Physics` F\* module rather than immediately expanding the
general expression AST.

```text
Dimension = integer exponents over:
  length, mass, time, current, temperature, amount, luminosity

Unit = {
  dimension;
  exact rational scale;
  symbol
}

Quantity = {
  scalar;
  dimension;
  preferred display unit
}

Vector = {
  homogeneous quantity components;
  coordinate frame
}

ParticleState = {
  time;
  mass;
  position;
  velocity
}

Trajectory = {
  model;
  integrator;
  step size;
  states;
  assurance
}
```

The first unit release should support only **multiplicative** units with exact
rational scale factors. Affine temperature units such as Celsius and Fahrenheit
should remain unsupported until point-versus-difference semantics are designed.

### Quantity rules

- Addition, subtraction, and comparison require equal dimensions.
- Multiplication and division combine dimension exponents.
- Integer powers multiply dimension exponents.
- `sin`, `exp`, and `log` require dimensionless arguments.
- `sqrt` requires dimensions that can be represented without silently
  introducing fractional exponents.
- Unit conversion never changes the canonical physical value.
- A dimensionful zero remains dimensionful; bare `0` should not automatically
  acquire arbitrary units.

## Physics architecture

| Layer | Responsibility |
| --- | --- |
| F\* | Dimensions, unit normalization, quantity arithmetic, vector operations, integrator update maps, semantic proofs |
| OCaml | Scenario parsing, bounded stepping, cancellation, trajectory storage, protocols and rendering |
| Arb | Interval quantities and later validated continuous-time enclosures |
| Julia/Nemo | Independent trajectories, unit-conversion properties, adversarial and differential testing |

The OCaml driver may enumerate time steps, just as it currently enumerates
finite sequences, but every state transition should call the **extracted F\***
implementation. OCaml must not independently redefine the update equations.

Simulation should be a pure read-only operation. Example request shape:

```json
{
  "physics_schema": 1,
  "model": "point_mass_1d",
  "initial": {
    "mass": { "value": "2", "unit": "kg" },
    "position": { "value": "0", "unit": "m" },
    "velocity": { "value": "3", "unit": "m/s" }
  },
  "force": {
    "kind": "constant",
    "value": { "value": "-4", "unit": "N" }
  },
  "integrator": {
    "kind": "velocity_verlet",
    "step": { "value": "1/100", "unit": "s" },
    "steps": 1000
  }
}
```

A result should distinguish:

```text
arithmetic: exact_algorithm
model: newtonian_point_mass
trajectory_scope: discrete_velocity_verlet
continuous_solution: not_claimed
```

## Implementation plan

### 0. Finish the current verification foundation

Before physics development:

1. Discharge the pending polynomial soundness proof (or keep identity claims
   honestly `unknown` until that lands).
2. Restore `make verify` and the full test suite to green.
3. Release the current contract work.
4. Avoid mixing the large physics semantic change into the already-modified
   development branch.

### 1. Dimensions and units

Implement:

- `dimension`, `unit`, and `quantity` in `src/fstar/Centl.Physics.fst`.
- Seven SI base dimensions.
- Exact rational conversion scales.
- Quantity arithmetic and dimension inference.
- Structured `dimension_mismatch`, `invalid_unit`, and
  `non_dimensionless_argument` failures.
- JSON-first input and output; calculator syntax can follow later.

Proof obligations:

- Dimension normalization is canonical.
- Quantity operations preserve their declared dimensions.
- Unit conversion preserves canonical magnitude.
- Converting between compatible units and back is identity.
- Incompatible quantities cannot reach arithmetic operations.

**Exit gate:** the same scenario expressed in metres or centimetres produces
identical canonical results.

### 2. Mechanics contracts

Add pure formula evaluation before simulation:

- Momentum (`p = mv`).
- Force (`F = ma`).
- Kinetic energy (`E_k = mv^2/2`).
- Gravitational potential in a uniform field.
- Constant-acceleration kinematics.
- Hooke’s law.

This stage should verify dimensions and closed numerical claims without
maintaining world state.

**Exit gate:** CENTL can reject `mass + velocity`, verify compatible unit
conversions, and produce exact results for rational mechanics problems.

### 3. Bounded 1D simulator

Add:

- One point mass.
- Constant force, uniform acceleration, and ideal spring force.
- Fixed-step velocity Verlet.
- Rational and enclosure-valued initial conditions.
- New bounded `Trajectory` result rather than overloading `ExactSequence`.
- Limits for steps, force evaluations, exact bits, trajectory bytes, and
  retained states.
- Cancellation between steps.
- No partial trajectory returned after failure.

Initial proof target:

> For constant acceleration, velocity Verlet agrees with the analytic solution
> at every grid time.

Also prove every accepted step preserves the dimensions of time, position,
velocity, acceleration, and force.

### 4. Multiple particles and vectors

After the 1D engine is stable:

- Fixed-size 2D and 3D vectors.
- Named coordinate frames.
- Dot product, cross product, norm, and frame-safe addition.
- Pairwise spring and gravitational forces.
- Exact discrete momentum preservation for antisymmetric internal forces.
- Spatial indexing only after correctness is established.

Do not reuse ordinary sequences as vectors; current sequences are result
containers and deliberately cannot participate in scalar arithmetic
([DESIGN.md](DESIGN.md)).

### 5. Validated continuous dynamics

Only later add:

- Interval initial conditions.
- Validated local truncation bounds.
- Adaptive interval subdivision.
- Certified trajectory tubes.
- Event isolation with three-valued results.
- General ODE models within a documented bounded domain.

Ordinary RK4 output must not be called rigorous merely because it uses high
precision.

## Testing and release gates

Required test families:

- Golden unit conversions and dimension errors.
- Generated conversion round trips.
- Metamorphic unit invariance.
- Exact comparison with analytic constant-acceleration trajectories.
- Independent Julia trajectory comparisons.
- Precision-refinement tests for enclosure states.
- Conservation-property tests.
- Malformed scenario, singular force, zero mass, cancellation, and
  resource-limit tests.
- Cross-surface agreement among CLI, JSON, and MCP.
- Explicit tests ensuring discrete exactness is never presented as continuous
  physical exactness.

Suggested new files (when implementation starts, on a dedicated branch):

```text
src/fstar/Centl.Physics.fst
src/ocaml/centl_physics.ml
tests/test_physics.ml
lab/julia/physics_reference.jl
docs/PHYSICS.md          (this document)
examples/physics/
```

## Relation to the 0.13 certified-domain pilot

[DESIGN_PATH.md](DESIGN_PATH.md) lists “first-class dimensions and exact unit
conversions” as one post-0.12 pilot expansion. CENTL Physics is the natural
**engineering/scientific** productization of that pilot when pilot demand
selects units or mechanics:

1. Ship dimensions and units first (stage 1).
2. Add pure mechanics contracts (stage 2).
3. Only then add bounded discrete simulation (stage 3).

Do not treat “physics engine” as a license to expand general ODEs, matrices, or
contact mechanics in the same release as units.
