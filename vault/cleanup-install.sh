#!/usr/bin/env bash
#
# Purge le lab Vault : conteneurs, état runtime et fichier de clés.
# Le réseau 1001lab est conservé : le runner GitLab s'y attache.
set -uo pipefail

ROOT_DIR_PATH="$(dirname "$(realpath "$0")")"

docker container rm -f server01 postgres >/dev/null 2>&1 || true

# L'état runtime appartient à l'utilisateur vault (uid 100) :
# suppression via un conteneur root, sans sudo.
docker run --rm -v "$ROOT_DIR_PATH:/lab" alpine rm -rf /lab/vault01

rm -f "$ROOT_DIR_PATH/vault-key.txt"

echo "Lab purgé. vault.sh régénérera vault-key.txt (le committer si c'est l'artefact de référence)."
