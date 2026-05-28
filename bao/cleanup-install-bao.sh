#!/usr/bin/env bash

export ROOT_DIR_PATH=$(dirname $(realpath "$0"))

sudo rm -rf $ROOT_DIR_PATH/bao01 || true

sudo docker container rm -f $(docker container ls -aq) || true

sudo rm $ROOT_DIR_PATH/bao-key.txt || true
sudo rm $ROOT_DIR_PATH/bao-init.txt || true

unset VAULT_TOKEN
