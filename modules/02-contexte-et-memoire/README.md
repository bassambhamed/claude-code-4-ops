# Module 02 — Contexte & mémoire

> **Durée :** 40 min · **Pré-requis :** [Module 01](../01-commandes-natives/)
> · **Suivant :** [Module 03 — Commandes personnalisées](../03-commandes-personnalisees/)

---

## 1. La limite

Hier, vous lui avez expliqué que vos branches se nomment `feat/`, `fix/`, `ops/`. Ce matin, il
propose `feature-new-thing`. Il n'a pas *oublié* : **il ne l'a jamais su**. Chaque session démarre
avec la même amnésie.

## 2. Le concept — trois horizons de mémoire

```
┌─ Fenêtre de contexte ────────────────────── la session en cours, volatile ──┐
│  votre conversation, les fichiers lus, les sorties de commandes             │
│  → se remplit, se résume (/compact), se vide (/clear)                       │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ Mémoire projet ─────────────── ./CLAUDE.md — versionné, partagé, durable ──┐
│  stack, conventions, commandes, interdits d'équipe                          │
│  → relu automatiquement à CHAQUE session, par TOUTE l'équipe                │
└─────────────────────────────────────────────────────────────────────────────┘
┌─ Mémoire personnelle ────────── ~/.claude/CLAUDE.md — vous seul, tout projet ┐
│  vos préférences : langue, style de réponse, outils favoris                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

**La distinction qui compte :** la fenêtre de contexte est une *mémoire de travail* qui s'efface ;
`CLAUDE.md` est une *procédure* qui reste. Tout ce que vous répétez à l'agent plus d'une fois doit
migrer de la première vers la seconde.

## 3. Anatomie

### Le fichier `CLAUDE.md`

Généré par `/init`, puis **édité à la main** — c'est là qu'est la valeur. Un bon `CLAUDE.md` Ops :

````markdown
# ecommerce-app

## Stack
Microservices .NET 10 / ASP.NET Core, orchestrés par .NET Aspire.
Catalog.Api, Ordering.Api (minimal APIs + EF Core in-memory), Gateway (YARP), Web (Blazor).
Ordering.Api appelle Catalog.Api pour valider les produits.

## Commandes
```bash
export PATH="/usr/local/share/dotnet:$PATH"
dotnet build ECommerce.slnx
dotnet run --project src/ECommerce.AppHost     # dashboard Aspire
```

## Conventions
- Branches : `feat/`, `fix/`, `ops/`, `chore/` — jamais de travail direct sur `main`.
- Commits : Conventional Commits, en anglais, à l'impératif.
- Les adresses de services ne sont JAMAIS codées en dur : service discovery Aspire.
- Tout manifeste Kubernetes porte des probes liveness ET readiness.

## Interdits
- Ne jamais committer de `.env`, `*.tfvars`, `*.pem`.
- Ne jamais lancer `terraform apply`, `kubectl delete` ou `helm upgrade` sans validation explicite.
- Ne jamais désactiver un test pour faire passer un build.
````

**Ce qui fait la différence entre un `CLAUDE.md` utile et un inutile :**

| ✅ Utile | ❌ Inutile |
|---|---|
| « Les branches se nomment `ops/...` » | « Écris du code propre » |
| « `dotnet build ECommerce.slnx` (pas `dotnet build`) » | « Utilise les bonnes pratiques » |
| « Ne jamais coder en dur les URL de services » | « Fais attention à la sécurité » |
| Une contrainte **vérifiable** | Une intention **non mesurable** |

Règle : si vous ne pouvez pas dire objectivement si la règle a été respectée, elle n'a rien à faire
dans le fichier. Visez **40 à 120 lignes** — au-delà, c'est du contexte consommé à chaque session.

### Les trois préfixes

| Préfixe | Ce qu'il fait | Exemple Ops |
|:---:|---|---|
| `@` | Injecte un fichier ou un dossier dans le contexte | `Analyse @src/ECommerce.Ordering.Api/Services/CatalogServiceClient.cs` |
| `!` | Exécute une commande, sa **sortie** entre en contexte | `!kubectl get pods -n ecommerce -o wide` |
| `#` | Écrit une note **durable** dans `CLAUDE.md` | `# toujours lancer terraform plan avant apply` |

`#` est le geste de capitalisation le plus rentable de la formation : une correction que vous faites
une fois est inscrite pour toute l'équipe.

### Gérer la fenêtre

| Situation | Commande | Effet |
|---|---|---|
| Le contexte se remplit, la tâche continue | `/compact` | Résume, garde l'essentiel |
| Nouveau sujet sans rapport | `/clear` | Repart à vide — `CLAUDE.md` reste chargé |
| Vérifier ce qui occupe la place | `/context` | Grille détaillée par source |
| Ouvrir un dépôt d'infra voisin | `/add-dir <chemin>` (ex. `/add-dir ../terraform-live`) | Élargit le périmètre au dossier indiqué |

---

## 4. Mini-lab — donner une mémoire au projet (20 min)

```bash
cd ../../ecommerce-app
claude
```

**1. Constater l'amnésie**

```text
> Quelle est notre convention de nommage des branches ?
```

Réponse générique ou aveu d'ignorance — c'est attendu.

**2. Générer la base**

```text
> /init
```

**3. L'enrichir là où c'est utile.** Ouvrez `CLAUDE.md` et ajoutez une section `## Conventions` et une
section `## Interdits` (inspirez-vous de l'exemple ci-dessus). Puis, dans la session :

```text
> /memory
```

**4. Vérifier que ça mord**

```text
> /clear
> Je veux corriger le healthcheck de Ordering.Api. Quelle branche je crée et quel message de commit ?
```

Il doit proposer `fix/...` et un message au format Conventional Commits. **C'est la même question
qu'à l'étape 1, avec une réponse d'équipe.**

**5. Capitaliser à la volée**

```text
> # ne jamais coder en dur une URL de service : toujours passer par le service discovery Aspire
```

Relisez `CLAUDE.md` : la règle y est. Vous venez d'ajouter un actif d'équipe en une ligne.

**6. Mesurer le coût**

```text
> /context
```

Regardez la part prise par `CLAUDE.md`. C'est le prix, à chaque session, de chaque ligne que vous y
mettez — d'où la discipline sur la taille.

---

## 5. Erreurs fréquentes

| Erreur | Conséquence | Correctif |
|---|---|---|
| `CLAUDE.md` de 600 lignes | Contexte mangé avant d'avoir commencé | Viser 40–120 lignes, factuelles |
| Y mettre des vœux pieux (« code propre ») | Aucun effet observable | Des règles vérifiables |
| Ne pas le versionner | Chacun a ses règles, l'équipe diverge | `git add CLAUDE.md` |
| Y écrire un secret ou une URL interne sensible | Fuite dans un dépôt partagé | Variables d'environnement |
| Confondre `/clear` et `/compact` | Perte de contexte utile | `/compact` pour continuer, `/clear` pour changer de sujet |
| Ne jamais relire `CLAUDE.md` après `/init` | Le fichier décrit un dépôt qui a changé | Le mettre à jour comme du code |

---

## 6. Checklist de sortie

- [ ] Je distingue fenêtre de contexte, mémoire projet et mémoire personnelle.
- [ ] `ecommerce-app/CLAUDE.md` contient mes conventions et mes interdits, vérifiables.
- [ ] J'ai utilisé `@`, `!` et `#` au moins une fois chacun.
- [ ] Je sais lire `/context` et choisir entre `/compact` et `/clear`.
- [ ] Je sais dire pourquoi un `CLAUDE.md` trop long est contre-productif.

> **La question pour le module suivant :** *« Il connaît mes règles. Mais je retape quand même le
> même prompt de vérification tous les matins — comment j'en fais un raccourci ? »*
