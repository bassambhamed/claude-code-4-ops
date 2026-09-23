#!/usr/bin/env bash
# Usage : test-acces.sh <user> <vm-source> <vm-cible> [--attendu ok|refuse]
# Test positif : <user> se connecte de la source vers la cible (ou est refusé si --attendu refuse).
# Tests négatifs : root de la source est refusé, et la clé de <user> ne donne jamais accès à root.
set -uo pipefail

user=${1:?user} src=${2:?vm-source} cible=${3:?vm-cible} attendu=ok
if [[ "${4:-}" == --attendu ]]; then attendu=${5:-}; fi
[[ "$attendu" == ok || "$attendu" == refuse ]] || { echo "--attendu doit valoir ok ou refuse" >&2; exit 2; }

ip=$(multipass info "$cible" --format json | jq -r ".info[\"$cible\"].ipv4[0]")
opts="-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new"
echecs=0

verifie() { # verifie <compte local> <compte distant> <attendu>
  # Sortie capturée, jamais vers /dev/null : sinon multipass exec se bloque sur un refus (stderr distant).
  local obtenu sortie
  if sortie=$(multipass exec "$src" -- sudo -u "$1" ssh $opts "$2@$ip" true </dev/null 2>&1); then obtenu=ok; else obtenu=refuse; fi
  if [[ "$obtenu" == "$3" ]]; then echo -n "OK    "; else echo -n "ECHEC "; ((echecs++)); fi
  echo "$1@$src -> $2@$cible : attendu=$3 obtenu=$obtenu"
}

verifie "$user" "$user" "$attendu"
verifie root root refuse
verifie "$user" root refuse

exit $((echecs > 0))
