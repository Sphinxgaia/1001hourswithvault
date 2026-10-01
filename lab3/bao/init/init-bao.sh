#!/bin/sh
# Lab 3 — initialisation, unseal et configuration d'OpenBao.
# Exécuté en one-shot par le service `init` (compose.yaml).
#
#   - première exécution : init (1 part, seuil 1), unseal, puis création des
#     namespaces `admin` et `root` (userpass jm/toto et jm/tata, KV v2
#     `secret/supersecret`) ;
#   - exécutions suivantes : unseal uniquement (l'état est conservé dans le
#     volume `bao-data`, les clés dans /runtime/bao-init.txt).
set -eu

BAO_ADDR="${BAO_ADDR:-http://bao:8200}"
export BAO_ADDR

RUNTIME=/runtime
INIT_FILE="$RUNTIME/bao-init.txt"

umask 022
mkdir -p "$RUNTIME"

log() { printf '[init] %s\n' "$*"; }

log "Attente de l'API OpenBao sur $BAO_ADDR..."
tries=0
while :; do
  set +e
  bao status >/dev/null 2>&1
  rc=$?
  set -e
  if [ "$rc" -eq 0 ] || [ "$rc" -eq 2 ]; then
    break
  fi
  tries=$((tries + 1))
  if [ "$tries" -ge 90 ]; then
    log "ERREUR : API injoignable après 90 s."
    exit 1
  fi
  sleep 1
done

if [ -f "$INIT_FILE" ]; then
  FIRST_INIT=0
  log "État existant détecté ($INIT_FILE) — unseal seulement."
else
  FIRST_INIT=1
  log "Initialisation du serveur (1 part de clé, seuil 1)..."
  bao operator init -key-shares=1 -key-threshold=1 > "$INIT_FILE.tmp"
  mv "$INIT_FILE.tmp" "$INIT_FILE"
fi

UNSEAL_KEY=$(awk '/Unseal Key 1:/ {print $NF}' "$INIT_FILE")
export BAO_TOKEN
BAO_TOKEN=$(awk '/Initial Root Token:/ {print $NF}' "$INIT_FILE")

set +e
bao status >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 2 ]; then
  log "Unseal du serveur..."
  bao operator unseal "$UNSEAL_KEY" >/dev/null
fi

if [ "$FIRST_INIT" -eq 0 ]; then
  log "Serveur déscellé, rien d'autre à faire."
  exit 0
fi

log "Namespace racine : KV v2, userpass (jm/toto), secret/supersecret=toto."
bao secrets enable -path=secret kv-v2
bao auth enable userpass
bao policy write lab3-read /init/policy-lab3-read.hcl
bao write auth/userpass/users/jm password=toto policies=lab3-read
bao kv put -mount=secret supersecret value=toto

log "Namespace admin : KV v2, userpass (jm/tata), secret/supersecret=tata."
bao namespace create admin
bao secrets enable -namespace=admin -path=secret kv-v2
bao auth enable -namespace=admin userpass
bao policy write -namespace=admin lab3-read /init/policy-lab3-read.hcl
bao write -namespace=admin auth/userpass/users/jm password=tata policies=lab3-read
bao kv put -namespace=admin -mount=secret supersecret value=tata

log "Terminé — clés d'init dans $INIT_FILE."
