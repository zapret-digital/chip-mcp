#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
LIVE="${CHIP_MCP_SPEC_URL:-https://chip-ai.digital/mcp/spec.json}"

echo "committed: spec.json"
echo "live:      $LIVE"
echo

remote="$(mktemp)"
trap 'rm -f "$remote"' EXIT
curl -fsS "$LIVE" > "$remote"

if command -v jq > /dev/null 2>&1; then
  if diff <(jq --sort-keys . spec.json) <(jq --sort-keys . "$remote"); then
    echo "✓ витрина совпадает с сервером"
  else
    echo "✗ расхождение — витрина отстала от прода" >&2
    exit 1
  fi
else
  if diff spec.json "$remote"; then
    echo "✓ витрина совпадает с сервером (побайтово)"
  else
    echo "✗ расхождение (поставь jq, если дело в форматировании)" >&2
    exit 1
  fi
fi
