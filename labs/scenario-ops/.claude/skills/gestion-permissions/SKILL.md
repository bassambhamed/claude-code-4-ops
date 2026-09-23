---
name: gestion-permissions
description: Applique ou audite les droits de l'espace de travail /srv/projet (comptes Linux, ACL) et de la base PostgreSQL selon la matrice des droits. À utiliser pour ajouter une personne, modifier ses droits ou vérifier l'existant.
argument-hint: appliquer|auditer [vm=vm1]
disable-model-invocation: true
---

# Gestion des permissions

La référence est [matrice-droits.md](matrice-droits.md). Aucun droit ne doit être accordé en dehors de cette matrice : si une demande ne la respecte pas, proposer d'abord de modifier la matrice.

## Auditer

Lancer `bash .claude/skills/gestion-permissions/scripts/audit-droits.sh <vm>`, puis comparer le résultat à la matrice.

## Appliquer

1. **Audit « avant »** avec le script.
2. **Préparer** : créer les comptes manquants (`useradd -m`), puis créer `/srv/projet/specs` et `/srv/projet/drafts/<user>`. Le propriétaire est `ba1`, en mode 750.
3. **ACL Linux**, avec `multipass exec <vm> -- sudo setfacl …` :
   - `ba2` : `rx` sur `/srv/projet`, `rX` récursif **et** par défaut (`-d`) sur `specs` (les fichiers ajoutés ensuite par `ba1` restent lisibles), `--x` sur `drafts` ;
   - `ba2` : `rwX` récursif **et** par défaut (`-d`) sur `drafts/ba2`.
4. **PostgreSQL** : appliquer les `GRANT` et `REVOKE` de la matrice avec `sudo -u postgres psql -d projet`. Si le MCP `postgres` est connecté, s'en servir pour relire l'état (lecture seule) ; les modifications passent toujours par `psql` dans la VM.
5. **Audit « après »** avec le script. Toutes les lignes doivent être `OK`.

## Résultat

Un tableau des différences avant et après, puis l'état final : conforme ou non conforme.
