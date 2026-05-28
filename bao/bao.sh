#!/usr/bin/env bash

export ROOT_DIR_PATH=$(dirname $(realpath "$0"))

export FILE="$ROOT_DIR_PATH/bao-init.txt"

if [ -f "$FILE" ]; then
  echo "$FILE exists."
  exit $1
fi

export BAO_ADDR='http://127.0.0.1:8300'

mkdir bao01/file -p

sudo mkdir -p $ROOT_DIR_PATH/bao01/file/audit

sudo chown -R 100:1000 $ROOT_DIR_PATH/bao01/file/audit

docker network create pg

docker container run --network pg --cap-add IPC_LOCK --name serverbao01 -d -p 8300:8300 -v $ROOT_DIR_PATH/bao.hcl:/bao/config/bao.hcl -v $ROOT_DIR_PATH/bao01/file:/bao/file openbao/openbao:2.5.1 bao server -config=/bao/config/bao.hcl

docker container run --network pg -d --name postgres -e POSTGRES_PASSWORD="password" postgres
docker container run -d --network pg --name nginx-base -v $ROOT_DIR_PATH/nginx/default.conf:/etc/nginx/conf.d/default.conf -p 80:80 nginx:latest

docker network connect pg serverbao01
docker network connect pg postgres

sleep 5
bao operator init -key-shares=1 -key-threshold=1 >$ROOT_DIR_PATH/bao-key.txt

sleep 2

bao operator unseal $(grep 'Key 1:' $ROOT_DIR_PATH/bao-key.txt | awk '{print $NF}')

cp $ROOT_DIR_PATH/bao-key.txt $ROOT_DIR_PATH/bao-init.txt

sleep 2

bao login $(grep 'Initial Root Token:' $ROOT_DIR_PATH/bao-key.txt | awk '{print $NF}')
