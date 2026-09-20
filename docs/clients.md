# Connecting Chip MCP to your client

Chip MCP is a **remote** server: streamable HTTP at `https://chip-ai.digital/mcp`,
authenticated with a Bearer token. There is nothing to install locally.

Get a token first: [@ChipAI_robot](https://t.me/ChipAI_robot) → mini app → **Chip MCP**
→ issue a token. Pick the **read** profile if the agent should never write.

Keep the token out of files you commit. Where a client supports environment
interpolation, prefer it — examples below show both.

## Claude Code

```bash
claude mcp add --transport http chip https://chip-ai.digital/mcp \
  --header "Authorization: Bearer chip_mcp_YOUR_TOKEN"
```

Use `--scope user` to make it available in every project instead of just the current
one. Verify with `claude mcp list`.

## Cursor

`~/.cursor/mcp.json` for all projects, `.cursor/mcp.json` for one:

```json
{
  "mcpServers": {
    "chip": {
      "url": "https://chip-ai.digital/mcp",
      "headers": { "Authorization": "Bearer ${env:CHIP_MCP_TOKEN}" }
    }
  }
}
```

## Other clients

Windsurf, Claude Desktop and most other MCP clients accept the same `mcpServers`
shape as Cursor — an entry with `url` and `headers`. For VS Code, follow Microsoft's
current MCP configuration docs and use the same URL and Authorization header.

If your client cannot do remote HTTP at all, bridge it with a stdio proxy such as
[`mcp-remote`](https://www.npmjs.com/package/mcp-remote):

```json
{
  "mcpServers": {
    "chip": {
      "command": "npx",
      "args": [
        "mcp-remote", "https://chip-ai.digital/mcp",
        "--header", "Authorization: Bearer ${CHIP_MCP_TOKEN}"
      ]
    }
  }
}
```

## First run

Ask your agent to call `whats_new` for the project you're working on. On a project it
has never seen it returns the full context; on a return visit, only what changed.
`list_projects` shows what exists, `create_project` makes a new one.

## Token limits

- up to 5 active tokens per account (revoke old ones in the mini app)
- rate limits are per token, so a laptop and a desktop don't share a bucket
- revoking a token in the mini app kills access immediately

## Troubleshooting

**401 with a message about a token** — the header is missing or the token was
revoked. Issue a new one in the mini app.

**"available in read-only mode"** — the token was issued with the `read` profile.
Profiles cannot be changed on a live token; issue a new one with full access.

**429** — rate limit for that token. Wait a minute.

**503** — the server is off for maintenance. Try later.
