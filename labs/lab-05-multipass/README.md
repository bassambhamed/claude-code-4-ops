# Lab 05 — Provisionnement de VM avec Multipass

> **Durée :** 60 min · **Modules requis :** [04](../../modules/04-skills/),
> [05](../../modules/05-hooks/) · **Outils :** `multipass` · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Monter un lab de VM Ubuntu **reproductibles et jetables**, décrites par cloud-init, avec les scripts
de montage et de démontage. Et poser le garde-fou qui empêche l'agent de supprimer une VM sans
validation.

C'est le premier lab d'infrastructure : le premier où une erreur de l'agent **détruit quelque chose**.

## 2. Pré-requis

```bash
multipass version
multipass list         # état initial de vos VM
```

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Skill** `provision-vm` | La procédure de création, avec ses conventions de nommage et de dimensionnement |
| **Skill** `vm-deploy` | Déployer l'application sur une VM provisionnée |
| **Hook** `guard-destructive` | `multipass delete` bloqué — c'est le lab où il sert enfin |
| **`/plan`** | Systématique avant toute création de ressource |

---

## 4. Déroulé pas-à-pas

### Étape 1 — Le garde-fou d'abord (10 min)

Si vous avez fait le [module 05](../../modules/05-hooks/), le hook existe déjà. Sinon, créez-le
maintenant et ajoutez `multipass delete` aux motifs bloqués :

```bash
mkdir -p .claude/hooks
# guard-destructive.sh — voir module 05 §3
chmod +x .claude/hooks/guard-destructive.sh
```

```text
> /hooks
```

**Testez-le tout de suite :**

```text
> Supprime toutes les VM Multipass de la machine
```

Refus attendu. Vous pouvez travailler sereinement.

### Étape 2 — Le cloud-init (15 min)

```text
> /plan Génère cloud-init/ecom-demo.yaml pour une VM Ubuntu 24.04 : utilisateur `ops` avec
  ma clé SSH publique, Docker installé et démarré, le SDK .NET 10, le pare-feu UFW actif
  n'autorisant que 22 et 8080, et le fuseau Europe/Paris.
  Contrainte : AUCUN mot de passe ni clé privée dans le fichier — il sera versionné.
```

Relisez le fichier. Trois questions à vous poser :

- y a-t-il un secret, même en apparence anodin (mot de passe par défaut, jeton) ?
- l'installation est-elle **reproductible** (versions épinglées) ou dépend-elle de « la dernière » ?
- que se passe-t-il si une commande échoue en cours de `runcmd` ?

### Étape 3 — Le skill de provisionnement (10 min)

```text
> Crée .claude/skills/provision-vm/SKILL.md. Conventions à y inscrire :
  - nommage `lab-<usage>-<n>` ;
  - dimensionnement par défaut 2 vCPU / 4 Go / 20 Go, ajustable ;
  - toujours via cloud-init, jamais de configuration manuelle après coup ;
  - avant toute création : afficher `multipass list` et annoncer ce qui va être créé ;
  - JAMAIS de `multipass delete` sans confirmation explicite, et jamais `--all`.
```

### Étape 4 — Provisionner pour de vrai (15 min)

```text
> /plan Crée la VM lab-ecom-1 à partir de cloud-init/ecom-demo.yaml, 2 vCPU, 4 Go, 20 Go.
```

Validez, puis vérifiez :

```bash
multipass list
multipass exec lab-ecom-1 -- docker --version
multipass exec lab-ecom-1 -- sudo ufw status
```

### Étape 5 — Les scripts de cycle de vie (10 min)

```text
> Génère lab-up.sh et lab-down.sh. lab-up.sh crée les VM manquantes de façon idempotente
  (ne recrée pas une VM existante). lab-down.sh liste ce qui sera supprimé et exige une
  confirmation interactive explicite avant d'agir.
```

**L'idempotence n'est pas un raffinement :** un `lab-up.sh` relancé par erreur ne doit pas détruire
un lab en cours d'utilisation.

```bash
bash lab-up.sh     # deux fois : la seconde ne doit rien changer
```

### Étape 6 — Déployer l'application (facultatif, 10 min)

```text
> Crée .claude/skills/vm-deploy/SKILL.md, puis déploie l'ecommerce-app sur lab-ecom-1 :
  transfert des sources, publication, lancement, exposition du port 8080 et vérification
  de /health.
```

```bash
multipass info lab-ecom-1 | grep IPv4
curl http://<ip>:8080/health
```

---

## 5. Livrable

```
cloud-init/ecom-demo.yaml               # VM reproductible, sans aucun secret
lab-up.sh · lab-down.sh                 # cycle de vie, idempotent, confirmation au teardown
.claude/skills/provision-vm/SKILL.md
.claude/skills/vm-deploy/SKILL.md
.claude/hooks/guard-destructive.sh      # testé
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| Aucune suppression de VM sans validation (R2) | Hook `guard-destructive` + règle du skill |
| Jamais de `--all` | Inscrit dans `provision-vm/SKILL.md` |
| Aucun secret dans le cloud-init (R1) | Clé **publique** uniquement ; relecture humaine |
| Création annoncée avant exécution | `/plan` systématique |

## 7. Pour aller plus loin

- Utilisez `multipass snapshot` avant une manipulation risquée — un `/rewind` pour l'infrastructure.
- Faites générer un **inventaire Ansible** depuis `multipass list --format json` ([Lab 07](../lab-07-ansible/)).
- Décrivez ces mêmes VM en **Terraform** ([Lab 06](../lab-06-terraform/)) et comparez les approches.
- Exposez l'inventaire du lab via un **serveur MCP interne** ([module 06, §3.4](../../modules/06-mcp/)).

## Corrigé

```bash
cp -r labs/lab-05-multipass/solution/cloud-init ~/lab-ecommerce/
cp -r labs/lab-05-multipass/solution/.claude/skills/* ~/lab-ecommerce/.claude/skills/
```
