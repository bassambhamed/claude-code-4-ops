# Corrigé — Ansible & durcissement

L'inventaire, le playbook idempotent et le skill de doctrine.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `ansible/inventory.ini` | Inventaire explicite, aucun mot de passe. |
| `ansible/playbook.yml` | Docker, durcissement SSH, UFW — idempotent (`changed=0` au 2e passage). |
| `.claude/skills/ansible-play/` | `--check` obligatoire, modules natifs, pas de `shell` déguisé. |

## Appliquer

```bash
cp -r labs/lab-07-ansible/solution/ansible ~/lab-ecommerce/
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
