# MCP

Run CENTL as a local Model Context Protocol server:

```sh
centl --mcp
```

The adapter uses newline-delimited JSON-RPC 2.0 over standard input and output.
It implements the current stable MCP revision, `2025-11-25`, and accepts the
final revisions `2025-06-18`, `2025-03-26`, and `2024-11-05` during
negotiation.

Configure an MCP client with the equivalent of:

```json
{
  "mcpServers": {
    "centl": {
      "command": "centl",
      "args": ["--mcp"]
    }
  }
}
```

CENTL 0.12.0-rc.1 exposes these nine tools in deterministic order:

- `centl_compute` performs read-only mathematical evaluation and rejects
  definitions.
- `centl_define` creates one immutable value or function definition.
- `centl_verify` checks one structured mathematical claim and returns
  `verified`, `refuted`, `unknown`, or `invalid` with evidence. It decides
  closed exact rational comparisons and certified enclosure order/inequality
  (with dyadic bounds). Univariate rational polynomial false equalities may be
  `refuted` with an exact witness; admitted polynomial identities are verified
  by the named F* zero-difference soundness theorem. Free-form assumptions,
  unsupported proof syntax, and multi-variable claims return `unknown`.
- `centl_capabilities` returns supported domains, resolution statuses, limits,
  and cancellation behavior.
- `centl_session` inspects definitions and their direct dependencies without
  mutation.
- `centl_help` searches focused help generated from the canonical syntax
  catalog.
- `centl_calculate` retains the earlier combined mathematical behavior for
  compatibility.
- `centl_reset` forgets definitions held by the current process.
- `centl_physics` exposes deterministic exact-rational particle mechanics:
  physics capability and unit discovery, exact compatible-unit conversion,
  exact physical constants, dimension-checked particle simulation, exact ideal
  elastic collisions in 1D and at caller-supplied 3D contact, exact sphere
  contact analysis, isolated exact sphere-contact resolution with explicit
  deferral outside the justified solver domain, and certified bounded
  continuous sphere contact under an exact constant-velocity model.

`centl_compute` requires `expression`; `centl_define` requires `definition`;
both accept the same optional `limits` object as `centl --serve`. Compute may
read definitions but cannot mutate them, and its MCP annotations accurately
mark it read-only, non-destructive, idempotent, and closed-world. Definitions
persist across tool calls in one server process. The server has no network
listener, reads no credentials, and accesses no files on behalf of a tool call.

The capability, session-inspection, help, and physics tools are read-only,
idempotent, and closed-world. Their output schemas are closed and exact rather
than free-form text contracts.

## Physics tool

`centl_physics` is a thin adapter over the same version-1 physics request/result
model documented in [PHYSICS_PROTOCOL.md](PHYSICS_PROTOCOL.md). MCP does not
implement a second physics evaluator.

The tool accepts one of ten discriminated actions:

- `capabilities`
- `units`
- `convert`
- `constant`
- `simulate_particle`
- `elastic_collision_1d`
- `elastic_collision_3d_at_contact`
- `analyze_sphere_contacts`
- `resolve_isolated_elastic_sphere_contacts`
- `certify_linear_sphere_contact`

Physical numeric inputs are strings so arbitrary-precision integers, finite
decimals, and fractions cross the JSON boundary without host-number rounding.
For example, a time step is represented as:

```json
{"value":"1/10","unit":"s"}
```

A gravity simulation can be called through MCP as:

```json
{
  "jsonrpc": "2.0",
  "id": "fall",
  "method": "tools/call",
  "params": {
    "name": "centl_physics",
    "arguments": {
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
      "steps": 10
    }
  }
}
```

The authoritative `structuredContent` identifies the integrator as
`symplectic_euler` and returns typed initial/final states plus exact momentum
and kinetic-energy diagnostics. Unsupported force models and incompatible
physical dimensions return structured tool errors rather than being silently
reinterpreted.

Sphere contact analysis uses complete stateless sphere-world input. For example:

```json
{
  "jsonrpc": "2.0",
  "id": "contact",
  "method": "tools/call",
  "params": {
    "name": "centl_physics",
    "arguments": {
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
  }
}
```

The result reports the exact pairwise contact summary and expands every
non-separated pair with exact squared-distance evidence. The paired action
`resolve_isolated_elastic_sphere_contacts` composes that contact classification
with CENTL's exact 3D elastic response only when the touching graph is a
disjoint matching.

Overlap or simultaneous shared-contact ambiguity returns a successful physics
result with `decision: "deferred"`; it does **not** set MCP `isError: true`.
That distinction is intentional. `deferred` means the request was valid and
CENTL exactly determined that the state lies outside the current solver's
justified resolution domain. The returned world is unchanged and no partial
impulses are applied.

### Certified continuous sphere contact

`certify_linear_sphere_contact` accepts two identified spheres and an exact
nonnegative duration. It certifies contact over the whole supplied interval
under one explicit model: both sphere centers move with constant exact-rational
velocity for the duration.

Example MCP arguments:

```json
{
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

The successful `structuredContent.physics` value is an exact
`linear_sphere_contact_certificate`. It exposes the squared-clearance quadratic,
closest time, minimum squared clearance, discriminant when applicable, and one
of five statuses: `initially_overlapping`, `touching_at_start`,
`no_contact_in_interval`, `tangent_contact`, or `crossing_contact`.

When first contact has a rational event time, the result returns that time as an
exact physical quantity. When the root is quadratic irrational, the tool does
not fabricate a decimal or rational timestamp; it returns a
`quadratic_irrational` certificate with the exact polynomial, exact
discriminant, and a certified rational bracket. This operation uses no time
sampling and no floating-point root finder.

The certificate is deliberately narrower than a general continuous-collision
solver. It does not integrate forces, alter particle state, apply collision
response, order simultaneous events, or claim that a force-driven
symplectic-Euler trajectory follows the admitted constant-velocity path.

The current physics MCP action is stateless with respect to simulated physical
worlds: every call supplies the complete initial particle or sphere state. It
inherits the ordinary MCP process request-admission limit and retains the
physics protocol's 100,000-step simulation ceiling, 4,096-step full
trajectory-output ceiling, and 4,096-pair sphere-contact ceiling. Because an
`n`-sphere world has `n(n-1)/2` unordered pairs, 91 spheres fit that contact
budget with 4,095 pairs while 92 spheres require 4,186 and are rejected.

When `include_trajectory` is false, the particle executor retains only the
current state and final result rather than allocating a state list proportional
to the requested step count. Sphere contact actions likewise expand detailed
evidence only for non-separated pairs, while still returning exact counts for
all classified pairs.

Exact finite `sum`, `product`, `sequence`, and `recurrence` expressions use
`centl_compute`. Sums and products return the ordinary exact integer, rational,
or symbolic value schema. Sequences and recurrences return a structured exact
`sequence` value whose ordered `items` use those scalar schemas:

```json
{"jsonrpc":"2.0","id":"squares","method":"tools/call","params":{"name":"centl_compute","arguments":{"expression":"sequence(k^2, k = 1, 3)"}}}
```

The tool's text content is `[1, 4, 9]`; its
`structuredContent.value` has `kind: "sequence"`, `exact: true`, `length: 3`,
and the three exact integer items. Its provenance is classified
`exact_sequence` with method `finite_iteration` and backend `centl-iteration`.
The identical shape is documented in
[the machine protocol](PROTOCOL.md#exact-sequences). Nested bounded operations
share the call's `max_integer_iterations`, expression-work, exact-bit,
expression-node, and result-byte budgets.

Every tool result contains human-readable `content` and the complete typed
response in `structuredContent`. For residual, unsupported, unchanged-proved,
and indeterminate mathematical outcomes, the text content appends the same
`resolution:` annotation used by the human calculator so agents that only read
tool text cannot treat incomplete work as success. Mathematical tool errors
include the stable message and, when known, a recovery `suggestion` line.
`structuredContent` remains authoritative. Mathematical failures such as
division by zero are MCP tool errors with `isError: true`; malformed JSON-RPC,
unknown methods, unknown tools, and invalid arguments are protocol errors.
Physics request failures such as a dimension mismatch, malformed sphere world,
contact-pair budget violation, or unsupported force model also return
`isError: true` with the physics response preserved in `structuredContent`.
A physics `deferred` contact verdict is instead a successful result with
`isError: false`.

Every successful mathematical calculation also has
`structuredContent.resolution`, which states whether the request was computed,
transformed, proved already in form, left residual, unsupported, or
indeterminate. Non-complete results identify the operation, stable reason, and
supported domain, so an agent never has to infer completion from symbolic text.
`structuredContent.provenance` classifies every mathematical result as exact,
exact symbolic, a rigorous enclosure, an exact or unresolved solution set, a
definition, a failure, or a cancellation, and records its method and backend.
Physics results carry their own physics provenance with the deterministic
`centl-physics` backend.

Each calculation tool advertises a closed, discriminated `outputSchema`.
`centl_compute` permits only mathematical values or errors; `centl_define`
permits only definitions or errors; the compatibility tool permits either.
`centl_physics` preserves its original closed output schema and extends it with
strict variants for enhanced capabilities, exact sphere-contact analysis,
isolated contact resolution, and certified continuous linear-contact results.
Completed contact resolution, overlap deferral, simultaneous-contact deferral,
and linear-contact certificates are closed typed variants, so callers do not
have to infer the verdict from free-form text. A quadratic-irrational contact
time has its own closed representation rather than being coerced into the
rational quantity schema. The solution-set branch for mathematics accepts the
existing rational solution object and the exact `real_quadratic` object
documented in [the machine protocol](PROTOCOL.md#values). `centl_reset`
advertises a separate self-contained control-response schema. The schemas are
constructed only for `tools/list`, so ordinary calculator and JSON startup do
not allocate MCP-only schema trees.

## Cancellation

The stdio adapter implements MCP `notifications/cancelled`. A client can cancel
an outstanding cancellable mathematical or physics `tools/call` by its
JSON-RPC request ID:

```json
{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":"tool-7","reason":"User stopped the calculation"}}
```

The input reader marks an active or queued cancellable tool call immediately
while the stateful evaluator continues to process accepted requests in FIFO
order. Mathematical cancellation is cooperative at parser, session-expansion,
bounded-iteration term boundaries, symbolic-transformation,
approximation-retry, and pre-commit checkpoints. A native backend call already
in progress completes before the next checkpoint. A definition whose
evaluation observes cancellation is not committed.

Every physics action has an admission-time cancellation checkpoint, so a queued
request that was cancelled before execution does not run. Physics particle
simulation additionally checks cancellation at deterministic integration-step
boundaries. A symplectic-Euler step already in progress completes before the
next cancellation checkpoint. Conversion, constant lookup, capability queries,
unit listing, exact collision calls, discrete sphere contact analysis/resolution,
and the bounded continuous linear-contact certificate are bounded operations
and do not contain internal cancellation checkpoints after admission. A signal
that races with an already completed call may have no effect.

As required by MCP, a cancellation notification has no response and CENTL does
not emit the cancelled tool call's response. Unknown, completed, and malformed
cancellation targets are ignored. Request IDs must remain unique while calls
are outstanding. Clients should retain an external timeout and terminate the
process if they require interruption inside a single non-cooperative native or
exact operation.

Valid cancellation notifications bypass the process request-admission counter.
The reader keeps at most 10,000 ordinary pending inputs and 16 MiB of their
source bytes. When either budget is full, one valid cancellation notification
may use a separately accounted emergency slot, still bounded by the per-request
input limit; there is no second emergency slot. Further overload is terminal:
CENTL marks active and queued cancellable tool evaluations cancelled, drains the
ordinary queue plus any emergency notification, emits one ordered overload
error when the overflowing input is a request, and exits with failure status.
This keeps cancellation reachable at saturation while preventing an unbounded
stdio backlog.

The adapter implements `initialize`, `notifications/initialized`,
`notifications/cancelled`, `ping`, `tools/list`, and `tools/call`. End of input
drains already accepted requests and then stops the server.

The wire behavior follows the official MCP
[lifecycle](https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle),
[stdio transport](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports),
and [tools](https://modelcontextprotocol.io/specification/2025-11-25/server/tools)
specifications, including the
[cancellation utility](https://modelcontextprotocol.io/specification/2025-11-25/basic/utilities/cancellation).
