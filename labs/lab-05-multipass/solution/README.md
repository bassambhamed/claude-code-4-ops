# Corrigé — Provisionnement de VM

Le cloud-init reproductible et les skills de cycle de vie des VM.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `cloud-init/ecom-demo.yaml` | VM Ubuntu reproductible : Docker, .NET, UFW. Aucun secret. |
| `.claude/skills/provision-vm/` | Conventions de nommage et de dimensionnement, confirmation avant suppression. |
| `.claude/skills/vm-deploy/` | Déploiement de l'application sur une VM provisionnée. |

## Appliquer

```bash
cp -r labs/lab-05-multipass/solution/cloud-init ~/lab-ecommerce/
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
