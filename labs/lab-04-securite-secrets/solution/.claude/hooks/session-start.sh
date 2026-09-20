#!/usr/bin/env bash
# Hook SessionStart — rappelle le contexte d'exploitation au demarrage de la session.
# Purement informatif : il n'echoue jamais.
set -uo pipefail

ctx="$(kubectl config current-context 2>/dev/null || echo 'aucun')"
ns="$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null || echo 'default')"
branch="$(git branch --show-current 2>/dev/null || echo '-')"

cat <<TXT
Contexte d'exploitation
  depot     : $(basename "$PWD")  (branche : $branch)
  cluster   : $ctx
  namespace : ${ns:-default}
  garde-fous: anti-secret, blocage destructif et journal d'audit actifs.
TXT
exit 0
