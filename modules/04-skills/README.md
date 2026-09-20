# Module 04 — Skills

> **Durée :** 45 min · **Pré-requis :** [Module 03](../03-commandes-personnalisees/)
> · **Suivant :** [Module 05 — Hooks](../05-hooks/)

---

## 1. La limite

Votre procédure de redémarrage tient en quinze étapes, avec des conditions (« si le pod ne redémarre
pas au bout de 60 s, alors… »), des vérifications intermédiaires et un rollback. Ça ne rentre pas
dans un prompt — et surtout, vous ne voulez pas avoir à penser à l'invoquer : vous voulez que l'agent
s'en serve **quand la situation s'y prête**.

## 2. Le concept — le runbook exécutable

Un **skill** est un dossier contenant un `SKILL.md` : une procédure écrite en langage naturel, que
l'agent **charge de lui-même** quand la demande correspond à sa `description`.

```
.claude/skills/k8s-debug-pod/
├── SKILL.md              ← la procédure + le frontmatter qui déclenche le chargement
└── references/           ← (optionnel) fichiers annexes lus au besoin
    └── codes-erreur.md
```

**La bascule mentale à opérer :** la `description` du frontmatter n'est pas de la documentation. C'est
le **critère de déclenchement**. L'agent la lit pour décider s'il charge le skill. Une description
vague = un skill qui ne sert jamais.

| | Commande personnalisée | **Skill** | Sous-agent (module 08) |
|---|---|---|---|
| Qui déclenche | Vous (`/nom`) | **L'agent**, selon la description | L'agent, pour déléguer |
| Contexte | Votre session | Votre session | **Le sien**, isolé |
| Taille adaptée | Un prompt | Une procédure de 5 à 50 étapes | Une tâche lourde et bruyante |
| Analogie Ops | Un alias shell | **Un runbook** | Un collègue spécialisé |

## 3. Anatomie

```markdown
---
name: k8s-debug-pod
description: Diagnostique un pod Kubernetes en échec (CrashLoopBackOff, ImagePullBackOff,
  OOMKilled, probes qui échouent). Collecte logs, events et describe, formule une hypothèse
  de cause racine et propose un correctif. N'applique aucune modification sans validation.
---

# Skill : k8s-debug-pod

Objectif : trouver **pourquoi** un pod ne tourne pas, de façon méthodique et reproductible.

## Quand l'utiliser
Un pod est en erreur, redémarre en boucle, ou ne passe jamais `Ready`.

## Procédure

1. **Situer** — `kubectl get pods -n <ns> -o wide`. Relever : phase, restarts, node, âge.
2. **Décrire** — `kubectl describe pod <pod> -n <ns>`. Lire la section `Events` en dernier
   (la plus récente est en bas) et l'état `Last State` du conteneur.
3. **Lire les logs** — `kubectl logs <pod> -n <ns> --previous` d'abord : les logs de
   l'instance qui a crashé sont plus utiles que ceux de celle qui démarre.
4. **Classer** selon la signature observée :
   - `ImagePullBackOff` → tag inexistant, registre inaccessible, secret de pull manquant.
   - `CrashLoopBackOff` → l'application sort en erreur : lire le code de sortie et les logs.
   - `OOMKilled` → `resources.limits.memory` trop bas, ou fuite mémoire.
   - `Readiness probe failed` → chemin, port ou délai de démarrage (`initialDelaySeconds`).
   - `Pending` → ressources insuffisantes, `nodeSelector`, ou PVC non lié.
5. **Vérifier les dépendances** — service discovery, ConfigMaps, Secrets, NetworkPolicies.
6. **Formuler** une hypothèse de cause racine, avec la preuve qui l'appuie.
7. **Proposer** le correctif sous forme de diff de manifeste. **Ne pas l'appliquer.**

## Garde-fous
- Lecture seule : `get`, `describe`, `logs`, `events`. Jamais `delete`, `apply` ni `scale`.
- Si l'hypothèse n'est pas étayée par une preuve dans les logs ou les events, le dire.
- Ne jamais afficher le contenu d'un Secret.

## Sortie attendue
| Symptôme | Preuve (log/event) | Cause racine probable | Correctif proposé |
```

### Les quatre règles d'un bon skill

1. **Une `description` qui dit *quand*, pas *quoi*.** « Diagnostique un pod en échec
   (CrashLoopBackOff, ImagePullBackOff…) » se déclenche ; « Aide Kubernetes » ne se déclenche jamais.
2. **Des étapes ordonnées et vérifiables**, comme un runbook d'astreinte.
3. **Une section Garde-fous explicite** — ce que le skill ne doit jamais faire.
4. **Un format de sortie imposé** — sinon le rendu varie à chaque exécution.

### Portée

| Emplacement | Disponible |
|---|---|
| `.claude/skills/<nom>/SKILL.md` | Dans ce projet, pour toute l'équipe (versionné) |
| `~/.claude/skills/<nom>/SKILL.md` | Pour vous, partout |
| `plugins/<plugin>/skills/<nom>/SKILL.md` | Distribué par plugin ([module 07](../07-plugins/)) |

`/skills` liste ce qui est réellement chargé.

---

## 4. Mini-lab — écrire un skill Ops (25 min)

```bash
cd ../../ecommerce-app
mkdir -p .claude/skills/restart-service
```

**1. Écrire `SKILL.md`** — `.claude/skills/restart-service/SKILL.md` :

```markdown
---
name: restart-service
description: Redémarre proprement un microservice de l'ecommerce-app (Catalog, Ordering,
  Gateway, Web) — drain du trafic, redémarrage, attente du healthcheck, restauration du
  trafic. Demande confirmation avant toute action et journalise l'opération.
---

# Skill : restart-service

## Quand l'utiliser
Un service répond mal ou doit être redémarré après un changement de configuration.

## Procédure
1. Identifier le service ciblé et son environnement. En cas de doute, DEMANDER.
2. Relever l'état avant : réplicas, âge, restarts, dernier déploiement.
3. Annoncer le plan et **attendre validation explicite**.
4. Drainer : réduire les réplicas progressivement (jamais de coupure sèche).
5. Redémarrer : `kubectl rollout restart deployment/<svc> -n <ns>`.
6. Attendre le healthcheck `/health` — 60 s maximum, puis alerter.
7. Restaurer le trafic, confirmer un 200 OK, relever l'état après.
8. Journaliser : service, heure, motif, résultat.

## Garde-fous
- Un seul service à la fois. Jamais `--all`.
- Aucune action si l'environnement cible n'est pas confirmé par l'utilisateur.
- En cas d'échec du healthcheck : rollback (`kubectl rollout undo`) et alerte, pas d'insistance.
```

**2. Vérifier le chargement**

```bash
claude
```
```text
> /skills
```

`restart-service` doit apparaître. S'il manque : frontmatter mal formé (voir erreurs fréquentes).

**3. Le déclencher *sans* le nommer** — c'est le test qui compte :

```text
> Le service ordering répond en 503, il faut le relancer proprement
```

L'agent doit mobiliser le skill de lui-même et, surtout, **s'arrêter à l'étape 3 pour demander
validation**. Le garde-fou écrit dans le fichier est respecté.

**4. Tester la description.** Ouvrez `SKILL.md`, remplacez la description par « Gère les services ».
Relancez la session et reposez la même question. Il ne se déclenche plus. **Remettez l'ancienne
description.** Vous venez de mesurer que la description *est* le mécanisme de déclenchement.

**5. Versionner**

```bash
git add .claude/skills/ && git commit -m "chore: add restart-service skill"
```

---

## 5. Erreurs fréquentes

| Erreur | Conséquence | Correctif |
|---|---|---|
| Description vague | Le skill ne se déclenche jamais | Décrire **la situation**, avec les mots que l'on emploierait vraiment |
| Frontmatter YAML invalide (indentation, `:` non échappé) | Skill absent de `/skills` | Vérifier `name` et `description` |
| Nom de dossier ≠ `name` du frontmatter | Comportement erratique | Les garder identiques |
| Aucune section Garde-fous | Le skill agit là où il devrait s'arrêter | Toujours lister les interdits |
| Un skill de 400 lignes | Contexte consommé, agent noyé | Le découper, ou déporter le détail dans `references/` |
| Un skill qui en fait trop | Impossible à réutiliser | Un skill = une procédure |

---

## 6. Checklist de sortie

- [ ] J'ai écrit un `SKILL.md` complet : frontmatter, procédure, garde-fous, format de sortie.
- [ ] Il apparaît dans `/skills` et se déclenche **sans que je le nomme**.
- [ ] J'ai vérifié expérimentalement le rôle de la `description`.
- [ ] Je sais dire ce qui distingue une commande, un skill et un sous-agent.
- [ ] Mon skill est versionné.

> **La question pour le module suivant :** *« Mon skill dit de demander confirmation. Mais si le
> modèle passe outre — ou si quelqu'un travaille sans ce skill — qu'est-ce qui l'en empêche ? »*
