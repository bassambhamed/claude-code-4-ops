# Lab 04 — Sécurité & secrets

> **Durée :** 75 min · **Modules requis :** [05](../../modules/05-hooks/),
> [07](../../modules/07-plugins/) · **Outils :** `gitleaks`, `trivy`
> · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Construire la **chaîne complète de garde-fous** : détection de secrets, blocage des actions
destructives, journal d'audit conforme, scan de sécurité automatisé — puis la packager pour qu'elle
s'applique à tous les dépôts de l'équipe, sans que personne ait à y penser.

C'est le lab qui rend **les huit suivants** acceptables en environnement bancaire : à partir d'ici,
les labs touchent à des VM, de l'IaC, des images et un cluster. La chaîne de garde-fous se met en
place **avant**, pas après coup.

## 2. Pré-requis

```bash
gitleaks version        # brew install gitleaks
trivy --version
```

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Hooks** | Les trois garde-fous : anti-secret, anti-destruction, audit |
| **`/permissions`** | Le cadrage `allow` / `ask` / `deny` |
| **`/security-review`** | La revue de sécurité du diff |
| **Plugin** | Distribuer la chaîne à toute l'équipe |
| **Mode headless** | Le scan de conformité en CI |

---

## 4. Déroulé pas-à-pas

### Étape 1 — Le cadrage des permissions (10 min)

```text
> /permissions
```

Mettez en place la configuration de référence des
[garde-fous, §3](../../docs/garde-fous.md#3-configuration-de-référence) : lecture et diagnostic en
`allow`, écriture sur systèmes réels en `ask`, irréversible en `deny`.

**Testez chaque niveau :**

```text
> !kubectl get pods -A            → passe sans question
> Applique ce manifeste            → demande confirmation
> Détruis l'infrastructure         → refusé
```

> Le `deny` sur `Read(./.env)` mérite une explication : il empêche l'agent de **lire** un fichier de
> secrets, donc de le recopier par inadvertance dans une réponse, un commit ou un ticket. Interdire
> l'écriture ne suffit pas — la fuite passe par la lecture.

### Étape 2 — L'anti-secret sérieux (20 min)

Le hook du [module 05](../../modules/05-hooks/) détecte des motifs. En production, on branche
`gitleaks` :

```bash
cat > .claude/hooks/gitleaks-guard.sh <<'EOF'
#!/usr/bin/env bash
# Hook PreToolUse — refuse un commit si gitleaks detecte un secret dans l'index.
set -uo pipefail

cmd="$(jq -r '.tool_input.command // empty')"
printf '%s' "$cmd" | grep -qi 'git commit' || exit 0

command -v gitleaks >/dev/null 2>&1 || {
  echo "gitleaks absent : commit bloque par precaution. Installez gitleaks." >&2
  exit 2
}

if ! out="$(gitleaks protect --staged --redact --no-banner 2>&1)"; then
  {
    echo "COMMIT BLOQUE : gitleaks a detecte un secret dans les fichiers indexes."
    printf '%s\n' "$out" | head -20
    echo ""
    echo "Procedure : retirer la valeur du code (variable d'environnement ou coffre),"
    echo "puis considerer le secret comme COMPROMIS et le faire revoquer."
  } >&2
  exit 2
fi
exit 0
EOF
chmod +x .claude/hooks/gitleaks-guard.sh
```

**Le détail qui compte :** si `gitleaks` est absent, le hook **bloque** au lieu de laisser passer. Un
contrôle de sécurité qui se désactive silencieusement quand son outil manque est un contrôle qui
n'existe pas.

Testez avec une vraie clé de test :

```bash
echo 'AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY' > .env.test
git add -f .env.test
```
```text
> Commite ce fichier
```

Refus attendu. Nettoyez : `git reset .env.test && rm .env.test`.

### Étape 3 — Le journal d'audit conforme (15 min)

Reprenez `audit-log.sh` du [module 05](../../modules/05-hooks/) et complétez-le pour un usage réel :

```text
> Améliore @.claude/hooks/audit-log.sh :
  - rotation quotidienne du fichier ;
  - un champ `session_id` pour corréler les commandes d'une même session ;
  - un champ `repo` (nom du dépôt) ;
  - écriture atomique (pas de ligne tronquée en cas d'arrêt brutal) ;
  - le hook ne doit JAMAIS faire échouer une commande, même s'il ne peut pas écrire.
```

```bash
tail -5 ~/.claude/audit/$(date +%F).jsonl | jq .
```

Puis vérifiez que le journal répond aux questions d'un auditeur :

```text
> À partir de @~/.claude/audit/, produis un rapport : combien de commandes l'agent a-t-il
  exécutées aujourd'hui, lesquelles ont été bloquées par un hook, et lesquelles ont touché
  à un système réel ?
```

### Étape 4 — La revue de sécurité (10 min)

```text
> /security-review
```

Puis sur l'infrastructure — c'est là que ça compte :

```text
> Relis @k8s/ et @terraform/ et réponds précisément :
  - un conteneur tourne-t-il en root ?
  - une limite de ressources est-elle absente ?
  - une règle réseau est-elle plus permissive que nécessaire ?
  - un secret est-il monté en clair, ou visible dans une variable d'environnement ?
  Classe par criticité réelle et propose le correctif exact.
```

```bash
trivy config k8s/
trivy config terraform/
```

### Étape 5 — L'automatisation du contrôle (10 min)

```text
> Génère .github/workflows/security.yml : à chaque PR, gitleaks sur l'historique du diff,
  trivy config sur k8s/ et terraform/, trivy image sur les images construites.
  Le job ÉCHOUE sur un secret détecté ou une vulnérabilité CRITICAL. Il commente le résultat
  sur la PR.
```

**Ici, le job bloque** — contrairement au hook local du [Lab 08](../lab-08-docker/) qui informait.
La différence : en CI, il y a une procédure d'équipe pour lever le blocage ; sur un poste, un
blocage inexpliqué pousse à désactiver le garde-fou.

### Étape 6 — Distribuer la chaîne (10 min)

Une chaîne de sécurité qui vit dans un seul dépôt ne protège qu'un seul dépôt. Vous savez déjà
packager un plugin ([module 07](../../modules/07-plugins/)) — appliquez-le à ce que vous venez
d'écrire.

```bash
cp .claude/hooks/*.sh ../Ops_Claude_code/plugins/oddo-ops-toolkit/hooks/
```

Un seul point d'attention, le même qu'au module 07 : `hooks.json` doit utiliser
`${CLAUDE_PLUGIN_ROOT}` et non `$CLAUDE_PROJECT_DIR` — un plugin ne connaît pas le projet qui
l'utilise.

```bash
claude plugin validate plugins/oddo-ops-toolkit
claude plugin install oddo-ops-toolkit
```

Ouvrez une session dans un dépôt **quelconque**, sans rapport avec la formation :

```text
> /hooks
```

Vos garde-fous vous suivent partout. **C'est le point de bascule du lab :** la sécurité n'est plus
une discipline individuelle qui dépend de la vigilance de chacun, c'est une configuration
distribuée qui s'applique par défaut.

---

## 5. Livrable

```
.claude/
├── settings.json                  # permissions allow/ask/deny + hooks câblés
└── hooks/
    ├── gitleaks-guard.sh          # bloque, y compris si gitleaks est absent
    ├── guard-destructive.sh
    └── audit-log.sh               # rotation, session_id, écriture atomique
.github/workflows/security.yml     # gitleaks + trivy, bloquant
plugins/oddo-ops-toolkit/hooks/    # la chaîne, distribuée
```

## 6. Garde-fous

Ce lab **est** le dispositif de garde-fous. Contrôle final :

- [ ] Un commit contenant un secret est refusé — **testé réellement**.
- [ ] `gitleaks` absent ⇒ blocage, pas contournement silencieux.
- [ ] Une commande destructive est refusée avec une procédure de remplacement.
- [ ] `/permissions` distingue `allow`, `ask` et `deny`, et `deny` couvre la **lecture** des secrets.
- [ ] Le journal d'audit est écrit hors du dépôt, avec horodatage et identification de session.
- [ ] La CI échoue sur un secret ou une vulnérabilité critique.
- [ ] La chaîne est packagée et installable par toute l'équipe.

## 7. Pour aller plus loin

- Branchez un **coffre** : SealedSecrets ou External Secrets Operator pour le cluster.
- Ajoutez des **policies OPA/Gatekeeper** : interdiction de conteneur root, limites obligatoires.
- Faites produire la **cartographie des secrets** du dépôt : où sont-ils, qui y accède, rotation.
- Testez les plugins officiels `claude-security`, `semgrep`, `security-guidance`.
- Construisez le **rapport de conformité DORA** mensuel à partir du journal d'audit, en headless.
