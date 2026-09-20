#!/usr/bin/env bash
set -u

HOOK_INPUT="$(cat)"

if ! command -v python3 >/dev/null 2>&1; then
  printf '%s\n' "Чип: не нашёл python3 — без него хуки плагина не работают. Поставь python3 или выключи плагин: claude plugin disable chip"
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR="$(printf '%s' "$HOOK_INPUT" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("cwd") or "")
except Exception: print("")' 2>/dev/null)"
fi
[ -n "$PROJECT_DIR" ] || PROJECT_DIR="$PWD"

[ -f "$PROJECT_DIR/.chip.json" ] || exit 0

printf '%s\n' "Перед сжатием контекста: если в сессии была работа, сохрани сводку через save_session_summary, решения — add_note(kind=decision), грабли — add_note(kind=pitfall)."
exit 0
