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

