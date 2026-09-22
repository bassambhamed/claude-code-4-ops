# Lab 01 — Git & GitHub assistés

> **Durée :** 60 min · **Modules requis :** [00](../../modules/00-prise-en-main/) →
> [05](../../modules/05-hooks/) · **Outils :** `git`, `gh` · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Partir d'une application non versionnée et arriver à une **Pull Request documentée**, en faisant
faire le travail répétitif par l'agent — tout en garantissant techniquement qu'aucun secret ne peut
être committé.

À la fin, vous aurez trois skills réutilisables, un hook de sécurité actif, et une PR propre sur
GitHub.

## 2. Pré-requis

**Installer la CLI GitHub (`gh`).** C'est l'outil en ligne de commande officiel de GitHub : l'agent
s'en sert pour créer le dépôt distant et ouvrir la Pull Request. Vérifiez d'abord qu'elle n'est pas
déjà là :

```bash
git --version        # Git est indispensable
gh --version         # si « command not found » : installer gh ci-dessous
```

| Système | Installation |
|---|---|
| macOS | `brew install gh` |
| Windows | `winget install --id GitHub.cli` (puis rouvrir le terminal) |
| Ubuntu / Debian | Dépôt APT officiel : [cli.github.com — Linux](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) |

> Sur un poste d'entreprise, `gh` peut devoir passer par le catalogue logiciel interne ou une demande
> au support : anticipez-le **avant** la séance. Voir aussi [`docs/prerequis.md`](../../docs/prerequis.md).

**Se connecter à GitHub avec `gh`.** Une seule fois par poste :

```bash
gh auth login        # GitHub.com → HTTPS → navigateur
gh auth status       # doit afficher un compte authentifié
```

`gh auth login` ouvre le navigateur, vous saisissez le code à usage unique affiché dans le terminal,
et `gh` conserve la session. Aucun token à copier-coller ici : celui de l'étape 7 est distinct.

Travaillez sur votre copie :

```bash
cp -r ecommerce-app ~/lab-ecommerce && cd ~/lab-ecommerce
```

> Un compte GitHub **personnel ou de test**. Jamais l'organisation de production.

## 3. Briques mobilisées

| Brique | Rôle dans ce lab |
|---|---|
| **Skills** | `init-repo`, `git-commit`, `open-pr` — trois procédures capitalisées |
| **Hooks** | `secret-scan` en `PreToolUse` : le commit d'un secret devient techniquement impossible |
| **MCP** | Serveur GitHub : lire les PR, les issues, l'état des Actions |
| **Commandes** | `/init`, `/security-review`, `/plan` |

**Pourquoi ce lab en premier :** le workflow Git est le geste le plus répété d'une équipe. C'est là
que la capitalisation rapporte le plus vite, et c'est le terrain idéal pour voir un hook bloquer une
vraie erreur.

---

## 4. Déroulé pas-à-pas

### Étape 1 — Donner un contexte au projet (5 min)

```bash
claude
```
```text
> /init
```

Ouvrez le `CLAUDE.md` produit et ajoutez vos conventions Git :

```text
> # branches : feat/, fix/, ops/, chore/ — jamais de travail direct sur main
> # commits : Conventional Commits, en anglais, à l'impératif
```

### Étape 2 — Le hook avant tout le reste (10 min)

**On pose le garde-fou avant de commencer à travailler, pas après le premier incident.**

```bash
mkdir -p .claude/hooks
```

Créez `.claude/hooks/secret-scan.sh` ([module 05, §4.2](../../modules/05-hooks/#4-mini-lab--poser-les-trois-garde-fous-25-min)),
puis `chmod +x .claude/hooks/secret-scan.sh`, et câblez-le dans `.claude/settings.json` :

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [
        { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/secret-scan.sh" }
      ]}
    ]
  }
}
```

Vérifiez — **c'est la seule preuve qu'il est actif** :

```text
> /hooks
```

### Étape 3 — Initialiser le dépôt (10 min)

Faites-le d'abord à la main pour comprendre ce que le skill automatisera :

```bash
git init
git branch -M main
git status                 # contrôle visuel : aucun .env, aucun secret
git add .
git commit -m "chore: initial commit of ecommerce app"
gh repo create lab-ecommerce --private --source=. --remote=origin --push
```

Puis capitalisez la procédure dans un skill :

```text
> Crée le skill .claude/skills/init-repo/SKILL.md : il enchaîne git init, contrôle qu'aucun
  fichier sensible n'est indexé, commit initial, création du repo GitHub en privé et push.
  Il doit DEMANDER confirmation avant la création du dépôt distant et avant le push.
```

### Étape 4 — Tester le garde-fou (10 min)

**L'étape la plus importante du lab.**

```bash
cat > appsettings.Local.json <<'EOF'
{ "ConnectionStrings": { "Db": "Server=prod;User=sa;Password=Sup3rS3cret!" } }
EOF
git add appsettings.Local.json
```

```text
> Commite ce fichier de configuration
```

**Le commit doit être refusé**, avec le motif. Observez la réaction de l'agent : il reçoit votre
message sur `stderr` et propose de sortir le secret du code.

Nettoyez :

```bash
git reset appsettings.Local.json && rm appsettings.Local.json
```

> Si le commit **passe**, votre hook n'est pas actif : revenez à l'étape 2 et vérifiez `/hooks`.
> Un garde-fou qu'on n'a pas testé n'est pas un garde-fou.

### Étape 5 — Une modification, un commit propre (10 min)

```text
> /plan Ajoute un endpoint /health/ready à Catalog.Api qui vérifie l'accès au DbContext
```

Validez le plan, laissez-le implémenter, puis :

```text
> Crée le skill .claude/skills/git-commit/SKILL.md : il analyse les changements, propose un
  message Conventional Commits, et demande TOUJOURS validation avant de committer.
> /security-review
```

Puis créez la branche et committez via le skill :

```text
> Crée une branche feat/health-ready et commite ces changements
```

### Étape 6 — La Pull Request (10 min)

```text
> Crée le skill .claude/skills/open-pr/SKILL.md : il pousse la branche et ouvre une PR avec
  un titre clair, une description structurée (contexte, changements, tests, risques) et une
  checklist de revue. Il demande validation avant de pousser. Il ne merge JAMAIS.
> Ouvre la PR pour cette branche
```

Vérifiez sur GitHub : `gh pr view --web`.

### Étape 7 — Brancher le MCP GitHub (10 min)

**Pourquoi.** Jusqu'ici, l'agent parlait à GitHub en lançant des commandes `gh` dans le shell. Le
serveur MCP officiel de GitHub lui donne un accès **direct** à l'API : des outils natifs pour lister
les PR, lire une issue, consulter le diff d'une PR ou l'état des Actions (voir le
[module 06](../../modules/06-mcp/)). Ce serveur est **hébergé par GitHub** : rien à installer.

**7.1 — Créer un token d'accès (sur github.com)**

Le serveur MCP s'authentifie avec un *Personal Access Token* (PAT) que vous créez vous-même :

1. Avatar en haut à droite → **Settings** → tout en bas à gauche : **Developer settings**.
2. **Personal access tokens** → **Fine-grained tokens** → **Generate new token**.
3. Renseignez :

   | Champ | Valeur |
   |---|---|
   | Token name | `claude-lab-01` |
   | Expiration | **7 jours** (la durée de la formation) |
   | Repository access | *Only select repositories* → **le seul dépôt du lab** |
   | Repository permissions | `Metadata`, `Contents`, `Pull requests`, `Issues`, `Actions` : **Read-only** |

4. **Generate token**, puis copiez-le immédiatement : GitHub ne le réaffichera jamais. Un token
   *fine-grained* commence par `github_pat_`.

> **Pourquoi pas un token *classic* avec le scope `repo` ?** Il donnerait lecture **et écriture** sur
> **tous** vos dépôts. Cette étape ne fait que lire : un seul dépôt, lecture seule, expiration courte.
> C'est le principe du **moindre privilège**, attendu en contexte DORA.
>
> Si le dépôt appartient à une organisation avec SSO, cliquez aussi sur **Configure SSO** → *Authorize*
> sur la page du token, sinon les appels seront refusés.

**7.2 — Déclarer le serveur MCP (dans votre terminal)**

```bash
read -s GITHUB_PERSONAL_ACCESS_TOKEN     # collez le token puis Entrée : rien ne s'affiche,
                                         # et il n'apparaît pas dans l'historique du shell
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  -H "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN"
unset GITHUB_PERSONAL_ACCESS_TOKEN
```

Ligne par ligne :

| Élément | Rôle |
|---|---|
| `claude mcp add ... github` | Déclare un serveur MCP nommé `github` |
| `--transport http` + URL | Serveur distant, joint en HTTPS chez GitHub |
| `-H "Authorization: Bearer ..."` | En-tête d'authentification envoyé à chaque appel |

Deux conséquences à connaître :

- **Le token est enregistré en clair** dans votre configuration Claude Code (`~/.claude.json`) : la
  variable est remplacée par sa valeur au moment du `claude mcp add`. D'où l'expiration courte et la
  révocation en fin de lab (7.4).
- **Portée `local` par défaut** : le serveur n'existe que pour vous, dans ce projet. Il n'est **pas**
  partagé avec l'équipe via `.mcp.json` — c'est voulu, puisqu'il contient votre token.

**7.3 — Vérifier et utiliser**

```text
> /mcp
```

Le serveur `github` doit apparaître comme **connected**. Sinon : token mal copié, dépôt non
sélectionné à la création, ou autorisation SSO manquante.

```text
> Résume l'état des PR ouvertes sur ce dépôt et signale celles qui touchent à l'infrastructure.
```

Vérifiez dans la sortie que l'agent appelle des outils `mcp__github__...` et non plus `gh`.

Testez aussi le garde-fou :

```text
> Ajoute un commentaire « LGTM » sur la PR que tu viens d'ouvrir.
```

L'appel doit **échouer** : le token est en lecture seule. C'est la preuve que la limite est
technique, pas seulement une consigne.

**7.4 — En fin de lab : révoquer**

```bash
claude mcp remove github
```

Puis sur GitHub : **Settings → Developer settings → Fine-grained tokens → `claude-lab-01` → Delete**.

---

## 5. Livrable

```
~/lab-ecommerce/
├── CLAUDE.md                              # conventions d'équipe
├── .claude/
│   ├── settings.json                      # hook câblé
│   ├── hooks/secret-scan.sh               # garde-fou testé
│   └── skills/{init-repo,git-commit,open-pr}/SKILL.md
└── (sur GitHub) une PR documentée avec checklist de revue
```

## 6. Garde-fous

| Règle | Mécanisme | Vérifié par |
|---|---|---|
| Aucun secret committé | Hook `secret-scan` (`PreToolUse`) | Étape 4 — test réel |
| Aucun push sans validation | Consigne explicite dans les skills | Étape 6 |
| Aucun merge par l'agent | Interdit dans `open-pr/SKILL.md` | Revue du skill |
| Pas de `--force` | Règle `deny` dans `/permissions` | `/permissions` |
| MCP GitHub en lecture seule | Token *fine-grained* : un dépôt, `Read-only`, 7 jours | Étape 7.3 — écriture refusée |
| Aucun token qui survit au lab | `claude mcp remove` + suppression du token sur GitHub | Étape 7.4 |

> **Attention à la limite du hook de démo :** il détecte des motifs courants, pas tout. En production,
> on branche `gitleaks` ou `trufflehog` — c'est l'objet du [Lab 04](../lab-04-securite-secrets/).

## 7. Pour aller plus loin

- Ajoutez un `PostToolUse` qui lance `gitleaks detect --staged` — détection bien plus robuste.
- Créez `.github/pull_request_template.md` et faites-le remplir par le skill `open-pr`.
- Ajoutez un skill `changelog` qui génère les notes de version depuis les Conventional Commits.
- Testez `/code-review <numéro-de-PR>` sur la PR d'un collègue.

## Corrigé

```bash
cp -r labs/lab-01-git-github/solution/.claude ~/lab-ecommerce/
```
