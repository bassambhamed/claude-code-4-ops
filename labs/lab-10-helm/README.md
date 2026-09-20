# Lab 10 — Packaging Helm

> **Durée :** 60 min · **Modules requis :** [04](../../modules/04-skills/)
> · **Outils :** `helm`, `kubectl`, `k3d` · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Transformer les manifestes du [Lab 09](../lab-09-kubernetes/) en **chart Helm paramétrable**, avec
des `values` par environnement — et apprendre à faire relire un chart, où les erreurs se cachent
dans les templates plutôt que dans le résultat.

## 2. Pré-requis

- [Lab 09](../lab-09-kubernetes/) terminé : manifestes fonctionnels, cluster k3d disponible.

```bash
helm version
k3d cluster create ecom-lab --config k8s/k3d-cluster.yaml    # si supprimé
```

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Skill** `helm-package` | La convention de chart de l'équipe |
| **`/code-review`** | Relire les templates — un `if` mal placé ne se voit qu'à l'exécution |
| **Sous-agent** | Comparer le rendu entre environnements |

---

## 4. Déroulé pas-à-pas

### Étape 1 — La conversion (20 min)

```text
> /plan Transforme les manifestes de @k8s/ en chart Helm dans helm/ecommerce/.
  Attendu : Chart.yaml, values.yaml, templates/ avec _helpers.tpl (labels et noms communs),
  deployment.yaml, service.yaml, ingress.yaml, hpa.yaml.
  Contraintes :
  - une boucle `range` sur la liste des services plutôt qu'un fichier par service ;
  - image repository/tag/pullPolicy paramétrables ;
  - resources, probes et replicas paramétrables par service ;
  - ingress activable/désactivable ;
  - aucune valeur en dur dans les templates.
```

```bash
helm lint helm/ecommerce
helm template ecommerce helm/ecommerce | head -60
```

### Étape 2 — Le rendu, pas le template (10 min)

**La règle du lab :** on ne relit pas un template Helm, on relit **ce qu'il produit**.

```bash
helm template ecommerce helm/ecommerce > /tmp/rendu-default.yaml
```
```text
> Compare @/tmp/rendu-default.yaml avec les manifestes d'origine de @k8s/.
  Liste précisément ce qui a changé, et dis-moi si une de ces différences est une régression.
```

C'est ici qu'on attrape les classiques : une probe perdue dans une condition, un `namespace`
disparu, une limite de ressources devenue vide.

### Étape 3 — Les environnements (15 min)

```text
> Génère values-dev.yaml et values-preprod.yaml.
  dev : 1 réplica, ressources minimales, ingress sur ecom.localhost, HPA désactivé.
  preprod : 2 réplicas, ressources doublées, ingress sur ecom-preprod.localhost,
  HPA activé de 2 à 5 pods.
```

```bash
helm template ecommerce helm/ecommerce -f helm/ecommerce/values-dev.yaml > /tmp/dev.yaml
helm template ecommerce helm/ecommerce -f helm/ecommerce/values-preprod.yaml > /tmp/preprod.yaml
diff <(grep -E 'replicas|cpu|memory' /tmp/dev.yaml) <(grep -E 'replicas|cpu|memory' /tmp/preprod.yaml)
```

```text
> Relis ces deux rendus. Y a-t-il un paramètre qui aurait dû différer entre dev et preprod
  et qui est resté identique par erreur ?
```

### Étape 4 — Installer (10 min)

```bash
helm install ecommerce helm/ecommerce -f helm/ecommerce/values-dev.yaml -n ecommerce --create-namespace
helm status ecommerce -n ecommerce
kubectl get pods -n ecommerce
```

Puis une montée de version :

```bash
helm upgrade ecommerce helm/ecommerce -f helm/ecommerce/values-preprod.yaml -n ecommerce --dry-run
```

> **`--dry-run` d'abord, toujours.** C'est le `terraform plan` de Helm. Un `helm upgrade` direct sur
> un environnement partagé est exactement le geste que la règle R2 interdit.

### Étape 5 — La revue de chart (5 min)

```text
> /code-review
> Relis le chart : valeurs en dur restantes, conditions manquantes, labels non conformes,
  et tout paramètre de sécurité (securityContext, resources) qui pourrait être contourné
  par un values.yaml mal rempli.
```

---

## 5. Livrable

```
helm/ecommerce/
├── Chart.yaml
├── values.yaml · values-dev.yaml · values-preprod.yaml
└── templates/
    ├── _helpers.tpl · deployment.yaml · service.yaml · ingress.yaml · hpa.yaml
.claude/skills/helm-package/SKILL.md
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| `helm upgrade` jamais direct (R2) | `--dry-run` obligatoire ; règle `ask` dans `/permissions` |
| Aucun secret dans `values.yaml` (R1) | Secrets externalisés (SealedSecrets, coffre) |
| Pas de `helm uninstall` par l'agent | Hook `guard-destructive` |
| Le rendu est comparé, pas supposé | `helm template` + diff |

## 7. Pour aller plus loin

- Ajoutez des **tests Helm** (`templates/tests/`) et lancez `helm test`.
- Ajoutez un `NOTES.txt` généré, avec les URL d'accès selon l'environnement.
- Poussez le chart dans un registre OCI (`helm push`) et faites générer le job CI correspondant.
- Comparez avec **Kustomize** : faites expliquer quand l'un est préférable à l'autre.

## Corrigé

```bash
cp -r labs/lab-10-helm/solution/helm ~/lab-ecommerce/
```
