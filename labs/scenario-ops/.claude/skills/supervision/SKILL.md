---
name: supervision
description: Installe la supervision locale (métriques SSH et PostgreSQL sur les VM, Prometheus et Grafana sur la VM monitor) avec le tableau de bord « Connexions » et les règles d'alerte. À utiliser à l'installation ou à l'ajout d'une VM à superviser.
argument-hint: "[vm-monitor=monitor]"
disable-model-invocation: true
---

# Mise en place de la supervision

Rôles : **Prometheus mesure** (collecte, stockage, alertes). **Grafana montre** (tableau de bord pour les humains).

Fichiers d'appui, dans `.claude/skills/supervision/fichiers/` :

| Fichier | Destination |
| --- | --- |
| `metriques-connexions.sh` | `/usr/local/bin/` sur vm1 et vm2 |
| `prometheus.yml` | `/etc/prometheus/prometheus.yml` sur monitor, après remplacement de `VM1_IP` et `VM2_IP` |
| `alertes.yml` | `/etc/prometheus/alertes.yml` sur monitor |
| `grafana-datasource.yml` | `/etc/grafana/provisioning/datasources/` sur monitor |
| `grafana-dashboards.yml` | `/etc/grafana/provisioning/dashboards/` sur monitor |
| `dashboard-connexions.json` | `/var/lib/grafana/dashboards/` sur monitor |
| `compte-service-grafana.sh` | `/tmp/` sur monitor, lancé une fois par `sudo sh` (étape 4) |

Pour copier un fichier : `multipass transfer <fichier> <vm>:/tmp/`, puis `sudo install` dans la VM.

## Étapes

Annoncer le plan et attendre la confirmation avant d'exécuter.

1. **Métriques de connexion** (vm1 et vm2) :
   - installer `metriques-connexions.sh` (mode 755) ;
   - le lancer chaque minute par cron root (`/etc/cron.d/metriques-connexions`).
   Le script écrit dans le *textfile collector* de `node_exporter`.
2. **Prometheus** (monitor) :
   - `sudo apt-get install -y prometheus` ;
   - installer `prometheus.yml` et `alertes.yml`, avec les IP obtenues par `multipass info` ;
   - valider avec `promtool check config` ;
   - redémarrer Prometheus.
3. **Grafana** (monitor) :
   - ajouter le dépôt APT officiel `https://apt.grafana.com` (clé dans `/etc/apt/keyrings/grafana.gpg`), puis `apt-get install -y grafana` ;
   - installer les trois fichiers de *provisioning* ;
   - `systemctl enable --now grafana-server`.
4. **Compte de service Grafana** pour le MCP : `multipass exec monitor -- sudo sh /tmp/compte-service-grafana.sh`. Ce script crée, par l'API locale de Grafana, **dans la VM monitor**, un compte `claude` au rôle *Viewer*, puis un jeton. Le jeton (champ `key` de la réponse) est extrait et écrit directement dans `/root/jeton-grafana` (mode 600, `umask 077`) : la réponse de l'API ne doit jamais s'afficher, car un hook ne peut pas masquer une sortie déjà produite. L'utilisateur lira ce fichier lui-même, hors de Claude, pour faire `export GRAFANA_SERVICE_ACCOUNT_TOKEN=...`.
5. **Vérification** :
   - `curl -s http://<ip-monitor>:9090/api/v1/targets` : toutes les cibles doivent être `up` ;
   - requête `ssh_connexions_acceptees_1h` (par le MCP `prometheus` s'il est connecté, sinon `curl -s http://<ip-monitor>:9090/api/v1/query --data-urlencode query=…`) : une série par VM ;
   - le tableau de bord « Connexions » doit exister : `curl -s -u admin:admin 'http://<ip-monitor>:3000/api/search?query=Connexions'` (le MCP `grafana` ne sera connecté qu'après l'export du jeton).

## Résultat

- URL de Prometheus et de Grafana ;
- état de chaque cible ;
- commande à lancer par l'humain, hors de Claude, pour lire le jeton : `multipass exec monitor -- sudo cat /root/jeton-grafana` ;
- rappel : le mot de passe `admin` de Grafana est à changer à la première connexion.
