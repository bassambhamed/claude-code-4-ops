#!/usr/bin/env bash
# Hook PreToolUse — refuse un `git commit` contenant un secret potentiel.
#
# Deux niveaux : gitleaks si disponible (recommande en production), sinon une detection
# par motifs. Si gitleaks est installe mais echoue, on BLOQUE : un controle de securite
# ne doit jamais se desactiver silencieusement.
set -uo pipefail

cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
printf '%s' "$cmd" | grep -qi 'git commit' || exit 0

if command -v gitleaks >/dev/null 2>&1; then
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
fi

PATTERNS='(password|passwd|secret|api[_-]?key|token|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|connectionstring|aws_secret_access_key)'
hits="$(git diff --cached -U0 2>/dev/null | grep -iE "^\+.*$PATTERNS" || true)"

if [ -n "$hits" ]; then
  {
    echo "COMMIT BLOQUE par le hook secret-scan : secret potentiel detecte."
    echo "Lignes suspectes :"
    printf '%s\n' "$hits" | head -5
    echo ""
    echo "Retirez la valeur du code (variable d'environnement ou coffre), puis recommencez."
    echo "Note : cette detection par motifs est un filet de securite. Installez gitleaks"
    echo "pour une couverture serieuse."
  } >&2
  exit 2
fi
exit 0
