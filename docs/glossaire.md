# Glossaire

Les termes que vous croiserez pendant la formation, expliqués pour un profil Ops.

---

## Intelligence artificielle générative

**LLM (Large Language Model)** — Un modèle entraîné à **prédire le prochain morceau de texte** le plus
plausible. Il ne « comprend » pas votre infrastructure : il produit la suite la plus vraisemblable
compte tenu de ce que vous lui avez donné. Toute la qualité vient donc de ce que vous lui donnez.

**Token** — L'unité de découpage du texte (≈ 4 caractères en français). Les coûts, les limites et la
fenêtre de contexte se comptent en tokens, pas en lignes.

**Fenêtre de contexte** — La quantité de texte que le modèle peut prendre en compte en une fois.
Au-delà, il faut résumer (`/compact`) ou repartir (`/clear`). Un contexte saturé est la cause n°1 des
réponses incohérentes.

**Hallucination** — Une affirmation fausse énoncée avec assurance : un flag `kubectl` qui n'existe
pas, une ressource Terraform imaginaire. D'où la règle : **on vérifie, on ne fait pas confiance**.

**Prompt** — L'instruction donnée au modèle. Un bon prompt Ops porte : le **rôle**, le **contexte**,
la **tâche**, les **contraintes** et le **format de sortie** attendu.

**Agent de coding** — Un LLM équipé d'**outils** (lire un fichier, lancer une commande, éditer du
code) et d'une **boucle** : il agit, observe le résultat, corrige. C'est ce que fait Claude Code.

---

## Claude Code — les briques

**Session** — Une conversation avec l'agent, attachée à un dossier. Elle a un contexte, un historique
et des checkpoints.

**Commande** (`/quelque-chose`) — Une instruction adressée au **harnais** (le programme), pas au
modèle. Certaines sont **natives** (`/init`, `/rewind`), d'autres **personnalisées** (un fichier
Markdown dans `.claude/commands/`).

**`CLAUDE.md`** — Le fichier de contexte permanent d'un projet. Lu automatiquement à chaque session.
C'est là que vivent vos conventions, vos commandes de build et vos interdits d'équipe.

**Mémoire** — L'ensemble des `CLAUDE.md` chargés : projet (versionné, partagé) et personnel
(`~/.claude/`, pour vous seul). Le préfixe `#` y ajoute une note à la volée.

**Skill** — Un **runbook exécutable** : un dossier `.claude/skills/<nom>/SKILL.md` décrivant une
procédure. L'agent le charge **quand sa description correspond à la demande** — on ne l'appelle pas
forcément à la main. C'est le format de capitalisation d'équipe le plus important.

**Hook** — Un **script déclenché automatiquement** par le harnais sur un événement (`PreToolUse`,
`PostToolUse`, `SessionStart`, `Stop`…). Il est **déterministe** : c'est le programme qui l'exécute,
pas le modèle qui décide. C'est l'outil des garde-fous et de l'audit.

**Permissions** — Les règles `allow` / `ask` / `deny` qui déterminent ce que l'agent peut lancer seul,
ce qui demande confirmation, et ce qui est interdit. Se règlent par `/permissions` ou
`.claude/settings.json`.

**MCP (Model Context Protocol)** — Un **protocole ouvert** qui branche l'agent sur des outils et des
données externes (GitHub, Grafana, Jira, une base de données). Un **serveur MCP** expose des outils ;
l'agent les appelle comme les siens. Se configure dans `.mcp.json` ou par `claude mcp`.

**Plugin** — Un **paquet distribuable** qui regroupe commandes, skills, hooks, sous-agents et serveurs
MCP. C'est le format de partage : un `plugin.json` + les dossiers correspondants.

**Marketplace** — Un catalogue de plugins. Il en existe un **officiel**
(`anthropics/claude-plugins-official`, 300+ plugins éditeurs) et vous pouvez en héberger un
**interne** — un simple dépôt Git avec un `.claude-plugin/marketplace.json`.

**Sous-agent** — Un agent **spécialisé** à qui l'agent principal délègue une tâche, avec ses propres
instructions, ses propres outils et **son propre contexte**. Il rend un résultat, pas ses 4 000 lignes
de logs intermédiaires. Défini dans `.claude/agents/<nom>.md`.

**Mode headless** (`claude -p`) — L'agent exécuté **sans interface** : il reçoit un prompt, agit,
imprime le résultat et rend la main. C'est ce qui permet de l'appeler depuis un script ou une CI.

**Checkpoint / `/rewind`** — Un point de reprise automatique. `/rewind` restaure l'état du code et/ou
de la conversation à un instant antérieur — le « Ctrl+Z » fiable de la session.

**Mode Plan** (`/plan`) — L'agent propose un plan d'action et **attend votre validation** avant
d'exécuter quoi que ce soit. Réflexe obligatoire avant toute opération d'infrastructure.

---

## Ops & infrastructure — rappels utiles

**IaC (Infrastructure as Code)** — Décrire l'infrastructure dans des fichiers versionnés
(Terraform, Ansible, manifests K8s) plutôt que par des actions manuelles.

**Idempotence** — Propriété d'une opération qui, rejouée, laisse le système dans le même état.
Critère de qualité central d'un playbook Ansible.

**cloud-init** — Le standard de configuration d'une VM à son premier démarrage (paquets, utilisateurs,
clés SSH). Utilisé au Lab 05 avec Multipass.

**k3d** — Kubernetes léger (k3s) exécuté dans des conteneurs Docker : un cluster multi-nœuds local en
quelques secondes. Utilisé aux Labs 09 à 11.

**Chart Helm** — Le format de packaging Kubernetes : des templates + un `values.yaml` paramétrable par
environnement.

**Probe liveness / readiness** — Les sondes Kubernetes : « le conteneur est-il vivant ? » et « peut-il
recevoir du trafic ? ». Confondre les deux est une cause classique de redémarrages en boucle.

**Post-mortem blameless** — Compte rendu d'incident centré sur les **causes systémiques**, jamais sur
les personnes. Livrable du Lab 12.

**DORA** — Règlement européen sur la résilience opérationnelle numérique du secteur financier. Impose
notamment la **traçabilité** et la **maîtrise** des outils utilisés en production — d'où l'insistance
de cette formation sur les hooks d'audit.

**MTTD / MTTR** — Temps moyen de **détection** / de **rétablissement** d'un incident. Les KPI par
lesquels on mesure l'apport réel de l'outillage.

---

## Les confusions les plus fréquentes

| On confond souvent… | …alors que |
|---|---|
| **Commande** et **skill** | La commande est un raccourci que *vous* invoquez ; le skill est une procédure que *l'agent* mobilise quand elle est pertinente. |
| **Skill** et **sous-agent** | Le skill est un *mode d'emploi* exécuté dans votre session ; le sous-agent est un *exécutant* avec son propre contexte. |
| **Hook** et **prompt** | Le hook est exécuté par le programme, toujours ; le prompt est interprété par le modèle, généralement. |
| **MCP** et **plugin** | Le MCP *connecte* à un outil externe ; le plugin *distribue* un ensemble de configurations (dont, éventuellement, des serveurs MCP). |
| **`/clear`** et **`/compact`** | `/clear` oublie tout ; `/compact` résume et garde l'essentiel. |
| **`CLAUDE.md`** et **`settings.json`** | Le premier informe le modèle ; le second contraint le harnais. |
