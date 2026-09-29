#!/usr/bin/env bash
#
# Purge le lab OpenBao : conteneurs, état runtime et fichiers de clés.
# Le réseau 1001lab est conservé (partagé avec le lab Vault et le runner).
set -uo pipefail

ROOT_DIR_PATH="$(dirname "$(realpath "$0")")"

docker container rm -f serverbao01 nginx-base >/dev/null 2>&1 || true

# L'état runtime peut appartenir à l'utilisateur du conteneur :
# suppression via un conteneur root, sans sudo.
docker run --rm -v "$ROOT_DIR_PATH:/bao" alpine rm -rf /bao/bao01

rm -f "$ROOT_DIR_PATH/bao-key.txt" "$ROOT_DIR_PATH/bao-init.txt"

unset VAULT_TOKEN
