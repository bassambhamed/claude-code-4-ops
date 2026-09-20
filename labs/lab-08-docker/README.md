# Lab 08 — Conteneurisation

> **Durée :** 60 min · **Modules requis :** [04](../../modules/04-skills/),
> [05](../../modules/05-hooks/) · **Outils :** `docker`, `trivy`
> · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Conteneuriser les quatre microservices avec des images **petites, non-root et scannées**, puis
câbler un `docker-compose` de développement. Et surtout : mettre en place le scan automatique qui
empêche une image vulnérable de passer inaperçue.

## 2. Pré-requis

```bash
docker version
trivy --version
dotnet build ECommerce.slnx     # la solution doit compiler
```

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Skill** `containerize` | La doctrine d'image de l'équipe : multi-stage, non-root, base autorisée |
| **Hook** `PostToolUse` | Scan Trivy automatique après chaque build d'image |
| **Commande perso** | `/ship-image` : build, scan, tag, en une fois |

---

## 4. Déroulé pas-à-pas

### Étape 1 — La doctrine d'image (10 min)

```text
> Crée .claude/skills/containerize/SKILL.md. Doctrine à y inscrire :
  - build multi-étapes : SDK pour compiler, runtime minimal pour exécuter ;
  - image finale `chiseled` ou `distroless` — ni shell, ni gestionnaire de paquets ;
  - exécution en utilisateur NON-root ;
  - les `.csproj` sont copiés avant le code source (cache du restore) ;
  - aucun secret dans une couche d'image, jamais d'`ARG` contenant un jeton ;
  - tout `docker system prune` ou `rmi` demande confirmation.
```

### Étape 2 — Le premier Dockerfile (15 min)

```text
> /plan Écris src/ECommerce.Catalog.Api/Dockerfile : build multi-étapes .NET 10, image
  finale chiseled non-root, port 8080. Le contexte de build est la racine du dépôt.
  Commente chaque étape en français.
```

```bash
docker build -t ecommerce-catalog:latest -f src/ECommerce.Catalog.Api/Dockerfile .
docker images | grep ecommerce-catalog
docker run --rm ecommerce-catalog:latest id      # ne doit PAS afficher uid=0(root)
```

### Étape 3 — Le scan, et ce qu'on en fait (10 min)

```bash
trivy image --severity HIGH,CRITICAL ecommerce-catalog:latest
```

```text
> Analyse ce rapport Trivy. Pour chaque finding : est-il exploitable dans notre contexte
  (l'image n'a ni shell ni réseau entrant direct) ? Classe par criticité réelle et propose
  une remédiation concrète.
```

> **La question à poser systématiquement.** Un scanner produit du volume ; la valeur ajoutée est de
> distinguer ce qui est exploitable **ici** de ce qui est un CVE théorique dans une bibliothèque
> jamais appelée. C'est un travail d'analyse, et c'est là que l'agent aide réellement.

### Étape 4 — Généraliser (10 min)

```text
> Applique la même doctrine à Ordering.Api, Gateway et Web. Pour Web, tiens compte des
  assets statiques de wwwroot.
```

```bash
for s in catalog ordering gateway web; do
  docker build -t ecommerce-$s:latest -f src/ECommerce.*.$s*/Dockerfile . 2>/dev/null || true
done
docker images | grep ecommerce-
```

### Étape 5 — Le compose de développement (10 min)

```text
> /plan Génère docker-compose.yml qui lance les quatre services. La découverte de services
  Aspire doit être recâblée à la main via les variables services__<nom>__http__0, en utilisant
  les noms de services compose comme DNS. Aucun secret en clair.
```

```bash
docker compose up -d
curl http://localhost:8080/health
docker compose down
```

### Étape 6 — Le scan automatique (5 min)

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Bash", "hooks": [
        { "type": "command",
          "command": "sh -c 'jq -r \".tool_input.command // empty\" | grep -q \"docker build\" && trivy image --severity CRITICAL --exit-code 0 --quiet $(docker images -q | head -1) 2>/dev/null; exit 0'" }
      ]}
    ]
  }
}
```

Chaque `docker build` déclenche désormais un scan. **Le `exit 0` est volontaire** : ce hook informe,
il ne bloque pas. Le blocage, lui, a sa place dans la CI ([Lab 02](../lab-02-ci-cd/)) — là où il y a
une porte de sortie pour l'équipe.

---

## 5. Livrable

```
src/ECommerce.{Catalog.Api,Ordering.Api,Gateway,Web}/Dockerfile
docker-compose.yml · .dockerignore
.claude/skills/containerize/SKILL.md
.claude/settings.json                  # scan Trivy automatique
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| Aucun conteneur en root | Vérifié par `docker run ... id` |
| Aucun secret dans une couche | Doctrine du skill + `/security-review` |
| Pas de `prune`/`rmi` sans confirmation (R2) | Hook `guard-destructive` |
| Toute image est scannée | Hook `PostToolUse` + job CI |
| Base d'image autorisée uniquement | Doctrine du skill (registre interne en production) |

## 7. Pour aller plus loin

- Comparez les tailles d'image : `aspnet:10.0` vs `noble-chiseled`. Faites expliquer l'écart.
- Générez un **SBOM** (`syft`) et scannez-le (`grype`).
- Ajoutez un `HEALTHCHECK` et faites expliquer pourquoi Kubernetes l'ignore au profit des probes.
- Faites analyser les couches (`docker history`) pour repérer le cache mal ordonné.

## Corrigé

```bash
cp -r labs/lab-08-docker/solution/src/* ~/lab-ecommerce/src/
cp labs/lab-08-docker/solution/{docker-compose.yml,.dockerignore} ~/lab-ecommerce/
```
