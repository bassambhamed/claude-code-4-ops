# Corrigé — Sécurité & secrets

La chaîne complète de garde-fous : permissions, hooks, configuration gitleaks et CI bloquante.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `.claude/settings.json` | Permissions `allow`/`ask`/`deny` de référence + les quatre hooks câblés. |
| `.claude/hooks/guard-destructive.sh` | Bloque les commandes irréversibles. |
| `.claude/hooks/secret-scan.sh` | Bloque un commit contenant un secret. Bloque aussi si gitleaks est absent. |
| `.claude/hooks/audit-log.sh` | Journal d'audit JSON Lines, hors du dépôt, rotation quotidienne. |
| `.claude/hooks/session-start.sh` | Rappelle dépôt, branche, cluster et namespace au démarrage. |
| `.gitleaks.toml` | Règles étendues + liste d'exclusion des faux positifs de la formation. |
| `.github/workflows/security.yml` | gitleaks + trivy config + trivy image, **bloquants**. |

## Appliquer

```bash
cp -r labs/lab-04-securite-secrets/solution/.claude ~/lab-ecommerce/
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
