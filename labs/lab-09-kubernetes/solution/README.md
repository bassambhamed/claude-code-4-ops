# Corrigé — Cluster Kubernetes

Les manifestes complets, le skill de bootstrap et le sous-agent de diagnostic.

> **À utiliser après avoir essayé**, pas à la place. Le but du lab est de produire ces fichiers
> avec l'agent ; le corrigé sert de référence en cas de blocage, et de point de comparaison une
> fois l'exercice terminé.

## Contenu

| Fichier | Rôle |
|---|---|
| `k8s/k3d-cluster.yaml` | Cluster 1 serveur + 2 agents, registre local, ingress Traefik. |
| `k8s/*.yaml` | Deployments, Services, Ingress : probes liveness ET readiness, limites, securityContext. |
| `.claude/skills/k8s-bootstrap/` | Création du cluster, import des images, application des manifestes. |
| `.claude/agents/k8s-debug-pod.md` | Diagnostic méthodique en lecture seule, correctif proposé en diff. |

## Appliquer

```bash
cp -r labs/lab-09-kubernetes/solution/k8s ~/lab-ecommerce/
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
