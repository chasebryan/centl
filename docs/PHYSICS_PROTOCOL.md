# CENTL physics machine protocol

Status: experimental development interface for the post-0.11.0 physics engine.

`centl-physics --serve` exposes the current deterministic particle-mechanics
engine as a stateless JSON Lines service. This is the machine-facing physics
surface used by CENTL AI and other automated callers.

The AI is not a second physics evaluator. It may interpret a natural-language
question, select a supported physical model, construct one of the typed requests
below, and explain the returned result. The numerical state evolution and
physical dimension checks remain inside deterministic CENTL.

## Transport

Start the server with:

```sh
centl-physics --serve
```

Send one JSON object per line and read one JSON response per line. Every request
requires:

```json
{"version":1,"action":"capabilities"}
```

An optional string or integer `id` is copied to the response.

The default process limits are:

- 65,536 bytes per request
- 10,000 admitted requests per process
- 100,000 simulation steps per request
- 4,096 simulation steps when the full trajectory is requested

The underlying physics engine retains its separate 1,000,000-step library safety
limit. The machine protocol deliberately uses the lower ceiling to bound
latency and response growth for automated callers.

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
constant symbols, and active machine-protocol limits.

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

## Exact one-dimensional elastic collisions

`elastic_collision_1d` accepts two positive masses and two one-dimensional
velocities as typed quantities. It returns both final velocities and exact
checks of momentum and kinetic-energy conservation for the ideal collision
model.

## Error behavior

Malformed requests, unknown fields, unsupported force models, dimension
mismatches, invalid rational strings, and resource-limit violations return
structured errors. Unsupported models do not silently fall back to a different
physical interpretation.

This is important for CENTL AI: a model must not transform an unsupported
request into a superficially similar supported simulation without making that
change explicit to the user.

## Current integration and next engine boundary

The JSON Lines interface is the canonical typed physics contract. The MCP
adapter exposes that same contract through `centl_physics`; it does not
introduce separate physics semantics.

The next engine boundary is physical breadth rather than another transport:
multi-particle world state, exact pair interactions where the underlying model
remains representable by CENTL's exact arithmetic, explicit collision
resolution, and conservation diagnostics across a world step. Models requiring
non-rational measured constants or algebraic normalization must retain honest
provenance and must not be mislabeled as exact rational mechanics.
