---
description: État de santé du cluster et des services de l'ecommerce-app — lecture seule
---

Établis un état de santé de l'environnement, dans cet ordre.

1. **Cluster** — `kubectl get nodes` puis `kubectl get pods -A -o wide`.
   Relève tout pod qui n'est ni `Running` ni `Ready`, avec son nombre de redémarrages.
2. **Événements récents** — `kubectl get events -A --sort-by=.lastTimestamp | tail -30`.
   Relève les events `Warning` et ce qui les a déclenchés.
3. **Ressources** — `kubectl top nodes` et `kubectl top pods -A` si le metrics-server
   est disponible. Signale toute consommation proche des limites.
4. **Services applicatifs** — pour chaque service de l'ecommerce-app (catalog, ordering,
   gateway, web), vérifie l'endpoint `/health`.

Produis ensuite un tableau :

| Service | État | Signal d'alerte | Action suggérée |

Puis, en trois lignes maximum : ce qui mérite une attention **aujourd'hui**.

## Contraintes

- **Lecture seule.** N'applique AUCUNE correction, ne relance AUCUN pod, ne modifie
  AUCUNE ressource. Tu observes et tu rapportes.
- Si le cluster est injoignable, **dis-le** au lieu de produire un diagnostic inventé.
- N'affiche jamais le contenu d'un Secret.
- Sois bref : ce rapport doit être lisible à 3 h du matin.
