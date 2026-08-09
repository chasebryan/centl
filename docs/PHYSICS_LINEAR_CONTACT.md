# Certified linear sphere contact

CENTL can certify whether two exact-rational spheres make contact during a
bounded interval when both centers move with constant exact-rational velocity.
This is a deliberately narrow continuous-contact contract. It is not a general
continuous collision detector and it is not coupled to the force integrator.

## Model

Let the two sphere centers have initial relative position `r`, relative velocity
`v`, and summed radius `R`. During the admitted constant-velocity interval,
CENTL reasons about

```text
f(t) = |r + v t|^2 - R^2
     = a t^2 + b t + c
```

with

```text
a = v · v
b = 2 (r · v)
c = r · r - R^2
```

All arithmetic is exact rational arithmetic. No time sampling and no binary
floating-point root finder is used.

The dimensions are part of the contract:

- `a` has dimension length² / time²;
- `b` has dimension length² / time;
- `c` has dimension length²;
- the discriminant `b² - 4ac` has dimension length⁴ / time²;
- a returned contact time has dimension time.

Because `a = |v|² >= 0`, `f` is convex. Its minimum on `[0, duration]` occurs at
the exact rational vertex `-b/(2a)` clamped to the interval, or at time zero
when the relative velocity is zero. This lets CENTL certify the existence or
absence of contact over the entire admitted interval rather than checking only
sampled endpoints.

## Verdicts

The certificate returns exactly one status:

- `initially_overlapping`: `f(0) < 0`;
- `touching_at_start`: `f(0) = 0`;
- `no_contact_in_interval`: the exact bounded minimum is positive;
- `tangent_contact`: the bounded minimum is zero at a repeated root;
- `crossing_contact`: the interval contains a simple contact root.

A zero bounded minimum is not automatically called tangency. In particular, if
first contact occurs exactly at the interval endpoint and the discriminant is
positive, the result is `crossing_contact`. This prevents a bounded endpoint
from being confused with a repeated quadratic root.

Initial overlap is reported, not repaired. Contact at time zero is reported as
such rather than silently applying an impulse.

## Exact first-contact time

For a crossing, the first root is

```text
t = (-b - sqrt(discriminant)) / (2a)
```

When the discriminant is a perfect rational square, CENTL returns the contact
time as an exact rational physical quantity.

When the root is quadratic irrational, CENTL does not round it into a fabricated
rational timestamp. The certificate returns `Quadratic_irrational_contact_time`
with:

- the exact quadratic coefficients;
- the exact discriminant;
- a rational lower bracket;
- a rational upper bracket.

For the admitted crossing case, `[0, closest_time]` is a certified bracket:
clearance is positive at zero and negative at the exact bounded minimum. The
algebraic event therefore exists strictly inside that bracket.

## Input boundary

The operation requires:

- two spheres with distinct particle identifiers;
- positive exact-rational radii through the existing sphere constructor;
- dimension-checked particle positions and velocities;
- a nonnegative duration carrying the time dimension;
- constant velocity throughout the queried interval.

## Exact rational event composition

The library now includes `evolve_linear_sphere_pair_through_contact`, a narrow
composition layer for the cases where the certificate can support an exact
state transition without approximating event time.

Its behavior is deterministic:

1. It first obtains the ordinary `certify_linear_sphere_contact` certificate.
2. `initially_overlapping` returns `Deferred initial_overlap` with both original
   spheres unchanged. No penetration repair or partial response is attempted.
3. `no_contact_in_interval` advances both centers linearly for the full exact
   duration while preserving their velocities.
4. `touching_at_start`, `tangent_contact`, or `crossing_contact` with a rational
   first-contact time advances both spheres exactly to that time.
5. Before any impulse is allowed, the advanced geometry is independently
   reclassified by the exact sphere classifier and must be exactly `touching`.
   An internal inconsistency raises instead of manufacturing a response.
6. The existing `elastic_collision_3d_at_contact` primitive then returns either
   `resolved` or `separating_or_stationary`.
7. The spheres are advanced linearly through the exact remaining duration using
   the post-response velocities.
8. A quadratic-irrational crossing returns
   `Deferred quadratic_irrational_event_time` with both original spheres
   unchanged and the algebraic event certificate preserved.

A completed result records the original certificate, rational event time when
present, exact at-event sphere states and contact evidence, collision-response
status, final sphere states, a state-change flag, and exact pair momentum and
kinetic-energy conservation flags.

The operation is failure-atomic for every deferred result. It never advances to
a rational approximation of an irrational event and then applies an impulse.

For the admitted two-body, force-free model, the exact elastic response makes
the post-contact normal motion non-approaching. With constant post-event
velocities, the remainder segment therefore does not silently introduce a
second contact of the same pair.

### Event-step assurance boundary

This composition layer is intentionally smaller than a general event-driven
physics engine:

- exactly two spheres are admitted;
- motion between event boundaries is constant velocity;
- there are no applied forces or acceleration;
- only rational first-contact times may drive a response;
- quadratic-irrational event times defer unchanged;
- initial overlap defers unchanged;
- no penetration correction is performed;
- no friction, spin, torque, orientation, or rigid-body geometry is modeled;
- no simultaneous multi-contact event ordering is defined;
- the operation is not called automatically by `symplectic_euler` or the world
  step;
- it is currently a library operation, not a JSON Lines or MCP action.

The distinction matters: an exact event step under an explicitly linear motion
model is not evidence that a force-driven numerical integration step follows
that same path.

## Explicit non-claims

The continuous certificate and its rational event-step composition do not claim
any of the following:

- continuous collision detection under acceleration or force integration;
- a guarantee that a symplectic-Euler step follows the admitted linear path;
- penetration correction;
- automatic world collision processing;
- friction, spin, torque, or rigid-body geometry;
- simultaneous multi-contact event ordering or impulse solving;
- a floating-point approximation of irrational event time;
- exact state evolution through an irrational event time.

The result is therefore evidence and state evolution inside one exact
mathematical motion model, not an implicit change to CENTL's world integrator.

## Regression coverage

The native test suite covers the certificate itself with:

- rational head-on first contact;
- first contact exactly at the bounded interval endpoint;
- exact tangency;
- quadratic-irrational first contact;
- short-interval no-contact certification;
- parallel miss;
- stationary separation;
- contact at time zero;
- initial overlap;
- distinct-ID enforcement;
- duration-dimension enforcement;
- negative-duration rejection.

The event-composition tests additionally cover:

- full-duration exact advancement when there is no contact;
- rational head-on response plus exact remainder advancement;
- response exactly at the interval endpoint;
- an oblique rational 3D event with fractional contact geometry, fractional
  post-impact velocities, and fractional final positions;
- touching-at-start approaching and separating cases;
- exact tangency with no impulse;
- failure-atomic deferral of quadratic-irrational contact;
- failure-atomic deferral of initial overlap;
- zero-duration separated evolution;
- preservation of identifiers, masses, and radii;
- exact pair momentum and kinetic-energy conservation after completed steps.
