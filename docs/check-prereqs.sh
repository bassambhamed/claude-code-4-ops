#!/usr/bin/env bash
# Vérifie l'outillage nécessaire à la formation « Claude Code pour les Ops ».
# N'installe rien, ne modifie rien. Codes de sortie : 0 = tout le nécessaire est présent.

set -uo pipefail

ok=0; ko=0; warn=0

check() {                      # check <commande> <libellé> <criticité: req|opt> [version-cmd]
  local bin="$1" label="$2" level="$3" vcmd="${4:-}"
  if command -v "$bin" >/dev/null 2>&1; then
    local v=""
    [ -n "$vcmd" ] && v="$(eval "$vcmd" 2>/dev/null | head -1)"
    printf '  \033[32m OK \033[0m %-14s %s\n' "$label" "$v"
    ok=$((ok+1))
  elif [ "$level" = "req" ]; then
    printf '  \033[31mMANQ\033[0m %-14s (indispensable)\n' "$label"
    ko=$((ko+1))
  else
    printf '  \033[33mABS \033[0m %-14s (optionnel — labs concernes en observation)\n' "$label"
    warn=$((warn+1))
  fi
}

echo
echo "Formation Claude Code pour les Ops — verification des pre-requis"
echo "---------------------------------------------------------------"
echo
echo "Indispensable"
check claude    "claude"     req 'claude --version'
check git       "git"        req 'git --version'
check jq        "jq"         req 'jq --version'

echo
echo "Labs 01-03 — code, CI/CD, tests"
check gh        "gh"         req 'gh --version | head -1'
check dotnet    "dotnet"     req 'dotnet --version'

echo
echo "Labs 04-06 — provisionnement & IaC"
check multipass "multipass"  opt 'multipass version | head -1'
check terraform "terraform"  opt 'terraform version | head -1'
check ansible   "ansible"    opt 'ansible --version | head -1'

echo
echo "Labs 07-10 — conteneurs, orchestration, observabilite"
check docker    "docker"     opt 'docker --version'
check kubectl   "kubectl"    opt 'kubectl version --client -o yaml 2>/dev/null | grep gitVersion | head -1'
check k3d       "k3d"        opt 'k3d version | head -1'
check helm      "helm"       opt 'helm version --short'

echo
echo "Lab 12 — securite & secrets"
check gitleaks  "gitleaks"   opt 'gitleaks version'
check trivy     "trivy"      opt 'trivy --version | head -1'

echo
echo "---------------------------------------------------------------"
printf 'Presents : %d   Manquants (bloquants) : %d   Absents (optionnels) : %d\n' "$ok" "$ko" "$warn"
echo

if [ "$ko" -gt 0 ]; then
  echo "=> Installez les outils bloquants : voir docs/prerequis.md"
  exit 1
fi
echo "=> Poste pret pour la formation."
