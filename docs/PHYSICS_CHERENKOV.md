# CENTL Physics: Cherenkov radiation certificate

CENTL Physics can certify the kinematic Cherenkov threshold and preserve the
cone-angle relation without silently inventing floating-point digits.

For an exact positive scalar refractive index `n` and an exact particle speed
`v`, CENTL uses the exact SI defining value of the vacuum speed of light `c` and
checks

```text
v > c/n
```

Equivalently, with `beta = v/c`, emission requires

```text
beta*n > 1
```

When the strict threshold is satisfied, the cone-angle relation is

```text
cos(theta) = c/(n*v) = 1/(beta*n)
```

The cosine is retained as an exact rational whenever the inputs are rational.
The angle itself is returned symbolically as `acos(exact-rational)` rather than
being converted to an unjustified binary floating-point decimal.

## CLI

```sh
centl-physics cherenkov REFRACTIVE_INDEX SPEED_MPS
```

For example:

```sh
centl-physics cherenkov 4/3 1349066061/5
```

The chosen speed is exactly `9/10 c`. CENTL returns:

```text
status=emission
emits=true
refractive_index=4/3
speed=1349066061/5 m/s
threshold_speed=449688687/2 m/s
beta=9/10
threshold_beta=3/4
beta_n=6/5
cos_theta=5/6
theta=acos(5/6) rad
exact_trigonometric_relation=true
```

At `beta*n = 1`, the status is `threshold` and CENTL does not claim an emitted
cone. Below threshold, the status is `below_threshold`.

## JSON Lines physics protocol

The version-1 physics server accepts the additive `cherenkov` action:

```json
{
  "version": 1,
  "action": "cherenkov",
  "refractive_index": "4/3",
  "speed": {"value": "1349066061/5", "unit": "m/s"}
}
```

The result is a `cherenkov_radiation_certificate` containing the exact input
speed, exact vacuum-light speed, exact threshold speed, `beta`, `1/n`,
`beta*n`, the strict threshold verdict, and an optional exact symbolic cone-angle
object. Capability discovery advertises the action.

The same typed action is exposed through the read-only `centl_physics` MCP tool.
Its input and output schemas remain closed and reject unknown fields.

## Trust boundary

This operation is deliberately a narrow kinematic certificate. The supplied
refractive index is treated as the scalar refractive index at the frequency of
interest. The operation does not model dispersion, spectral photon yield,
Frank-Tamm intensity, particle energy loss, detector response, particle species,
or relativistic particle dynamics.

It therefore answers a precise question: given `n` and `v`, is the exact
Cherenkov threshold crossed, and if so what exact value must `cos(theta)` have?
It does not claim to be a full electrodynamics or radiation-transport solver.
