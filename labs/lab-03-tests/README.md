# Lab 03 — Tests automatisés

> **Durée :** 60 min · **Modules requis :** [04](../../modules/04-skills/),
> [08](../../modules/08-sous-agents/) · **Outils :** `dotnet` · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Doter l'application d'une suite de tests utile : tests unitaires des règles métier, tests
d'intégration sur les endpoints HTTP, et surtout **identification des cas non couverts** — ce que
l'agent fait bien mieux qu'une lecture humaine fatiguée.

> **« Je suis Ops, pourquoi des tests ? »** Parce que la question que vous posez tous les jours est
> *« est-ce que je peux déployer ça ? »*. Une suite de tests est la réponse automatisable. Et parce
> que les mêmes réflexes s'appliquent aux tests d'infrastructure : un playbook Ansible idempotent
> ([Lab 07](../lab-07-ansible/)) ou un chart Helm ([Lab 10](../lab-10-helm/)) se testent aussi.

## 2. Pré-requis

- `dotnet --version` ≥ 8
- [Lab 01](../lab-01-git-github/) terminé (dépôt initialisé)

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Skill** `gen-tests` | La doctrine de test de l'équipe, écrite une fois |
| **Sous-agent** `test-engineer` | Analyse la couverture sans saturer votre session |
| **`/code-review`** | Relit les tests produits — un test faux est pire que pas de test |

---

## 4. Déroulé pas-à-pas

### Étape 1 — Comprendre avant de tester (10 min)

```bash
cd ~/lab-ecommerce && claude
```
```text
> Analyse @src/ECommerce.Catalog.Api/Endpoints/CatalogEndpoints.cs et
  @src/ECommerce.Ordering.Api/Endpoints/OrderingEndpoints.cs.
  Liste les comportements observables : entrées, sorties, codes HTTP, cas d'erreur.
  Ne génère aucun test pour l'instant.
```

**Cette étape n'est pas facultative.** Des tests écrits sans compréhension du comportement attendu
valident le code tel qu'il est — bugs compris.

### Étape 2 — Le skill de doctrine (10 min)

```text
> Crée .claude/skills/gen-tests/SKILL.md. Doctrine à y inscrire :
  - un test = un comportement, nommé Methode_Condition_ResultatAttendu ;
  - on teste les cas limites et les erreurs, pas seulement le chemin nominal ;
  - aucun test ne doit dépendre de l'ordre d'exécution ;
  - on n'invente jamais un comportement : en cas de doute, on demande ;
  - les tests d'intégration utilisent WebApplicationFactory.
```

### Étape 3 — Les premiers tests (15 min)

```text
> /plan Crée le projet tests/ECommerce.Catalog.Tests (xUnit) et génère des tests
  d'intégration des endpoints du catalogue avec WebApplicationFactory : liste, récupération
  par id, id inexistant, id non entier, création puis relecture, et l'endpoint /health.
```

**Le point de friction attendu.** Les *top-level statements* de `Program.cs` génèrent une classe
`Program` **interne** : `WebApplicationFactory<Program>` ne la voit pas. L'agent doit vous
proposer d'ajouter, à la fin de `src/ECommerce.Catalog.Api/Program.cs` :

```csharp
// Rend la classe Program accessible aux tests d'integration.
public partial class Program { }
```

S'il ne le propose pas et que la compilation échoue, donnez-lui l'erreur : c'est un bon exemple
de boucle *agir → observer → corriger*.

```bash
export PATH="/usr/local/share/dotnet:$PATH"
dotnet test tests/ECommerce.Catalog.Tests/ECommerce.Catalog.Tests.csproj
```

Résultat attendu : **5 tests, 5 réussis**.

### Étape 4 — Le test qui trouve un vrai bug (10 min)

Introduisez volontairement une erreur classique de pagination dans
`src/ECommerce.Catalog.Api/Endpoints/CatalogEndpoints.cs` — un `<=` à la place d'un `<`, par
exemple — puis :

```text
> Un test échoue. Analyse la cause et propose un correctif. Ne modifie pas le test pour le
  faire passer.
```

**La dernière phrase est capitale.** Sans elle, un agent (comme un humain pressé) peut être tenté
d'ajuster le test. Inscrivez cette règle dans votre `CLAUDE.md` :

```text
> # ne jamais modifier un test pour faire passer un build : corriger le code
```

Restaurez ensuite le code correct.

### Étape 5 — Le sous-agent de couverture (15 min)

Créez `.claude/agents/test-engineer.md` :

```markdown
---
name: test-engineer
description: Analyse la couverture de tests d'un projet .NET et identifie les comportements
  non testés, classés par risque. À utiliser avant une livraison ou une revue de qualité.
  Lecture seule.
tools: Bash, Read, Grep, Glob
---

Tu es ingénieur qualité. Ton rôle est d'identifier ce qui n'est PAS testé.

## Méthode
1. Recense les comportements observables du code (endpoints, branches, cas d'erreur).
2. Recense ce que la suite de tests couvre réellement.
3. Établis l'écart, et classe chaque manque par risque : impact si ça casse en production.
4. Distingue un test manquant d'un test inutile.

## Garde-fous
- Lecture seule : tu n'écris aucun test, tu ne modifies aucun fichier.
- Le pourcentage de couverture n'est pas un objectif : un chemin critique non testé compte
  plus que dix getters couverts.

## Format de sortie
| Comportement | Testé ? | Risque si régression | Test suggéré |
```

```text
> /agents
> Analyse la couverture de tests de la solution et dis-moi ce qui manque.
```

Vérifiez avec `/context` que le bruit de l'analyse n'a pas envahi votre session.

---

## 5. Livrable

```
tests/ECommerce.Catalog.Tests/          # projet xUnit + tests unitaires et d'intégration
.claude/skills/gen-tests/SKILL.md
.claude/agents/test-engineer.md
CLAUDE.md                               # règle : ne jamais modifier un test pour passer
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| Ne jamais adapter un test pour faire passer un build | Règle dans `CLAUDE.md` + consigne de prompt |
| Aucun comportement inventé | Inscrit dans `gen-tests/SKILL.md` |
| Le sous-agent n'écrit rien | `tools:` sans `Write` ni `Edit` |
| Aucune donnée réelle dans les jeux de test | Données fictives uniquement |

## 7. Pour aller plus loin

- Tests d'intégration avec **Testcontainers** (PostgreSQL réel plutôt qu'EF in-memory).
- **Tests de contrat** entre `Gateway` et `Ordering.Api`.
- Tests des **manifestes Kubernetes** avec `kubeconform` ou `conftest` (OPA).
- Tests d'**idempotence** Ansible : `--check` puis double exécution, zéro `changed`.

## Corrigé

```bash
cp -r labs/lab-03-tests/solution/tests ~/lab-ecommerce/
cp -r labs/lab-03-tests/solution/.claude/skills/gen-tests ~/lab-ecommerce/.claude/skills/
cp -r labs/lab-03-tests/solution/.claude/agents ~/lab-ecommerce/.claude/
```

Le corrigé est **vérifié** : 5 tests, 5 réussis. N'oubliez pas le `public partial class Program { }`
de l'étape 3 — voir [`solution/tests/ECommerce.Catalog.Tests/README.md`](solution/tests/ECommerce.Catalog.Tests/README.md).
