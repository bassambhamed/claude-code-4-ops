# Module 00 — Prise en main

> **Durée :** 45 min · **Pré-requis :** [docs/prerequis.md](../../docs/prerequis.md) validé
> · **Suivant :** [Module 01 — Commandes natives](../01-commandes-natives/)

---

## 1. La limite

Vous avez installé un outil dont vous ne savez ni ce qu'il voit, ni ce qu'il peut faire, ni ce qu'il
va faire sans vous demander. Tant que ces trois points ne sont pas clairs, on ne le lance pas sur un
dépôt qui compte.

## 2. Le concept — qu'est-ce qu'un agent de coding

Un LLM seul ne fait que produire du texte. Claude Code, c'est un LLM **équipé** :

```
        ┌─────────────────────────────────────────────┐
        │                  Le modèle                  │
        │        décide de la prochaine action        │
        └───────────────┬─────────────────┬───────────┘
                        │ appelle         │ observe
                        ▼                 │
        ┌─────────────────────────────────┴───────────┐
        │                 Les outils                  │
        │  Read · Edit · Write · Bash · Grep · Glob   │
        └───────────────┬─────────────────────────────┘
                        │ agit sur
                        ▼
        ┌─────────────────────────────────────────────┐
        │        Votre dépôt · votre machine          │
        └─────────────────────────────────────────────┘
```

La boucle est : **il agit → il observe le résultat → il corrige**. C'est ce qui le distingue d'un chat
qui vous propose du texte à recopier : il lance `dotnet build`, lit l'erreur, et la corrige.

**Trois conséquences immédiates pour un Ops :**

| Conséquence | Ce que ça implique |
|---|---|
| Il exécute de vraies commandes | Les **permissions** ne sont pas un détail de confort. |
| Il ne voit que ce qu'on lui donne | Le **contexte** conditionne toute la qualité. |
| Il se trompe avec assurance | La **vérification humaine** reste la dernière ligne. |

## 3. Anatomie d'une session

```bash
cd ecommerce-app     # 1. le dossier détermine ce que l'agent voit
claude               # 2. session interactive
```

Ce qui se passe au démarrage, dans l'ordre :

1. L'agent détermine le **répertoire de travail** — sa frontière par défaut.
2. Il charge les fichiers **mémoire** : `~/.claude/CLAUDE.md` (vous) puis `./CLAUDE.md` (le projet).
3. Il charge les **skills**, **hooks**, **permissions** et **serveurs MCP** applicables.
4. Il attend votre prompt.

Trois façons de lui parler :

| Vous tapez | Ça part vers |
|---|---|
| Du texte libre | Le **modèle** (il interprète) |
| `/quelque-chose` | Le **harnais** (le programme exécute) |
| `!commande` | Le **shell** (la sortie entre en contexte) |

---

## 4. Mini-lab — première session (15 min)

```bash
cd ../ecommerce-app
claude
```

**Étape 1 — voir sans toucher.** Dans la session :

```text
> Décris-moi l'architecture de cette application : les services, comment ils communiquent,
  et ce qui est exposé à l'extérieur. Ne modifie aucun fichier.
```

Observez : il **lit** des fichiers avant de répondre. Notez lesquels — c'est sa stratégie
d'exploration, et elle vous dit ce qu'il a compris.

**Étape 2 — le faire exécuter.**

```text
> !dotnet build ECommerce.slnx
```

Le `!` exécute la commande vous-même ; la sortie entre dans le contexte. Comparez avec :

```text
> Lance le build de la solution et dis-moi si ça passe.
```

Là, c'est **lui** qui décide de lancer la commande. Selon vos permissions, il vous demande
l'autorisation. **C'est le moment clé de la formation :** cette boîte de dialogue est votre dernier
rempart, et elle apparaîtra des dizaines de fois. Apprenez à la lire plutôt qu'à la valider.

**Étape 3 — constater ce qu'il ignore.**

```text
> Quelle est notre convention de nommage des branches Git ?
```

Il ne sait pas. Il n'a aucune raison de savoir. **Retenez cette réponse** : c'est exactement le
problème que le [Module 02](../02-contexte-et-memoire/) va résoudre.

**Étape 4 — quitter proprement.**

```text
> /exit
```

Puis reprenez là où vous en étiez :

```bash
claude -c      # continue la dernière conversation de ce dossier
```

---

## 5. Erreurs fréquentes

| Erreur | Conséquence | Correctif |
|---|---|---|
| Lancer `claude` depuis `$HOME` ou `/` | L'agent explore tout votre disque, le contexte explose | Toujours se placer dans le dossier du projet |
| Valider toutes les demandes de permission par réflexe | Un jour, c'est un `delete` qui passe | Lire la commande proposée, systématiquement |
| Traiter l'agent comme un moteur de recherche | Réponses génériques, hors projet | Lui demander de **lire** le dépôt : `@fichier`, « analyse d'abord » |
| Attendre qu'il devine vos conventions | Du code qui ne ressemble pas au vôtre | Module 02 : `CLAUDE.md` |
| Ne jamais regarder ce qu'il exécute | Perte de contrôle, audit impossible | `/permissions` et hooks (module 05) |

---

## 6. Checklist de sortie

- [ ] Je sais lancer une session dans le bon dossier et la reprendre (`claude -c`).
- [ ] Je sais expliquer la boucle **agir → observer → corriger**.
- [ ] Je distingue ce qui part vers le modèle, vers le harnais (`/`) et vers le shell (`!`).
- [ ] J'ai vu une demande de permission et je sais ce qu'elle protège.
- [ ] J'ai constaté que l'agent ignore les conventions de mon équipe.

> **La question à garder en tête pour le module suivant :** *« Qu'est-ce que cet outil sait faire que
> je n'ai pas encore essayé ? »*
