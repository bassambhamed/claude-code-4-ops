# Corrigé — Incident & post-mortem

Le sous-agent d'investigation, le skill de post-mortem et son modèle.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `.claude/agents/incident-analyst.md` | Timeline, 3 hypothèses étayées, lecture seule, blameless. |
| `.claude/skills/postmortem/` | Le format imposé : cause racine, impact chiffré, MTTD/MTTR, actions assignées. |
| `docs/postmortems/TEMPLATE.md` | Le modèle à remplir, prêt pour la revue d'équipe. |

## Appliquer

```bash
cp -r labs/lab-12-incident-postmortem/solution/.claude ~/lab-ecommerce/
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
