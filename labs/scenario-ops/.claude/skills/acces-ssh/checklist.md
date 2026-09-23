# Checklist accès SSH

## Arrivée (ouvrir)

- [ ] Le besoin figure dans la matrice des droits (`gestion-permissions/matrice-droits.md`, section « Accès SSH »)
- [ ] Plan annoncé et validé par un humain
- [ ] Compte présent sur la VM source et sur la VM cible
- [ ] Clé ed25519 générée **sur la VM source** ; la clé privée n'a pas quitté la VM
- [ ] `~/.ssh` en 700 et `authorized_keys` en 600 sur la cible, propriétaire `<user>`
- [ ] Seule la clé publique a été copiée, sans doublon
- [ ] `test-acces.sh` : 3 lignes `OK` (utilisateur accepté, root refusé, clé de l'utilisateur refusée pour root)

## Départ (révoquer)

- [ ] Plan annoncé et validé par un humain
- [ ] Ligne `<user>@<vm-source>` retirée du `authorized_keys` de la cible
- [ ] Compte verrouillé sur la cible (`usermod -L -e 1`), fichiers conservés
- [ ] `test-acces.sh … --attendu refuse` : 3 lignes `OK`
