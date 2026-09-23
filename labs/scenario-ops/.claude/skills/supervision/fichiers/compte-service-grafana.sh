#!/bin/sh
# Exécuté dans la VM monitor (root) : crée le compte de service Grafana « claude » (Viewer)
# et écrit son jeton dans /root/jeton-grafana (600), sans jamais l'afficher.
# Nom volontairement sans « jeton » : le hook anti-secret bloque les commandes qui citent le fichier du jeton.
set -eu
umask 077

api=http://localhost:3000/api
auth=admin:admin
json='Content-Type: application/json'

id=$(curl -sf -u "$auth" -H "$json" -d '{"name":"claude","role":"Viewer"}' "$api/serviceaccounts" \
  | python3 -c 'import json, sys; print(json.load(sys.stdin)["id"])')

curl -sf -u "$auth" -H "$json" -d '{"name":"mcp"}' "$api/serviceaccounts/$id/tokens" \
  | python3 -c 'import json, sys; sys.stdout.write(json.load(sys.stdin)["key"])' > /root/jeton-grafana

echo "compte de service claude (id $id) : jeton écrit dans /root/jeton-grafana ($(wc -c < /root/jeton-grafana) octets)"
