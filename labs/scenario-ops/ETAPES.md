# Déroulement du scénario, étape par étape

Ce guide exécute le scénario décrit dans `scenario-agentique-deux-ba.md` avec la configuration Claude Code du dossier `.claude/`. Tout tourne en local : 3 VM Multipass, Prometheus et Grafana.

```text
scenario-ops/
├── ETAPES.md                  ← ce guide
├── scenario-agentique-deux-ba.md ← le scénario et les choix de briques
├── .mcp.json                  ← serveurs MCP : prometheus, postgres, grafana
└── .claude/
    ├── CLAUDE.md              ← règles du projet
    ├── settings.json          ← permissions + déclaration des hooks
    ├── commands/              ← /provision-vm, /creer-db
    ├── skills/                ← acces-ssh, gestion-permissions, supervision, rapport-connexions
    ├── agents/                ← log-inspector (lecture seule)
    ├── hooks/                 ← garde-fou, anti-secret, audit, verification-finale (+ lecture-seule, propre à log-inspector)
    └── ressources/            ← cloud-init commun aux VM
```

Au cours de l'exécution, deux dossiers apparaissent : `journal/` (audit de chaque action) et `rapports/` (bilans des connexions).

---

## Étape 0 : Prérequis sur le poste hôte

| Outil | Pourquoi | Vérification |
| --- | --- | --- |
| Multipass | Créer les VM | `multipass version` |
| jq | Utilisé par les hooks | `jq --version` |
| Docker | MCP `prometheus` et `grafana` | `docker info` |
| Node.js (npx) | MCP `postgres` | `npx --version` |
| Claude Code | L'agent | `claude --version` |

Préparer un terminal :

```bash
cd scenario-ops
chmod +x .claude/hooks/*.sh .claude/skills/*/scripts/*.sh
claude
```

Au premier lancement, Claude Code demande d'approuver les serveurs MCP du projet. Refuser pour l'instant : les variables d'environnement ne seront prêtes qu'à l'étape 6.

**Contrôle :** dans Claude Code, vérifier la configuration :
- `/hooks` : 4 hooks ;
- `/agents` : `log-inspector` ;
- `/permissions` : les règles de `settings.json`.

---

## Étape 1 : Créer les trois VM

```text
/provision-vm vm1 2 2G 10G
/provision-vm vm2 1 1G 8G
/provision-vm monitor 2 2G 10G
```

| Ce qui se passe | Brique |
| --- | --- |
| Claude annonce la commande `multipass launch`, avec le cloud-init de durcissement SSH et `node_exporter` | commande `/provision-vm` |
| Une confirmation est demandée, même si la commande est autorisée | hook **garde-fou** |
| L'action est tracée dans `journal/audit.jsonl` | hook **audit** |
| Claude ne peut pas conclure sans avoir lancé `multipass info` | hook **verification-finale** |

**Résultat attendu :** `multipass list` affiche 3 VM `Running` avec une IPv4.

---

## Étape 2 : Créer la base PostgreSQL sur vm1

```text
/creer-db vm1 projet
```

Claude installe PostgreSQL et `postgres_exporter`, puis crée :
- la base `projet` ;
- les rôles `projet_owner`, `lecture_seule` et `prometheus` ;
- une sauvegarde initiale.

Les mots de passe restent dans `/root/mot-de-passe-*` sur vm1 : le hook **anti-secret** bloque toute tentative de les afficher.

**Résultat attendu :** `pg_isready` répond `accepting connections`.

Récupérer soi-même le mot de passe du rôle en lecture seule, **dans un terminal séparé, hors Claude** :

```bash
multipass exec vm1 -- sudo cat /root/mot-de-passe-lecture_seule
```

---

## Étape 3 : Appliquer les permissions

```text
/gestion-permissions appliquer vm1
```

La matrice de référence est `.claude/skills/gestion-permissions/matrice-droits.md`. Claude procède dans cet ordre :

1. audit « avant » ;
2. création des comptes `ba1` et `ba2`, et de `/srv/projet/{specs,drafts/ba2}` ;
3. application des ACL et des `GRANT` ;
4. audit « après ».

**Résultat attendu :** toutes les lignes du script d'audit sont `OK`, y compris les tests négatifs :
- BA2 **ne peut pas** écrire dans `specs/` ;
- BA2 **ne peut pas** lister `drafts/`.

---

## Étape 4 : Ouvrir l'accès SSH de BA2 (vm2 → vm1)

```text
/acces-ssh ouvrir ba2 vm2 vm1
```

Claude génère la clé ed25519 **sur vm2** : la clé privée ne quitte jamais vm2. Il copie la clé publique dans `authorized_keys` sur vm1, puis lance le script de test.

**Résultat attendu :**

```text
OK    ba2@vm2 -> ba2@vm1 : attendu=ok obtenu=ok
OK    root@vm2 -> root@vm1 : attendu=refuse obtenu=refuse
OK    ba2@vm2 -> root@vm1 : attendu=refuse obtenu=refuse
```

---

## Étape 5 : Installer la supervision

```text
/supervision monitor
```

| Élément installé | Où | Rôle |
| --- | --- | --- |
| `metriques-connexions.sh` + cron | vm1, vm2 | Compte les connexions SSH et PostgreSQL et les publie pour `node_exporter` |
| Prometheus + `alertes.yml` | monitor | **Mesure** : collecte, stockage, alertes |
| Grafana + tableau de bord « Connexions » | monitor | **Montre** : 4 panneaux pour les humains |

**Résultat attendu :**
- toutes les cibles sont `up` dans `http://<ip-monitor>:9090/targets` ;
- Grafana répond sur `http://<ip-monitor>:3000`. Identifiants `admin`/`admin`, à changer à la première connexion.
- le jeton du compte de service `claude` est dans `/root/jeton-grafana` sur monitor. Le lire soi-même, **dans un terminal séparé, hors Claude** : `multipass exec monitor -- sudo cat /root/jeton-grafana`.

---

## Étape 6 : Brancher les serveurs MCP

Quitter Claude Code (`/exit`), puis exporter les variables, **sans les écrire dans un fichier du dépôt** :

```bash
IP_MON=$(multipass info monitor --format json | jq -r '.info.monitor.ipv4[0]')
IP_VM1=$(multipass info vm1 --format json | jq -r '.info.vm1.ipv4[0]')
export PROMETHEUS_URL="http://$IP_MON:9090"
export GRAFANA_URL="http://$IP_MON:3000"
read -rsp 'Jeton Grafana : ' GRAFANA_SERVICE_ACCOUNT_TOKEN; export GRAFANA_SERVICE_ACCOUNT_TOKEN; echo
read -rsp 'Mot de passe lecture_seule : ' PGPW; echo
export PG_RO_URL="postgresql://lecture_seule:$PGPW@$IP_VM1:5432/projet"; unset PGPW
claude
```

Accepter les serveurs MCP, puis taper `/mcp` : `prometheus`, `postgres` et `grafana` doivent être connectés.

---

## Étape 7 : Simuler de l'activité

Pour que le rapport contienne des chiffres, générer quelques événements depuis un terminal hors Claude :

```bash
# Connexions réussies de BA2
for i in 1 2 3; do multipass exec vm2 -- sudo -u ba2 ssh -o BatchMode=yes ba2@$IP_VM1 true; done
# Tentatives refusées : un utilisateur inconnu
for i in $(seq 1 6); do multipass exec vm2 -- ssh -o BatchMode=yes -o StrictHostKeyChecking=no intrus@$IP_VM1 true; done
```

Attendre environ 2 minutes (cron, puis collecte par Prometheus). Grafana montre alors les refus sur vm1, et l'alerte `EchecsSshASurveiller` s'allume (seuil de 5).

---

## Étape 8 : Produire le rapport

```text
Fais-moi le bilan des connexions.
```

Le skill **rapport-connexions** se déclenche automatiquement : il est invocable par le modèle, car il ne fait que lire. Il interroge Prometheus par MCP et écrit `rapports/AAAA-MM-JJ.md`. Exemple :

| Indicateur | vm1 | vm2 | Statut |
| --- | --- | --- | --- |
| Connexions SSH acceptées (24 h) | 3 | 0 | OK |
| Tentatives SSH refusées (24 h) | 6 | 0 | À surveiller |

---

## Étape 9 : Analyser l'anomalie

Le rapport propose de lancer l'agent. Accepter, ou demander :

```text
Utilise log-inspector pour analyser les refus SSH sur vm1 depuis 1 h.
```

L'agent **log-inspector** (lecture seule, contexte séparé) :
1. situe la période avec Prometheus ;
2. lit `journalctl` sur vm1 ;
3. renvoie un résumé : 6 tentatives, utilisateur `intrus`, source vm2, cause probable, recommandation **non exécutée**.

---

## Étape 10 : Clôturer la mission

```text
/acces-ssh revoquer ba2 vm2 vm1
```

**Résultat attendu :** la connexion de BA2 est maintenant `refuse`. Pour supprimer l'environnement :

```text
Supprime les VM vm1, vm2 et monitor.
```

Le hook **garde-fou** demande une confirmation pour chaque `multipass delete`. La commande `multipass purge` est interdite à l'agent : l'humain la lance lui-même.

Le fichier `journal/audit.jsonl` conserve la trace de toutes les actions de la session.

---

## Récapitulatif

| # | Étape | Tapé par l'humain | Brique | Confirmation |
| --- | --- | --- | --- | --- |
| 1 | Créer les VM | `/provision-vm` | Commande | Oui |
| 2 | Créer la base | `/creer-db` | Commande | Oui |
| 3 | Permissions | `/gestion-permissions` | Skill | Oui |
| 4 | Accès SSH | `/acces-ssh ouvrir` | Skill | Oui |
| 5 | Supervision | `/supervision` | Skill | Oui |
| 6 | Brancher les MCP | variables + `/mcp` | MCP | — |
| 7 | Simuler de l'activité | terminal | — | — |
| 8 | Rapport | « bilan des connexions » | Skill (auto) | — |
| 9 | Anomalie | « utilise log-inspector » | Agent | — |
| 10 | Clôture | `/acces-ssh revoquer` | Skill | Oui |

## Points à vérifier au premier essai

- **Images des MCP** : `ghcr.io/pab1it0/prometheus-mcp-server`, `mcp/grafana` et `@modelcontextprotocol/server-postgres` (paquet archivé mais fonctionnel) sont des choix par défaut à confirmer.
- **Réseau Docker** : depuis Docker Desktop, les conteneurs MCP doivent pouvoir joindre les IP Multipass (`192.168.64.x` en général).
- **Ordre des étapes** : les étapes 2 et 3 sont placées avant l'accès SSH parce que `gestion-permissions` crée les comptes et l'espace de travail. Le document de scénario présente l'accès SSH en premier ; les deux ordres fonctionnent, car les skills créent les comptes manquants.
