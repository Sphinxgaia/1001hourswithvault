#!/usr/bin/env bash

wget https://releases.hashicorp.com/vault/2.0.1/vault_2.0.1_linux_amd64.zip
unzip vault_2.0.1_linux_amd64.zip
chmod +x vault

sudo mv vault /usr/bin/
vault version

rm -f vault_2.0.1_linux_amd64.zip
