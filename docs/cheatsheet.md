# Cheat-sheet Claude Code — mémo Ops

À garder ouvert pendant toute la formation. Version de référence : **Claude Code 2.1.x**.
La liste exacte des commandes de *votre* version s'obtient en tapant `/` dans une session.

---

## Lancer l'agent

| Commande | Effet |
|---|---|
| `claude` | Session interactive dans le dossier courant |
| `claude "consigne"` | Démarre en exécutant immédiatement ce prompt |
| `claude -p "consigne"` | **Headless** : exécute, imprime, rend la main — pour les scripts et la CI |
| `claude -c` | Continue la dernière conversation de ce dossier |
| `claude -r` | Reprend une session précédente (sélecteur) |
| `claude mcp` | Gère les serveurs MCP hors session |
| `claude doctor` / `claude update` | Diagnostic / mise à jour |

## Préfixes de saisie

| Préfixe | Effet | Exemple Ops |
|:---:|---|---|
| `@` | Référencer un fichier ou dossier (l'agent le lit) | `Analyse @k8s/ordering.yaml` |
| `!` | Exécuter une commande shell, sa sortie entre en contexte | `!kubectl get pods -n ecommerce` |
| `#` | Ajouter une note durable à la mémoire (`CLAUDE.md`) | `# toujours lancer terraform plan avant apply` |
| `/` | Ouvrir le menu des commandes | `/permissions` |

---

## Commandes natives, par intention

### Se repérer et diagnostiquer
| Commande | Effet |
|---|---|
| `/help` | Aide et liste des commandes |
| `/status` | Version, modèle, compte, connectivité |
| `/doctor` | Diagnostic install & config |
| `/context` | **Ce que l'agent a réellement en mémoire de travail**, et ce qui le remplit |
| `/usage` | Coût de session et limites du plan |
| `/insights` | Statistiques d'usage et d'impact |

### Cadrer le travail
| Commande | Effet | Réflexe Ops |
|---|---|---|
| `/init` | Analyse le dépôt et génère un `CLAUDE.md` | **Tout premier geste** sur un repo |
| `/goal` | Fixe l'objectif de la session ; l'agent garde le cap | Avant un chantier long (migration, incident) |
| `/memory` | Édite les fichiers mémoire projet et perso | Pour inscrire une règle d'équipe |
| `/add-dir <chemin>` | Ouvre un dossier supplémentaire à la session | Repo d'infra séparé du repo applicatif |
| `/model` · `/effort` | Choisit le modèle / le niveau de raisonnement | `/effort high` avant une revue d'IaC |
| `/plan` | Mode Plan : l'agent propose, vous validez **avant** toute action | **Systématique avant une action infra** |

### Piloter la session
| Commande | Effet |
|---|---|
| `/btw` | Glisser une remarque ou un complément **sans casser la tâche en cours** |
| `/rewind` | Revenir à un point antérieur (code et/ou conversation) — le *checkpoint* |
| `/compact` | Résume la conversation pour libérer du contexte |
| `/clear` | Repart d'une conversation vide (la mémoire projet est conservée) |
| `/resume` | Reprend une conversation précédente |
| `/export` · `/rename` | Exporte / renomme la session |
| `/todos` | Suit la liste de tâches de l'agent |

### Sécurité et garde-fous
| Commande | Effet |
|---|---|
| `/permissions` | Règles **allow / ask / deny** par outil et par commande |
| `/hooks` | Hooks actuellement actifs (et leur déclencheur) |
| `/security-review` | Analyse de sécurité des changements en cours |

### Qualité
| Commande | Effet |
|---|---|
| `/code-review [niveau] [--fix]` | Revue du diff : bugs, simplifications ; `--fix` applique |
| `/review [PR]` | Revue d'une pull request dans la session |
| `/ultrareview` | Revue approfondie multi-agents |

### Extensions
| Commande | Effet |
|---|---|
| `/skills` | Liste les skills disponibles |
| `/agents` | Gère les sous-agents spécialisés |
| `/mcp` | Serveurs MCP : statut, authentification, outils exposés |
| `/plugin` | Installe / gère les plugins et les marketplaces |
| `/output-style` · `/statusline` | Style de sortie / barre de statut |

### Aller plus loin
| Commande | Effet | Cas Ops |
|---|---|---|
| `/loop [intervalle] <prompt>` | Rejoue un prompt à intervalle régulier | Surveiller un déploiement, attendre une CI |
| `/workflows` | Orchestrations multi-agents | Revue d'un gros diff d'infra |
| `/remote-control` | Piloter la session depuis un autre appareil | Suivre une migration depuis son téléphone |
| `/teleport` | Reprendre le travail dans un autre environnement | Poste → VM de lab |
| `/bashes` | Commandes shell lancées en arrière-plan | `kubectl logs -f` pendant qu'on travaille |
| `/fast` | Sortie accélérée (sur modèles compatibles) | Itérations courtes |

---

## Où vivent les fichiers

```
<projet>/
├── CLAUDE.md                          # contexte projet, versionné, lu à chaque session
└── .claude/
    ├── settings.json                  # partagé (hooks, permissions) — versionné
    ├── settings.local.json            # local à vous — jamais versionné
    ├── commands/<nom>.md              # /nom  → commande personnalisée
    ├── skills/<nom>/SKILL.md          # skill (runbook exécutable)
    ├── agents/<nom>.md                # sous-agent spécialisé
    └── hooks/<script>.sh              # scripts de garde-fous
<projet>/.mcp.json                     # serveurs MCP du projet — versionné

~/.claude/                             # équivalents personnels (tous projets)
```

---

## Les 7 réflexes Ops

1. **`/init` d'abord.** Un agent sans contexte projet réinvente vos conventions à chaque session.
2. **`/plan` avant toute action d'infra.** On lit le plan, puis on autorise.
3. **Un garde-fou = un hook, jamais un prompt.** Le modèle peut ignorer une consigne ; un hook non.
4. **`/context` quand ça dérive.** Une réponse incohérente est presque toujours un contexte saturé.
5. **`/rewind` plutôt que « annule ».** Le checkpoint est fiable, la demande verbale ne l'est pas.
6. **Un bon prompt utilisé deux fois devient un skill.** Sinon vous le retaperez cinquante fois.
7. **Jamais de secret dans un prompt.** Variables d'environnement, coffre, et hook anti-secret.
