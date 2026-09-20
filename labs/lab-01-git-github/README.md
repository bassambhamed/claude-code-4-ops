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

```bash
gh auth login        # GitHub.com → HTTPS → navigateur
gh auth status       # doit afficher un compte authentifié
```

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

### Étape 7 — Brancher le MCP GitHub (5 min)

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx     # scope `repo`
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  -H "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN"
```
```text
> /mcp
> Résume l'état des PR ouvertes sur ce dépôt et signale celles qui touchent à l'infrastructure.
```

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

> **Attention à la limite du hook de démo :** il détecte des motifs courants, pas tout. En production,
> on branche `gitleaks` ou `trufflehog` — c'est l'objet du [Lab 04](../lab-04-securite-secrets/).

## 7. Pour aller plus loin

- Ajoutez un `PostToolUse` qui lance `gitleaks detect --staged` — détection bien plus robuste.
- Créez `.github/pull_request_template.md` et faites-le remplir par le skill `open-pr`.
- Ajoutez un skill `changelog` qui génère les notes de version depuis les Conventional Commits.
- Testez `/review <numéro-de-PR>` sur la PR d'un collègue.

## Corrigé

```bash
cp -r labs/lab-01-git-github/solution/.claude ~/lab-ecommerce/
```
