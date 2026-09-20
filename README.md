# Chip MCP

**Project memory, tasks and Telegram notifications for your coding agent.**

[Русская версия](README.ru.md) · [chip-ai.digital/mcp](https://chip-ai.digital/mcp)

Chip is an assistant living in Telegram. This MCP server connects your IDE agent —
Claude Code, Cursor, anything that speaks MCP — to the same account. Decisions you
made yesterday, notes your agent wrote last session, tasks you assigned from your
phone: all still there when the next session starts with an empty context window.

> **Language note.** Chip is a Russian-language product: the tools answer in Russian
> and billing is in rubles. Everything works from any country, but if you don't read
> Russian, the responses will not be useful to you.

## Why bother

**Returning to a project costs 63 tokens instead of 2538.** Your agent calls
`whats_new` and gets only what changed since its last visit, not the whole project
again. Measured 2026-09-10 on a reference mature project with real `tiktoken
o200k_base` counting — not an estimate:

| scenario | before | after |
|---|---:|---:|
| first visit to a project | 2538 tokens | 2284 tokens |
| returning, nothing changed | 2538 tokens | **63 tokens** |
| returning after a day of edits | 2538 tokens | 295 tokens |

**A read-only token costs less to even list.** The tool list is paid for by every
session before the first call: 27 tools = 2905 tokens, the 11 read-only ones = 1155.
If your agent only reads the project, issue a `read` token and save 1750 tokens per
session.

**Your agent can reach you.** `notify_me` pushes a message to your Telegram when a
long build finishes; `ask_user` asks a question with buttons and `check_confirmation`
picks up the answer later — so an agent working alone can wait for a human decision
instead of guessing.

## Install

You need a free account: open [@ChipAI_robot](https://t.me/ChipAI_robot) in Telegram
→ mini app → **Chip MCP** → issue a token (`chip_mcp_…`). Choose **read** if you want
the agent to look but never touch.

**Claude Code**

```bash
claude mcp add --transport http chip https://chip-ai.digital/mcp --header "Authorization: Bearer chip_mcp_YOUR_TOKEN"
```

**Cursor** — `~/.cursor/mcp.json` (or `.cursor/mcp.json` in the project):

```json
{
  "mcpServers": {
    "chip": {
      "url": "https://chip-ai.digital/mcp",
      "headers": { "Authorization": "Bearer chip_mcp_YOUR_TOKEN" }
    }
  }
}
```

Any other client that takes an `mcpServers` entry with `url` + `headers` works the
same way. See [docs/clients.md](docs/clients.md) for more.

Then tell your agent to start with `whats_new` — the server's own instructions say so
too, so most agents do it unprompted.

## Claude Code plugin

Claude Code can install everything at once — the server, the session ritual and two
commands — instead of you wiring up the config by hand.

```bash
export CHIP_MCP_TOKEN=chip_mcp_YOUR_TOKEN
claude plugin marketplace add zapret-digital/chip-mcp
claude plugin install chip@chip-ai
```

The token lives **only** in `CHIP_MCP_TOKEN`. It is never written into the plugin
files, and never into `.chip.json`.

What the plugin adds:

- the `chip` MCP server, pointed at `https://chip-ai.digital/mcp/` — the address is
  a literal in the plugin, not something the environment can re-point;
- `/chip:start` and `/chip:finish` — the same session ritual as the server's `start`
  and `finish` prompts, for clients that don't render prompts;
- three hooks: on session start the project delta goes into the context; before
  context compaction and on stop the agent is reminded to save the summary.

The hooks need a `.chip.json` in the repository root to know which project this is:

```json
{ "project_id": 12 }
```

The mini app sends it to you — project settings, **«Правила для IDE-агента»**, next to
`AGENTS.md`. Telegram strips the leading dot from attachment names, so rename the file
back to `.chip.json` after saving. Without the file the hooks stay quiet — except for
one line at session start saying this repository has no `.chip.json`. The plugin still
works, the session just starts without the delta.

The hooks never block a session — no token, no network, no `python3` or `curl`, and
you get one line of explanation instead of a failed start.

*For local development:* `CHIP_MCP_URL` re-points **the hooks only**, and only at the
production address or a loopback stand (`http://127.0.0.1:8092/mcp/`); anything else
is refused. The MCP channel itself ignores the variable, so no repository can send
your token to its own host through `.claude/settings.json`.

## Tools

27 tools. `read` tokens get the 11 marked *read*; `full` tokens get everything.

<!-- tools:start -->
| Tool | Access | Arguments |
|---|---|---|
| `add_note` | write | `project_id`, `text`, `kind` |
| `add_task` | write | `project_id`, `text` |
| `archive_project` | write | `project_id` |
| `ask_user` | write | `question`, `options` |
| `attach_file` | write | `filename`, `size_bytes` |
| `check_confirmation` | write | `ask_id` |
| `complete_task` | write | `task_id`, `result` |
| `create_project` | write | `name` |
| `finalize_upload` | write | `upload_id` |
| `generate_image` | write | `prompt`, `project_id` |
| `get_project_context` | read | `project_id`, `depth` |
| `get_project_map` | write | `project_id` |
| `list_files` | read | `project_id` |
| `list_projects` | read | — |
| `list_tasks` | read | `project_id` |
| `notify_me` | write | `text`, `upload_id` |
| `read_journal` | read | `project_id`, `offset` |
| `read_map_section` | read | `project_id`, `section` |
| `read_project_dialog` | read | `project_id`, `session_id` |
| `read_project_file` | read | `project_id`, `filename`, `page` |
| `rename_project` | write | `project_id`, `name` |
| `save_session_summary` | write | `project_id`, `text` |
| `search_project` | read | `query`, `project_id`, `kind`, `since` |
| `set_reminder` | write | `text`, `when` |
| `upload_project_file` | write | `project_id`, `filename`, `size_bytes`, `content` |
| `whats_new` | read | `project_id`, `since`, `session` |
| `whoami` | read | — |
<!-- tools:end -->

`get_project_map` reads a table of contents but is listed as *write*, and that is
deliberate: fetching it also refreshes the project map, so a read-only token does not
get it. `read_map_section` reads a single entry without side effects.

Machine-readable: [spec.json](spec.json), generated from the server's own tool
registry — see below.

## What the server can and cannot see

- **It has no access to your filesystem.** It only ever receives what your agent
  explicitly passes as arguments. Nothing scans your repository.
- **Call arguments and results are not logged.** The usage log stores the tool name,
  duration and success flag — nothing else.
- **A `read` token cannot write.** Enforced on the call itself, not just by hiding
  tools from the list.
- **Tokens are stored as SHA-256.** The raw value is shown once, at issue time.
- Listing tools needs no token, so directories can index this server. Every actual
  call does.

## Verify the spec yourself

`spec.json` in this repo is generated from the live server's tool registry, so it
cannot quietly drift from reality. Check it against production yourself:

```bash
./scripts/verify.sh
```

It diffs the committed spec against `https://chip-ai.digital/mcp/spec.json`.

## Pricing

Connecting is free. Reading your own projects is free. Writes, Telegram messages and
image generation are metered against your Chip plan — the tools tell your agent when
a limit is reached and what to do about it. Plans live in the Telegram bot.

## Links

- [Landing page and docs](https://chip-ai.digital/mcp)
- [Telegram bot](https://t.me/ChipAI_robot)
- [Live spec](https://chip-ai.digital/mcp/spec.json)

## License

[MIT](LICENSE) for the contents of this repository (spec, docs, scripts). The Chip
service itself is proprietary.
