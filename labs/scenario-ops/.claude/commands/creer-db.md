---
description: Installe PostgreSQL sur une VM et crée la base, ses rôles et une sauvegarde initiale
argument-hint: "[vm=vm1] [base=projet]"
disable-model-invocation: true
---

Arguments reçus : `$ARGUMENTS`. Créer la base `$1` (défaut `projet`) sur la VM `$0` (défaut `vm1`) ; un argument absent apparaît vide ou sous la forme `$n` : appliquer alors la valeur par défaut. Annoncer le plan et attendre la confirmation avant d'exécuter.

1. **Installer** : `multipass exec <vm> -- sudo apt-get install -y postgresql prometheus-postgres-exporter`.
2. **Configurer PostgreSQL** (fichiers de `/etc/postgresql/*/main/`) :
   - `listen_addresses = '*'` et `log_connections = on` ;
   - dans `pg_hba.conf`, autoriser en `scram-sha-256` le sous-réseau `/24` de l'IP de la VM (réseau Multipass) ;
   - redémarrer PostgreSQL.
3. **Créer les rôles et la base** avec `sudo -u postgres psql` :
   - `projet_owner` : LOGIN, propriétaire de la base ;
   - `lecture_seule` : LOGIN, `CONNECT` sur la base, `USAGE` sur `public`, `SELECT` sur les tables actuelles et futures (`ALTER DEFAULT PRIVILEGES`), et `pg_monitor` pour les statistiques ;
   - la base `<base>`, avec `OWNER projet_owner`, puis `REVOKE CONNECT ON DATABASE <base> FROM PUBLIC` : seuls les rôles de la matrice s'y connectent.
4. **Mots de passe** : pour chaque rôle LOGIN, en **une seule** commande exécutée dans la VM, générer le mot de passe dans une variable, l'écrire dans `/root/mot-de-passe-<rôle>` (mode 600) et l'appliquer par une variable psql, sans jamais le relire ni l'afficher :
   ```bash
   multipass exec <vm> -- sudo bash -c "umask 077; pw=\$(openssl rand -hex 24); printf %s \"\$pw\" > /root/mot-de-passe-<rôle>; echo \"ALTER ROLE <rôle> PASSWORD :'pw';\" | sudo -u postgres psql -q -v pw=\"\$pw\""
   ```
   Le hook **anti-secret** refuse toute relecture de ces fichiers. Donner à l'utilisateur la commande pour lire lui-même celui de `lecture_seule`, hors de Claude, afin qu'il construise `PG_RO_URL`.
5. **Exporter** :
   - créer le rôle `prometheus` (LOGIN, `pg_monitor`), qui s'authentifie en `peer` avec l'utilisateur système du même nom ;
   - dans `/etc/default/prometheus-postgres-exporter`, définir `DATA_SOURCE_NAME="user=prometheus host=/var/run/postgresql/ dbname=postgres sslmode=disable"` ;
   - redémarrer l'exporter.
6. **Sauvegarde initiale** : `pg_dump -Fc` dans `/var/backups/postgresql/<base>-initial.dump`.
7. **Test** :
   - `multipass exec <vm> -- pg_isready` ;
   - rôles, tests négatifs compris : `bash .claude/skills/gestion-permissions/scripts/audit-droits.sh <vm> --base`, toutes les lignes `OK` ;
   - l'exporter répond : `multipass exec <vm> -- sh -c 'curl -s localhost:9187/metrics | grep "^pg_up"'`.
