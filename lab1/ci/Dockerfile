# Image de job GitLab du lab : CLI Vault 2.0.1 + gnupg + jq.
# Construite localement par le runner (pull_policy: if-not-present) :
#   docker build -t 1001lab/vault-ci:2.0.1 -f ci/Dockerfile .
FROM hashicorp/vault:2.0.1

USER root
RUN apk add --no-cache gnupg jq
USER vault
