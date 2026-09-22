# Module 01 — Les commandes natives

> **Durée :** 45 min · **Pré-requis :** [Module 00](../00-prise-en-main/)
> · **Suivant :** [Module 02 — Contexte & mémoire](../02-contexte-et-memoire/)

---

## 1. La limite

Vous savez faire *parler* l'agent. Mais vous ne savez pas **le cadrer** : lui fixer un objectif,
annuler une bêtise, vérifier ce qu'il a en tête, contrôler ce qu'il a le droit de lancer. Tout cela
existe déjà, sans rien installer — encore faut-il savoir que ça existe.

## 2. Le concept — harnais ≠ modèle

Une commande `/` ne part **pas** vers le modèle : elle est exécutée par le **harnais**, le programme
qui héberge l'agent. C'est pour cela qu'elle est fiable et instantanée.

```
   Vous tapez  ──▶  « redémarre le service »   ──▶  le MODÈLE interprète  (probabiliste)
   Vous tapez  ──▶  /rewind                    ──▶  le HARNAIS exécute    (déterministe)
```

Retenez la règle : **tout ce qui doit marcher à coup sûr passe par le harnais.** C'est le même
principe qui fondera les hooks au module 05.

> La liste exacte dépend de votre version. Tapez `/` dans une session : c'est la seule source de
> vérité. Ce module couvre Claude Code **2.1.x**.

---

## 3. Anatomie — les commandes par intention

### 3.1 Démarrer un projet

| Commande | Ce qu'elle fait | Le réflexe Ops |
|---|---|---|
| `/init` | Analyse le dépôt et **génère un `CLAUDE.md`** : stack, structure, commandes de build | **Le tout premier geste** sur un dépôt |
| `/status` | Version, modèle, compte, connectivité | Avant d'ouvrir un ticket de support |
| `/doctor` | Diagnostic de l'installation et de la configuration | Quand « ça ne marche pas » |

`/init` mérite une minute d'attention : il **lit** votre dépôt puis **écrit** un fichier que l'agent
relira à chaque session. C'est votre point d'entrée dans la capitalisation.

### 3.2 Cadrer la session

| Commande | Ce qu'elle fait | Le réflexe Ops |
|---|---|---|
| `/goal` | Fixe **l'objectif de la session** ; l'agent s'y réfère et signale les dérives | Avant un chantier long : migration, incident, refonte de pipeline |
| `/plan` | Mode Plan : l'agent **propose** et attend votre validation avant d'agir | **Systématique avant toute action d'infrastructure** |
| `/model` · `/effort` | Choisit le modèle et le niveau de raisonnement | `/effort high` avant une revue d'IaC ou un diagnostic difficile |
| `/add-dir <chemin>` | Ouvre un dossier supplémentaire à la session | Quand l'IaC est dans un dépôt séparé de l'applicatif |

`/goal` est sous-estimé. Sur une session de deux heures, il évite la dérive classique : on part
diagnostiquer un pod en `CrashLoopBackOff`, et quarante minutes plus tard on refactore un Dockerfile
sans avoir réglé l'incident.

### 3.3 Reprendre la main

| Commande | Ce qu'elle fait | Le réflexe Ops |
|---|---|---|
| `/rewind` | **Revient à un point antérieur** : code, conversation, ou les deux | La bonne réponse à « annule ce que tu viens de faire » |
| `/btw` | Glisse une remarque **sans interrompre** la tâche en cours | « au fait, la prod est en 1.28, pas 1.29 » |
| `/compact` | Résume la conversation pour libérer du contexte | Quand `/context` vire au rouge |
| `/clear` | Repart d'une conversation vide (la mémoire projet est conservée) | Changement complet de sujet |
| `/resume` · `/export` · `/rename` | Reprend, exporte, renomme une session | Passer la main, archiver une investigation |

**`/rewind` vs « annule ».** Demander verbalement d'annuler, c'est demander au modèle de *deviner* ce
qu'il faut défaire. `/rewind` restaure un **checkpoint** réel. Sur de l'infrastructure, la différence
n'est pas théorique.

**`/btw`, à quoi ça sert vraiment.** Sans lui, vous coupez l'agent en pleine tâche et il repart de
travers. Avec lui, votre précision est intégrée et le travail continue.

### 3.4 Voir ce qui se passe

| Commande | Ce qu'elle fait | Le réflexe Ops |
|---|---|---|
| `/context` | **Ce que l'agent a réellement en mémoire de travail**, et qui l'occupe | Dès qu'une réponse est incohérente |
| `/usage` | Coût de session et limites du plan | Pour chiffrer un usage d'équipe |
| `/insights` | Statistiques d'usage et d'impact | Pour argumenter le déploiement auprès du management |
| `/tasks` | Tout ce qui tourne en arrière-plan (commandes shell, sous-agents) : voir, arrêter | Un `kubectl logs -f` qui tourne pendant qu'on travaille |

**`/context` est la commande de diagnostic n°1.** Une réponse qui part en vrille, c'est presque
toujours un contexte saturé — pas un modèle « devenu bête ».

### 3.5 Sécurité et qualité

| Commande | Ce qu'elle fait | Le réflexe Ops |
|---|---|---|
| `/permissions` | Règles **allow / ask / deny** par outil et par commande | À configurer **avant** de laisser l'agent travailler seul |
| `/hooks` | Les hooks réellement actifs | Vérifier, ne jamais supposer |
| `/security-review` | Analyse de sécurité des changements en cours | Avant chaque PR — et systématiquement sur de l'IaC |
| `/code-review [--fix]` | Revue du diff : bugs, simplifications | Avant de pousser |

### 3.6 Extensions — les briques des modules suivants

| Commande | Ouvre sur |
|---|---|
| `/skills` | [Module 04](../04-skills/) |
| `/hooks` | [Module 05](../05-hooks/) |
| `/mcp` | [Module 06](../06-mcp/) |
| `/plugin` | [Module 07](../07-plugins/) |
| `/agents` | [Module 08](../08-sous-agents/) |

### 3.7 Les commandes « qui changent la façon de travailler »

Moins connues, très utiles en exploitation.

| Commande | Ce qu'elle fait | Cas Ops concret |
|---|---|---|
| `/loop [intervalle] <prompt>` | **Rejoue** un prompt à intervalle régulier, ou en auto-rythme | Surveiller un rollout : *« toutes les 2 min, vérifie les pods du namespace ecommerce et alerte-moi si l'un redémarre »* |
| `/remote-control` | Piloter la session **depuis un autre appareil** | Suivre une migration de nuit depuis son téléphone |
| `/teleport` | Reprendre le travail dans un autre environnement | Passer du poste à la VM de lab sans perdre le fil |
| `/workflows` | Orchestrations multi-agents | Revue d'un gros diff d'infra selon plusieurs axes en parallèle |
| `/fast` | Sortie accélérée sur les modèles compatibles | Itérations courtes et répétitives |
| `/output-style` · `/statusline` | Style de sortie, barre de statut | Afficher le cluster et le namespace courants en permanence |

> **`/loop` : le garde-fou avant l'automatisation.** Une boucle qui *observe et rapporte* est sans
> risque. Une boucle qui *corrige toute seule* en production ne fait pas partie du cadre de cette
> formation (règle R2 des [garde-fous](../../docs/garde-fous.md)).

---

## 4. Mini-lab — tour guidé (20 min)

À dérouler dans l'ordre, dans l'application fil rouge. Pas de raccourci : chaque commande est censée
produire un effet visible.

```bash
cd ../../ecommerce-app
claude
```

**1. Prendre la température**

```text
> /status
> /context
```

Notez le pourcentage de contexte occupé **avant** d'avoir rien fait. C'est votre point de référence.

**2. Donner un contexte projet**

```text
> /init
```

Laissez-le travailler, puis lisez le `CLAUDE.md` généré. Il a lu votre dépôt pour l'écrire.

```text
> !cat CLAUDE.md
```

**3. Fixer un cap**

```text
> /goal Préparer la conteneurisation de Catalog.Api sans modifier le code applicatif
```

**4. Travailler en mode Plan**

```text
> /plan Propose un Dockerfile multi-stage pour Catalog.Api, non-root, et explique chaque étape
```

Lisez le plan. **Ne validez pas encore.**

**5. Annuler proprement**

```text
> /rewind
```

Choisissez le point de reprise. Constatez que l'état est restauré — sans avoir eu à décrire ce qu'il
fallait défaire.

**6. Glisser une précision en cours de route**

```text
> /plan Propose un Dockerfile multi-stage pour Catalog.Api
> /btw notre registre interne n'autorise que les images basées sur Debian, pas Alpine
```

Observez : la contrainte est intégrée sans que la tâche reparte de zéro.

**7. Cadrer les permissions**

```text
> /permissions
```

Ajoutez une règle `ask` sur `Bash(docker:*)`, puis demandez-lui de construire une image. Vous êtes
sollicité — c'est exactement le comportement voulu.

**8. Passer la sécurité**

```text
> /security-review
```

Sur un dépôt encore vierge, le rapport sera court. L'important est de savoir que la commande existe
et **quand** la lancer : avant chaque PR.

**9. Mesurer**

```text
> /context
> /usage
> /insights
```

Comparez `/context` avec la mesure de l'étape 1. Vous venez de voir concrètement ce qui remplit une
fenêtre de contexte.

**10. Boucler** *(démonstration, 3 min)*

```text
> /loop 2m Vérifie l'état du build de la solution et signale toute régression
```

Laissez tourner deux itérations, puis arrêtez la boucle. Vous avez un agent de surveillance — sans
écrire une ligne de script.

---

## 5. Erreurs fréquentes

| Erreur | Conséquence | Correctif |
|---|---|---|
| Sauter `/init` | L'agent réinvente vos conventions à chaque session | `/init` en premier, toujours |
| Ignorer `/context` jusqu'au blocage | Réponses incohérentes attribuées au modèle | Surveiller, puis `/compact` |
| Dire « annule » au lieu de `/rewind` | Annulation approximative, état incertain | `/rewind` |
| Couper l'agent pour une précision | La tâche repart de travers | `/btw` |
| Configurer `/permissions` après l'incident | Trop tard | Avant la première session de travail réel |
| Croire que `/security-review` remplace une revue humaine | Faux sentiment de sécurité | C'est un filet, pas un contrôle |

---

## 6. Checklist de sortie

- [ ] J'ai lancé `/init` et lu le `CLAUDE.md` produit.
- [ ] Je sais fixer un objectif (`/goal`) et travailler en mode Plan (`/plan`).
- [ ] Je sais revenir en arrière avec `/rewind` et corriger le tir avec `/btw`.
- [ ] Je sais lire `/context` et décider entre `/compact` et `/clear`.
- [ ] J'ai posé au moins une règle dans `/permissions`.
- [ ] Je sais où sont `/skills`, `/hooks`, `/mcp`, `/plugin`, `/agents` — les modules à venir.
- [ ] J'ai vu `/loop` tourner et je sais dire pourquoi une boucle qui *corrige* seule est hors cadre.

> **La question pour le module suivant :** *« Comment faire pour qu'il n'oublie pas, demain, ce que
> je viens de lui apprendre ? »*
