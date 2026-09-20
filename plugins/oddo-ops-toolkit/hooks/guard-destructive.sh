#!/usr/bin/env bash
# Hook PreToolUse — bloque les commandes irreversibles.
#
# Contrat : l'appel d'outil arrive en JSON sur stdin ; un code de sortie != 0 BLOQUE la
# commande et renvoie stderr a l'agent. C'est un controle DETERMINISTE : le modele n'est
# pas consulte, il ne peut donc pas le contourner.
set -uo pipefail

cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null)" || exit 0
[ -z "$cmd" ] && exit 0

DANGER='terraform destroy|kubectl delete (ns|namespace|pvc|pv )|helm uninstall|rm -rf /|docker system prune|docker volume rm|multipass delete|git push --force|DROP (TABLE|DATABASE)|mkfs|dd if=.*of=/dev/'

if printf '%s' "$cmd" | grep -qiE "$DANGER"; then
  {
    echo "BLOQUE par le hook guard-destructive."
    echo "Commande refusee : $cmd"
    echo ""
    echo "Cette commande est irreversible. Procedure attendue :"
    echo "  1. Presenter le plan et l'impact (ressources supprimees, environnement cible)."
    echo "  2. Faire valider explicitement par l'ingenieur responsable."
    echo "  3. L'humain lance la commande lui-meme, hors session."
  } >&2
  exit 2
fi
exit 0
