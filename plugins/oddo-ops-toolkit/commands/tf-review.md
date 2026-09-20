---
description: Génère un plan Terraform et le fait relire avant tout apply
---

Prépare et fais relire un plan Terraform. Cible : $ARGUMENTS (répertoire, `terraform/` par défaut).

1. `terraform fmt -check -recursive` puis `terraform validate`. Corrige le formatage si besoin.
2. `terraform plan -out=tfplan`, puis `terraform show -no-color tfplan > plan.txt`.
3. Délègue la revue au sous-agent **tf-plan-reviewer** et restitue son verdict intégralement.
4. Si le verdict est **À REVOIR** ou **BLOQUANT** : arrête-toi et présente les points à traiter.
5. Si le verdict est **SÛR** : présente la commande `terraform apply tfplan` à l'utilisateur
   et **attends** qu'il la lance lui-même.

## Interdits

- Ne lance **jamais** `terraform apply` ni `terraform destroy` toi-même.
- Ne conclus pas à la place du relecteur.
