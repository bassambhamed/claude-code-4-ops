---
name: acces-ssh
description: Ouvre ou révoque un accès SSH par clé ed25519 d'un utilisateur d'une VM Multipass vers une autre, avec test positif et négatif. À utiliser pour l'arrivée ou le départ d'un BA.
argument-hint: ouvrir|revoquer <utilisateur> <vm-source> <vm-cible>
disable-model-invocation: true
---

# Accès SSH entre VM

Arguments : `$ARGUMENTS`, soit l'action, l'utilisateur, la VM source et la VM cible (exemple : `ouvrir ba2 vm2 vm1`).

Annoncer le plan et attendre la confirmation avant toute modification. Suivre [checklist.md](checklist.md) et la recopier cochée dans la réponse.

## Ouvrir

1. **Compte sur la VM source**, s'il est absent : `sudo useradd -m -s /bin/bash <user>`.
2. **Clé sur la VM source**, en tant que `<user>`, seulement si `~/.ssh/id_ed25519` n'existe pas :
   `ssh-keygen -t ed25519 -N '' -C '<user>@<vm-source>' -f ~/.ssh/id_ed25519`.
   La clé privée ne quitte jamais la VM source.
3. **Compte sur la VM cible**, s'il est absent. Créer `~/.ssh` (mode 700) et `authorized_keys` (mode 600), avec `<user>` comme propriétaire.
4. **Copier la clé publique uniquement** : lire `~/.ssh/id_ed25519.pub` sur la source et l'ajouter au `authorized_keys` de la cible, sans doublon.
5. **Test** : `bash .claude/skills/acces-ssh/scripts/test-acces.sh <user> <vm-source> <vm-cible>`. Toutes les lignes doivent être `OK` : `<user>` entre, root est refusé, et la clé de `<user>` ne donne pas accès à root.

## Révoquer

1. Retirer la ligne `<user>@<vm-source>` du `authorized_keys` de la cible.
2. Verrouiller le compte sur la cible (`sudo usermod -L -e 1 <user>`), sans supprimer ses fichiers.
3. **Test** : `bash .claude/skills/acces-ssh/scripts/test-acces.sh <user> <vm-source> <vm-cible> --attendu refuse`.

## Résultat

Un tableau `test | attendu | obtenu`, puis une ligne de conclusion.
