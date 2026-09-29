# Image de job GitLab du lab : CLI Vault 2.0.1 + gnupg + jq.
# Construite localement par le runner (pull_policy: if-not-present) :
#   docker build -t 1001lab/vault-ci:2.0.1 -f lab1/ci/Dockerfile .
# Le job reste en root : il doit lire la clé privée montée par le runner
# (fichier 0600 appartenant à l'utilisateur hôte).
#
# Le binaire /bin/vault de l'image porte la file-capability cap_ipc_lock=ep
# (pour le serveur) : dans un conteneur de job sans --cap-add IPC_LOCK,
# l'exécuter renvoie EPERM. La copie vers /usr/local/bin perd la
# file-capability, le CLI fonctionne sans capability particulière.
FROM hashicorp/vault:2.0.1

USER root
RUN apk add --no-cache gnupg jq \
    && cp /bin/vault /usr/local/bin/vault

