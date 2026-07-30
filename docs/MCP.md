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

Every calculation result contains human-readable `content` and the complete
CENTL protocol response in `structuredContent`. Mathematical failures such as
division by zero are MCP tool errors with `isError: true`; malformed JSON-RPC,
unknown methods, unknown tools, and invalid arguments are protocol errors.

The adapter implements `initialize`, `notifications/initialized`, `ping`,
`tools/list`, and `tools/call`. Close standard input to stop it.

The wire behavior follows the official MCP
[lifecycle](https://modelcontextprotocol.io/specification/2025-11-25/basic/lifecycle),
[stdio transport](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports),
and [tools](https://modelcontextprotocol.io/specification/2025-11-25/server/tools)
specifications.
