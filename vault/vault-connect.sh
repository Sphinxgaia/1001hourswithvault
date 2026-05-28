#!/usr/bin/env bash

export ROOT_DIR_PATH=$(dirname $(realpath "$0"))

export FILE="$ROOT_DIR_PATH/vault-init.txt"

if [ ! -f "$FILE" ]; then
    echo "$FILE does not exists."
    exit $1
fi

export VAULT_ADDR='http://127.0.0.1:8200' 

sleep 2

vault operator unseal $(grep 'Key 1:' $ROOT_DIR_PATH/vault-init.txt | awk '{print $NF}') || true

sleep 2

vault login $(grep 'Initial Root Token:' $ROOT_DIR_PATH/vault-init.txt | awk '{print $NF}')
