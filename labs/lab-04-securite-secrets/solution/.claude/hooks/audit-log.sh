#!/usr/bin/env bash
# Hook PostToolUse — journalise chaque commande shell executee par l'agent.
#
# Tracabilite exigee par DORA : qui, quand, quoi, dans quel depot. Le journal est ecrit
# HORS du depot de travail : il ne doit etre ni committe, ni efface par un `git clean`.
# Ce hook ne fait JAMAIS echouer une commande (exit 0 systematique).
set -uo pipefail

LOG_DIR="${CLAUDE_AUDIT_DIR:-$HOME/.claude/audit}"
LOG="$LOG_DIR/$(date -u +%F).jsonl"
mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

payload="$(cat)"
line="$(jq -c \
  --arg ts    "$(date -u +%FT%TZ)" \
  --arg user  "${USER:-unknown}" \
  --arg repo  "$(basename "$PWD")" \
  --arg cwd   "$PWD" \
  --arg sid   "${CLAUDE_SESSION_ID:-unknown}" \
  '{ts:$ts, session:$sid, user:$user, repo:$repo, cwd:$cwd,
    tool:(.tool_name // "unknown"), command:(.tool_input.command // null)}' \
  <<<"$payload" 2>/dev/null)" || exit 0

# Ecriture atomique : une ligne complete ou rien.
[ -n "$line" ] && printf '%s\n' "$line" >> "$LOG" 2>/dev/null
exit 0
