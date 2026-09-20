---
name: ansible-play
description: Génère ou met à jour des playbooks et inventaires Ansible pour configurer des serveurs (ex. la VM Multipass de l'UC4) et y déployer l'ecommerce-app. Lance TOUJOURS un --check (dry-run) avant d'appliquer, vise l'idempotence, et ne met aucun secret en clair (Ansible Vault / clés SSH).
---

# Skill : ansible-play

Objectif : produire des playbooks Ansible **idempotents, lisibles et sûrs**, appliqués pas à pas.

## Étapes à suivre
1. Identifier les hôtes cibles et créer/mettre à jour `ansible/inventory.ini` (groupes, IP, user SSH).
2. Écrire `ansible/playbook.yml` avec des tasks idempotentes (modules `apt`, `get_url`, `copy`, `systemd`…).
3. Vérifier la syntaxe : `ansible-playbook --syntax-check` puis `ansible-lint` si dispo.
4. DRY-RUN obligatoire : `ansible-playbook -i inventory.ini playbook.yml --check --diff` ; EXPLIQUER les changements.
5. Après validation humaine : exécuter sans `--check` ; vérifier le service et l'endpoint /health.
6. Secrets via Ansible Vault (`ansible-vault encrypt`) ou clés SSH — jamais en clair.

## Garde-fous
- JAMAIS d'exécution réelle sans `--check` préalable et validation humaine.
- Aucun mot de passe / token en clair : Ansible Vault ou variables protégées.
- Tasks idempotentes : rejouer le playbook ne doit rien casser.
