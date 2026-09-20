---
name: tf-infra
description: Génère ou met à jour de la configuration Terraform (provider docker pour la démo) et déroule le cycle init/plan/apply. Montre TOUJOURS un plan avant d'appliquer, ne met aucun secret en clair, et demande validation humaine avant apply/destroy.
---

# Skill : tf-infra

Objectif : produire de l'IaC Terraform **claire, paramétrée et sûre**, appliquée pas à pas.

## Étapes à suivre
1. Identifier la cible (ici : provider `docker`, image de l'ecommerce-app) et les paramètres (port, nom).
2. Générer `terraform/main.tf` (provider + resources), `variables.tf` (paramètres) et `terraform.tfvars.example`.
3. `terraform init` (télécharge le provider), `terraform fmt` + `terraform validate` (forme + cohérence).
4. `terraform plan` : présenter ce qui va être créé/modifié et l'EXPLIQUER.
5. Après validation humaine : `terraform apply` ; vérifier le résultat (conteneur up, endpoint /health).
6. Nettoyage sur demande : `terraform destroy` (jamais sans confirmation).

## Garde-fous
- JAMAIS d'`apply`/`destroy` sans plan affiché et validation humaine explicite.
- Aucun secret en clair dans les `.tf` : variables + `*.tfvars` ignorés par Git.
- Ne pas committer `terraform.tfstate` ni `.terraform/` (les ajouter au `.gitignore`).
