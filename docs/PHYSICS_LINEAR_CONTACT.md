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

## Explicit non-claims

This certificate does not claim any of the following:

- continuous collision detection under acceleration or force integration;
- a guarantee that a symplectic-Euler step follows the admitted linear path;
- penetration correction;
- automatic collision response;
- friction, spin, torque, or rigid-body geometry;
- simultaneous multi-contact event ordering or impulse solving;
- a floating-point approximation of irrational event time.

The result is therefore evidence about one exact mathematical motion model, not
an implicit change to CENTL's world integrator.

## Composition direction

The safe next composition boundary is event-aware physics that treats this
certificate as evidence rather than silently changing integrator semantics. A
future layer may use a rational contact time directly, or preserve an algebraic
contact-time certificate when the root is irrational. It must still defer where
force-driven trajectories or simultaneous contacts lack a justified exact
semantics.

## Regression coverage

The native test suite covers:

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
