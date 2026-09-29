#!/usr/bin/env bash
#
# Init du Vault du lab (démo « Mes 1001 Heures avec Vault »).
# - réseau Docker 1001lab partagé avec le runner GitLab
# - clé d'unseal chiffrée à la source par PGP (-pgp-keys)
# - vault-key.txt contient la clé d'unseal chiffrée + le root token en clair :
#   artefact de démo committé volontairement (voir README.md)
set -euo pipefail

ROOT_DIR_PATH="$(dirname "$(realpath "$0")")"
REPO_DIR_PATH="$(dirname "$ROOT_DIR_PATH")"
PGP_DIR_PATH="$REPO_DIR_PATH/pgp"
KEY_FILE="$ROOT_DIR_PATH/vault-key.txt"
STATE_DIR="$ROOT_DIR_PATH/vault01/file"

export VAULT_ADDR='http://127.0.0.1:8200'
export GNUPGHOME="$PGP_DIR_PATH/gnupg"

if [ -d "$STATE_DIR" ]; then
    echo "$STATE_DIR existe déjà — lancer cleanup-install.sh avant une nouvelle init."
    exit 1
fi

if [ ! -f "$PGP_DIR_PATH/lab-pub.b64" ]; then
    echo "Clé publique du lab absente : $PGP_DIR_PATH/lab-pub.b64"
    exit 1
fi

mkdir -p "$STATE_DIR/audit"

docker network create 1001lab >/dev/null 2>&1 || true

docker container run --network 1001lab --cap-add IPC_LOCK --name server01 -d -p 8200:8200 \
    -v "$ROOT_DIR_PATH/vault.hcl:/vault/config/vault.hcl" \
    -v "$ROOT_DIR_PATH/vault01/file:/vault/file" \
    hashicorp/vault:2.0.1 vault server -config=/vault/config/vault.hcl

docker container run --network 1001lab -d --name postgres -e POSTGRES_PASSWORD="password" postgres

# Le serveur Vault tourne en uid 100 : lui ouvrir l'écriture sur le stockage
docker run --rm -v "$ROOT_DIR_PATH/vault01:/work" alpine chown -R 100:1000 /work

sleep 5

vault operator init -key-shares=1 -key-threshold=1 \
    -pgp-keys="$PGP_DIR_PATH/lab-pub.b64" > "$KEY_FILE"

sleep 2

UNSEAL_KEY="$(grep 'Key 1:' "$KEY_FILE" | awk '{print $NF}' | base64 --decode | gpg -dq)"
vault operator unseal "$UNSEAL_KEY"

sleep 2

vault login "$(grep 'Initial Root Token:' "$KEY_FILE" | awk '{print $NF}')"

vault audit enable file file_path=/vault/file/audit/audit.log

echo
echo "Init terminée. Clé d'unseal chiffrée et root token dans $KEY_FILE (artefact de démo)."
