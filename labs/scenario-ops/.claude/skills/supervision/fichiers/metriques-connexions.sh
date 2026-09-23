#!/usr/bin/env bash
# Compte les connexions SSH et PostgreSQL sur 1 h et 24 h et les publie
# pour le textfile collector de node_exporter. Lancé chaque minute par cron.
set -uo pipefail

sortie=/var/lib/prometheus/node-exporter/connexions.prom
tmp=$(mktemp)

acceptee='Accepted (publickey|password)'
# Un refus par clé (BatchMode, clé inconnue) ne produit que « Connection closed by authenticating user ».
refusee='Failed |Invalid user|authentication failure|Connection closed by authenticating user'

ssh_journal() { # ssh_journal <période>, sans le canal d'administration Multipass
  # Chaque « multipass exec » est une connexion SSH du compte ubuntu : l'exclure, sinon
  # les commandes de l'agent elles-mêmes gonflent les compteurs.
  journalctl -t sshd -t sshd-session --since "-$1" --no-pager -q 2>/dev/null | grep -Ev 'for ubuntu from|user ubuntu '
}

ssh_compte() { # ssh_compte <période> <motif>
  ssh_journal "$1" | grep -Ec "$2"
}

ssh_par_source() { # refus de la dernière heure, par IP source
  ssh_journal 1h | grep -E "$refusee" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort | uniq -c \
    | awk '{ printf "ssh_refus_par_source_1h{source=\"%s\"} %d\n", $2, $1 }'
}

pg_compte() { # pg_compte <minutes> <motif> (0 si PostgreSQL absent)
  local log
  log=$(ls /var/log/postgresql/postgresql-*-main.log 2>/dev/null | head -1)
  [[ -n "$log" ]] || { echo 0; return; }
  # Exclut l'administration (postgres, ubuntu de Multipass, ex. pg_isready) et l'exporter (prometheus) :
  # seuls comptent les rôles d'usage.
  awk -v depuis="$(date -d "-$1 min" '+%Y-%m-%d %H:%M:%S')" \
      'substr($0,1,19) >= depuis' "$log" | grep -Ev 'user=(postgres|prometheus|ubuntu)( |$)' | grep -Ec "$2"
}

{
  echo "# HELP ssh_connexions_acceptees_1h Connexions SSH acceptées sur la dernière heure."
  echo "# TYPE ssh_connexions_acceptees_1h gauge"
  echo "ssh_connexions_acceptees_1h $(ssh_compte 1h "$acceptee")"
  echo "# TYPE ssh_connexions_refusees_1h gauge"
  echo "ssh_connexions_refusees_1h $(ssh_compte 1h "$refusee")"
  echo "# TYPE ssh_connexions_acceptees_24h gauge"
  echo "ssh_connexions_acceptees_24h $(ssh_compte 24h "$acceptee")"
  echo "# TYPE ssh_connexions_refusees_24h gauge"
  echo "ssh_connexions_refusees_24h $(ssh_compte 24h "$refusee")"
  echo "# HELP ssh_refus_par_source_1h Tentatives SSH refusées sur la dernière heure, par IP source."
  echo "# TYPE ssh_refus_par_source_1h gauge"
  ssh_par_source
  echo "# TYPE pg_connexions_24h gauge"
  echo "pg_connexions_24h $(pg_compte 1440 'connection authorized')"
  echo "# TYPE pg_echecs_auth_24h gauge"
  echo "pg_echecs_auth_24h $(pg_compte 1440 'authentication failed')"
} >"$tmp"

chmod 644 "$tmp" && mv "$tmp" "$sortie"
