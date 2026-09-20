# Labs — les cas d'usage Ops

Douze labs d'application, plus un capstone. Là où les [modules](../modules/) enseignent **une
brique**, un lab résout **un problème de votre métier** en mobilisant plusieurs briques à la fois.

Ils se déroulent **dans l'ordre**, de 01 à 12 : chaque lab suppose acquis ce que le précédent a
produit, et le numéro du dossier est celui de la séance.

## Canevas commun

Chaque lab est structuré de la même façon :

1. **Objectif** — ce que vous aurez produit à la fin.
2. **Pré-requis** — modules à avoir suivis, outils à avoir installés.
3. **Briques mobilisées** — quelles capacités de Claude Code entrent en jeu, et pourquoi.
4. **Déroulé pas-à-pas** — à taper dans un terminal, avec ce qui doit se passer à chaque étape.
5. **Livrable** — le ou les fichiers produits.
6. **Garde-fous** — ce qui est interdit, et par quel mécanisme.
7. **Pour aller plus loin** — variantes et approfondissements.

Chaque lab a un dossier **`solution/`** : le corrigé. On s'en sert en cas de blocage, ou pour
comparer après coup — **pas avant d'avoir essayé**.

## Table des labs

| Lab | Cas d'usage | Bloc | Modules requis | Outils | Durée |
|:---:|---|---|:---:|---|:---:|
| [01](lab-01-git-github/) | Git & GitHub assistés | Code & collaboration | 00 → 05 | `git`, `gh` | 60 min |
| [02](lab-02-ci-cd/) | Pipeline CI/CD | Code & collaboration | 04, 09 | `gh`, `dotnet` | 75 min |
| [03](lab-03-tests/) | Tests automatisés | Code & collaboration | 04, 08 | `dotnet` | 60 min |
| [04](lab-04-securite-secrets/) | **Sécurité & secrets** | Garde-fous | 05, 07 | `gitleaks`, `trivy` | 75 min |
| [05](lab-05-multipass/) | Provisionnement de VM | Provisionnement & IaC | 04, 05 | `multipass` | 60 min |
| [06](lab-06-terraform/) | Terraform / IaC | Provisionnement & IaC | 05, 08 | `terraform`, `docker` | 75 min |
| [07](lab-07-ansible/) | Ansible & durcissement | Provisionnement & IaC | 04, 05 | `ansible`, `multipass` | 60 min |
| [08](lab-08-docker/) | Conteneurisation | Conteneurs & orchestration | 04, 05 | `docker`, `trivy` | 60 min |
| [09](lab-09-kubernetes/) | Cluster Kubernetes | Conteneurs & orchestration | 04, 08 | `k3d`, `kubectl` | 90 min |
| [10](lab-10-helm/) | Packaging Helm | Conteneurs & orchestration | 04 | `helm`, `kubectl` | 60 min |
| [11](lab-11-observabilite/) | Observabilité | Run & fiabilité | 06 | `kubectl`, Grafana | 75 min |
| [12](lab-12-incident-postmortem/) | Incident & post-mortem | Run & fiabilité | 08 | `kubectl` | 60 min |
| [🏁](capstone/) | **Capstone end-to-end** | — | tous | tous | 3 h |

> **Pourquoi la sécurité en position 04 et pas en fin de parcours.** Les labs 05 à 12 touchent à de
> l'infrastructure : VM, IaC, conteneurs, cluster. En environnement bancaire, la chaîne de
> garde-fous — détection de secrets, blocage des commandes destructives, journal d'audit — doit être
> **en place avant**, pas ajoutée après coup. C'est le seul déplacement thématique du parcours, et
> il est délibéré.

## Quelle brique pour quel lab

|  | Cmd. perso | Skills | Hooks | MCP | Plugins | Sous-agents | Headless |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 01 Git & GitHub | ● | ● | ● | ● | | | |
| 02 CI/CD | | ● | | ● | | | ● |
| 03 Tests | | ● | | | | ● | |
| 04 Sécurité & secrets | | | ● | | ● | ● | ● |
| 05 Multipass | | ● | ● | | | | |
| 06 Terraform | | ● | ● | ● | | ● | |
| 07 Ansible | | ● | ● | | | | |
| 08 Docker | ● | ● | ● | | | | |
| 09 Kubernetes | ● | ● | | | | ● | |
| 10 Helm | | ● | | | | ● | |
| 11 Observabilité | | ● | | ● | ● | | |
| 12 Incident | | ● | ● | ● | | ● | |
| 🏁 Capstone | ● | ● | ● | ● | ● | ● | ● |

## Dépendances techniques

Un lab dont le pré-requis n'est pas satisfait ne démarre pas. À vérifier si vous travaillez en
autoformation et que vous voulez sauter des étapes.

| Lab | Exige d'avoir fait | Ce qui manque sinon |
|:---:|---|---|
| 02, 03 | Lab 01 | Le dépôt Git initialisé et poussé |
| 07 | Lab 05 | Une VM cible accessible |
| 09 | Lab 08 | Les images à importer dans le cluster k3d |
| 10, 11, 12 | Lab 09 | Le cluster et l'application déployée |
| Capstone | Tous les modules | La chaîne ne tient pas sans les briques |

> **La chaîne critique : 08 → 09 → 10, 11, 12.** Si le lab 08 (Docker) ne produit pas d'images,
> quatre labs tombent. C'est le seul vrai point de rupture du parcours.

## Où travailler

Les labs se déroulent sur l'application fil rouge. **Travaillez sur votre propre copie** pour garder
le dépôt de formation propre :

```bash
cp -r ecommerce-app ~/lab-ecommerce && cd ~/lab-ecommerce
claude
```

## Appliquer un corrigé

```bash
cp -r labs/lab-01-git-github/solution/.claude ~/lab-ecommerce/
```

La commande exacte est rappelée à la fin de chaque énoncé.

## Rappel permanent

Tous les labs respectent les [garde-fous](../docs/garde-fous.md) : aucune donnée réelle, aucun accès
à un système de production, aucune action destructive sans validation humaine explicite.
