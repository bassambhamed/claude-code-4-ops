# Lab 02 — Pipeline CI/CD

> **Durée :** 75 min · **Modules requis :** [04](../../modules/04-skills/),
> [09](../../modules/09-automatisation-et-ci/) · **Outils :** `gh`, `dotnet`, `docker`
> · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Produire une chaîne d'intégration et de déploiement complète pour l'application fil rouge : build,
tests, construction et scan des images, publication — **avec un gate manuel avant la production**.
Puis ajouter un job qui fait relire les changements d'infrastructure par l'agent lui-même.

## 2. Pré-requis

- [Lab 01](../lab-01-git-github/) terminé : dépôt GitHub créé et poussé.
- `gh auth status` valide.

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Skill** `ci-pipeline` | La procédure de génération de workflows, avec ses règles de sécurité |
| **Mode headless** | `claude -p` appelé *depuis* la CI pour relire un diff d'infra |
| **MCP GitHub** | Lire l'état des runs, diagnostiquer un échec sans quitter le terminal |
| **`/security-review`** | Auditer le workflow produit — un pipeline est du code sensible |

**Le point d'attention du lab :** un pipeline généré par un agent est **une proposition**. Il
manipule des secrets, des registres et des environnements de déploiement. Il se relit ligne à ligne.

---

## 4. Déroulé pas-à-pas

### Étape 1 — Capitaliser la procédure (10 min)

```bash
cd ~/lab-ecommerce && claude
```
```text
> Crée le skill .claude/skills/ci-pipeline/SKILL.md. Il génère des workflows GitHub Actions
  pour cette solution .NET. Règles non négociables à inscrire dans le skill :
  - la CI ne déploie jamais ;
  - tout déploiement vers un environnement de production passe par un gate manuel
    (`environment:` protégé) ;
  - aucun secret en clair : uniquement `secrets.` ;
  - permissions du workflow au minimum nécessaire ;
  - chaque étape est commentée en français.
```

### Étape 2 — Le workflow d'intégration (15 min)

```text
> /plan Génère .github/workflows/ci.yml : déclenché sur push et PR vers main. Job 1 : build
  de ECommerce.slnx en Release avec le SDK .NET 10. Job 2 : build des images Docker des
  quatre services et scan Trivy. Aucun déploiement.
```

Lisez le plan **avant** de valider. Vérifiez trois points :

- les `permissions:` du workflow sont-elles restreintes ?
- le scan Trivy fait-il **échouer** le job sur une vulnérabilité critique, ou se contente-t-il
  d'afficher ?
- la version des actions est-elle épinglée (`@v4`) ?

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add build and image scan workflow"
git push
gh run watch
```

### Étape 3 — Le workflow de déploiement, avec gate (15 min)

```text
> /plan Génère .github/workflows/cd.yml : déclenché manuellement (workflow_dispatch) et sur
  tag. Il publie les images sur GHCR, déploie sur un environnement `staging` automatiquement,
  puis sur `production` UNIQUEMENT après approbation manuelle via un environnement protégé.
```

Puis configurez la protection côté GitHub — **c'est le contrôle réel** :

```bash
gh api -X PUT repos/:owner/lab-ecommerce/environments/production \
  -f 'reviewers[][type]=User' -F "reviewers[][id]=$(gh api user --jq .id)"
```

> **Ce qui protège la production, ce n'est pas le YAML : c'est la règle d'environnement côté
> forge.** Le workflow décrit l'intention ; la protection l'impose. Niveau 5 des
> [garde-fous](../../docs/garde-fous.md).

### Étape 4 — Auditer le pipeline (10 min)

```text
> /security-review
> Relis @.github/workflows/cd.yml et réponds précisément : quels secrets sont exposés à quels
  jobs ? Un fork peut-il déclencher ce workflow ? Un secret peut-il finir dans les logs ?
```

### Étape 5 — L'agent dans la CI (15 min)

Créez `.github/workflows/infra-review.yml` (voir
[module 09, §3.3](../../modules/09-automatisation-et-ci/#33-dans-un-pipeline-github-actions)).

Points de vigilance à vérifier dans le fichier produit :

- `-p` est bien présent (sinon le job attend un humain, puis expire) ;
- `--allowedTools "Read,Grep,Glob"` : le job **ne peut pas écrire** ;
- `permissions: pull-requests: write` et rien de plus ;
- le job **commente**, il ne merge pas.

Testez avec une PR touchant `k8s/` ou `terraform/`.

### Étape 6 — Diagnostiquer un échec sans quitter le terminal (10 min)

Cassez volontairement le build :

```bash
echo "invalid c# here" >> src/ECommerce.Catalog.Api/Program.cs
git add -A && git commit -m "test: break the build" && git push
```
```text
> Le dernier run CI a échoué. Analyse les logs et explique la cause en trois lignes.
```

Avec le MCP GitHub branché, il lit les logs du run directement. Puis :

```text
> /rewind
```

et remettez le dépôt d'aplomb.

---

## 5. Livrable

```
.github/workflows/
├── ci.yml                  # build + images + scan Trivy, aucun déploiement
├── cd.yml                  # staging automatique, production après approbation
└── infra-review.yml        # revue assistée du diff d'infra, en commentaire de PR
.claude/skills/ci-pipeline/SKILL.md
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| Aucun déploiement prod automatique (R3) | `environment: production` protégé côté GitHub |
| Aucun secret dans le YAML | `secrets.` uniquement ; audité par `/security-review` |
| Le job de revue ne peut rien modifier | `--allowedTools "Read,Grep,Glob"` |
| Permissions minimales | `permissions:` explicite dans chaque workflow |
| Le pipeline est relu par un humain | Revue de PR obligatoire sur `.github/` |

## 7. Pour aller plus loin

- Ajoutez un job de **scan IaC** (`tfsec`, `checkov`) sur `terraform/`.
- Publiez un **SBOM** (`syft`) et faites-le scanner par `grype`.
- Ajoutez un job planifié hebdomadaire : *« liste les dépendances obsolètes et évalue la criticité »*.
- Faites commenter par l'agent uniquement **ce qui a changé** depuis sa revue précédente.

## Corrigé

```bash
cp -r labs/lab-02-ci-cd/solution/.github ~/lab-ecommerce/
cp -r labs/lab-02-ci-cd/solution/.claude/skills/ci-pipeline ~/lab-ecommerce/.claude/skills/
```
