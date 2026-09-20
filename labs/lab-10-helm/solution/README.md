# Corrigé — Packaging Helm

Le chart paramétrable et ses values par environnement.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `helm/ecommerce/Chart.yaml` | Métadonnées du chart. |
| `helm/ecommerce/templates/` | `_helpers.tpl`, deployment, service, ingress, hpa — aucune valeur en dur. |
| `helm/ecommerce/values*.yaml` | Valeurs par défaut, `dev` et `preprod`. |

## Appliquer

```bash
cp -r labs/lab-10-helm/solution/helm ~/lab-ecommerce/
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
