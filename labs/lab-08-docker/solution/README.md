# Corrigé — Conteneurisation

Les Dockerfiles multi-stage non-root, le compose de développement et le skill de doctrine.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `src/*/Dockerfile` | Build multi-étapes, runtime chiselé, exécution non-root, port 8080. |
| `docker-compose.yml` | Les quatre services, service discovery recâblé à la main. |
| `.dockerignore` | Réduit le contexte de build et évite d'embarquer des fichiers sensibles. |
| `.claude/skills/containerize/` | La doctrine d'image : base autorisée, non-root, scan systématique. |

## Appliquer

```bash
cp -r labs/lab-08-docker/solution/src/* ~/lab-ecommerce/src/
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
