#!/usr/bin/env bash
# PreToolUse (Bash) de l'agent log-inspector : n'autorise que des commandes de lecture.
# Toute autre commande est refusée, quel que soit le mode de permission.
set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')

refuse() {
  echo "lecture-seule : $1. log-inspector ne fait que lire ; recommander l'action dans le résumé." >&2
  exit 2
}

# Pas d'enchaînement, de redirection ni de substitution.
if grep -Eq '[;&>`]|\$\(|<\(' <<<"$cmd"; then
  refuse "enchaînement, redirection ou substitution interdits"
fi

# Premier segment : lecture sur une VM, ou requête Prometheus.
lecture_vm='^multipass +(list|info)( |$)|^multipass +exec +[a-z][a-z0-9-]* +-- +(sudo +)?((sh|bash) +-c +.)?(journalctl|grep|zgrep|tail|head|cat|ls|last|lastb|who|ss|systemctl +status|pg_isready)( |$)'
prometheus='^curl +-s[G]? .*:9090/api/v1/(query|query_range|series|labels|label/[^ ]+/values|targets|alerts|rules)'
journal_dangereux='--(vacuum|rotate|flush|relinquish|setup-keys)|tail +.*-[a-zA-Z]*[fF]'

IFS='|' read -r -a segments <<<"$cmd"
premier=$(sed -E 's/^ +//' <<<"${segments[0]}")
if ! grep -Eq "$lecture_vm|$prometheus" <<<"$premier"; then
  refuse "commande non autorisée : ${premier:0:80}"
fi
if grep -Eq -- "$journal_dangereux" <<<"$cmd"; then
  refuse "option de journalctl ou de tail non autorisée"
fi

# Segments suivants : filtres locaux uniquement.
for seg in "${segments[@]:1}"; do
  seg=$(sed -E 's/^ +//' <<<"$seg")
  grep -Eq '^(grep|sort|uniq|wc|head|tail|cut|tr|jq|column)( |$)' <<<"$seg" \
    || refuse "filtre non autorisé après | : ${seg:0:40}"
done
exit 0
