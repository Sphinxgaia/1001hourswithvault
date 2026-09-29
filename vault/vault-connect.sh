#!/usr/bin/env bash
#
# Unseal + login root à partir de vault-key.txt (clé d'unseal déchiffrée par PGP).
set -euo pipefail

ROOT_DIR_PATH="$(dirname "$(realpath "$0")")"
REPO_DIR_PATH="$(dirname "$ROOT_DIR_PATH")"
KEY_FILE="$ROOT_DIR_PATH/vault-key.txt"

export VAULT_ADDR='http://127.0.0.1:8200'
export GNUPGHOME="$REPO_DIR_PATH/pgp/gnupg"

if [ ! -f "$KEY_FILE" ]; then
    echo "$KEY_FILE absent — lancer vault.sh d'abord."
    exit 1
fi

sleep 2

vault operator unseal "$(grep 'Key 1:' "$KEY_FILE" | awk '{print $NF}' | base64 --decode | gpg -dq)" || true

sleep 2

vault login "$(grep 'Initial Root Token:' "$KEY_FILE" | awk '{print $NF}')"
