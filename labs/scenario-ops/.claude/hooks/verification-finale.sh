#!/usr/bin/env bash
# Stop : empêche Claude de conclure si une opération de la session n'a pas été suivie
# d'un test réussi, lancé APRÈS la dernière occurrence de cette opération.
set -euo pipefail

entree=$(cat)
[[ "$(jq -r '.stop_hook_active' <<<"$entree")" == "true" ]] && exit 0

session=$(jq -r '.session_id' <<<"$entree")
journal="$CLAUDE_PROJECT_DIR/journal/audit.jsonl"
[[ -f "$journal" ]] || exit 0

manque=()
exige() { # exige <motif opération> <motif test> <message>
  # Opération : commande Bash qui commence par « multipass » (évite les faux positifs d'un texte cité).
  # Test : n'importe quelle action réussie (statut ok) de la session.
  local verdict
  verdict=$(jq -rs --arg s "$session" --arg op "$1" --arg t "$2" '
    [ .[] | select(.session == $s) ] | to_entries
    | ([ .[] | select(.value.outil == "Bash" and (.value.action | test("^\\s*multipass ")) and (.value.action | test($op; "i"))) | .key ] | max) as $o
    | ([ .[] | select((.value.statut // "ok") == "ok" and ("\(.value.outil) \(.value.action)" | test($t))) | .key ] | max) as $d
    | if $o == null or ($d != null and $d >= $o) then "ok" else "manque" end' "$journal")
  [[ "$verdict" == ok ]] || manque+=("$3")
}

exige 'multipass +launch'                      'multipass +info'                  "VM créée sans vérification ultérieure (multipass info)"
exige 'multipass +delete'                      'multipass +list'                  "VM supprimée sans vérification ultérieure (multipass list)"
exige 'authorized_keys'                        'test-acces\.sh'                   "accès SSH modifié sans test-acces.sh réussi (positif et négatif)"
exige 'createdb|CREATE DATABASE'               'pg_isready'                       "base créée sans test pg_isready"
exige 'setfacl|GRANT|REVOKE'                   'audit-droits\.sh'                 "droits modifiés sans audit-droits.sh réussi"
exige 'prometheus\.yml|alertes\.yml|metriques-connexions' 'api/v1/targets|mcp__prometheus' "supervision installée sans vérifier les cibles Prometheus"

if ((${#manque[@]})); then
  printf 'Vérifications manquantes (à lancer après la dernière modification) :\n' >&2
  printf ' - %s\n' "${manque[@]}" >&2
  exit 2
fi
exit 0
