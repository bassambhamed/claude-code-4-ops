# Corrigé — Pipeline CI/CD

Les workflows GitHub Actions et le skill qui les génère.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `.github/workflows/ci.yml` | Build .NET, construction des images, scan Trivy. Ne déploie jamais. |
| `.github/workflows/cd.yml` | Staging automatique, production après approbation manuelle. |
| `.claude/skills/ci-pipeline/` | La doctrine de pipeline : gate obligatoire, aucun secret en clair. |

## Appliquer

```bash
cp -r labs/lab-02-ci-cd/solution/.github ~/lab-ecommerce/
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
