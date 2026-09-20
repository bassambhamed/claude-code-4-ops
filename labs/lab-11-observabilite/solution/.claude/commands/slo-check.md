---
description: Vérifie les objectifs de service de l'ecommerce-app sur une période donnée
---

Vérifie les objectifs de service (SLO) de l'ecommerce-app.
Période demandée : $ARGUMENTS (par défaut : les 24 dernières heures).

Pour chaque service (catalog, ordering, gateway, web), relève via Grafana / Prometheus :

1. **Disponibilité** — pourcentage de requêtes non-5xx. Objectif : 99,5 %.
2. **Latence** — p95 des requêtes HTTP. Objectif : < 300 ms.
3. **Budget d'erreur** — part du budget consommée sur la période, et à quelle vitesse.

Produis le tableau :

| Service | Disponibilité | p95 | Budget d'erreur consommé | Objectif tenu ? |

Puis, en trois lignes : le service le plus à risque, et **pourquoi** — en citant la métrique.

## Contraintes

- Lecture seule. Aucune modification de dashboard, d'alerte ou de datasource.
- Si une métrique est absente, dis-le explicitement au lieu d'extrapoler.
- Compare toujours à la période précédente de même durée : une valeur isolée ne dit rien.
