# Corrigé — Git & GitHub assistés

Les trois skills du workflow Git, le hook anti-secret et le cadrage des permissions.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `.claude/skills/init-repo/` | Initialise le dépôt et le publie sur GitHub, avec confirmation avant le push. |
| `.claude/skills/git-commit/` | Commit Conventional Commits, validé avant exécution. |
| `.claude/skills/open-pr/` | PR documentée avec checklist. Ne merge jamais. |
| `.claude/hooks/secret-scan.sh` | Bloque un commit contenant un secret (gitleaks si disponible). |
| `.claude/settings.json` | Câblage du hook + permissions `allow`/`ask`/`deny`. |

## Appliquer

```bash
cp -r labs/lab-01-git-github/solution/.claude ~/lab-ecommerce/
```

Puis, dans une session lancée depuis votre copie de travail :

```text
> /skills     # les skills du corrigé doivent apparaître
> /hooks      # les hooks doivent être listés comme actifs
```

## Ce qu'il faut regarder en priorité

Comparez surtout les **garde-fous** : la section « Garde-fous » de chaque skill, les motifs bloqués
par les hooks, et les contraintes explicites (« lecture seule », « demande confirmation »,
« ne merge jamais »). C'est là que se joue la différence entre un outillage utilisable en
production bancaire et un outillage de démonstration.

Retour à l'[énoncé du lab](../README.md) · [Tous les labs](../../README.md)
