# Modules — les briques de Claude Code

Dix modules, à suivre **dans l'ordre**. Chacun répond à une limite concrète rencontrée au module
précédent : c'est ce qui rend la progression mémorable.

| # | Module | La limite qu'il lève | Durée |
|:---:|---|---|:---:|
| [00](00-prise-en-main/) | Prise en main | « Par où je commence ? » | 45 min |
| [01](01-commandes-natives/) | Commandes natives | « Je ne sais pas ce que l'outil sait faire. » | 45 min |
| [02](02-contexte-et-memoire/) | Contexte & mémoire | « Il refait toujours la même erreur. » | 40 min |
| [03](03-commandes-personnalisees/) | Commandes personnalisées | « Je retape le même prompt tous les jours. » | 30 min |
| [04](04-skills/) | Skills | « Ma procédure fait quinze étapes. » | 45 min |
| [05](05-hooks/) | Hooks | « Et s'il lance un `terraform destroy` ? » | 45 min |
| [06](06-mcp/) | MCP | « Il ne voit ni nos tickets ni nos métriques. » | 45 min |
| [07](07-plugins/) | Plugins | « Comment je donne tout ça à l'équipe ? » | 45 min |
| [08](08-sous-agents/) | Sous-agents | « Ma session est noyée sous les logs. » | 40 min |
| [09](09-automatisation-et-ci/) | Automatisation & CI | « Et sans moi devant le clavier ? » | 40 min |

## Canevas commun

Chaque module suit la même structure :

1. **La limite** — le problème concret qui justifie la brique (une phrase).
2. **Le concept** — ce que c'est, en quoi ça diffère de la brique précédente.
3. **Anatomie** — les fichiers, la syntaxe, ce qui est obligatoire.
4. **Mini-lab** — 10 à 20 min, clavier en main, sur l'application fil rouge.
5. **Erreurs fréquentes** — ce qui va rater, et pourquoi.
6. **Checklist de sortie** — ce que vous devez savoir faire avant de passer au suivant.

## Où travailler

Sauf mention contraire, tous les mini-labs se déroulent dans l'application fil rouge :

```bash
cd ../ecommerce-app
claude
```

Les artefacts produits (`.claude/`, `.mcp.json`) restent **locaux à votre poste** : ils ne sont pas
committés dans le dépôt de formation. Les versions de référence sont dans
[`labs/*/solution/`](../labs/) et dans [`plugins/oddo-ops-toolkit/`](../plugins/oddo-ops-toolkit/).
