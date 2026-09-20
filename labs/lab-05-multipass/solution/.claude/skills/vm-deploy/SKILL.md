---
name: vm-deploy
description: Déploie l'ecommerce-app (.NET) sur une VM Multipass déjà provisionnée : partage le code, publie/lance l'app, expose le port et vérifie le /health. Demande confirmation avant toute action destructive et ne met aucun secret en clair.
---

# Skill : vm-deploy

Objectif : faire tourner l'ecommerce-app sur une VM Multipass de façon claire et réversible.

## Étapes à suivre
1. Vérifier que la VM cible existe et tourne (`multipass info <nom>`).
2. Rendre le code accessible : `multipass mount <dossier-hôte> <nom>:/srv/app` (ou `multipass transfer`).
3. Publier/lancer : `multipass exec <nom> -- dotnet run --project /srv/app/src/ECommerce.AppHost` (ou un `dotnet <dll>` publié).
4. Récupérer l'IP (`multipass info <nom>`) et vérifier l'endpoint `/health` depuis l'hôte.
5. Expliquer comment arrêter proprement (`multipass stop`) et nettoyer.

## Garde-fous
- Confirmation humaine avant `delete`/`purge`/`umount`.
- Aucun secret en clair (connexions, tokens) : variables d'environnement ou coffre.
- Démo uniquement : pas d'ouverture de port vers l'extérieur, pas de données réelles.
