# Lab 09 — Cluster Kubernetes

> **Durée :** 90 min · **Modules requis :** [04](../../modules/04-skills/),
> [08](../../modules/08-sous-agents/) · **Outils :** `k3d`, `kubectl`, `docker`
> · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Monter un cluster k3d, y déployer l'application avec des manifestes corrects (probes, limites,
ingress), puis **diagnostiquer un pod en échec** avec un sous-agent spécialisé.

Le diagnostic est le cœur du lab : c'est le geste Ops le plus fréquent, et celui où l'agent fait
gagner le plus de temps — à condition d'être cadré pour ne rien modifier.

## 2. Pré-requis

- [Lab 08](../lab-08-docker/) terminé : les images sont construites localement.

```bash
k3d version && kubectl version --client && docker version
```

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Skill** `k8s-bootstrap` | Créer le cluster, importer les images, appliquer les manifestes |
| **Sous-agent** `k8s-debug-pod` | Diagnostiquer sans polluer la session, et sans rien modifier |
| **Commande perso** `/ops-doctor` | État de santé en lecture seule |
| **Hook** `guard-destructive` | `kubectl delete ns` bloqué |

---

## 4. Déroulé pas-à-pas

### Étape 1 — Le cluster (15 min)

```text
> /plan Génère k8s/k3d-cluster.yaml : cluster `ecom-lab`, 1 serveur + 2 agents, registre
  local, ingress Traefik, ports 80 et 443 mappés sur l'hôte.
```

```bash
k3d cluster create --config k8s/k3d-cluster.yaml
kubectl get nodes
```

Importez vos images du lab précédent :

```bash
for s in catalog ordering gateway web; do
  k3d image import ecommerce-$s:latest -c ecom-lab
done
```

### Étape 2 — Les manifestes (25 min)

```text
> /plan Génère les manifestes k8s/ pour les quatre services : namespace `ecommerce`,
  un Deployment et un Service par service, un Ingress vers le gateway.
  Contraintes non négociables :
  - probes liveness ET readiness sur chaque Deployment, avec des chemins distincts
    (/alive pour liveness, /health pour readiness) ;
  - requests et limits CPU/mémoire sur chaque conteneur ;
  - `imagePullPolicy: IfNotPresent` (images importées localement) ;
  - securityContext : runAsNonRoot, pas d'escalade de privilèges ;
  - le service discovery passe par les variables services__<nom>__http__0.
```

```bash
kubectl apply -f k8s/
kubectl get pods -n ecommerce -w
```

**Avant d'aller plus loin, faites expliquer :**

```text
> Explique-moi la différence entre la probe liveness et la probe readiness sur ordering-api,
  et ce qui se passe concrètement si j'utilise le même chemin pour les deux.
```

> C'est l'erreur de configuration la plus courante en Kubernetes : une liveness probe qui teste une
> dépendance externe transforme une indisponibilité temporaire en redémarrage en boucle.

### Étape 3 — Le sous-agent de diagnostic (15 min)

Créez `.claude/agents/k8s-debug-pod.md` — méthode et garde-fous dans
[`solution/.claude/skills/k8s-debug-pod/SKILL.md`](solution/.claude/skills/k8s-debug-pod/SKILL.md).

Points obligatoires : `tools: Bash, Read, Grep, Glob` (pas d'écriture), `kubectl logs --previous`
avant les logs courants, et **jamais** l'affichage d'un Secret.

### Étape 4 — Casser, puis diagnostiquer (20 min)

Trois pannes à provoquer, une par une. À chaque fois, demandez le diagnostic **sans dire ce que vous
avez fait**.

**Panne A — image inexistante**
```bash
kubectl set image deployment/catalog-api catalog=ecommerce-catalog:v99 -n ecommerce
```
```text
> Le service catalog ne répond plus. Diagnostique.
```
Attendu : `ImagePullBackOff`, tag inexistant, correctif = revenir au tag valide.

**Panne B — mémoire insuffisante**
```bash
kubectl set resources deployment/ordering-api -n ecommerce --limits=memory=16Mi
```
```text
> Le pod ordering redémarre en boucle. Diagnostique.
```
Attendu : `OOMKilled`, relevé dans `Last State`, correctif = limite réaliste.

**Panne C — readiness mal configurée**
```bash
kubectl patch deployment gateway -n ecommerce --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/nope"}]'
```
```text
> Le gateway ne reçoit jamais de trafic. Diagnostique.
```
Attendu : `Readiness probe failed: 404`, correctif = chemin correct.

Restaurez entre chaque :

```bash
kubectl rollout undo deployment/<nom> -n ecommerce
```

> **Ce qu'il faut observer.** À chaque fois, le sous-agent doit citer **la preuve** (la ligne d'event
> ou de log) avant de conclure. Un diagnostic sans preuve citée est une hypothèse déguisée — et c'est
> exactement ce qu'on ne veut pas en astreinte.

### Étape 5 — La commande de santé (10 min)

Reprenez `/ops-doctor` du [module 03](../../modules/03-commandes-personnalisees/) et lancez-la sur le
cluster réel. Ajustez le prompt jusqu'à obtenir un rapport que vous liriez vraiment à 3 h du matin :
court, factuel, sans bruit.

### Étape 6 — Nettoyer (5 min)

```text
> Supprime le namespace ecommerce
```

Refus attendu — le hook fait son travail. Vous supprimez vous-même :

```bash
k3d cluster delete ecom-lab
```

---

## 5. Livrable

```
k8s/
├── k3d-cluster.yaml
├── namespace.yaml
├── catalog.yaml · ordering.yaml · gateway.yaml · web.yaml
└── ingress.yaml
.claude/skills/k8s-bootstrap/SKILL.md
.claude/agents/k8s-debug-pod.md
.claude/commands/ops-doctor.md
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| Aucune suppression de namespace par l'agent (R2) | Hook `guard-destructive` |
| Le diagnostic ne modifie rien | Sous-agent sans `Write`/`Edit` |
| Aucun Secret affiché | Inscrit dans les garde-fous du sous-agent |
| Toute conclusion est étayée | Format de sortie imposant la preuve |
| Cluster local uniquement | k3d ; aucun `kubeconfig` d'entreprise |

## 7. Pour aller plus loin

- Ajoutez un **HPA** et faites-le déclencher avec un test de charge.
- Ajoutez des **NetworkPolicies** (deny par défaut) et faites vérifier les flux autorisés.
- Validez les manifestes avec `kubeconform` et des policies `conftest` (OPA).
- Faites générer un **runbook d'astreinte** pour chacune des trois pannes rejouées.

## Corrigé

```bash
cp -r labs/lab-09-kubernetes/solution/k8s ~/lab-ecommerce/
cp -r labs/lab-09-kubernetes/solution/.claude/skills/* ~/lab-ecommerce/.claude/skills/
```
