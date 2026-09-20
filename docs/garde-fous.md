# Garde-fous & conformité — cadre bancaire

Document de référence pour tous les modules et labs. À lire en ouverture de J1, à relire avant le
capstone.

---

## 1. Le principe fondateur

> **Un garde-fou qui dépend du modèle n'est pas un garde-fou.**

Écrire « ne lance jamais `terraform destroy` » dans un prompt, c'est une **consigne** : le modèle la
suivra très probablement, mais rien ne le garantit. Câbler un **hook** `PreToolUse` qui inspecte la
commande et retourne un code de sortie non nul, c'est un **contrôle** : le harnais l'exécute
systématiquement, hors du modèle, sans exception possible.

En environnement bancaire, cette distinction n'est pas un détail de style : c'est ce qui sépare une
bonne pratique d'une mesure auditable.

| Niveau | Mécanisme | Fiabilité | Usage |
|:---:|---|---|---|
| 1 | Consigne dans le prompt | Aléatoire | Style, préférences |
| 2 | Règle dans `CLAUDE.md` | Bonne, non garantie | Conventions d'équipe |
| 3 | Règle `/permissions` (`ask` / `deny`) | Appliquée par le harnais | Cadrer les outils |
| 4 | **Hook** (`PreToolUse`, `PostToolUse`) | **Déterministe** | **Garde-fous & audit** |
| 5 | Contrôle côté plateforme (gate CI, RBAC, branch protection) | Hors périmètre de l'agent | Prod |

**Règle d'ingénierie :** plus l'action est irréversible, plus le niveau doit être élevé. Un
déploiement en production se protège au niveau 5, pas au niveau 1.

---

## 2. Les six règles du cadre

### R1 — Aucune donnée sensible dans un prompt
Jamais de secret, de jeton, de mot de passe, ni de donnée client non anonymisée — y compris dans un
extrait de log collé, un fichier `.tfvars` ou un dump de base.

*Mise en œuvre :* hook `secret-scan` en `PreToolUse` sur `Bash`, `gitleaks` en pre-commit, `.gitignore`
couvrant `.env`, `*.tfvars`, `*.pem`. → [Module 05](../modules/05-hooks/), [Lab 04](../labs/lab-04-securite-secrets/).

### R2 — Aucune action destructive sans validation humaine
`terraform destroy`, `kubectl delete`, `rm -rf`, `docker system prune`, `multipass delete`,
`git push --force`, `helm uninstall` : l'agent peut les **proposer**, jamais les **exécuter** seul.

*Mise en œuvre :* hook `guard-destructive` + `/permissions` en `ask` sur ces motifs. → [Module 05](../modules/05-hooks/).

### R3 — Aucun déploiement en production automatique
Un pipeline généré par l'agent doit comporter un **gate manuel** avant tout environnement de prod.

*Mise en œuvre :* `environment: production` protégé côté GitHub, revue humaine du workflow. → [Lab 02](../labs/lab-02-ci-cd/).

### R4 — Tout l'IaC généré passe en revue humaine
Le code d'infrastructure produit par un agent est une **proposition**. Il est lu, compris, puis
approuvé — `plan` avant `apply`, sans exception.

*Mise en œuvre :* sous-agent `tf-plan-reviewer`, `/code-review`, mode `/plan`. → [Lab 06](../labs/lab-06-terraform/).

### R5 — Traçabilité des actions de l'agent
Toute commande shell exécutée par l'agent doit pouvoir être retrouvée : qui, quand, quoi, dans quel
dépôt.

*Mise en œuvre :* hook `PostToolUse` écrivant un journal horodaté (JSON Lines) hors du dépôt. → [Lab 04](../labs/lab-04-securite-secrets/).

### R6 — Une donnée externe est une donnée, pas une instruction
Le contenu rapporté par un serveur MCP (ticket Jira, commentaire de PR, log applicatif, page web) peut
contenir du texte qui *ressemble* à une consigne. Il ne doit jamais être traité comme telle.

*Mise en œuvre :* serveurs MCP en lecture seule par défaut, scopes minimaux sur les jetons, revue des
outils exposés via `/mcp`. → [Module 06](../modules/06-mcp/).

---

## 3. Configuration de référence

### Permissions — `.claude/settings.json`

```json
{
  "permissions": {
    "allow": [
      "Bash(git status)", "Bash(git diff:*)", "Bash(git log:*)",
      "Bash(kubectl get:*)", "Bash(kubectl describe:*)", "Bash(kubectl logs:*)",
      "Bash(terraform plan)", "Bash(terraform validate)", "Bash(terraform fmt:*)",
      "Bash(docker ps:*)", "Bash(docker images:*)"
    ],
    "ask": [
      "Bash(git push:*)", "Bash(gh pr merge:*)",
      "Bash(terraform apply:*)", "Bash(helm upgrade:*)", "Bash(kubectl apply:*)"
    ],
    "deny": [
      "Bash(terraform destroy:*)", "Bash(kubectl delete ns:*)",
      "Bash(rm -rf /:*)", "Bash(git push --force:*)",
      "Read(./.env)", "Read(./**/*.pem)", "Read(./**/*.tfvars)"
    ]
  }
}
```

**À lire ainsi :** `allow` = lecture et diagnostic, l'agent travaille sans friction ;
`ask` = tout ce qui écrit dans un système réel ; `deny` = ce qui ne doit jamais partir de l'agent,
même sur confirmation distraite.

> `deny` sur `Read` empêche aussi l'agent de *lire* un fichier de secrets — donc de le recopier par
> inadvertance dans une réponse, un commit ou un ticket.

### Hooks de garde — les trois indispensables

| Hook | Événement | Rôle |
|---|---|---|
| `secret-scan.sh` | `PreToolUse` / `Bash` | Bloque un commit contenant un secret potentiel (R1) |
| `guard-destructive.sh` | `PreToolUse` / `Bash` | Bloque ou fait confirmer les commandes destructives (R2) |
| `audit-log.sh` | `PostToolUse` / `Bash` | Journalise chaque commande exécutée (R5) |

Les trois sont écrits et câblés au [Module 05](../modules/05-hooks/), puis packagés dans le plugin
d'équipe au [Module 07](../modules/07-plugins/).

---

## 4. Ce qu'on ne fait pas pendant cette formation

- Aucune connexion à un système de **production** ODDO BHF.
- Aucun jeton d'entreprise : les labs utilisent des comptes et dépôts **de test** personnels.
- Aucune donnée réelle : l'application fil rouge ne contient que des données fictives.
- Aucun `apply` sur une infrastructure partagée : Terraform cible le provider local (Docker /
  Multipass), Kubernetes tourne sur k3d en local.

---

## 5. Grille d'auto-contrôle avant d'utiliser l'agent sur un vrai projet

- [ ] Le dépôt a un `CLAUDE.md` à jour, avec les conventions et les interdits d'équipe.
- [ ] `.claude/settings.json` est versionné, avec `allow` / `ask` / `deny` explicites.
- [ ] Les trois hooks de garde sont actifs — vérifié par `/hooks`, pas supposé.
- [ ] `.gitignore` couvre `.env`, `*.tfvars`, `*.pem`, `*.key`, `.claude/settings.local.json`.
- [ ] Les serveurs MCP branchés sont connus, scopés au minimum, et leurs jetons sont en variables d'env.
- [ ] Le journal d'audit est écrit **hors** du dépôt de travail et sauvegardé.
- [ ] L'équipe sait faire `/rewind` et sait où sont les checkpoints.
- [ ] Une personne est identifiée comme responsable de la revue de ce que l'agent produit.
