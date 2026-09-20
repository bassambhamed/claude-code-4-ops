# oddo-ops-toolkit

Boîte à outils Claude Code pour les équipes **DevOps / SRE / Infra**. Elle rassemble, sous une
forme installable en une commande, tout ce qui est construit pendant la
[formation](../../README.md) : commandes, skills, sous-agents, garde-fous et connecteurs.

> **Ce plugin est le livrable de fin de formation.** Il est fourni comme référence : la version
> que vous distribuerez à votre équipe est celle que *vous* aurez construite, avec vos conventions.

## Installation

```bash
claude plugin marketplace add ./Ops_Claude_code     # ou l'URL du dépôt interne
claude plugin install oddo-ops-toolkit
claude plugin details oddo-ops-toolkit              # inventaire et coût en contexte
```

Vérification, dans une session :

```text
> /help      → /ops-doctor, /ship, /tf-review
> /skills    → les 8 skills Ops
> /agents    → les 3 sous-agents
> /hooks     → les 4 hooks actifs
```

## Contenu

### Commandes

| Commande | Rôle |
|---|---|
| `/ops-doctor` | État de santé du cluster et des services — **lecture seule** |
| `/ship <contexte>` | Diff, revue de sécurité, commit conventionnel, PR — sans jamais merger |
| `/tf-review [dir]` | Plan Terraform + revue par sous-agent, sans jamais appliquer |

### Skills

| Skill | Rôle |
|---|---|
| `provision-vm` | VM Multipass reproductibles via cloud-init |
| `containerize` | Dockerfiles multi-stage, non-root, scannés |
| `k8s-bootstrap` | Cluster k3d, import d'images, application des manifestes |
| `tf-infra` | Cycle Terraform `init` → `validate` → `plan` → revue → `apply` |
| `ansible-play` | Playbooks idempotents, `--check` obligatoire |
| `ci-pipeline` | Workflows GitHub Actions avec gate manuel avant la production |
| `git-commit` | Commits Conventional Commits, validés avant exécution |
| `open-pr` | Pull requests documentées, avec checklist de revue |

### Sous-agents

| Agent | Rôle | Outils |
|---|---|---|
| `tf-plan-reviewer` | Relit un plan Terraform et rend un verdict SÛR / À REVOIR / BLOQUANT | Lecture seule |
| `incident-analyst` | Timeline, hypothèses de cause racine étayées, actions | Lecture seule |
| `k8s-debug-pod` | Diagnostic de pod en échec, correctif proposé en diff | Lecture seule |

### Hooks — les garde-fous

| Hook | Événement | Effet |
|---|---|---|
| `guard-destructive.sh` | `PreToolUse` / `Bash` | **Bloque** les commandes irréversibles |
| `secret-scan.sh` | `PreToolUse` / `Bash` | **Bloque** un commit contenant un secret (gitleaks si présent) |
| `audit-log.sh` | `PostToolUse` / `Bash` | Journalise chaque commande — traçabilité DORA |
| `session-start.sh` | `SessionStart` | Rappelle dépôt, branche, cluster et namespace courants |

Les hooks sont **déterministes** : ils sont exécutés par le harnais, jamais interprétés par le
modèle. Le journal d'audit est écrit hors du dépôt (`~/.claude/audit/`, ou `$CLAUDE_AUDIT_DIR`).

### Serveurs MCP

`.mcp.json` déclare **GitHub** (HTTP) et **Terraform** (stdio via Docker). Les jetons sont des
références d'environnement — aucun secret n'est distribué avec le plugin.

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=...    # scope `repo` minimal
```

## Personnaliser

1. Copiez le dossier et renommez-le dans `.claude-plugin/plugin.json`.
2. Adaptez les skills à vos conventions — **c'est là qu'est la valeur**, pas dans l'outillage.
3. Ajustez les motifs de `guard-destructive.sh` à votre environnement.
4. Publiez sur votre marketplace interne (voir [module 07](../../modules/07-plugins/)).

```bash
claude plugin validate plugins/mon-toolkit
claude plugin tag plugins/mon-toolkit
```

## Avertissement

Ce plugin exécute des scripts shell sur votre poste et peut ouvrir des accès réseau via ses
serveurs MCP. Avant un déploiement en entreprise : relisez chaque hook, vérifiez les scopes des
jetons, et faites valider par votre équipe sécurité.
