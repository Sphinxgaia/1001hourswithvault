#!/usr/bin/env bash

export ROOT_DIR_PATH=$(dirname $(realpath "$0"))

export FILE="$ROOT_DIR_PATH/vault-init.txt"

if [ -f "$FILE" ]; then
    echo "$FILE exists."
    exit $1
fi

export VAULT_ADDR='http://127.0.0.1:8200' 

mkdir vault01/file -p

docker network create pg

docker container run --network pg  --cap-add IPC_LOCK --name server01 -d -p 8200:8200 -v $ROOT_DIR_PATH/vault.hcl:/vault/config/vault.hcl -v $ROOT_DIR_PATH/vault01/file:/vault/file hashicorp/vault:2.0.1 vault server -config=/vault/config/vault.hcl

docker container run --network pg -d --name postgres -e POSTGRES_PASSWORD="password" postgres

docker network connect pg server01
docker network connect pg postgres

sleep 5
vault operator init -key-shares=1 -key-threshold=1 > $ROOT_DIR_PATH/vault-key.txt

sleep 2

vault operator unseal $(grep 'Key 1:' $ROOT_DIR_PATH/vault-key.txt | awk '{print $NF}')


cp $ROOT_DIR_PATH/vault-key.txt $ROOT_DIR_PATH/vault-init.txt

sleep 2

vault login $(grep 'Initial Root Token:' $ROOT_DIR_PATH/vault-key.txt | awk '{print $NF}')

sudo mkdir -p $ROOT_DIR_PATH/vault01/file/audit
sudo chown -R 100:1000 $ROOT_DIR_PATH/vault01/file/audit

vault audit enable file file_path=/vault/file/audit/audit.log
