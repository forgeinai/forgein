#!/usr/bin/env bash
# forgein → Windsurf adapter
# Fetches your active forgein context and writes it to .windsurfrules in the current project.
# Usage: bash inject.sh [--global]
#   --global  writes to ~/.codeium/windsurf/memories/global_rules.md
set -euo pipefail

TOKEN_FILE="$HOME/.config/forgein/token"
API="https://api.forgein.ai"
GLOBAL=0

for arg in "$@"; do
  case $arg in --global) GLOBAL=1 ;; esac
done

[ -f "$TOKEN_FILE" ] || { echo "✗ Not authenticated. Run: curl -fsSL https://app.forgein.ai/cli/install.sh | bash  then /forgein auth"; exit 1; }
TOKEN=$(cat "$TOKEN_FILE")

printf 'Fetching active context from forgein...\n'
RESPONSE=$(curl -sf --max-time 10 \
  -H "Authorization: Bearer $TOKEN" \
  "$API/api/adapters/copilot" 2>/dev/null) || { echo "✗ Could not reach api.forgein.ai — check your connection."; exit 1; }

CONTENT=$(echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('content',''))" 2>/dev/null)
CTX=$(echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('context','work'))" 2>/dev/null)
FILES=$(echo "$RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('fileCount',0))" 2>/dev/null)

[ -z "$CONTENT" ] && { echo "✗ No context files synced yet. Run /forgein mem sync first."; exit 1; }

if [ "$GLOBAL" -eq 1 ]; then
  mkdir -p "$HOME/.codeium/windsurf/memories"
  OUT="$HOME/.codeium/windsurf/memories/global_rules.md"
else
  OUT="./.windsurfrules"
fi

{
  printf '# forgein context — %s (%s files) — %s\n\n' "$CTX" "$FILES" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "$CONTENT"
} > "$OUT"

printf '✓ Written to %s (%s context, %s files)\n' "$OUT" "$CTX" "$FILES"
printf '  Re-run this script (or set it as a git hook) to keep it in sync.\n'
