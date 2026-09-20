# Module 05 — Hooks

> **Durée :** 45 min · **Pré-requis :** [Module 04](../04-skills/)
> · **Suivant :** [Module 06 — MCP](../06-mcp/)

---

## 1. La limite

Votre skill dit « demande confirmation avant tout `terraform destroy` ». Très bien. Mais :
le modèle peut mal l'interpréter ; un collègue peut travailler **sans** ce skill ; une mise à jour
peut changer son comportement. Vous avez une **consigne**, pas un **contrôle**.

En environnement bancaire, cette nuance décide de ce qui est auditable et de ce qui ne l'est pas.

## 2. Le concept — le harnais exécute, le modèle n'est pas consulté

Un **hook** est un script déclenché automatiquement par le harnais sur un événement. Le modèle
n'intervient pas : il ne peut ni le contourner, ni l'oublier, ni le « juger inutile cette fois ».

```
  L'agent veut lancer :  terraform destroy -auto-approve
                                  │
                                  ▼
             ┌────────── hook PreToolUse (Bash) ──────────┐
             │  votre script reçoit l'appel en JSON       │
             │  sur stdin et décide                       │
             └───────────┬───────────────────┬────────────┘
                exit 0   │                   │  exit ≠ 0
                         ▼                   ▼
                 la commande part      BLOQUÉE — le message
                                       stderr revient à l'agent
```

| Niveau | Mécanisme | Fiabilité |
|:---:|---|---|
| 1 | Consigne dans le prompt | Aléatoire |
| 2 | Règle dans `CLAUDE.md` | Bonne, non garantie |
| 3 | `/permissions` (`ask`/`deny`) | Appliquée par le harnais |
| 4 | **Hook** | **Déterministe, et il peut faire n'importe quoi** |

Les permissions *filtrent* ; les hooks *raisonnent* : un hook peut lire la commande, inspecter le
dépôt, appeler `gitleaks`, écrire un journal, puis décider.

## 3. Anatomie

### Les événements utiles en Ops

| Événement | Quand | Usage type |
|---|---|---|
| `PreToolUse` | **Avant** l'exécution d'un outil | Bloquer une commande destructive, scanner un commit |
| `PostToolUse` | **Après** l'exécution | Journal d'audit, `terraform fmt`, `ansible-lint` |
| `SessionStart` | À l'ouverture de session | Rappeler le contexte : cluster et namespace courants |
| `UserPromptSubmit` | À chaque prompt envoyé | Détecter un secret collé dans le prompt |
| `Stop` | Quand l'agent termine sa réponse | Vérifier qu'une règle a bien été respectée |

### Le câblage — `.claude/settings.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/guard-destructive.sh" },
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/secret-scan.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/audit-log.sh" }
        ]
      }
    ]
  }
}
```

**Le contrat d'un hook :** il reçoit l'appel d'outil en **JSON sur stdin**, et son **code de sortie**
décide. `0` = on laisse passer. **Non nul = bloqué**, et ce qui est écrit sur `stderr` remonte à
l'agent — c'est votre occasion de lui expliquer quoi faire à la place.

### Un hook de garde complet

`.claude/hooks/guard-destructive.sh` :

```bash
#!/usr/bin/env bash
# Hook PreToolUse — bloque les commandes irréversibles.
# stdin : l'appel d'outil en JSON. exit != 0 => commande bloquee.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // empty')"
[ -z "$cmd" ] && exit 0

DANGER='terraform destroy|kubectl delete (ns|namespace|pvc)|helm uninstall|rm -rf /|docker system prune|multipass delete|git push --force|DROP (TABLE|DATABASE)'

if printf '%s' "$cmd" | grep -qiE "$DANGER"; then
  {
    echo "BLOQUE par le hook guard-destructive."
    echo "Commande refusee : $cmd"
    echo ""
    echo "Cette commande est irreversible. Procedure attendue :"
    echo "  1. Presenter le plan et l'impact (ressources supprimees, environnement cible)."
    echo "  2. Faire valider explicitement par l'ingenieur."
    echo "  3. L'humain lance la commande lui-meme, hors session."
  } >&2
  exit 2
fi
exit 0
```

**Pourquoi `jq` plutôt qu'un `grep` sur le JSON brut :** un parsing approximatif rate une commande
échappée ou multi-lignes. Un garde-fou qui rate une fois sur vingt n'est pas un garde-fou.

---

## 4. Mini-lab — poser les trois garde-fous (25 min)

```bash
cd ../../ecommerce-app
mkdir -p .claude/hooks
```

**1. Le hook de blocage** — recopiez `guard-destructive.sh` ci-dessus, puis :

```bash
chmod +x .claude/hooks/guard-destructive.sh
```

**2. Le hook anti-secret** — `.claude/hooks/secret-scan.sh` :

```bash
#!/usr/bin/env bash
# Hook PreToolUse — refuse un `git commit` contenant un secret potentiel.
set -euo pipefail

cmd="$(jq -r '.tool_input.command // empty')"
printf '%s' "$cmd" | grep -qi 'git commit' || exit 0

PATTERNS='(password|passwd|secret|api[_-]?key|token|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|connectionstring|aws_secret_access_key)'
hits="$(git diff --cached -U0 2>/dev/null | grep -iE "^\+.*$PATTERNS" || true)"

if [ -n "$hits" ]; then
  {
    echo "COMMIT BLOQUE par le hook secret-scan : secret potentiel detecte."
    echo "Lignes suspectes :"
    printf '%s\n' "$hits" | head -5
    echo ""
    echo "Retirez la valeur du code : variable d'environnement ou coffre, puis recommencez."
  } >&2
  exit 2
fi
exit 0
```

**3. Le hook d'audit** — `.claude/hooks/audit-log.sh` :

```bash
#!/usr/bin/env bash
# Hook PostToolUse — journalise chaque commande shell executee par l'agent (tracabilite DORA).
set -euo pipefail

LOG="${CLAUDE_AUDIT_LOG:-$HOME/.claude/audit/ecommerce-app.jsonl}"
mkdir -p "$(dirname "$LOG")"

payload="$(cat)"
printf '%s\n' "$(jq -c --arg ts "$(date -u +%FT%TZ)" --arg user "${USER:-unknown}" --arg cwd "$PWD" \
  '{ts:$ts, user:$user, cwd:$cwd, tool:.tool_name, command:(.tool_input.command // null)}' <<<"$payload")" >> "$LOG"
exit 0
```

```bash
chmod +x .claude/hooks/*.sh
```

> Le journal est écrit **hors du dépôt** (`~/.claude/audit/`) : il ne doit ni être committé, ni
> pouvoir être effacé par un `git clean`.

**4. Câbler** — créez `.claude/settings.json` avec le contenu de la section Anatomie, en ajoutant
`audit-log.sh` en `PostToolUse`.

**5. Vérifier que c'est réellement actif**

```bash
claude
```
```text
> /hooks
```

Les trois doivent apparaître. **`/hooks` est la seule preuve** : un hook mal câblé ne produit aucun
message d'erreur, il ne se déclenche simplement jamais.

**6. Tester le blocage**

```text
> Supprime le namespace ecommerce du cluster
```

Vous devez voir le message de refus. L'agent reçoit votre explication et propose la procédure
attendue.

**7. Tester l'anti-secret**

```bash
echo 'ConnectionString="Server=db;Password=Sup3rS3cret!"' > appsettings.Local.json
git add appsettings.Local.json
```
```text
> Commite ce fichier
```

Le commit est refusé. Nettoyez :

```bash
git reset appsettings.Local.json && rm appsettings.Local.json
```

**8. Vérifier le journal**

```bash
tail -3 ~/.claude/audit/ecommerce-app.jsonl | jq .
```

Vous avez la trace horodatée de chaque commande lancée par l'agent. C'est la pièce qu'un auditeur
demandera.

---

## 5. Erreurs fréquentes

| Erreur | Conséquence | Correctif |
|---|---|---|
| Script non exécutable | Hook silencieusement ignoré | `chmod +x` |
| `matcher` erroné (`bash` au lieu de `Bash`) | Ne se déclenche jamais | Vérifier par `/hooks` |
| `exit 1` attendu comme un blocage « souple » | Comportement ambigu | Utiliser `exit 2` et écrire le motif sur `stderr` |
| Parser le JSON au `grep` | Faux négatifs sur commandes échappées | `jq` |
| Un message d'erreur sans mode d'emploi | L'agent réessaie la même chose | Expliquer sur `stderr` ce qu'il faut faire |
| Hook lent (scan complet du dépôt) | Chaque commande traîne | Restreindre au diff indexé |
| Journal d'audit dans le dépôt | Effaçable, committé par erreur | L'écrire hors du dépôt |

---

## 6. Checklist de sortie

- [ ] Les trois hooks (`guard-destructive`, `secret-scan`, `audit-log`) sont écrits et exécutables.
- [ ] Ils sont câblés dans `.claude/settings.json` et **visibles dans `/hooks`**.
- [ ] J'ai vu un blocage réel et lu le message reçu par l'agent.
- [ ] Le journal d'audit se remplit, hors du dépôt.
- [ ] Je sais expliquer pourquoi un hook est un contrôle et un prompt une consigne.

> **La question pour le module suivant :** *« Il est bien cadré. Mais il ne voit toujours ni nos
> tickets, ni nos dashboards, ni l'état réel de nos pipelines. »*
