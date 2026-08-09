# CENTL physics machine protocol

Status: experimental development interface for the post-0.11.0 physics engine.

`centl-physics --serve` exposes the current deterministic particle-mechanics
engine as a stateless JSON Lines service. This is the machine-facing physics
surface used by CENTL AI and other automated callers.

The AI is not a second physics evaluator. It may interpret a natural-language
question, select a supported physical model, construct one of the typed requests
below, and explain the returned result. Numerical state evolution, exact contact
classification, collision response, continuous linear-contact certification,
and physical dimension checks remain inside deterministic CENTL.

## Transport

Start the server with:

```sh
centl-physics --serve
```

Send one JSON object per line and read one JSON response per line. Every request
requires a protocol version and action:

```json
{"version":1,"action":"capabilities"}
```

An optional string or integer `id` is copied to the response.

The default process limits are:

- 65,536 bytes per request
- 10,000 admitted requests per process
- 100,000 simulation steps per request
- 4,096 simulation steps when the full trajectory is requested
- 4,096 pairwise sphere comparisons for contact-machine requests

The underlying particle integrator retains its separate 1,000,000-step library
safety limit. The machine protocol deliberately uses lower ceilings to bound
latency and response growth for automated callers.

The contact-pair ceiling is evaluated before pairwise classification. Since a
world of `n` spheres contains `n(n-1)/2` unordered pairs, 91 spheres require
4,095 comparisons and fit the current machine budget, while 92 spheres require
4,186 and are rejected. This machine-output bound is separate from the
256-particle library world ceiling.

## Exact scalar representation

All physical scalar inputs are strings. This avoids routing arbitrary-precision
integers, decimals, or fractions through a host JSON-number representation.

```json
{"value":"1/10","unit":"s"}
```

Decimals are exact rationals under the same physics-engine rules as the CLI.

Three-dimensional vectors use exact string components:

```json
{"x":"0","y":"0","z":"-10","unit":"m/s^2"}
```

## Capability discovery

Request:

```json
{"version":1,"action":"capabilities"}
```

The result lists the supported actions, force models, integrators, exact
constant symbols, and active machine-protocol limits, including the sphere
contact-pair ceiling. The action list includes the discrete sphere-analysis and
resolution actions plus `certify_linear_sphere_contact` for the narrow bounded
constant-velocity continuous-contact contract.

`units` returns the current unit catalog with exact SI scale and seven-base SI
dimension metadata.

## Exact unit conversion

Request:

```json
{
  "version": 1,
  "id": "example-conversion",
  "action": "convert",
  "value": "100",
  "from_unit": "cm",
  "to_unit": "m"
}
```

The exact result is `1`. Incompatible dimensions are errors rather than implicit
coercions.

## Physical constants

Request:

```json
{"version":1,"action":"constant","symbol":"c"}
```

The initial catalog intentionally exposes only the exact SI defining or
conventional constants already documented by the physics engine. Measured
constants such as Newton's gravitational constant are not promoted to exact
machine values.

## Particle simulation

A particle contains positive mass, 3D position, and 3D velocity:

```json
{
  "id": "body",
  "mass": {"value":"2","unit":"kg"},
  "position": {"x":"0","y":"0","z":"10","unit":"m"},
  "velocity": {"x":"1","y":"0","z":"0","unit":"m/s"}
}
```

The machine interface exposes only force models implemented by the current
engine:

- `constant_force`
- `uniform_gravity`
- `hooke_spring`
- `linear_drag`

Example:

```json
{
  "version": 1,
  "action": "simulate_particle",
  "particle": {
    "id": "body",
    "mass": {"value":"2","unit":"kg"},
    "position": {"x":"0","y":"0","z":"10","unit":"m"},
    "velocity": {"x":"1","y":"0","z":"0","unit":"m/s"}
  },
  "forces": [
    {
      "kind": "uniform_gravity",
      "acceleration": {"x":"0","y":"0","z":"-10","unit":"m/s^2"}
    }
  ],
  "dt": {"value":"1/10","unit":"s"},
  "steps": 10,
  "include_trajectory": false
}
```

The result names `symplectic_euler` explicitly and returns typed initial/final
particle states plus exact momentum and kinetic-energy diagnostics. If
`include_trajectory` is true, every discrete state is returned, subject to the
lower trajectory-output ceiling. If it is false, the machine executor retains
only the current state and final result instead of building a trajectory list.

A discrete trajectory is the exact rational result of the selected integrator.
It is not represented as the analytic continuous-time solution.

Through MCP, every physics action has an admission-time cancellation checkpoint,
and particle simulation is additionally cooperatively cancellable at integration
step boundaries. A step already in progress completes before the next
cancellation checkpoint. The standalone JSON Lines transport remains a simple
request/response stream and does not define a separate cancellation message.

## Exact elastic collisions

`elastic_collision_1d` accepts two positive masses and two one-dimensional
velocities as typed quantities. It returns both final velocities and exact
checks of momentum and kinetic-energy conservation for the ideal collision
model.

`elastic_collision_3d_at_contact` accepts two complete particle states at a
caller-supplied contact configuration with distinct centers. It applies the
exact rational frictionless elastic normal response and returns both final
particle states plus exact momentum and kinetic-energy checks. It does not infer
radii or prove that the caller actually supplied a touching configuration.

For sphere worlds, use the contact-analysis and isolated-resolution actions
below instead. Those actions perform the exact sphere contact test inside CENTL.

## Sphere input

A sphere combines a particle state with a positive length radius:

```json
{
  "particle": {
    "id": "a",
    "mass": {"value":"1","unit":"kg"},
    "position": {"x":"0","y":"0","z":"0","unit":"m"},
    "velocity": {"x":"1","y":"0","z":"0","unit":"m/s"}
  },
  "radius": {"value":"1","unit":"m"}
}
```

Sphere-world particle identifiers are required explicitly and must be non-empty
and unique. Unlike the legacy single-particle parser, sphere contact requests do
not synthesize a default `"body"` identifier when `id` is omitted. Radius values
must be positive and dimensionally lengths. The existing world constructor
retains the 256-particle library ceiling; machine contact requests additionally
must fit the 4,096-pair budget.

## Exact sphere contact analysis

`analyze_sphere_contacts` performs exact pairwise spherical contact
classification without changing the world:

```json
{
  "version": 1,
  "action": "analyze_sphere_contacts",
  "spheres": [
    {
      "particle": {
        "id": "a",
        "mass": {"value":"1","unit":"kg"},
        "position": {"x":"0","y":"0","z":"0","unit":"m"},
        "velocity": {"x":"1","y":"0","z":"0","unit":"m/s"}
      },
      "radius": {"value":"1","unit":"m"}
    },
    {
      "particle": {
        "id": "b",
        "mass": {"value":"1","unit":"kg"},
        "position": {"x":"2","y":"0","z":"0","unit":"m"},
        "velocity": {"x":"-1","y":"0","z":"0","unit":"m/s"}
      },
      "radius": {"value":"1","unit":"m"}
    }
  ]
}
```

CENTL compares the exact squared center distance with the exact squared sum of
radii. No square-root normalization is needed:

- distance squared greater than radius-sum squared => `separated`
- equal => `touching`
- less => `overlapping`

The result returns exact counts for all unordered pairs and detailed evidence
for every non-separated pair. Evidence contains the center delta, exact squared
distance, exact squared radius sum, and relation. Separated pairs are counted
but intentionally not expanded into detailed output, which keeps ordinary
machine responses compact.

## Exact isolated sphere-contact resolution

`resolve_isolated_elastic_sphere_contacts` combines the exact sphere contact
test with the merged exact 3D elastic response. It is deliberately a partial
solver with explicit verdicts.

The deterministic precedence is:

1. If any pair is already overlapping, return `decision: "deferred"` with
   `reason: "overlap_detected"` and the world unchanged.
2. Otherwise, if any particle participates in more than one simultaneous
   touching pair, return `decision: "deferred"` with
   `reason: "ambiguous_simultaneous_contacts"` and the world unchanged.
3. Otherwise the touching graph is a disjoint matching. Each touching pair can
   be resolved independently with the exact 3D elastic normal response.
4. If there are no touching pairs, return `decision: "completed"` with an
   unchanged world and an empty pair-resolution list.

A completed result includes:

- the exact initial and resulting sphere worlds
- the initial contact summary and exact touching evidence
- one status per touching pair (`resolved` or `separating_or_stationary`)
- whether the world changed
- exact whole-world momentum and kinetic-energy conservation flags
- the explicit solver trust boundary

A deferred result is **not** a malformed request and is **not** a tool error. It
is a successful exact CENTL verdict that says the supplied state lies outside
the solver's justified resolution domain. No partial impulses are applied before
deferral, so the operation is failure-atomic.

The trust-boundary object states the current limits directly: exact pairwise
sphere geometry, squared-distance contact testing, frictionless elastic normal
response, disjoint touching pairs only, whole-world deferral on overlap or
shared-contact ambiguity, and no claim that this discrete resolver performs
general continuous collision detection, penetration correction, friction, or
spin.

## Certified bounded continuous sphere contact

`certify_linear_sphere_contact` answers a different question from the discrete
world actions: whether two exact-rational spheres make contact anywhere in a
bounded interval under a constant-velocity center-motion model.

Request:

```json
{
  "version": 1,
  "action": "certify_linear_sphere_contact",
  "sphere1": {
    "particle": {
      "id": "a",
      "mass": {"value":"1","unit":"kg"},
      "position": {"x":"0","y":"0","z":"0","unit":"m"},
      "velocity": {"x":"1","y":"0","z":"0","unit":"m/s"}
    },
    "radius": {"value":"1","unit":"m"}
  },
  "sphere2": {
    "particle": {
      "id": "b",
      "mass": {"value":"1","unit":"kg"},
      "position": {"x":"4","y":"0","z":"0","unit":"m"},
      "velocity": {"x":"0","y":"0","z":"0","unit":"m/s"}
    },
    "radius": {"value":"1","unit":"m"}
  },
  "duration": {"value":"3","unit":"s"}
}
```

CENTL forms the exact squared-clearance polynomial

```text
f(t) = |r + vt|^2 - R^2 = a t^2 + b t + c
```

for relative position `r`, relative velocity `v`, and summed radius `R`. It then
certifies the exact minimum over `[0,duration]`; it does not sample the interval
or invoke a floating-point root finder.

The result status is exactly one of:

- `initially_overlapping`
- `touching_at_start`
- `no_contact_in_interval`
- `tangent_contact`
- `crossing_contact`

The certificate includes particle identifiers, duration, exact `a`, `b`, and
`c`, the exact closest time, exact minimum squared clearance, and the exact
discriminant when relative motion exists.

`first_contact_time` is one of three machine shapes:

- `null` when there is no first contact in the interval;
- `kind: "rational"` with an exact time quantity when the first root is
  rational;
- `kind: "quadratic_irrational"` with the exact polynomial, exact
  discriminant, and a certified rational bracket when the event time is not
  rational.

CENTL therefore never converts a quadratic-irrational event time into a decimal
or fabricated rational timestamp merely to cross the JSON boundary. The output
also carries a trust-boundary object stating `constant_velocity`, exact sphere
geometry, exact squared-clearance reasoning, no sampling, no floating-point
root finding, no force integration, no automatic response, and no simultaneous
contact solving.

This action is not a general continuous collision detector. It certifies one
specific exact mathematical motion model. It does not claim contact timing under
acceleration or force integration, and it is not implicitly coupled to
`symplectic_euler`.

## Contact reasoning is not automatic time stepping

The discrete sphere-world actions operate on one supplied world state. The
continuous action operates on one supplied constant-velocity pair model. None
of them is implicitly called by `simulate_particle` or by the library world
step, and none automatically applies a collision response at a certified event.

CENTL therefore does **not** claim that a force-driven symplectic-Euler step
cannot pass through contact between sampled states. The linear certificate can
answer that question only when the caller intentionally supplies and accepts the
constant-velocity model for the queried interval. Keeping these contracts
separate prevents the machine interface from manufacturing a stronger
force-driven CCD claim.

## Error behavior

Malformed requests, unknown fields, unsupported force models, dimension
mismatches, invalid rational strings, missing, duplicate, or blank sphere-world
identifiers, invalid sphere radii, contact-pair budget violations, invalid
continuous-contact duration, and other resource-limit violations return
structured errors. Unsupported models do not silently fall back to a different
physical interpretation.

This is important for CENTL AI: a model must not transform an unsupported
request into a superficially similar supported simulation without making that
change explicit to the user.

By contrast, `deferred` from the isolated sphere-contact resolver is a valid
physics result, not an error. It preserves the distinction between invalid input
and valid input for which the current exact solver refuses to invent a unique
physical resolution. Likewise, a successful continuous-contact certificate is
evidence about the admitted constant-velocity model; it does not imply that
CENTL integrated or mutated a physical world.
