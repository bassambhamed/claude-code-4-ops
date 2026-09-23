# Bilan des connexions du {{date}}

**Statut global : {{OK | À surveiller | Critique}}**

| Indicateur | vm1 | vm2 | Statut |
| --- | --- | --- | --- |
| Connexions SSH acceptées (24 h) | {{n}} | {{n}} | {{statut}} |
| Tentatives SSH refusées (24 h) | {{n}} | {{n}} | {{statut}} |
| Pire heure de refus SSH | {{n}} | {{n}} | {{statut}} |
| Pire source de refus SSH (1 h) | {{n}} ({{ip}}) | {{n}} ({{ip}}) | {{statut}} |
| Connexions PostgreSQL (24 h) | {{n}} | — | {{statut}} |
| Pic de connexions simultanées | {{n}} | — | {{statut}} |
| Échecs d'authentification PostgreSQL | {{n}} | — | {{statut}} |

## Alertes actives

{{liste des alertes, ou « Aucune »}}

## À faire

{{actions proposées, ou « Rien »}}

Détail visuel : Grafana, tableau de bord « Connexions » (`{{GRAFANA_URL}}/d/connexions`).
