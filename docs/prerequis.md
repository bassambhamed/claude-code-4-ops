# Pré-requis techniques

À installer **avant J1**. Comptez 45 min si tout est à installer, 10 min si Docker et le SDK .NET
sont déjà là.

> **Poste verrouillé ?** Si votre poste ne permet pas ces installations, montez une **VM bac à sable**
> (Multipass, voir plus bas) et installez-y tout l'outillage. C'est d'ailleurs exactement ce que fait
> le [Lab 05](../labs/lab-05-multipass/).

---

## 1. Claude Code — indispensable

| Plateforme | Commande |
|---|---|
| macOS / Linux / WSL | `curl -fsSL https://claude.ai/install.sh \| bash` |
| Windows (PowerShell) | `irm https://claude.ai/install.ps1 \| iex` |
| macOS (Homebrew) | `brew install --cask claude-code` |
| Windows (WinGet) | `winget install Anthropic.ClaudeCode` |
| Multiplateforme (npm, Node 18+) | `npm install -g @anthropic-ai/claude-code` |

```bash
claude --version     # ≥ 2.1 attendu pour cette formation
claude doctor        # diagnostic complet : install, config, connectivité
```

> ⚠️ Ne **jamais** faire `sudo npm install -g` : cela crée des fichiers root dans votre arborescence
> utilisateur et pose des problèmes de permissions à la première mise à jour.

**Compte requis :** abonnement **Pro, Max, Team, Enterprise** ou **Console**. Le plan gratuit
Claude.ai ne donne pas accès à Claude Code. Alternative en entreprise : passer par Amazon Bedrock,
Google Vertex AI ou Microsoft Foundry.

---

## 2. Outillage par bloc de labs

| Outil | Sert à | Labs | Vérification |
|---|---|:---:|---|
| Git | tout | tous | `git --version` |
| GitHub CLI (`gh`) | repos, PR, Actions | 01, 02, 12 | `gh auth status` |
| .NET SDK 8+ (10 recommandé) | builder l'app fil rouge | 02, 03, 07 | `dotnet --version` |
| Docker ou Podman | images, compose | 07, 08, 10 | `docker version` |
| Multipass | VM Ubuntu jetables | 04, 06 | `multipass version` |
| Terraform ou OpenTofu | IaC | 05 | `terraform version` |
| Ansible | configuration | 06 | `ansible --version` |
| kubectl + k3d | cluster local | 08, 09, 10 | `kubectl version --client` · `k3d version` |
| Helm | packaging K8s | 09 | `helm version` |
| gitleaks | détection de secrets | 12 | `gitleaks version` |
| Trivy | scan d'images et d'IaC | 07, 12 | `trivy --version` |
| jq | manipuler le JSON des hooks | 05, 09 | `jq --version` |

### Installation express — macOS

```bash
brew install git gh dotnet-sdk docker terraform ansible kubectl helm k3d gitleaks trivy jq
brew install --cask multipass
```

### Installation express — Ubuntu / Debian

```bash
sudo apt update && sudo apt install -y git jq ansible
sudo snap install multipass
# gh, dotnet, docker, terraform, kubectl, helm, k3d, gitleaks, trivy :
# suivre les dépôts officiels de chaque éditeur (voir liens dans le glossaire)
```

---

## 3. Vérifier d'un coup

```bash
./docs/check-prereqs.sh
```

Le script affiche une ligne par outil avec ✅ / ❌ et n'installe rien. Un ❌ sur un outil de bloc
optionnel (Multipass, Terraform, Ansible) ne bloque pas la formation : les labs concernés peuvent
être suivis en observation.

---

## 4. Comptes et accès à préparer

| Accès | Pourquoi | Labs |
|---|---|:---:|
| Compte GitHub (perso ou org de test) | créer un repo, ouvrir des PR | 01, 02 |
| Token GitHub *fine-grained*, lecture seule (créé pendant le lab 01, étape 7) | serveur MCP GitHub | 01, module 06 |
| Instance Grafana de démo (ou `grafana/grafana` en local) | serveur MCP Grafana | 10 |
| Projet Jira de test *(optionnel)* | serveur MCP Atlassian | 11 |

> **Règle absolue :** ces jetons vont dans des **variables d'environnement**, jamais dans un fichier
> committé, jamais dans un prompt. Le [Lab 04](../labs/lab-04-securite-secrets/) met en place la
> chaîne technique qui le garantit.

---

## 5. Application fil rouge

```bash
export PATH="/usr/local/share/dotnet:$PATH"    # si dotnet n'est pas trouvé
cd ecommerce-app
dotnet restore ECommerce.slnx
dotnet build ECommerce.slnx
dotnet dev-certs https --trust                 # une seule fois, sinon dashboard en UntrustedRoot
dotnet run --project src/ECommerce.AppHost     # URL du dashboard + token affichés en console
```

Si le build passe et que le dashboard Aspire s'ouvre, votre poste est prêt.
