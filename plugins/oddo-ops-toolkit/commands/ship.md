---
description: Prépare une livraison — diff, revue de sécurité, commit conventionnel et PR
---

Prépare la livraison de la branche courante.
Contexte fourni par l'utilisateur : $ARGUMENTS

1. Affiche `git status` et `git diff`. Résume les changements en trois lignes.
2. Relis le diff sous l'angle sécurité : secret en clair, URL interne, jeton, donnée
   personnelle, permission élargie. Signale tout ce qui sort de l'ordinaire.
3. Si le diff touche à l'infrastructure (`terraform/`, `k8s/`, `helm/`, `.github/`),
   signale explicitement les changements destructifs ou les élargissements de droits.
4. Propose un message de commit au format **Conventional Commits** — en anglais, à
   l'impératif, avec un corps qui explique le *pourquoi*.
5. **Attends ma validation** avant de committer.
6. Après validation : commit, push de la branche, puis ouverture d'une Pull Request avec
   titre clair, description structurée (contexte, changements, tests, risques) et une
   checklist de revue.

## Interdits

- Ne merge **jamais**.
- Ne force **jamais** un push (`--force`, `--force-with-lease`).
- Ne committe pas si l'étape 2 a relevé un secret : signale-le et arrête-toi.
