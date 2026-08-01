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

CENTL exposes two tools in deterministic order:

- `centl_calculate` evaluates an expression or immutable definition.
- `centl_reset` forgets definitions held by the current process.

`centl_calculate` requires `expression` and accepts the same optional `limits`
object as `centl --serve`. Definitions persist across tool calls in one server
process. The server has no network listener, reads no credentials, and accesses
no files on behalf of a tool call.

Exact finite `sum` and `product` expressions use this same tool and return the
ordinary exact integer, rational, or symbolic value schema. Nested iterations
share the call's `max_integer_iterations` budget.

Every calculation result contains human-readable `content` and the complete
CENTL protocol response in `structuredContent`. Mathematical failures such as
division by zero are MCP tool errors with `isError: true`; malformed JSON-RPC,
unknown methods, unknown tools, and invalid arguments are protocol errors.
`structuredContent.provenance` classifies every mathematical result as exact,
exact symbolic, a rigorous enclosure, an exact or unresolved solution set, a
definition, a failure, or a cancellation, and records its method and backend.

## Cancellation

The stdio adapter implements MCP `notifications/cancelled`. A client can cancel
an outstanding `tools/call` by its JSON-RPC request ID:

```json
{"jsonrpc":"2.0","method":"notifications/cancelled","params":{"requestId":"tool-7","reason":"User stopped the calculation"}}
```

The input reader marks an active or queued tool call immediately while the
stateful evaluator continues to process calculations and definitions in FIFO
order. Cancellation is cooperative at parser, session-expansion,
finite-iteration term boundaries, symbolic-transformation,
approximation-retry, and pre-commit checkpoints. A native backend call already
in progress completes before the next checkpoint.
A definition whose evaluation observes cancellation is not committed. A signal
that races with an already completed call may have no effect.

As required by MCP, a cancellation notification has no response and CENTL does
not emit the cancelled tool call's response. Unknown, completed, and malformed
cancellation targets are ignored. Request IDs must remain unique while calls
are outstanding. Clients should retain an external timeout and terminate the
process if they require immediate interruption.

Valid cancellation notifications bypass the process request-admission counter.
The reader keeps at most 10,000 pending inputs and 16 MiB of pending source
bytes. Exceeding either ceiling is terminal: CENTL marks active and queued tool
evaluations cancelled, drains the bounded queue, emits one ordered overload
error when the overflowing input is a request, and exits with failure status.
This keeps cancellation reachable through ordinary small request bursts while
preventing an unbounded stdio backlog.

The adapter implements `initialize`, `notifications/initialized`,
`notifications/cancelled`, `ping`, `tools/list`, and `tools/call`. End of input
drains already accepted requests and then stops the server.

The wire behavior follows the official MCP
[lifecycle](https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle),
[stdio transport](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports),
and [tools](https://modelcontextprotocol.io/specification/2025-11-25/server/tools)
specifications, including the
[cancellation utility](https://modelcontextprotocol.io/specification/2025-11-25/basic/utilities/cancellation).
