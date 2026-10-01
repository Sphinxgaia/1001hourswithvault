#!/usr/bin/env bash
# Lab 3 — démarre le lab et attend la fin de l'initialisation.
set -euo pipefail

cd "$(dirname "$(realpath "$0")")/.."

mkdir -p runtime

docker compose up -d

# Le service `init` est one-shot : on attend sa sortie et on remonte son code.
init_id=$(docker compose ps -q --all init)
code=$(docker wait "$init_id")
docker compose logs init
if [ "$code" != "0" ]; then
  echo "Échec de l'initialisation OpenBao (code $code)." >&2
  exit 1
fi

cat <<'EOF'

OpenBao est prêt :
  nginx1 — namespace racine : http://localhost:8081
  nginx2 — namespace admin  : http://localhost:8082 (X-Vault-Namespace injecté)
  nginx3 — namespace admin  : http://localhost:8083 (chemin /v1/admin réécrit ; /ui non réécrite)
  clés d'init (root token)  : runtime/bao-init.txt — jamais committé

Vérifications : voir README.md. Remise à zéro : ./scripts/reset.sh
EOF
