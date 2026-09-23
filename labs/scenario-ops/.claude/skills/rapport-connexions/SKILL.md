---
name: rapport-connexions
description: Produit le bilan des connexions SSH et PostgreSQL des dernières 24 h à partir des métriques Prometheus, et l'enregistre en Markdown dans rapports/. À utiliser quand on demande un bilan, un rapport ou l'état des connexions.
allowed-tools: mcp__prometheus, Bash(curl -s http://*:9090/api/v1/*), Write(./rapports/**)
---

# Rapport de connexions

Les chiffres viennent **uniquement** de Prometheus. Ne jamais compter ni estimer à la main.

1. Exécuter ces requêtes instantanées avec le MCP `prometheus`. À défaut, utiliser `curl -s "$PROMETHEUS_URL/api/v1/query" --data-urlencode 'query=…'`.

   | Indicateur | Requête |
   | --- | --- |
   | SSH acceptées (24 h) | `ssh_connexions_acceptees_24h{vm!="monitor"}` |
   | SSH refusées (24 h) | `ssh_connexions_refusees_24h{vm!="monitor"}` |
   | Pire heure de refus (24 h) | `max_over_time(ssh_connexions_refusees_1h[24h])` |
   | Pire source sur 1 h (24 h) | `max by (vm, source) (max_over_time(ssh_refus_par_source_1h[24h]))` |
   | Connexions PostgreSQL (24 h) | `pg_connexions_24h{vm="vm1"}` |
   | Pic de connexions simultanées | `max_over_time(sum(pg_stat_database_numbackends{datname="projet"})[24h:5m])` |
   | Échecs d'authentification PostgreSQL | `pg_echecs_auth_24h{vm="vm1"}` |
   | Alertes actives | `ALERTS{alertstate="firing"}` |

2. Attribuer un statut à chaque ligne :

   | Statut | Condition |
   | --- | --- |
   | **OK** | Aucun échec, ou des échecs isolés |
   | **À surveiller** | Une même source a ≥ 5 refus sur 1 h |
   | **Critique** | Pire heure ≥ 20 refus (toutes sources), ou alerte `critique` active |

3. Remplir [gabarit-rapport.md](gabarit-rapport.md) et l'enregistrer dans `rapports/AAAA-MM-JJ.md`.

4. En cas de statut « À surveiller » ou « Critique », proposer de lancer l'agent `log-inspector` sur la VM et la période concernées.
