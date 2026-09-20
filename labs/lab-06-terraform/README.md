# Lab 06 — Terraform / Infrastructure as Code

> **Durée :** 75 min · **Modules requis :** [05](../../modules/05-hooks/),
> [08](../../modules/08-sous-agents/) · **Outils :** `terraform`, `docker`
> · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Écrire un module Terraform propre, et surtout **mettre en place la revue de plan assistée** : le
sous-agent qui relit chaque `terraform plan` et signale ce qui va être détruit, avant que quiconque
tape `apply`.

C'est le lab le plus important du bloc infrastructure : celui où l'agent apporte le plus de valeur
(lire 300 lignes de plan sans sauter de ligne) et où une erreur coûte le plus cher.

## 2. Pré-requis

```bash
terraform version
docker version        # le provider utilisé reste LOCAL — aucune ressource cloud
```

> **Cadre du lab :** provider `docker` en local. On ne touche à aucune infrastructure partagée,
> aucun compte cloud, aucun backend distant.

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Sous-agent** `tf-plan-reviewer` | Relit le plan avec un contexte isolé et un rôle de sceptique |
| **Skill** `tf-infra` | La procédure `init` → `validate` → `plan` → revue → `apply` |
| **Hook** `PostToolUse` | `terraform fmt` et `tflint` automatiques après chaque édition |
| **Hook** `guard-destructive` | `terraform destroy` bloqué |
| **MCP Terraform** | Documentation de providers et modules à jour, depuis le registry |

---

## 4. Déroulé pas-à-pas

### Étape 1 — Les deux garde-fous (15 min)

**Blocage du `destroy`** — vérifiez que `terraform destroy` figure bien dans les motifs de
`guard-destructive.sh`, puis testez :

```text
> Détruis l'infrastructure Terraform
```

**Formatage et lint automatiques** — ajoutez dans `.claude/settings.json` :

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [
        { "type": "command",
          "command": "sh -c 'terraform fmt -recursive terraform/ >/dev/null 2>&1; exit 0'" }
      ]}
    ]
  }
}
```

> `exit 0` en fin de commande : un hook de confort ne doit **jamais** bloquer le travail. Un hook de
> sécurité, si. Sachez lequel vous écrivez.

### Étape 2 — Le module (20 min)

```text
> /plan Écris un module Terraform dans terraform/ qui provisionne l'ecommerce-app avec le
  provider docker en local : un réseau dédié, un conteneur par service (catalog, ordering,
  gateway, web), les variables de service discovery, et des outputs donnant les URL.
  Structure attendue : main.tf, variables.tf, outputs.tf, versions.tf.
  Contraintes : versions de provider épinglées, aucune valeur en dur, variables typées
  avec description et validation.
```

```bash
cd terraform
terraform init
terraform validate
terraform fmt -check
```

### Étape 3 — Le sous-agent de revue (15 min)

Créez `.claude/agents/tf-plan-reviewer.md` — le contenu complet est au
[module 08, §3](../../modules/08-sous-agents/#3-anatomie).

```bash
terraform plan -out=tfplan
terraform show -no-color tfplan > plan.txt
```
```text
> /agents
> Fais relire @terraform/plan.txt avant que j'applique.
```

Vérifiez que la sortie contient bien : le classement `create` / `update` / `replace` / `destroy`, la
cause de chaque remplacement, et un **verdict explicite**.

### Étape 4 — La revue qui sert vraiment (15 min)

C'est ici que le lab devient utile. Introduisez un changement qui **force un remplacement** — par
exemple modifiez le nom du réseau Docker, ce qui recrée tout ce qui s'y rattache :

```bash
terraform plan -out=tfplan && terraform show -no-color tfplan > plan.txt
```
```text
> Relis ce nouveau plan.
```

Le relecteur doit **remonter le `replace`**, en expliquer la cause (l'attribut qui force la
recréation) et sa conséquence (interruption de service). Verdict attendu : **À REVOIR** ou
**BLOQUANT**.

> **Le geste à retenir de toute la formation :** vous ne lirez plus jamais un `terraform plan` de
> 300 lignes en diagonale un vendredi soir. Vous le ferez relire, puis vous vérifierez les points
> signalés.

### Étape 5 — Appliquer, sous contrôle (10 min)

```text
> /plan Applique le plan revu.
```

L'`apply` reste une **action humaine validée**. Vérifiez :

```bash
terraform output
curl "$(terraform output -raw gateway_url)/health"
```

### Étape 6 — Brancher le MCP Terraform (facultatif, 10 min)

```bash
claude mcp add terraform -- docker run -i --rm hashicorp/terraform-mcp-server:0.4.0
```
```text
> /mcp
> Quelles sont les bonnes pratiques actuelles du provider docker pour la gestion des réseaux ?
```

L'agent interroge le registry plutôt que de se fier à sa mémoire d'entraînement — c'est exactement
le cas où un serveur MCP évite une hallucination de syntaxe.

---

## 5. Livrable

```
terraform/
├── main.tf · variables.tf · outputs.tf · versions.tf
├── terraform.tfvars.example            # jamais le vrai .tfvars
└── .gitignore                          # .terraform/, *.tfstate, *.tfvars
.claude/agents/tf-plan-reviewer.md
.claude/skills/tf-infra/SKILL.md
.claude/settings.json                   # fmt automatique + blocage destroy
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| `destroy` interdit à l'agent (R2) | Hook `guard-destructive` |
| Tout plan est relu avant `apply` (R4) | Sous-agent `tf-plan-reviewer` |
| `apply` reste une décision humaine | Mode `/plan` + règle `ask` dans `/permissions` |
| Aucun `.tfstate` ni `.tfvars` committé (R1) | `.gitignore` + hook `secret-scan` |
| Aucune infrastructure partagée touchée | Provider `docker` local uniquement |

## 7. Pour aller plus loin

- Ajoutez `tfsec` ou `checkov` en `PostToolUse` : sécurité de l'IaC vérifiée à chaque édition.
- Faites générer la documentation du module (`terraform-docs`) par un skill.
- Simulez une **dérive** (modifiez un conteneur à la main) et demandez l'analyse du `plan` suivant.
- Reprenez les VM du [Lab 05](../lab-05-multipass/) et décrivez-les en Terraform.

## Corrigé

```bash
cp -r labs/lab-06-terraform/solution/terraform ~/lab-ecommerce/
cp -r labs/lab-06-terraform/solution/.claude/skills/tf-infra ~/lab-ecommerce/.claude/skills/
```
