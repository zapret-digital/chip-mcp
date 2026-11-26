# Changelog

## 1.3.2 · 2026-11-26

- Errands from the IDE: `errand_plan` → `errand_start` → `errand_status`, `errand_result`, `errand_cancel`. A multi-step background task (search, table, report, deck): the plan and the price come before the start, the user approves it, and it is paid with Chip credits. 32 tools.
- `list_tasks`: pages of 20 with `offset`; `task_id` returns one task in full.
- `add_note`: agent notes up to 500 characters (pitfalls and corrections stay at 600). A longer note is refused with a request to shorten it, before the daily write limit is touched; a duplicate or empty note gives its write back.
- `add_task`: when the open-task limit is reached, the refusal lists the oldest tasks with their ids.
- `generate_image`: the description states the current price.
- README: what is free and what needs the Basic plan.

## 1.3.1 · 2026-09-10

- Claude Code plugin: marketplace `chip-ai`, session hooks (SessionStart, PreCompact, Stop), commands `/chip:start` and `/chip:finish`, `.chip.json` for the project id.
- Server prompts `start`, `finish`, `pitfall` (`/mcp__chip__…` in Claude Code).
- Resources `chip://project/{id}/…`: context, tasks, journal, decisions, pitfalls and map shelves; read-only, never move the `whats_new` mark.
- `attach_file` + `notify_me(upload_id)`: screenshots, PDFs and logs up to 5 MB delivered to Telegram. 27 tools.
- Note kinds `pitfall` and `correction`; session summaries get their own daily cap.
- Install buttons for Cursor and VS Code in the account; project export as an Obsidian vault.

## 1.1.0 · 2026-09-08

- `add_task`: the agent leaves tasks for its next session.
- `whats_new(since, session)`: cursor for parallel sessions, peer session labels, open task count.
- Tool annotations (read-only / destructive hints), `whoami` with remaining daily limits, `search_project` filters. 26 tools.

## 1.0.0 · 2026-08-09

- First public listing: `spec.json` generated from the server's tool registry, `server.json` for the MCP registry, client configs for Claude Code, Cursor, Codex CLI, Windsurf, Cline and VS Code.
