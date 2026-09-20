# Module 08 — Sous-agents

> **Durée :** 40 min · **Pré-requis :** [Module 07](../07-plugins/)
> · **Suivant :** [Module 09 — Automatisation & CI](../09-automatisation-et-ci/)

---

## 1. La limite

Vous demandez d'analyser un incident. L'agent lit 4 000 lignes de logs, 12 manifestes et l'historique
des déploiements. Il trouve la cause — mais votre session est saturée : tout ce bruit occupe
désormais la place dont vous avez besoin pour **corriger**.

Le problème n'est pas la quantité de travail. C'est que **le bruit de l'investigation pollue la
session qui doit rester claire**.

## 2. Le concept — déléguer avec un contexte séparé

Un **sous-agent** est un agent spécialisé, avec ses propres instructions, ses propres outils, et
surtout **sa propre fenêtre de contexte**. Il travaille à côté, et ne vous rend que sa conclusion.

```
  Session principale                      Sous-agent « incident-analyst »
  ──────────────────                      ───────────────────────────────
  « analyse l'incident »  ────────────▶   contexte VIERGE
                                          lit 4 000 lignes de logs
                                          corrèle events et déploiements
       contexte intact   ◀────────────    rend 15 lignes : cause + preuves
  « corrige le manifeste »
```

**Les trois bénéfices, dans l'ordre d'importance pour un Ops :**

1. **Isolation du contexte** — le bruit reste chez lui. C'est la raison principale.
2. **Spécialisation** — des instructions taillées pour une seule tâche, et un ton adapté
   (un relecteur de plan Terraform doit être méfiant, pas serviable).
3. **Restriction d'outils** — un sous-agent d'analyse peut être limité à la lecture. Pas de `Write`,
   pas de `Edit` : il lui est *techniquement* impossible de modifier quoi que ce soit.

| | Skill ([module 04](../04-skills/)) | **Sous-agent** |
|---|---|---|
| Nature | Un mode d'emploi | Un exécutant |
| Contexte | Le vôtre | **Le sien** |
| Outils | Les vôtres | Ceux qu'on lui accorde |
| Rend | Le déroulé complet | **Une synthèse** |
| Bon pour | Une procédure à suivre | Une tâche lourde, bruyante ou sensible |

## 3. Anatomie

`.claude/agents/tf-plan-reviewer.md` :

```markdown
---
name: tf-plan-reviewer
description: Relit un `terraform plan` et signale les changements destructifs, les dérives
  et les risques avant tout apply. À utiliser systématiquement avant d'appliquer un plan
  Terraform. Lecture seule.
tools: Bash, Read, Grep, Glob
---

Tu es ingénieur infrastructure senior, chargé de la revue des plans Terraform avant
application en environnement bancaire. Ton rôle est de **douter**, pas d'approuver.

## Méthode

1. Lis le plan intégralement. Ne survole pas.
2. Classe chaque changement : `create` / `update in-place` / **`replace`** / **`destroy`**.
3. Pour chaque `replace` ou `destroy`, identifie : la ressource, la cause du remplacement
   (quel attribut force la recréation), et la conséquence opérationnelle (perte de données,
   interruption de service, changement d'adresse IP).
4. Repère les signaux d'alerte :
   - suppression d'une ressource à état (base, volume, bucket) ;
   - modification d'une règle réseau ou d'un groupe de sécurité ;
   - `lifecycle` absent sur une ressource critique ;
   - dérive entre l'état et la réalité (`Objects have changed outside of Terraform`) ;
   - secret ou valeur sensible visible en clair dans le plan.
5. Conclus par un verdict explicite : **SÛR** / **À REVOIR** / **BLOQUANT**.

## Garde-fous
- Lecture seule. Tu ne lances JAMAIS `terraform apply` ni `terraform destroy`.
- Tu ne conclus pas « SÛR » s'il reste un `destroy` non justifié.
- Si le plan est incomplet ou illisible, tu le dis au lieu de supposer.

## Format de sortie
| # | Ressource | Action | Risque | Justification exigée |

Puis : verdict, et les trois questions à poser à l'auteur du changement.
```

**Ce qui fait un bon sous-agent :**

| Champ | Ce qui compte |
|---|---|
| `description` | **Quand** déléguer à cet agent — c'est le critère de sélection |
| `tools` | La liste minimale. Un relecteur n'a pas besoin de `Write` |
| Corps | Un **rôle** (« tu es… »), une **méthode** numérotée, des **garde-fous**, un **format de sortie** |

Le format de sortie est décisif : un sous-agent qui rend un paragraphe libre oblige à tout relire —
il n'aura rien fait gagner.

### Portée

| Emplacement | Disponible |
|---|---|
| `.claude/agents/<nom>.md` | Ce projet, toute l'équipe (versionné) |
| `~/.claude/agents/<nom>.md` | Vous, partout |
| `plugins/<plugin>/agents/<nom>.md` | Distribué par plugin |

`/agents` liste, crée et inspecte les sous-agents disponibles.

---

## 4. Mini-lab — deux sous-agents Ops (20 min)

```bash
cd ../../ecommerce-app
mkdir -p .claude/agents
```

**1. Le relecteur de plan** — recopiez `tf-plan-reviewer.md` ci-dessus.

**2. L'analyste d'incident** — `.claude/agents/incident-analyst.md` :

```markdown
---
name: incident-analyst
description: Analyse un incident de production à partir de logs, d'events Kubernetes et de
  l'historique de déploiement. Produit une timeline, des hypothèses de cause racine classées
  et les preuves associées. Lecture seule, à utiliser pendant ou après un incident.
tools: Bash, Read, Grep, Glob
---

Tu es SRE d'astreinte. Ton objectif : établir **ce qui s'est passé**, pas rassurer.

## Méthode
1. Établis la **timeline** : premier symptôme, premier impact utilisateur, actions menées.
2. Corrèle avec les changements : déploiements, changements de configuration, montées de version.
3. Groupe les erreurs par signature plutôt que de les lister une à une.
4. Formule 3 hypothèses de cause racine, **classées par vraisemblance**, chacune avec :
   la preuve qui l'appuie, et ce qui la réfuterait.
5. Distingue toujours **cause racine** et **facteur aggravant**.

## Garde-fous
- Lecture seule. Aucune action corrective, aucun redémarrage.
- Aucune hypothèse sans preuve citée — dire « je ne sais pas » est une réponse valable.
- Ne jamais désigner une personne. Les causes sont systémiques.
- Ne jamais recopier de donnée client ni de secret trouvé dans un log.

## Format de sortie
1. Timeline (heure | événement | source)
2. Tableau des hypothèses (hypothèse | preuve | ce qui la réfuterait | vraisemblance)
3. Cause racine retenue et sa justification
4. Actions correctives : immédiates, puis de fond
```

**3. Vérifier**

```bash
claude
```
```text
> /agents
```

**4. Déléguer sans nommer l'agent**

```text
> !kubectl get events -A --sort-by=.lastTimestamp | tail -50
> Analyse ces events, établis une timeline et donne-moi les causes racines probables.
```

Observez deux choses : il **délègue** à `incident-analyst`, et il vous rend une **synthèse** — pas
les 50 events. Vérifiez avec `/context` que votre session n'a pas absorbé tout le bruit.

**5. Le test de la restriction d'outils**

```text
> Demande à incident-analyst de corriger directement le manifeste fautif.
```

Il ne peut pas : `tools` ne contient ni `Write` ni `Edit`. **La restriction n'est pas une consigne,
c'est une contrainte technique.** C'est la même logique que les hooks, appliquée à la délégation.

---

## 5. Erreurs fréquentes

| Erreur | Conséquence | Correctif |
|---|---|---|
| `description` qui décrit l'agent au lieu du moment de l'appeler | Jamais délégué | Décrire **la situation** |
| `tools` trop large sur un agent d'analyse | Il modifie ce qu'il devait seulement lire | Liste minimale |
| Pas de format de sortie | Un pavé à relire entièrement | Imposer un tableau ou des sections |
| Déléguer une tâche triviale | Surcoût pour rien | Le sous-agent sert quand la tâche est **lourde ou bruyante** |
| Attendre qu'il se souvienne de la session | Il a son propre contexte, vierge | Tout ce dont il a besoin doit être dans la demande |
| Un sous-agent « généraliste » | Résultats quelconques | Un agent = un rôle |

---

## 6. Checklist de sortie

- [ ] J'ai créé deux sous-agents avec `description`, `tools` restreints, méthode et format de sortie.
- [ ] Ils apparaissent dans `/agents` et sont mobilisés **sans que je les nomme**.
- [ ] J'ai vérifié dans `/context` que le bruit de l'investigation n'a pas pollué ma session.
- [ ] J'ai constaté qu'un outil non listé est techniquement indisponible.
- [ ] Je sais dire quand choisir un skill et quand choisir un sous-agent.

> **La question pour le module suivant :** *« Tout cela suppose que je sois devant le clavier. Et
> dans un pipeline, la nuit, pendant une astreinte ? »*
