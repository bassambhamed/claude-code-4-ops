---
name: provision-vm
description: Provisionne et gère des VM Ubuntu jetables avec Multipass (launch, list, exec, snapshot, delete) de façon reproductible via cloud-init. N'écrit jamais de secret dans le cloud-init et demande TOUJOURS confirmation avant toute commande destructive.
---

# Skill : provision-vm

Objectif : créer des VM **reproductibles** et **jetables** avec Multipass, pilotées par cloud-init.

## Étapes à suivre
1. Demander le besoin : nom de l'instance, CPU/RAM/disque, paquets à installer.
2. Générer un `cloud-init/<nom>.yaml` (paquets, user, scripts `runcmd`) — commenté pour débutants.
3. Lancer la VM : `multipass launch <image> --name <nom> --cpus N --memory Ng --disk Ng --cloud-init cloud-init/<nom>.yaml`.
4. Vérifier l'état : `multipass list` puis `multipass info <nom>`.
5. Exécuter / inspecter dans la VM via `multipass exec <nom> -- <commande>` (jamais en root inutilement).
6. (Optionnel) `multipass snapshot <nom>` avant un changement risqué.

## Garde-fous
- JAMAIS de secret en clair dans le cloud-init (mot de passe, token, clé privée) — utiliser des clés SSH ou un coffre.
- `multipass delete`/`purge`/`stop` : afficher la commande et DEMANDER confirmation avant exécution.
- Une VM de démo n'est pas la prod : pas de données réelles, pas d'exposition publique.
