#!/usr/bin/env bash
# PostToolUse / PostToolUseFailure : trace chaque action (qui, quoi, quand, sur quelle VM, résultat)
# dans journal/audit.jsonl.
set -euo pipefail

journal="$CLAUDE_PROJECT_DIR/journal/audit.jsonl"
mkdir -p "$(dirname "$journal")"

jq -c --arg qui "$(whoami)" --arg quand "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  (.tool_input.command // .tool_input.file_path // (.tool_input | tostring | .[0:300])) as $action
  | {
      quand: $quand,
      qui: $qui,
      session: .session_id,
      agent: (.agent_type // "principal"),
      outil: .tool_name,
      vm: ([ $action | scan("multipass +(?:exec|info|launch .*--name|transfer [^ ]+|delete|stop|start|restart|shell) +([a-z][a-z0-9-]*)") | .[0] ] | unique | join(",")),
      action: $action,
      statut: (if .hook_event_name == "PostToolUseFailure" then "echec" else "ok" end)
    }' >>"$journal"
exit 0
