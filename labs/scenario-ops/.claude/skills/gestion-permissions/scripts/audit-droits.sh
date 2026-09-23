#!/usr/bin/env bash
# Usage : audit-droits.sh [vm=vm1] [--base]
# Vérifie la matrice des droits : tests positifs et négatifs pour ba2, puis rôles PostgreSQL.
# --base : rôles PostgreSQL seulement (test de fin de /creer-db, avant la création de /srv/projet).
set -uo pipefail

vm=${1:-vm1} mode=${2:-complet}
echecs=0

resultat() { # resultat <description> <attendu> <obtenu>
  if [[ "$3" == "$2" ]]; then echo -n "OK    "; else echo -n "ECHEC "; ((echecs++)); fi
  echo "$1 : attendu=$2 obtenu=$3"
}

verifie() { # verifie <description> <attendu oui|non> <commande exécutée en tant que ba2>
  # Capturer la sortie plutôt que l'envoyer vers /dev/null : multipass exec se bloque
  # quand la commande distante écrit sur stderr et que la sortie locale est /dev/null.
  local obtenu sortie
  if sortie=$(multipass exec "$vm" -- sudo -u ba2 bash -c "$3" </dev/null 2>&1); then obtenu=oui; else obtenu=non; fi
  resultat "$1" "$2" "$obtenu"
}

verifie_sql() { # verifie_sql <description> <attendu t|f> <requête booléenne>
  local obtenu
  obtenu=$(multipass exec "$vm" -- sudo -u postgres psql -d projet -Atc "$3" </dev/null 2>&1) || obtenu=erreur
  resultat "$1" "$2" "${obtenu:-vide}"
}

if [[ "$mode" != --base ]]; then
  echo "--- Espace /srv/projet"
  verifie "ba2 lit specs/"             oui "ls /srv/projet/specs"
  verifie "ba2 écrit dans specs/"      non "test -w /srv/projet/specs"
  verifie "ba2 écrit dans drafts/ba2/" oui "test -w /srv/projet/drafts/ba2"
  verifie "ba2 liste drafts/"          non "ls /srv/projet/drafts"

  echo "--- ACL"
  multipass exec "$vm" -- sudo getfacl -p /srv/projet/specs /srv/projet/drafts/ba2 </dev/null 2>&1 | grep -E '^# file|ba2'
fi

echo "--- Rôles PostgreSQL"
verifie_sql "projet_owner possède projet"          t "SELECT pg_get_userbyid(datdba) = 'projet_owner' FROM pg_database WHERE datname = 'projet'"
verifie_sql "lecture_seule se connecte à projet"   t "SELECT has_database_privilege('lecture_seule', 'projet', 'CONNECT')"
verifie_sql "lecture_seule est pg_monitor"         t "SELECT pg_has_role('lecture_seule', 'pg_monitor', 'MEMBER')"
verifie_sql "lecture_seule crée dans public"       f "SELECT has_schema_privilege('lecture_seule', 'public', 'CREATE')"
verifie_sql "lecture_seule crée un schéma"         f "SELECT has_database_privilege('lecture_seule', 'projet', 'CREATE')"
verifie_sql "prometheus est pg_monitor"            t "SELECT pg_has_role('prometheus', 'pg_monitor', 'MEMBER')"
verifie_sql "prometheus se connecte à projet"      f "SELECT has_database_privilege('prometheus', 'projet', 'CONNECT')"

exit $((echecs > 0))
