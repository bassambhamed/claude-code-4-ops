# Corrigé — Tests automatisés

Le projet de tests, le skill de doctrine et le sous-agent de couverture.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `tests/ECommerce.Catalog.Tests/` | Projet xUnit **vérifié** : 5 tests d'intégration (nominal, 404, id non entier, création/relecture, `/health`). |
| `.claude/skills/gen-tests/` | La doctrine de test : un test = un comportement, cas limites inclus. |
| `.claude/agents/test-engineer.md` | Analyse de couverture en lecture seule, classée par risque. |

## Appliquer

```bash
cp -r labs/lab-03-tests/solution/tests ~/lab-ecommerce/
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
