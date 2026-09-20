# Corrigé — Observabilité

La stack de monitoring, les règles d'alerte et le connecteur Grafana.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `observability/values-prometheus.yaml` | kube-prometheus-stack dimensionné pour k3d, sans persistance. |
| `observability/alerts.yaml` | PrometheusRule : erreurs, latence p95, saturation, crashloop — chacune avec `for:` et runbook. |
| `.claude/skills/observability/` | Les quatre signaux dorés, et ce qu'il ne faut PAS alerter. |
| `.claude/commands/slo-check.md` | Vérification des SLO en lecture seule. |
| `.mcp.json` | Serveur Grafana — jeton par variable d'environnement, rôle `Viewer`. |

## Appliquer

```bash
cp -r labs/lab-11-observabilite/solution/observability ~/lab-ecommerce/
```

Puis, dans une session lancée depuis votre copie de travail :

```text
> /skills     # les skills du corrigé doivent apparaître
> /hooks      # les hooks doivent être listés comme actifs
```

## Ce qui n'est volontairement pas fourni

Le **dashboard Grafana** (`dashboard-ecommerce.json`) n'est pas dans le corrigé : ses requêtes
PromQL dépendent des **labels réellement exposés** par votre instrumentation, qui varient selon la
version d'OpenTelemetry et la configuration de scrape. Un JSON figé donnerait des panneaux vides et
enverrait tout le monde chercher au mauvais endroit.

C'est justement le bon exercice : faites générer le dashboard, constatez les panneaux vides, puis
faites diagnostiquer l'écart entre la requête et les labels réels
(`promtool query instant`). Le diagnostic vaut plus que le fichier.

## Ce qu'il faut regarder en priorité

Comparez surtout les **garde-fous** : la section « Garde-fous » de chaque skill, les motifs bloqués
par les hooks, et les contraintes explicites (« lecture seule », « demande confirmation »,
« ne merge jamais »). C'est là que se joue la différence entre un outillage utilisable en
production bancaire et un outillage de démonstration.

Retour à l'[énoncé du lab](../README.md) · [Tous les labs](../../README.md)
