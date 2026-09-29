# 1001hourswithvault — lab de démo

Support de démo du talk **« Mes 1001 Heures avec Vault — De Vault à OpenBao, récits de survie d'un SRE »** (Volcamp 2026) : un Vault local en Docker, un dépôt public qui expose son root token, et un job GitLab qui en régénère un autre dans ses logs.

## Le récit en deux fuites

1. **Fuite n° 1 — le dépôt public.** L'init du Vault écrit `vault/vault-key.txt` (clé d'unseal chiffrée par PGP + root token **en clair**) et ce fichier est committé volontairement. N'importe qui clone le dépôt, lit le token et se connecte au Vault.
2. **Fuite n° 2 — les logs GitLab.** Le job `vault-generate-root` régénère un root token avec la procédure Vault (`vault operator generate-root`) ; le token neuf s'affiche en clair dans le log du job sur gitlab.com, et se lit via le MCP GitLab (ou l'interface).

> ⚠️ **Avertissements** — le root token committé et la clé PGP publique ne contrôlent qu'un Vault local éphémère, sur cette machine. Ne jamais reproduire ces pratiques sur un Vault réel. La **clé privée** PGP du lab (`pgp/lab-secret.b64`) n'est **pas** dans le dépôt : elle reste chez l'opérateur et n'est montée que dans le runner local.

## Contenu

| Chemin | Rôle |
|---|---|
| `vault/` | scripts Docker : init PGP, unseal, login, restart, purge, `vault-key.txt` (artefact de fuite n° 1) |
| `pgp/` | clé PGP du lab : `lab-pub.b64` committée, `lab-secret.b64` locale (gitignorée) |
| `policies/templates/` | policies HCL appliquées par le job (`secretreader`, `secretwriter`, `operator`) |
| `ci/Dockerfile` | image de job (`vault` 2.0.1 + gnupg + jq) |
| `.gitlab-ci.yml` | jobs `vault-configure` et `vault-generate-root` |

## Prérequis

- Docker (et l'accès au socket pour le runner) ;
- CLI `vault` 2.0.1 sur l'hôte (`vault/install-cli.sh`) ;
- `gpg` 2.4+ ;
- un projet GitLab.com privé + un runner GitLab local ;
- pour la lecture MCP : un PAT GitLab scope `read_api`.

## 0. Clé PGP du lab

La clé publique est committée dans `pgp/lab-pub.b64` (format attendu par `-pgp-keys` : base64, non armé). Empreinte : `DABE82446C2F55FEF76EBD6430A215E3012F5379`.

Régénération (opérateur, écrase la paire) :

```bash
mkdir -p pgp/gnupg && chmod 700 pgp/gnupg
GNUPGHOME="$PWD/pgp/gnupg" gpg --batch --generate-key <<'EOF'
%no-protection
Key-Type: RSA
Key-Length: 3072
Subkey-Type: RSA
Subkey-Length: 3072
Subkey-Usage: encrypt
Name-Real: 1001lab
Name-Comment: temporary lab key (no passphrase)
Name-Email: 1001lab@localhost
Expire-Date: 0
%commit
EOF
export GNUPGHOME="$PWD/pgp/gnupg"
gpg --export | base64 -w0 > pgp/lab-pub.b64
gpg --export-secret-keys | base64 -w0 > pgp/lab-secret.b64
chmod 600 pgp/lab-secret.b64
```

## 1. Init du Vault (hôte)

```bash
vault/cleanup-install.sh   # seulement si un état existe déjà
vault/vault.sh
```

Le script démarre `server01` (port 8200) et `postgres` sur le réseau Docker `1001lab`, initialise Vault avec une clé d'unseal chiffrée à la source (`-pgp-keys="pgp/lab-pub.b64"`), la déchiffre, unseal, se logue en root et active l'audit fichier.

Résultat dans `vault/vault-key.txt` :

```
Unseal Key 1: wcDMA...            <- chiffrée par la clé publique du lab
Initial Root Token: hvs....       <- en clair (fuite n° 1, assumée)
```

## 2. Fuite n° 1 — le root token dans le dépôt

```bash
grep 'Initial Root Token' vault/vault-key.txt
vault login hvs.xxxxxxxx
vault token lookup          # token_policies = ["root"]
```

## 3. CI GitLab — runner et jobs

Image de job (une fois) :

```bash
docker build -t 1001lab/vault-ci:2.0.1 -f ci/Dockerfile .
```

Runner local (projet GitLab.com privé → Settings → CI/CD → Runners → New project runner, tag `local`) :

```bash
docker run -d --name gitlab-runner --restart unless-stopped \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest

docker exec -it gitlab-runner gitlab-runner register \
  --url https://gitlab.com \
  --token "$RUNNER_TOKEN" \
  --executor docker \
  --docker-image alpine:3.21 \
  --docker-network-mode 1001lab \
  --docker-volumes "$PWD/pgp/lab-secret.b64:/lab/pgp/lab-secret.b64:ro" \
  --tag-list local \
  --description "1001lab local"
```

Le point clé : le job tourne **sur le réseau `1001lab`** (il joint Vault sur `http://server01:8200`) et la clé privée lui est **montée en lecture seule** — elle n'est jamais poussée.

Jobs du pipeline :

- `vault-configure` (automatique) : unseal, login avec le root token committé, puis `vault policy write` des trois policies du dépôt ;
- `vault-generate-root` (**manuel**) : `generate-root` → root token neuf affiché dans le log.

## 4. Fuite n° 2 — le token dans les logs, lu via MCP

Le job manuel `vault-generate-root` écrit le token neuf dans le log GitLab. Lecture possible via l'interface (Build → Pipelines → job), ou via le MCP GitLab `@zereight/mcp-gitlab` (`read_api`), configuré pour la flotte par le rôle `agents` de `neural-codes` (wrapper + PAT `0600`). Pour un poste hors flotte :

```json
{
  "mcp": {
    "gitlab": {
      "type": "local",
      "command": ["npx", "-y", "@zereight/mcp-gitlab@2.1.67"],
      "enabled": true
    }
  }
}
```

avec `GITLAB_PERSONAL_ACCESS_TOKEN` (scope `read_api`), `GITLAB_API_URL=https://gitlab.com/api/v4` et `GITLAB_PERMISSION_MODE=readonly` dans l'environnement. Puis demander à l'agent de lire le log du job (`get_pipeline_job_output`) : il y retrouve `Root Token: hvs....`.

## 5. Rejouer / nettoyer

```bash
vault/vault-restart.sh        # relance les conteneurs + unseal + login
vault/vault-connect.sh        # unseal + login seulement
vault/cleanup-install.sh      # purge conteneurs + état + vault-key.txt
```

Après une nouvelle init, `vault-key.txt` change : le committer à nouveau si c'est l'artefact de référence.

## Limites et pièges

- La clé privée est détenue par l'opérateur : les participants exploitent la fuite n° 1 sans elle.
- Un Vault redémarré est scellé : les scripts et le `before_script` du job refont l'unseal.
- Les policies avec chemins de namespaces (Enterprise) ne sont pas appliquées (voir `policies/README.md`).
- Le mot de passe postgres `password` n'a aucune valeur en dehors du lab.

## Vérifications

- **2026-09-29** — `vault/vault.sh` exécuté sur cette machine : Vault 2.0.1 (`hashicorp/vault:2.0.1`), init `-pgp-keys`, unseal par déchiffrement PGP, login root, audit activé ; cycle `vault operator seal` → `vault/vault-connect.sh` → `Sealed false` + `policies [root]` vérifié. Clé d'unseal déchiffrée : 64 caractères. CLI hôte `vault` v2.0.1, `gpg` 2.4.8.
- Pipeline GitLab et lecture MCP : **pas encore exécutés** (en attente de l'enregistrement du runner sur le projet).

## Remotes

- GitHub (canonique, public) : `git@github.com:Sphinxgaia/1001hourswithvault.git`
- GitLab (CI, privé) : `git@gitlab.com:SphinxGaia/1001hourswithvault.git`
