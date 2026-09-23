#!/usr/bin/env bash
# PreToolUse (Bash|Write|Edit) : bloque l'écriture ou l'affichage de secrets.
# Les motifs sont découpés ('PASS''WORD') pour que ce fichier ne se bloque pas lui-même.
set -euo pipefail

entree=$(cat)
outil=$(jq -r '.tool_name' <<<"$entree")

case "$outil" in
  Bash)  texte=$(jq -r '.tool_input.command // ""' <<<"$entree") ;;
  Write) texte=$(jq -r '.tool_input.content // ""' <<<"$entree") ;;
  Edit)  texte=$(jq -r '.tool_input.new_string // ""' <<<"$entree") ;;
  *)     exit 0 ;;
esac

# Contenu de clé privée, mot de passe en littéral, jeton Grafana.
# Une variable shell ($pw) est acceptée : le secret reste alors dans la VM.
contenu='-----BEGIN [A-Z ]*PRIVATE'' KEY-----|PGPASS''WORD=[^$ ]|PASS''WORD +'"'"'[^'"'"'$][^'"'"']*'"'"'|glsa''_[A-Za-z0-9_]{10,}'
# Lecture d'une clé privée, d'un mot de passe ou d'un jeton (Bash uniquement)
lecteurs='(^|[^a-zA-Z0-9_-])(cat|less|more|head|tail|base64|xxd|od|strings|grep|awk|sed|nl|tac|cp|dd|scp|rsync|transfer)[ ]'
fichiers='(id_ed25519|id_rsa|mot-de-passe|jeton-grafana|\.pgpass)'

if grep -Eq -- "$contenu" <<<"$texte"; then
  echo "anti-secret : secret en clair détecté. Utiliser un fichier 600 ou une variable d'environnement." >&2
  exit 2
fi
if [[ "$outil" == Bash ]]; then
  sans_pub=$(sed -E 's/id_(ed25519|rsa)\.pub//g' <<<"$texte")
  if grep -Eq -- "$lecteurs[^|;&]*$fichiers" <<<"$sans_pub"; then
    echo "anti-secret : lecture d'une clé privée, d'un mot de passe ou d'un jeton refusée. L'humain le lit lui-même hors de Claude." >&2
    exit 2
  fi
fi
exit 0
