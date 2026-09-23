# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Nature du projet

Pas d'application à compiler ni de suite de tests : le dépôt est une **configuration Claude Code** qui pilote un scénario ops entièrement local. Trois VM Multipass (`vm1` : PostgreSQL + espace `/srv/projet` de BA1 ; `vm2` : poste de BA2 ; `monitor` : Prometheus + Grafana). Aucun service cloud, aucune notification externe.

- `scenario-agentique-deux-ba.md` : le *pourquoi* (choix commande / skill / agent / hook / MCP pour chaque tâche).
- `ETAPES.md` : le *comment* (déroulé en 10 étapes, résultats attendus, prérequis : multipass, jq, docker, npx).

Le projet est rédigé en français : garder cette langue pour les fichiers, rapports et messages.

## Règles du projet

- **Annoncer le plan et attendre une validation** avant toute création, suppression, ouverture d'accès ou modification de droits.
- **Secrets** : ne jamais afficher ni écrire de clé privée, mot de passe ou jeton. Les mots de passe PostgreSQL restent dans `/root/mot-de-passe-<rôle>` (mode 600) sur vm1 ; l'humain les lit lui-même hors Claude. Les clés privées SSH ne quittent jamais la VM source (seul le `.pub` est copié).
- **Moindre privilège** : aucun droit hors de `.claude/skills/gestion-permissions/matrice-droits.md`. Si une demande sort de la matrice, proposer d'abord de modifier la matrice.
- **Toute opération se termine par un test**, y compris un test négatif pour les droits et l'accès SSH.
- **Chiffres = Prometheus** (MCP `prometheus` ou `curl -s $PROMETHEUS_URL/api/v1/query`). Ne jamais compter ou estimer à la main.
- `multipass purge` est interdit à l'agent ; `journal/` est en écriture interdite (seul le hook d'audit l'alimente).

## Architecture de la configuration

Toutes les actions sur les VM passent par la CLI : `multipass exec <vm> -- …`, `multipass transfer <fichier> <vm>:/tmp/` puis `sudo install`. IP d'une VM : `multipass info <vm> --format json | jq -r '.info["<vm>"].ipv4[0]'`.

| Brique | Rôle |
| --- | --- |
| `commands/provision-vm`, `commands/creer-db` | Actions ponctuelles, invocables **uniquement par l'humain** (`disable-model-invocation`) |
| `skills/acces-ssh`, `gestion-permissions`, `supervision` | Procédures réutilisables avec fichiers d'appui, également réservées à l'humain |
| `skills/rapport-connexions` | Seul skill invocable par le modèle (lecture seule) : remplit `gabarit-rapport.md` → `rapports/AAAA-MM-JJ.md` |
| `agents/log-inspector` | Seul sous-agent : lecture seule **imposée par son hook `lecture-seule`** (journalctl, logs PostgreSQL, PromQL), résumé ≤ 15 lignes, recommande sans exécuter |
| `ressources/cloud-init-base.yaml` | Durcissement SSH (pas de root, clé uniquement) + `node_exporter` avec textfile collector, commun à toutes les VM |

### Hooks (`settings.json`) : ils conditionnent ce que l'agent peut faire

- **garde-fou** (PreToolUse Bash) : refuse (`deny`) la purge Multipass (y compris `delete --purge` / `-p`) et toute commande qui cite `journal/audit.jsonl` ; force une confirmation (`ask`) sur `multipass launch|delete|stop|restart`, `rm -r…`, `DROP …`, `dropdb`, `dropuser`, `userdel`, `authorized_keys`, `setfacl -b|-x|-k`, `ufw`, `iptables`, même si la permission est accordée. Le hook lit le texte brut de la commande : une commande qui se contente de *citer* ces mots (heredoc, sed sur un fichier de doc) est aussi concernée, d'où l'usage de l'outil Edit pour modifier ces fichiers.
- **anti-secret** (PreToolUse Bash/Write/Edit) : bloque tout contenu ressemblant à une clé privée, un mot de passe PostgreSQL en littéral (variable d'environnement PG ou clause SQL de mot de passe entre quotes) ou un jeton Grafana `glsa_…`, ainsi que toute lecture (`cat`, `head`, `base64`…) de `id_ed25519`, `id_rsa`, `mot-de-passe*`, `.pgpass`. Pour définir un mot de passe SQL, utiliser la commande de `/creer-db` (variable shell + variable psql `:'pw'`), jamais un littéral. Ce hook s'applique aussi à la documentation écrite par Claude ; ses propres motifs sont découpés (`'PASS''WORD'`) pour ne pas se bloquer eux-mêmes.
- **audit** (PostToolUse **et** PostToolUseFailure) : ajoute chaque action à `journal/audit.jsonl` (quand, qui, session, agent, outil, VM, action, statut `ok`/`echec`).
- **lecture-seule** (PreToolUse Bash, déclaré dans le frontmatter de `agents/log-inspector.md`, donc actif uniquement pour cet agent) : n'accepte que `multipass list|info`, `multipass exec <vm> -- [sudo] journalctl|grep|tail|…`, les requêtes `curl` vers `:9090/api/v1/…` et des filtres locaux après `|`.
- **verification-finale** (Stop) : relit le journal de la session et **empêche de conclure** tant qu'une commande `multipass …` sensible n'a pas été suivie, *après coup*, d'un test **réussi** :

  | Si la session contient… | Il faut aussi avoir lancé… |
  | --- | --- |
  | `multipass launch` | `multipass info` |
  | `multipass delete` | `multipass list` |
  | `authorized_keys` | `test-acces.sh` |
  | `createdb` / `CREATE DATABASE` | `pg_isready` |
  | `setfacl` / `GRANT` / `REVOKE` (y compris ceux de `/creer-db`) | `audit-droits.sh` (`--base` après `/creer-db`) |
  | `prometheus.yml` / `alertes.yml` / `metriques-connexions` | `api/v1/targets` ou un appel `mcp__prometheus` |

### Scripts de test (autorisés sans confirmation)

```bash
bash .claude/skills/acces-ssh/scripts/test-acces.sh <user> <vm-source> <vm-cible> [--attendu ok|refuse]
bash .claude/skills/gestion-permissions/scripts/audit-droits.sh [vm1] [--base]
```

Les hooks se testent hors VM en leur envoyant le JSON d'un appel d'outil sur l'entrée standard, par exemple `jq -n '{tool_name:"Bash",tool_input:{command:"multipass list"}}' | .claude/hooks/garde-fou.sh` (avec `CLAUDE_PROJECT_DIR` pointant vers un dossier jetable pour `audit.sh` et `verification-finale.sh`). Ils tournent avec le bash 3.2 de macOS : pas de `mapfile` ni de `${var,,}`.

Chaque ligne doit être `OK` ; une ligne `ECHEC` rend le code de sortie non nul.

### Chaîne de supervision

`metriques-connexions.sh` (cron chaque minute sur vm1/vm2) compte les événements `sshd` et PostgreSQL et écrit `/var/lib/prometheus/node-exporter/connexions.prom` → `node_exporter` → Prometheus sur monitor (`prometheus.yml`, `alertes.yml`) → Grafana (tableau de bord « Connexions »). Les métriques custom (`ssh_connexions_{acceptees,refusees}_{1h,24h}`, `ssh_refus_par_source_1h{source=…}`, `pg_connexions_24h`, `pg_echecs_auth_24h`) sont celles interrogées par `rapport-connexions` et `log-inspector` : renommer une métrique implique de mettre à jour le script, `alertes.yml`, le dashboard et les deux consommateurs. Chaque `multipass exec` est une connexion SSH du compte `ubuntu` depuis la passerelle de l'hôte : le script exclut ce compte (et, côté PostgreSQL, `postgres`, `prometheus` et `ubuntu`), sinon les commandes de l'agent gonflent les compteurs. Seuils du scénario : ≥ 5 refus SSH en 1 h **depuis une même source** = « À surveiller » ; ≥ 20 refus en 1 h, VM ou base injoignable = « Critique ».

### Serveurs MCP (`.mcp.json`)

`prometheus` et `postgres` (rôle `lecture_seule`) sont en lecture seule et autorisés ; `grafana` est soumis à confirmation. Ils dépendent des variables `PROMETHEUS_URL`, `GRAFANA_URL`, `GRAFANA_SERVICE_ACCOUNT_TOKEN`, `PG_RO_URL`, exportées par l'humain dans son shell (étape 6 d'`ETAPES.md`) et jamais écrites dans un fichier du dépôt. Tant qu'elles ne sont pas définies, ces serveurs ne se connectent pas.
