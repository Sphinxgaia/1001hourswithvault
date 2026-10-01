#!/usr/bin/env bash
# Lab 3 — arrête le lab et efface l'état Raft et les clés d'init.
set -euo pipefail

cd "$(dirname "$(realpath "$0")")/.."

docker compose down --volumes --remove-orphans
rm -rf runtime

echo "Lab 3 remis à zéro (conteneurs, réseaux, volume Raft, clés d'init)."
