# Module 03 — Commandes personnalisées

> **Durée :** 30 min · **Pré-requis :** [Module 02](../02-contexte-et-memoire/)
> · **Suivant :** [Module 04 — Skills](../04-skills/)

---

## 1. La limite

Tous les matins, vous tapez la même chose : *« vérifie l'état du cluster, les pods non prêts, les
events des 30 dernières minutes, et résume-moi ça »*. Quatre lignes, tous les jours, à chaque
ingénieur de l'équipe — et chacun sa variante.

## 2. Le concept — un prompt devient un fichier

Une commande personnalisée, c'est **un fichier Markdown dont le contenu est envoyé comme prompt**.
Le nom du fichier devient le nom de la commande.

```
.claude/commands/ops-doctor.md      →      /ops-doctor
```

C'est la brique la plus simple du parcours, et c'est volontaire : on capitalise un prompt **avant**
d'apprendre à capitaliser une procédure (les skills, module suivant).

| | **Commande personnalisée** | **Skill** (module 04) |
|---|---|---|
| Déclenchement | **Vous** l'invoquez : `/ops-doctor` | **L'agent** la mobilise quand c'est pertinent |
| Contenu | Un prompt paramétré | Une procédure, avec des étapes et des fichiers annexes |
| Bon pour | Un raccourci quotidien | Un runbook d'équipe en plusieurs étapes |

## 3. Anatomie

### Le fichier minimal

`.claude/commands/ops-doctor.md` :

```markdown
---
description: État de santé du cluster et des services de l'ecommerce-app
---

Établis un état de santé, dans cet ordre :

1. `kubectl get pods -A -o wide` — liste les pods qui ne sont pas `Running`/`Ready`.
2. `kubectl get events -A --sort-by=.lastTimestamp | tail -30` — relève les events anormaux.
3. Pour chaque service de l'ecommerce-app, vérifie l'endpoint `/health`.

Puis produis un tableau : Service | État | Signal d'alerte | Action suggérée.

Contraintes :
- Lecture seule. N'applique AUCUNE correction, ne relance AUCUN pod.
- Si tu ne peux pas joindre le cluster, dis-le au lieu d'inventer un diagnostic.
```

### Arguments

`$ARGUMENTS` reçoit ce que l'utilisateur tape après la commande.

`.claude/commands/ship.md` :

```markdown
---
description: Prépare une livraison — diff, revue, commit conventionnel et PR
---

Prépare la livraison de la branche courante. Contexte fourni par l'utilisateur : $ARGUMENTS

1. Affiche `git status` et `git diff` ; résume les changements en trois lignes.
2. Lance une revue de sécurité sur le diff. Signale tout secret ou toute URL interne.
3. Propose un message de commit au format Conventional Commits — en anglais, à l'impératif.
4. Attends ma validation AVANT de committer.
5. Après validation : commit, push, puis ouvre une PR avec description et checklist de revue.

Ne merge jamais. Ne force jamais un push.
```

Invocation : `/ship correctif du healthcheck Ordering`.

### Où les placer

| Emplacement | Portée | Versionné ? |
|---|---|---|
| `.claude/commands/<nom>.md` | Le projet, **toute l'équipe** | Oui — c'est le but |
| `~/.claude/commands/<nom>.md` | Vous, sur tous vos projets | Non |
| `plugins/<plugin>/commands/<nom>.md` | Distribuée par plugin ([module 07](../07-plugins/)) | Oui |

Des sous-dossiers créent des espaces de noms : `.claude/commands/k8s/debug.md` → `/k8s:debug`.

---

## 4. Mini-lab — vos deux premières commandes (15 min)

```bash
cd ../../ecommerce-app
mkdir -p .claude/commands
```

**1. Créer `/ops-doctor`** — recopiez l'exemple ci-dessus dans
`.claude/commands/ops-doctor.md`. Ou, plus dans l'esprit de la formation, faites-le écrire :

```bash
claude
```
```text
> Crée .claude/commands/ops-doctor.md : une commande qui établit un état de santé en lecture
  seule des services de l'ecommerce-app (pods, events, endpoints /health) et rend un tableau
  Service | État | Signal | Action. Elle ne doit jamais corriger quoi que ce soit.
```

**2. Vérifier qu'elle est vue**

```text
> /help
```

`/ops-doctor` doit apparaître dans la liste.

**3. L'exécuter**

```text
> /ops-doctor
```

Sans cluster actif, il doit **dire qu'il ne peut pas joindre le cluster** — et non inventer un
diagnostic. Si votre commande produit un faux diagnostic, c'est la contrainte « dis-le au lieu
d'inventer » qui manque : c'est exactement ce genre de garde-fou qu'on écrit une fois pour toutes.

**4. Créer `/ship` avec argument**

Recopiez l'exemple, puis :

```text
> /ship test de la commande
```

Observez qu'il s'arrête pour demander validation avant de committer — parce que c'est écrit dans le
fichier, pas parce qu'il est prudent aujourd'hui.

**5. Versionner**

```bash
git add .claude/commands/ && git commit -m "chore: add ops-doctor and ship commands"
```

Vos collègues récupèrent vos commandes avec un `git pull`. **C'est ça, la capitalisation.**

---

## 5. Erreurs fréquentes

| Erreur | Conséquence | Correctif |
|---|---|---|
| Pas de `description` dans le frontmatter | Commande peu lisible dans `/help` | Toujours en mettre une, courte |
| Un prompt vague (« vérifie que tout va bien ») | Résultat différent à chaque exécution | Des étapes numérotées et un format de sortie imposé |
| Oublier la contrainte « lecture seule » | Une commande de diagnostic qui *corrige* | L'écrire explicitement, en majuscules si besoin |
| Mettre la commande dans `~/.claude/` | L'équipe ne l'a pas | `.claude/commands/`, versionné |
| Une commande qui fait douze choses | Impossible à maintenir et à réutiliser | En faire un skill ([module 04](../04-skills/)) |

---

## 6. Checklist de sortie

- [ ] J'ai créé `/ops-doctor` et `/ship` dans `.claude/commands/`.
- [ ] Je sais utiliser `$ARGUMENTS`.
- [ ] Mes commandes sont versionnées, donc disponibles pour l'équipe.
- [ ] Je sais dire ce qui distingue une commande d'un skill.
- [ ] Mes commandes de diagnostic sont explicitement en lecture seule.

> **La question pour le module suivant :** *« Ma procédure de redémarrage fait quinze étapes, avec des
> conditions et des vérifications. Un prompt ne suffit plus. »*
