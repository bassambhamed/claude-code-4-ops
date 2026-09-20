# Lab 12 — Incident & post-mortem

> **Durée :** 60 min · **Modules requis :** [08](../../modules/08-sous-agents/)
> · **Outils :** `kubectl` · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Dérouler un incident complet : détecter, investiguer, formuler une cause racine étayée, rétablir,
puis produire un **post-mortem blameless** exploitable. Le tout en gardant la règle qui compte en
astreinte : **l'agent investigue, l'humain agit**.

## 2. Pré-requis

- [Lab 09](../lab-09-kubernetes/) terminé (cluster avec l'application).
- [Lab 11](../lab-11-observabilite/) recommandé (métriques disponibles).

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Sous-agent** `incident-analyst` | Investigation dans un contexte isolé, en lecture seule |
| **Skill** `postmortem` | Le format de post-mortem de l'équipe |
| **Hook** d'audit | Chaque commande de l'investigation est tracée (R5, DORA) |
| **MCP** Jira / incident.io | Rattacher l'investigation au ticket d'incident |

---

## 4. Déroulé pas-à-pas

### Étape 1 — Préparer l'astreinte (10 min)

**Le hook d'audit avant l'incident, pas après.** Vérifiez qu'il est actif :

```text
> /hooks
```

Créez `.claude/agents/incident-analyst.md` — contenu complet au
[module 08, §4](../../modules/08-sous-agents/#4-mini-lab--deux-sous-agents-ops-20-min).

Points non négociables : `tools` sans `Write` ni `Edit`, aucune hypothèse sans preuve citée, aucune
personne désignée, aucune donnée client recopiée.

### Étape 2 — Déclencher l'incident (5 min)

Faites déclencher la panne par quelqu'un d'autre, sans vous dire laquelle :

```bash
# Option A — saturation mémoire
kubectl set resources deployment/ordering-api -n ecommerce --limits=memory=24Mi
# Option B — dépendance cassée
kubectl set env deployment/ordering-api -n ecommerce services__catalog__http__0=http://catalog-typo:8080
# Option C — probe inadaptée
kubectl patch deployment catalog-api -n ecommerce --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/periodSeconds","value":1}]'
```

### Étape 3 — Investiguer (20 min)

```text
> Les utilisateurs signalent des erreurs 500 sur la création de commande depuis 10 minutes.
  Investigue et donne-moi une timeline, puis tes hypothèses de cause racine classées.
```

Observez le comportement attendu :

1. Il **délègue** à `incident-analyst`.
2. Le sous-agent collecte events, logs, `describe`, historique de rollout.
3. Il rend une **synthèse structurée** — pas 800 lignes de logs.
4. Chaque hypothèse est accompagnée de **sa preuve** et de **ce qui la réfuterait**.

Vérifiez votre contexte :

```text
> /context
```

Il doit être quasi intact. **C'est tout l'intérêt de la délégation** : la session reste disponible
pour la décision et le rétablissement.

### Étape 4 — Rétablir (10 min)

```text
> Quelle est l'action de rétablissement la plus rapide, et quel est son risque ?
```

**L'agent propose. Vous exécutez.**

```bash
kubectl rollout undo deployment/ordering-api -n ecommerce
kubectl get pods -n ecommerce -w
```

> En astreinte, la tentation est de laisser l'agent corriger pour gagner deux minutes. C'est
> précisément le moment où la règle R2 protège : sous stress, à 3 h du matin, personne ne relit
> correctement une commande proposée. Le hook, lui, ne fatigue pas.

### Étape 5 — Le post-mortem (15 min)

```text
> Crée .claude/skills/postmortem/SKILL.md. Format à imposer :
  1. Résumé en 3 lignes (impact utilisateur, durée, cause)
  2. Chronologie horodatée (détection, diagnostic, rétablissement)
  3. Impact quantifié : durée, services, requêtes en échec
  4. Cause racine, distinguée des facteurs aggravants
  5. Ce qui a bien fonctionné / ce qui a manqué
  6. Actions correctives : propriétaire, échéance, critère de clôture
  7. MTTD et MTTR
  Règles : blameless, jamais de nom de personne, jamais de donnée client,
  aucune action corrective sans propriétaire identifié.
```

```text
> Rédige le post-mortem de l'incident qu'on vient de traiter.
```

**Le critère de qualité :** chaque action corrective a un propriétaire et une échéance. Un
post-mortem qui se termine par « il faudrait améliorer le monitoring » n'a servi à rien.

### Étape 6 — Vérifier la trace (5 min)

```bash
tail -20 ~/.claude/audit/*.jsonl | jq -r '"\(.ts) \(.tool) \(.command // "-")"'
```

Vous avez la chronologie exacte de l'investigation. C'est la pièce qu'un auditeur DORA demandera :
qui a fait quoi, quand, avec quel outil.

---

## 5. Livrable

```
.claude/agents/incident-analyst.md       # lecture seule, preuves obligatoires
.claude/skills/postmortem/SKILL.md       # format d'équipe
docs/postmortems/YYYY-MM-DD-<titre>.md   # le post-mortem produit
~/.claude/audit/*.jsonl                  # journal de l'investigation
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| L'agent n'agit jamais sur un système en incident (R2) | Sous-agent sans écriture + hook de garde |
| Aucune donnée client dans l'analyse (R1) | Inscrit dans les garde-fous du sous-agent |
| Post-mortem blameless | Règle explicite dans le skill |
| Traçabilité complète (R5) | Hook d'audit `PostToolUse` |
| Aucune conclusion sans preuve | Format de sortie imposé |

## 7. Pour aller plus loin

- Branchez le MCP **Atlassian** ou **incident.io** et faites rattacher l'investigation au ticket.
- Faites produire un **runbook** à partir du post-mortem, pour que la prochaine occurrence soit
  traitée en dix minutes.
- Rejouez un incident déjà documenté et comparez le diagnostic de l'agent au vôtre.
- Mesurez : MTTD et MTTR avec et sans assistance, sur trois incidents simulés.
