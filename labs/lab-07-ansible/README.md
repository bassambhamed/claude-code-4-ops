# Lab 07 — Ansible : configuration & durcissement

> **Durée :** 60 min · **Modules requis :** [04](../../modules/04-skills/),
> [05](../../modules/05-hooks/) · **Outils :** `ansible`, `multipass`
> · **Corrigé :** [`solution/`](solution/)

---

## 1. Objectif

Configurer et durcir les VM du [Lab 05](../lab-05-multipass/) avec des playbooks **idempotents**, et
apprendre à faire vérifier cette idempotence — qui est le seul vrai critère de qualité d'un playbook.

## 2. Pré-requis

- [Lab 05](../lab-05-multipass/) terminé : au moins une VM `lab-ecom-1` accessible.
- `ansible --version` ≥ 2.15

```bash
multipass list         # relever l'adresse IP
```

## 3. Briques mobilisées

| Brique | Rôle |
|---|---|
| **Skill** `ansible-play` | La doctrine : idempotence, `--check` obligatoire, pas de `shell` déguisé |
| **Hook** `PostToolUse` | `ansible-lint` après chaque édition de playbook |
| **`/plan`** | Avant toute exécution sur une VM réelle |

---

## 4. Déroulé pas-à-pas

### Étape 1 — Le skill de doctrine (10 min)

```text
> Crée .claude/skills/ansible-play/SKILL.md. Doctrine à y inscrire :
  - toujours lancer `--check` (dry-run) AVANT toute application réelle ;
  - viser l'idempotence : une seconde exécution doit donner zéro `changed` ;
  - préférer les modules natifs (`ansible.builtin.package`, `service`, `lineinfile`)
    à `command`/`shell` ; si `shell` est inévitable, ajouter `creates:` ou `changed_when:` ;
  - aucun secret en clair : Ansible Vault ou variable d'environnement ;
  - chaque tâche a un `name` explicite, en français.
```

### Étape 2 — L'inventaire (10 min)

```text
> Génère ansible/inventory.ini et ansible/ansible.cfg pour la VM lab-ecom-1
  (IP relevée par `multipass list`, utilisateur `ops`, clé SSH).
  Aucun mot de passe dans l'inventaire.
```

```bash
ansible -i ansible/inventory.ini all -m ping
```

### Étape 3 — Le playbook de durcissement (20 min)

```text
> /plan Génère ansible/playbook.yml qui, sur le groupe `ecom` :
  - installe Docker et ses dépendances ;
  - durcit SSH (pas de login root, pas d'authentification par mot de passe) ;
  - configure UFW : deny par défaut, autorise 22 et 8080 ;
  - crée l'utilisateur de service `ecom` sans shell de connexion ;
  - active et démarre les services nécessaires.
  Chaque tâche doit être idempotente et porter un nom explicite.
```

### Étape 4 — Le dry-run, puis l'application (10 min)

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --check --diff
```

Lisez le diff **avant** d'appliquer. Puis :

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

### Étape 5 — Le test qui compte (10 min)

Relancez exactement la même commande :

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

Le récapitulatif doit afficher **`changed=0`**. Si ce n'est pas le cas :

```text
> Le playbook n'est pas idempotent : ces tâches repassent en `changed` à chaque exécution.
  Identifie lesquelles et corrige-les en utilisant les modules natifs appropriés.
```

> **Pourquoi c'est le vrai test :** un playbook non idempotent redémarre des services à chaque
> exécution. En production, cela transforme une simple convergence de configuration en incident.

### Étape 6 — Le lint automatique (facultatif, 10 min)

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [
        { "type": "command",
          "command": "sh -c 'ansible-lint ansible/ 2>&1 | head -20; exit 0'" }
      ]}
    ]
  }
}
```

Chaque édition de playbook est désormais relue par `ansible-lint`, sans y penser.

---

## 5. Livrable

```
ansible/
├── ansible.cfg
├── inventory.ini                # aucun mot de passe
└── playbook.yml                 # idempotent, vérifié par double exécution
.claude/skills/ansible-play/SKILL.md
```

## 6. Garde-fous

| Règle | Mécanisme |
|---|---|
| `--check` avant toute application | Inscrit dans le skill |
| Aucun secret en clair (R1) | Ansible Vault ; hook `secret-scan` |
| Aucune exécution sur une machine non identifiée | Inventaire explicite, jamais `all` implicite |
| Idempotence vérifiée | Double exécution, `changed=0` |

## 7. Pour aller plus loin

- Convertissez un script shell existant en playbook : *« convertis @setup.sh en rôle Ansible
  idempotent, en expliquant chaque choix de module »*.
- Structurez en **rôles** (`roles/docker`, `roles/hardening`) plutôt qu'en playbook unique.
- Ajoutez un playbook de **vérification de conformité** en lecture seule (CIS niveau 1).
- Générez l'inventaire dynamiquement depuis `multipass list --format json`.

## Corrigé

```bash
cp -r labs/lab-07-ansible/solution/ansible ~/lab-ecommerce/
cp -r labs/lab-07-ansible/solution/.claude/skills/ansible-play ~/lab-ecommerce/.claude/skills/
```
