---
description: Crée une VM Multipass durcie (Ubuntu 24.04, SSH par clé, node_exporter)
argument-hint: <nom> [cpus=2] [memoire=2G] [disque=10G]
disable-model-invocation: true
allowed-tools: Bash(multipass launch *), Bash(multipass info *), Bash(multipass list *)
---

Arguments reçus : `$ARGUMENTS`. Créer la VM Multipass `$0` avec les ressources suivantes : CPU `$1` (défaut 2), mémoire `$2` (défaut 2G), disque `$3` (défaut 10G). Un argument absent apparaît vide ou sous la forme `$n` : appliquer alors la valeur par défaut.

1. Vérifier avec `multipass list` que `$0` n'existe pas déjà. Si elle existe, s'arrêter et le signaler.
2. Annoncer la commande exacte et attendre la confirmation :
   `multipass launch 24.04 --name $0 --cpus <cpus> --memory <memoire> --disk <disque> --cloud-init .claude/ressources/cloud-init-base.yaml`
3. Après la création, exécuter `multipass info $0 --format json` et vérifier que l'état est `Running` et que la VM a une IPv4.
4. Répondre en trois lignes : nom, IP, état.
