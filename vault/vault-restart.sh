#!/usr/bin/env bash

export ROOT_DIR_PATH=$(dirname $(realpath "$0"))

export FILE="$ROOT_DIR_PATH/vault-init.txt"

if [ ! -f "$FILE" ]; then
    echo "$FILE does not exists."
    exit $1
fi


export VAULT_ADDR='http://127.0.0.1:8200' 

docker network create pg

docker container run --network pg  --cap-add IPC_LOCK --name server01 -d -p 8200:8200 -v $ROOT_DIR_PATH/vault.hcl:/vault/config/vault.hcl -v $ROOT_DIR_PATH/vault01/file:/vault/file hashicorp/vault:1.16.2 vault server -config=/vault/config/vault.hcl

docker container run --network pg -d --name postgres -e POSTGRES_PASSWORD="password" postgres

docker network connect pg server01
docker network connect pg postgres


vault operator unseal $(grep 'Key 1:' $ROOT_DIR_PATH/vault-init.txt | awk '{print $NF}')

sleep 2

vault login $(grep 'Initial Root Token:' $ROOT_DIR_PATH/vault-init.txt | awk '{print $NF}')
