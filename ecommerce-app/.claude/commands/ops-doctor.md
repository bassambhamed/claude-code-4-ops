---
description: État de santé du cluster et des services de l'ecommerce-app
---

Établis un état de santé, dans cet ordre :

1. `kubectl get pods -A -o wide` — liste les pods qui ne sont pas `Running`/`Ready`.
2. `kubectl get events -A --sort-by=.lastTimestamp | tail -30` — relève les events anormaux.
3. Pour chaque service de l'ecommerce-app, vérifie l'endpoint `/health`.

Puis produis un tableau : Service | État | Signal d'alerte | Action suggérée.

Contraintes :
- Lecture seule. N'applique AUCUNE correction, ne relance AUCUN pod.
- Si tu ne peux pas joindre le cluster, dis-le au lieu d'inventer un diagnostic.
