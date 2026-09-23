# Matrice des droits

## Espace de travail `/srv/projet` sur vm1

| Chemin | ba1 | ba2 | autres |
| --- | --- | --- | --- |
| `/srv/projet` | propriétaire (rwx) | traverser et lister (rx) | aucun |
| `specs/` | rwx | lecture (rX, ACL par défaut) | aucun |
| `drafts/` | rwx | traverser seulement (x) | aucun |
| `drafts/ba2/` | rwx | écriture (rwX, ACL par défaut) | aucun |

## Base `projet` sur vm1

| Rôle | Utilisé par | Droits |
| --- | --- | --- |
| `projet_owner` | Application et BA1 | Propriétaire de la base |
| `lecture_seule` | MCP `postgres`, BA2 | `CONNECT`, `USAGE` sur `public`, `SELECT` sur toutes les tables, `pg_monitor` |
| `prometheus` | `postgres_exporter` (socket local) | `pg_monitor` uniquement, pas de `CONNECT` sur `projet` |
| `PUBLIC` | — | Aucun : `CONNECT` révoqué sur `projet` |

## Accès SSH

| Utilisateur | Depuis | Vers | Méthode |
| --- | --- | --- | --- |
| `ba2` | vm2 | vm1 | Clé ed25519 uniquement |
| `root` | toutes | toutes | **Refusé** |
