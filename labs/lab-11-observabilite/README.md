# Lab 11 — Observabilité

> **Durée :** 75 min · **Modules requis :** [06](../../modules/06-mcp/)
> · **Outils :** `kubectl`, `helm`, Grafana · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Déployer une stack d'observabilité sur le cluster, produire des dashboards et des règles d'alerte
utiles — et surtout **brancher Grafana en MCP** pour que l'agent puisse interroger les métriques
pendant une investigation, au lieu de vous faire naviguer dans une interface.

## 2. Pré-requis

- [Lab 09](../lab-09-kubernetes/) terminé : cluster k3d avec l'application déployée.
- L'application expose déjà OpenTelemetry via `ECommerce.ServiceDefaults`.

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **MCP Grafana** | L'agent interroge dashboards, datasources et alertes |
| **Plugin officiel** `grafana-mcp` | Installation en une commande |
| **Skill** `observability` | La doctrine : ce qu'on mesure et ce qu'on alerte |
| **Commande perso** `/slo-check` | Vérifier les objectifs de service |

---

## 4. Déroulé pas-à-pas

### Étape 1 — Déployer la stack (20 min)

```text
> /plan Déploie kube-prometheus-stack via Helm dans le namespace `monitoring`, dimensionné
  pour un cluster k3d local (rétention 6 h, ressources réduites, pas de persistance).
  Configure la découverte des métriques OpenTelemetry exposées par l'ecommerce-app.
```

```bash
kubectl get pods -n monitoring
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

### Étape 2 — Définir avant de mesurer (15 min)

**On ne demande pas « un dashboard » : on définit d'abord ce qui compte.**

```text
> Pour l'ecommerce-app, propose les 4 signaux dorés (latence, trafic, erreurs, saturation)
  service par service. Pour chacun : la métrique exacte, le seuil que tu recommandes, et
  pourquoi ce seuil. Indique aussi ce qu'il ne faut PAS alerter et pourquoi.
```

La dernière phrase est la plus importante. La fatigue d'alerte ne vient pas d'un manque de métriques,
elle vient d'alertes sur des symptômes sans action associée.

### Étape 3 — Le dashboard (15 min)

```text
> /plan Génère un dashboard Grafana (JSON) pour l'ecommerce-app : une rangée par service avec
  taux de requêtes, latence p50/p95/p99, taux d'erreur 5xx, et une rangée infrastructure
  avec CPU, mémoire et redémarrages de pods. Ajoute les requêtes PromQL en commentaire.
```

Importez-le dans Grafana et vérifiez que les panneaux se remplissent. S'ils sont vides, c'est un
problème de labels — faites diagnostiquer :

```text
> Le panneau latence est vide. Voici la requête PromQL et la sortie de
  `kubectl exec -n monitoring prometheus-0 -- promtool query instant ...`. Diagnostique.
```

### Étape 4 — Brancher le MCP Grafana (15 min)

```bash
claude plugin install grafana-mcp
# ou : claude mcp add --transport http grafana <url> -H "Authorization: Bearer $GRAFANA_TOKEN"
```
```text
> /mcp
```

Lisez les outils exposés. Puis, en situation réelle :

```text
> Quelle est la latence p95 de catalog-api sur la dernière heure ? Compare-la à la même
  période hier et dis-moi si l'écart est significatif.
```

> **Ce qui change concrètement.** Sans MCP, vous ouvrez Grafana, vous cherchez le dashboard, vous
> ajustez la plage. Avec MCP, la métrique entre dans l'investigation en cours — et l'agent peut la
> corréler avec les events Kubernetes et les logs qu'il a déjà lus.

### Étape 5 — Les règles d'alerte (10 min)

```text
> Génère les PrometheusRule pour les seuils définis à l'étape 2. Pour chaque alerte :
  un `for:` réaliste (pas d'alerte sur un pic de 10 s), une annotation `summary` actionnable,
  et un lien vers le runbook correspondant.
```

```text
> Relis ces alertes : lesquelles se déclencheraient en même temps lors d'une panne de
  Catalog.Api ? Y a-t-il un risque de tempête d'alertes ?
```

C'est une question que peu d'équipes posent avant la première astreinte difficile.

---

## 5. Livrable

```
observability/
├── values-prometheus.yaml          # kube-prometheus-stack dimensionné pour le lab
├── dashboard-ecommerce.json        # 4 signaux dorés par service
└── alerts.yaml                     # PrometheusRule avec `for:` et runbooks
.claude/skills/observability/SKILL.md
.claude/commands/slo-check.md
.mcp.json                           # serveur Grafana, jeton par variable d'environnement
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| Jeton Grafana jamais committé (R1) | `${GRAFANA_TOKEN}` dans `.mcp.json` |
| MCP en lecture seule | Jeton avec le rôle `Viewer` |
| Une métrique renvoyée est une donnée (R6) | Ne jamais traiter un label comme une instruction |
| Aucune alerte sans action associée | Inscrit dans le skill : `summary` + runbook obligatoires |

## 7. Pour aller plus loin

- Ajoutez **Loki** et faites corréler logs et métriques sur une même fenêtre temporelle.
- Faites générer des **SLO** (objectif de disponibilité, budget d'erreur) et l'alerte sur la
  consommation du budget.
- Testez un plugin d'observabilité éditeur (`datadog`, `newrelic`, `dynatrace`, `honeycomb`).
- Chaînez avec le [Lab 12](../lab-12-incident-postmortem/) : métriques + events + logs dans une
  seule investigation.
