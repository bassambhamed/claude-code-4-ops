#!/usr/bin/env bash
# PreToolUse (Bash) : impose une confirmation humaine pour les commandes destructrices ou sensibles,
# même si une règle de permission les autorise. Refuse sans appel ce qui est réservé à l'humain.
set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')

decision() { # decision <ask|deny> <raison>
  jq -n --arg d "$1" --arg r "$2" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: $d,
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

# Réservé à l'humain : purge Multipass (y compris delete --purge) et altération du journal d'audit.
interdit='multipass +purge|multipass +delete .*(--purge|-p\b)|journal/audit\.jsonl'
if grep -Eq "$interdit" <<<"$cmd"; then
  decision deny "Interdit à l'agent : $(grep -Eo "$interdit" <<<"$cmd" | head -1). L'humain lance cette commande lui-même."
fi

motif='multipass +(launch|delete|stop|restart)|rm +-[a-zA-Z]*[rR]|DROP +(DATABASE|TABLE|SCHEMA|ROLE|USER)|dropdb|dropuser|userdel|deluser|authorized_keys|setfacl +(-b|-x|-k|--remove)|ufw |iptables '
if grep -Eiq "$motif" <<<"$cmd"; then
  decision ask "Action sensible détectée : $(grep -Eio "$motif" <<<"$cmd" | head -1). Confirmation humaine requise."
fi
exit 0
