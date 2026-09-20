# Module 09 — Automatisation & CI

> **Durée :** 40 min · **Pré-requis :** [Module 08](../08-sous-agents/)
> · **Suivant :** les [labs](../../labs/) — l'application à vos cas d'usage

---

## 1. La limite

Tout ce que vous avez construit suppose un humain devant un terminal. Or les besoins Ops les plus
répétitifs se produisent **quand personne ne regarde** : une PR ouverte à 23 h, un rollout à
surveiller pendant une réunion, un scan de conformité hebdomadaire.

## 2. Le concept — l'agent comme commande Unix

```bash
claude -p "ta consigne"
```

En mode **headless** (`-p`, *print*), Claude Code se comporte comme n'importe quel outil en ligne de
commande : il prend une entrée, agit, écrit sur `stdout`, et rend la main. Il s'enchaîne donc avec un
pipe, un `cron`, un `Makefile` ou un job de CI.

```
  cat plan.txt | claude -p "Résume les changements destructifs" > revue.md
```

**Le renversement de perspective :** jusqu'ici vous pilotiez l'agent. À partir d'ici, **vos systèmes**
le pilotent.

### Les trois degrés d'automatisation

| Degré | Mécanisme | L'agent… | Risque |
|:---:|---|---|---|
| 1 | `/loop` en session | observe et rapporte pendant que vous travaillez | Nul |
| 2 | `claude -p` dans un script ou un job CI | analyse et **produit un artefact** (rapport, commentaire) | Maîtrisé |
| 3 | Agent qui **modifie** un système sans revue | corrige, déploie, supprime | **Hors cadre de cette formation** |

Le degré 3 est exclu par la règle R2 des [garde-fous](../../docs/garde-fous.md). En production
bancaire, un agent autonome sur des systèmes réels demande un cadre de gouvernance qui dépasse
largement un choix d'outillage.

## 3. Anatomie

### 3.1 `/loop` — surveiller pendant qu'on travaille

```text
> /loop 3m Vérifie le rollout du deployment ordering-api dans le namespace ecommerce.
  Signale tout pod qui redémarre ou toute probe en échec. N'entreprends aucune correction.
```

Sans intervalle, l'agent choisit lui-même son rythme selon ce qu'il attend. Utile pour surveiller un
déploiement, attendre une CI, suivre une migration longue.

**Toujours formuler une boucle en lecture seule.** « Signale » et non « corrige ».

### 3.2 Mode headless — les options qui comptent

```bash
claude -p "Résume les changements d'infrastructure de ce diff" \
  --output-format json \
  --allowedTools "Read,Grep,Glob" \
  --permission-mode plan
```

| Option | Rôle | Pourquoi c'est important en CI |
|---|---|---|
| `-p` | Mode non interactif | Sans lui, le job attend indéfiniment |
| `--output-format json` | Sortie structurée | Exploitable par `jq` dans la suite du pipeline |
| `--allowedTools` | **Liste blanche d'outils** | Un job de revue n'a aucune raison d'écrire |
| `--permission-mode` | Comportement face aux permissions | Aucun humain ne peut répondre « oui » |

> **La règle d'or de la CI :** en environnement non interactif, **aucune demande de permission ne
> peut être satisfaite**. Donnez donc une liste blanche restrictive plutôt que de laisser le job
> échouer — ou pire, de désactiver les garde-fous pour qu'il passe.

### 3.3 Dans un pipeline GitHub Actions

```yaml
name: Revue d'infrastructure assistée
on:
  pull_request:
    paths: ['terraform/**', 'k8s/**', 'helm/**', '.github/workflows/**']

permissions:
  contents: read
  pull-requests: write

jobs:
  infra-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }

      - name: Installer Claude Code
        run: curl -fsSL https://claude.ai/install.sh | bash

      - name: Revue du diff d'infrastructure
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          git diff origin/${{ github.base_ref }}...HEAD -- terraform/ k8s/ helm/ > infra.diff
          claude -p "Relis ce diff d'infrastructure. Signale : changements destructifs,
            secrets en clair, absence de probes ou de limites de ressources, règles réseau
            trop permissives. Rends un tableau Markdown, puis un verdict SÛR / À REVOIR /
            BLOQUANT. N'invente aucun fichier." \
            --allowedTools "Read,Grep,Glob" < infra.diff > review.md

      - name: Publier la revue en commentaire
        run: gh pr comment ${{ github.event.pull_request.number }} --body-file review.md
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Ce que fait ce job — et ce qu'il ne fait pas.** Il produit un **commentaire**. Il ne corrige rien,
ne merge rien, ne déploie rien. La décision reste humaine : l'agent est un relecteur supplémentaire,
pas un approbateur.

### 3.4 Le script d'astreinte

```bash
#!/usr/bin/env bash
# Rapport de santé quotidien — lecture seule, envoyé par mail.
set -euo pipefail

{
  kubectl get pods -A -o wide
  kubectl get events -A --sort-by=.lastTimestamp | tail -50
  kubectl top nodes 2>/dev/null || true
} > /tmp/cluster-state.txt

claude -p "À partir de cet état de cluster, produis un rapport de santé : anomalies détectées,
  tendances inquiétantes, et les 3 points à surveiller aujourd'hui. Sois factuel et bref.
  N'entreprends aucune action." \
  --allowedTools "Read" < /tmp/cluster-state.txt > /tmp/rapport.md

mail -s "Santé cluster $(date +%F)" ops@exemple.com < /tmp/rapport.md
```

---

## 4. Mini-lab — de la boucle au pipeline (20 min)

### Partie A — `/loop` (5 min)

```bash
cd ../../ecommerce-app
claude
```
```text
> /loop 2m Vérifie que la solution compile (dotnet build ECommerce.slnx) et signale toute
  régression. Ne corrige rien.
```

Laissez passer deux itérations, puis arrêtez. Vous avez un moniteur de build, sans script.

### Partie B — headless (7 min)

```bash
claude -p "Décris l'architecture de cette application en 5 lignes." --allowedTools "Read,Grep,Glob"
```

Puis en pipe, avec sortie structurée :

```bash
git diff HEAD~1 2>/dev/null | claude -p "Résume ce diff en 3 points" --output-format json | jq -r '.result'
```

Testez maintenant la restriction :

```bash
claude -p "Crée un fichier test.txt contenant bonjour" --allowedTools "Read,Grep"
```

Il ne peut pas. **Vous venez de vérifier votre garde-fou de CI** — la liste blanche est une
contrainte technique, pas une consigne.

### Partie C — le job de revue (8 min)

Créez `.github/workflows/infra-review.yml` avec le contenu de la section 3.3. Faites-le relire :

```bash
claude
```
```text
> /security-review
> Relis @.github/workflows/infra-review.yml : ce job peut-il modifier le dépôt, merger une PR,
  ou exposer un secret dans les logs ?
```

C'est le bon réflexe : **on fait auditer le pipeline qui appelle l'agent**, au même titre que le
reste de la chaîne.

---

## 5. Erreurs fréquentes

| Erreur | Conséquence | Correctif |
|---|---|---|
| Oublier `-p` en CI | Le job attend un humain, puis expire | Toujours `-p` en non interactif |
| Pas de `--allowedTools` | Le job échoue sur une demande de permission | Liste blanche explicite |
| Élargir les permissions pour « faire passer » le job | Garde-fous contournés | Corriger la tâche, pas les droits |
| Clé d'API dans le workflow | Secret exposé dans les logs | `secrets.` de la forge |
| Boucle qui **corrige** en autonomie | Action non revue en production | Boucles en lecture seule (R2) |
| Faire décider un job (merge, déploiement) | Décision non tracée, non humaine | L'agent commente, l'humain décide |
| Sortie texte parsée à la main | Pipeline fragile | `--output-format json` + `jq` |

---

## 6. Checklist de sortie

- [ ] J'ai fait tourner une boucle `/loop` en lecture seule.
- [ ] Je sais appeler `claude -p` dans un pipe et exploiter `--output-format json`.
- [ ] J'ai vérifié expérimentalement l'effet de `--allowedTools`.
- [ ] J'ai un job de CI qui **commente** une PR sans rien modifier.
- [ ] Je sais énoncer pourquoi le degré 3 d'automatisation est hors cadre ici.

---

## Et maintenant

Les dix briques sont posées. La suite, ce sont les **[labs](../../labs/)** : les mêmes briques,
appliquées à vos cas d'usage réels — Git, CI/CD, Terraform, Kubernetes, observabilité, incidents,
sécurité — puis le [capstone](../../labs/capstone/) qui les enchaîne de bout en bout.
