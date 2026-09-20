# Module 07 — Plugins : industrialiser et distribuer

> **Durée :** 45 min · **Pré-requis :** [Module 06](../06-mcp/)
> · **Suivant :** [Module 08 — Sous-agents](../08-sous-agents/)

---

## 1. La limite

Vous avez construit quelque chose de bon : deux commandes, trois skills, trois hooks de garde, deux
serveurs MCP. Tout cela vit dans **votre** `.claude/`. Vos douze collègues, eux, n'ont rien — et leur
expliquer quoi copier où, en gardant tout le monde à jour, c'est un travail à plein temps.

## 2. Le concept — le paquet, et le catalogue

Un **plugin** est un dossier qui regroupe tout ce que les modules précédents ont produit, sous un
manifeste. Un **marketplace** est un catalogue de plugins : un simple dépôt Git avec un fichier
`marketplace.json`.

```
   Marketplace (dépôt Git)              Plugin                     Ce qu'il embarque
   ────────────────────────      ──────────────────       ───────────────────────────────
   officiel : 300+ plugins  ──▶  oddo-ops-toolkit   ──▶   commands/   skills/
   interne  : les vôtres                                  hooks/      agents/   .mcp.json
```

Pour l'équipe, tout se résume alors à :

```bash
/plugin marketplace add ODDO-BHF/claude-ops-toolkit
/plugin install oddo-ops-toolkit
```

C'est la dernière brique de la chaîne de capitalisation : **prompt → commande → skill → hook → MCP →
plugin.** Et c'est la seule qui répond à la question « comment ça se déploie sur l'équipe ? ».

## 3. Anatomie

### 3.1 Consommer : le marketplace officiel

Claude Code est livré avec le marketplace **`claude-plugins-official`**
(`anthropics/claude-plugins-official`) : plus de 300 plugins, publiés par Anthropic et par les
éditeurs. On y trouve aussi bien des connecteurs que des outils de travail.

**Les plugins Anthropic utiles en formation :**

| Plugin | Ce qu'il apporte |
|---|---|
| `plugin-dev` | Skills et agents pour **créer** des plugins : structure, hooks, MCP, commandes, validation |
| `hookify` | Transforme une règle exprimée en langage naturel en **hook** opérationnel |
| `mcp-server-dev` | Aide à écrire un **serveur MCP** |
| `claude-md-management` | Maintient les `CLAUDE.md` d'un dépôt |
| `pr-review-toolkit`, `code-review` | Revue de PR et de diff |
| `claude-security`, `security-guidance` | Analyse de vulnérabilités, avertissements à l'édition |
| `commit-commands` | Commits structurés |

**Les plugins éditeurs utiles en Ops :** `github`, `gitlab`, `terraform` (HashiCorp),
`grafana-mcp`, `datadog`, `newrelic`, `dynatrace`, `honeycomb`, `sentry`, `atlassian`,
`incident-io`, `rootly`, `pagerduty`, `aws-core`, `azure`, `semgrep`, `sonarqube`, `jfrog`,
`crowdsec`.

```bash
# En session
/plugin                      # explorer, installer, activer, désactiver

# En ligne de commande
claude plugin marketplace list
claude plugin install github
claude plugin details github          # inventaire des composants + coût en contexte
claude plugin list
claude plugin disable github
```

> **`claude plugin details` avant d'installer.** Un plugin ajoute des outils, des skills et des
> définitions MCP **au contexte de chaque session**. Trois plugins bien choisis valent mieux que
> quinze installés « pour voir ».

> **Cadre bancaire :** un plugin tiers exécute du code sur votre poste et peut ouvrir des accès
> réseau. Avant d'en installer un dans un dépôt d'entreprise : vérifier l'éditeur, lire ce qu'il
> embarque (`details`), et le faire valider. `claude plugin validate` contrôle la forme du manifeste,
> pas les intentions de son auteur.

### 3.2 Produire : la structure d'un plugin

```
oddo-ops-toolkit/
├── .claude-plugin/
│   └── plugin.json          ← manifeste (seul fichier obligatoire)
├── commands/
│   ├── ops-doctor.md        → /ops-doctor
│   └── ship.md              → /ship
├── skills/
│   ├── provision-vm/SKILL.md
│   ├── containerize/SKILL.md
│   └── k8s-debug-pod/SKILL.md
├── agents/
│   ├── tf-plan-reviewer.md
│   └── incident-analyst.md
├── hooks/
│   ├── hooks.json           ← câblage des hooks du plugin
│   ├── guard-destructive.sh
│   ├── secret-scan.sh
│   └── audit-log.sh
├── .mcp.json                ← serveurs MCP livrés avec le plugin
└── README.md
```

`plugin.json` :

```json
{
  "name": "oddo-ops-toolkit",
  "version": "1.0.0",
  "description": "Boîte à outils Ops : provisionnement, conteneurisation, Kubernetes et diagnostic, avec garde-fous déterministes (anti-secret, blocage destructif, journal d'audit).",
  "author": { "name": "Équipe Ops" },
  "keywords": ["ops", "devops", "kubernetes", "terraform", "dotnet"],
  "license": "MIT"
}
```

Les dossiers sont découverts par convention : pas besoin de les déclarer. `${CLAUDE_PLUGIN_ROOT}`
permet de référencer un fichier du plugin depuis `hooks.json` :

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [
        { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/guard-destructive.sh" }
      ]}
    ]
  }
}
```

### 3.3 Distribuer : le marketplace interne

Un dépôt Git avec, à sa racine, `.claude-plugin/marketplace.json` :

```json
{
  "name": "oddo-ops-marketplace",
  "owner": { "name": "Équipe Ops ODDO BHF" },
  "metadata": { "description": "Plugins Ops internes — usage interne uniquement." },
  "plugins": [
    {
      "name": "oddo-ops-toolkit",
      "source": "./plugins/oddo-ops-toolkit",
      "description": "Boîte à outils Ops avec garde-fous déterministes."
    }
  ]
}
```

Côté équipe :

```bash
claude plugin marketplace add ODDO-BHF/claude-ops-toolkit   # ou une URL, ou un chemin local
claude plugin install oddo-ops-toolkit
```

**Une mise à jour = un commit.** `claude plugin marketplace update` puis
`claude plugin update oddo-ops-toolkit`. Le versionnage passe par `version` dans `plugin.json` ;
`claude plugin tag` pose un tag Git cohérent avec le manifeste.

---

## 4. Mini-lab — packager le toolkit d'équipe (25 min)

### Partie A — installer un plugin officiel (5 min)

```bash
cd ../../ecommerce-app
claude
```
```text
> /plugin
```

Cherchez `plugin-dev`, regardez ce qu'il embarque, installez-le.

```text
> /skills
```

Ses skills (`plugin-structure`, `hook-development`, `mcp-integration`…) sont maintenant disponibles.
Vous venez de **consommer** ; vous allez maintenant **produire**.

### Partie B — construire votre plugin (15 min)

```bash
cd ../../          # racine du dépôt de formation
mkdir -p mon-toolkit/.claude-plugin
```

Créez `mon-toolkit/.claude-plugin/plugin.json` (section 3.2), puis déplacez-y ce que vous avez
produit aux modules 03 à 05 :

```bash
cp -r ecommerce-app/.claude/commands mon-toolkit/commands
cp -r ecommerce-app/.claude/skills   mon-toolkit/skills
cp -r ecommerce-app/.claude/hooks    mon-toolkit/hooks
```

Écrivez `mon-toolkit/hooks/hooks.json` en remplaçant `$CLAUDE_PROJECT_DIR` par
`${CLAUDE_PLUGIN_ROOT}` — **c'est l'erreur classique** : un plugin ne connaît pas le projet qui
l'utilise.

Validez :

```bash
claude plugin validate mon-toolkit
```

### Partie C — publier et installer (5 min)

Créez `.claude-plugin/marketplace.json` à la racine (section 3.3, avec
`"source": "./mon-toolkit"`), puis :

```bash
claude plugin marketplace add .
claude plugin install mon-toolkit
claude plugin details mon-toolkit
```

Ouvrez une session dans un **autre** dossier et vérifiez :

```text
> /ops-doctor
> /hooks
```

Vos commandes et vos garde-fous vous suivent partout. **C'est le livrable de fin de formation.**

> Une version de référence complète est fournie dans
> [`plugins/oddo-ops-toolkit/`](../../plugins/oddo-ops-toolkit/).

---

## 5. Erreurs fréquentes

| Erreur | Conséquence | Correctif |
|---|---|---|
| `$CLAUDE_PROJECT_DIR` dans les hooks du plugin | Chemins introuvables chez les autres | `${CLAUDE_PLUGIN_ROOT}` |
| `plugin.json` hors de `.claude-plugin/` | Plugin non détecté | Respecter l'emplacement |
| Installer quinze plugins | Contexte saturé, sessions lentes | `claude plugin details` avant, `disable` après |
| Un secret dans le `.mcp.json` du plugin | Secret distribué à toute l'équipe | Références `${VAR}` uniquement |
| Pas de `version` mise à jour | Personne ne reçoit les correctifs | Incrémenter à chaque changement |
| Plugin tiers installé sans revue | Code non audité exécuté sur le poste | Revue éditeur + `details` + validation interne |
| Un plugin fourre-tout | Illisible, impossible à faire adopter | Un plugin = un périmètre |

---

## 6. Checklist de sortie

- [ ] J'ai exploré le marketplace officiel et installé un plugin en connaissance de cause.
- [ ] Je sais lire `claude plugin details` avant d'installer.
- [ ] J'ai packagé mes commandes, skills et hooks dans un plugin valide.
- [ ] Mon plugin utilise `${CLAUDE_PLUGIN_ROOT}` et ne contient aucun secret.
- [ ] Je l'ai publié sur un marketplace et installé depuis un autre dossier.
- [ ] Je sais ce que j'exige avant d'autoriser un plugin tiers dans un dépôt d'entreprise.

> **La question pour le module suivant :** *« Mon analyse d'incident a lu 4 000 lignes de logs. Ma
> session est saturée et je n'ai plus de place pour la suite du travail. »*
