#!/usr/bin/env bash
set -u

HOOK_INPUT="$(cat)"

if ! command -v python3 >/dev/null 2>&1; then
  printf '%s\n' "Чип: не нашёл python3 — без него хуки плагина не работают. Поставь python3 или выключи плагин: claude plugin disable chip"
  exit 0
fi

MIN_TOOL_CALLS=5

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(printf '%s' "$HOOK_INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("cwd") or "")
except Exception: print("")' 2>/dev/null)"
fi
[ -n "$PROJECT_DIR" ] || PROJECT_DIR="$PWD"

[ -f "$PROJECT_DIR/.chip.json" ] || exit 0

DATA_DIR="${CLAUDE_PLUGIN_DATA:-${XDG_STATE_HOME:-$HOME/.local/state}/chip-plugin}"

DATA_DIR="$DATA_DIR" MIN_TOOL_CALLS="$MIN_TOOL_CALLS" python3 -c '
import json, os, re, sys

data = json.loads(sys.stdin.read() or "{}")
if data.get("stop_hook_active"):
    sys.exit(0)

path = data.get("transcript_path") or ""
try:
    with open(path, encoding="utf-8", errors="replace") as f:
        transcript = f.read()
except OSError:
    sys.exit(0)

if "mcp__chip__save_session_summary" in transcript:
    sys.exit(0)

calls = len(re.findall(r"\"type\"\s*:\s*\"tool_use\"", transcript))
if calls < int(os.environ["MIN_TOOL_CALLS"]):
    sys.exit(0)

session_id = str(data.get("session_id") or "").strip()
session_id = re.sub(r"[^A-Za-z0-9._-]", "_", session_id) or "unknown"
data_dir = os.environ["DATA_DIR"]
marker = os.path.join(data_dir, "stop-" + session_id)
try:
    os.makedirs(data_dir, exist_ok=True)
    fd = os.open(marker, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    os.close(fd)
except FileExistsError:
    sys.exit(0)
except OSError:
    sys.exit(0)

sys.stdout.write(json.dumps({
    "decision": "block",
    "reason": (
        "Сессия работала, а сводки в Чипе нет: вызови save_session_summary "
        "(или /chip:finish, он же /mcp__chip__finish), потом заканчивай."
    ),
}, ensure_ascii=False))
' <<CHIP_HOOK_INPUT
$HOOK_INPUT
CHIP_HOOK_INPUT
exit 0
