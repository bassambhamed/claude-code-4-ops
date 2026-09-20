# Capstone — la chaîne de bout en bout

> **Durée :** 3 h (J3 après-midi) · **Pré-requis :** tous les modules, labs 01 à 12 parcourus
> · **Format :** binômes · **Restitution :** 10 min par binôme

---

## 1. Objectif

Livrer l'application fil rouge **du provisionnement à la production observée**, en n'utilisant que
Claude Code et les briques que vous avez construites pendant la formation.

Ce n'est pas un exercice de plus : c'est la démonstration que les briques **tiennent ensemble**. Et
c'est le moment où l'on mesure ce que l'outillage a réellement changé.

## 2. Règles du jeu

1. **Aucune commande tapée à la main** sans être passée par un `/plan` ou un skill — sauf les actions
   que vos garde-fous vous obligent à exécuter vous-même (c'est le but).
2. **Tous les garde-fous actifs** du [Lab 04](../lab-04-securite-secrets/), vérifiés par `/hooks` en
   début de session.
3. **Tout ce qui est produit est versionné** : IaC, manifestes, charts, workflows, skills, hooks.
4. **Chaque décision d'infrastructure est justifiée** par écrit, dans le dépôt.
5. **Rien en production, rien de réel** : k3d, Multipass et provider Docker local uniquement.

## 3. La chaîne à dérouler

```
  1. Provisionner     Multipass + Terraform                 [Labs 05, 06]
          │
  2. Configurer       Ansible — Docker, durcissement, UFW    [Lab 07]
          │
  3. Conteneuriser    Dockerfiles multi-stage + scan Trivy   [Lab 08]
          │
  4. Orchestrer       Cluster k3d + manifestes               [Lab 09]
          │
  5. Packager         Chart Helm multi-environnements        [Lab 10]
          │
  6. Livrer           CI/CD avec gate manuel                 [Lab 02]
          │
  7. Tester           Unitaires, intégration, charge         [Lab 03]
          │
  8. Observer         Prometheus / Grafana + alertes         [Lab 11]
          │
  9. Sécuriser        gitleaks, trivy, policies, audit       [Lab 04]
          │
 10. Éprouver         Incident simulé + post-mortem          [Lab 12]
          │
 11. Industrialiser   Plugin d'équipe publié                 [Module 07]
```

## 4. Déroulé (3 h)

| Temps | Phase | Attendu |
|:---:|---|---|
| 0:00–0:15 | **Cadrage** | `/goal`, `/hooks` vérifiés, répartition du binôme, plan écrit |
| 0:15–1:00 | **Socle** | Étapes 1 à 3 : VM provisionnées, configurées, images construites et scannées |
| 1:00–1:45 | **Déploiement** | Étapes 4 à 6 : cluster, chart, pipeline avec gate |
| 1:45–2:15 | **Exploitation** | Étapes 7 à 9 : tests, observabilité, sécurité |
| 2:15–2:40 | **Épreuve** | Étape 10 : un binôme casse, l'autre diagnostique et rédige le post-mortem |
| 2:40–3:00 | **Industrialisation & restitution** | Étape 11 + préparation de la présentation |

> **Conseil de rythme :** si vous prenez du retard, sacrifiez les étapes 1 et 2 (Multipass,
> Ansible) et partez directement du cluster k3d. Ne sacrifiez **jamais** les étapes 9 et 10 : les
> garde-fous et l'incident sont le cœur du message.

## 5. L'épreuve croisée

À 2:15, échangez les postes. Le binôme adverse provoque **une panne de son choix** dans votre
environnement, sans vous dire laquelle.

Vous disposez de 25 minutes pour :

1. Détecter (via vos dashboards et alertes — pas parce qu'on vous a prévenu).
2. Diagnostiquer avec votre sous-agent `incident-analyst`.
3. Rétablir — en respectant vos propres garde-fous.
4. Produire le post-mortem avec votre skill `postmortem`.

**Ce qui est évalué ici :** votre outillage vous a-t-il servi sous pression, ou vous a-t-il gêné ?
Les deux réponses sont instructives — et la seconde vous dit exactement quoi corriger lundi.

## 6. Livrables

```
<votre-dépôt>/
├── CLAUDE.md                       # contexte et conventions d'équipe
├── .claude/
│   ├── settings.json               # permissions + hooks
│   ├── commands/ · skills/ · agents/ · hooks/
├── .mcp.json                       # serveurs MCP, sans aucun secret
├── terraform/ · ansible/ · k8s/ · helm/ · observability/
├── .github/workflows/              # ci, cd (avec gate), security, infra-review
├── docs/
│   ├── decisions.md                # les choix d'infrastructure et leur justification
│   └── postmortems/                # le post-mortem de l'épreuve croisée
└── plugins/<votre-toolkit>/        # le plugin d'équipe, validé et installable
```

## 7. Restitution — 10 minutes par binôme

1. **La chaîne** (3 min) — démonstration en direct : un changement de code jusqu'au cluster.
2. **Les garde-fous** (3 min) — montrez un blocage réel, pas un slide. Expliquez pourquoi ce
   contrôle est au bon niveau.
3. **L'incident** (2 min) — la panne, le diagnostic, le MTTR constaté.
4. **Le plan** (2 min) — vos 3 cas d'usage prioritaires, vos KPI, votre plan 30/60/90 jours.

## 8. Grille d'évaluation

| Critère | Poids | Ce qu'on regarde |
|---|:---:|---|
| La chaîne fonctionne de bout en bout | 25 % | Un changement atteint le cluster, l'application répond |
| Les garde-fous sont actifs et **testés** | 25 % | Un blocage réel est démontré, pas décrit |
| Qualité des artefacts produits | 20 % | IaC lisible, manifestes conformes, charts paramétrés |
| Diagnostic et post-mortem | 15 % | Cause racine étayée, actions avec propriétaire et échéance |
| Capitalisation | 15 % | Plugin valide, installable, réellement réutilisable |

> Un binôme qui livre une chaîne **partielle mais correctement cadrée** passe devant un binôme qui
> livre tout sans garde-fou. C'est le message central de la formation.

## 9. Le plan 30/60/90 jours

Le vrai livrable de la formation n'est pas ce dépôt : c'est ce que vous ferez la semaine prochaine.

| Horizon | Attendu | Exemple |
|---|---|---|
| **30 jours** | Un `CLAUDE.md` et deux skills sur **un** dépôt réel ; les trois hooks de garde | « Le dépôt IaC a ses conventions et son anti-secret » |
| **60 jours** | Le plugin d'équipe publié sur un marketplace interne ; MCP GitHub branché | « Les 12 ingénieurs ont la même configuration » |
| **90 jours** | L'agent dans la CI en revue d'infra ; KPI mesurés (MTTD, MTTR, délai de revue) | « On sait chiffrer ce que ça nous a apporté » |

**Les trois questions à traiter dans votre plan :**

1. Quel est votre cas d'usage n°1 — celui qui vous fait perdre le plus de temps aujourd'hui ?
2. Quel garde-fou doit être en place **avant** de lancer ce cas d'usage sur un dépôt réel ?
3. Qui, dans l'équipe, est propriétaire du `CLAUDE.md` et du plugin ?
