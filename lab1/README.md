# Lab 1 — Deux fuites de root token

Démo en deux temps autour d'un Vault local en Docker :

1. **Fuite n° 1 — le dépôt public.** L'init du Vault écrit `lab1/vault/vault-key.txt` : la clé d'unseal **chiffrée par PGP** et le **root token en clair**. Ce fichier est committé volontairement. On le retrouve dans le dépôt, on se connecte avec, on l'utilise, puis on le révoque.
2. **Fuite n° 2 — les logs GitLab.** Une fois le token révoqué, le job `vault-generate-root` régénère un root token avec la procédure Vault (`vault operator generate-root`, qui ne demande que la clé d'unseal) ; le token neuf s'affiche en clair dans le log du job et se récupère via le MCP GitLab (ou l'interface). On se reconnecte avec.

> ⚠️ **Avertissements** — le root token committé et la clé PGP publique ne contrôlent qu'un Vault local éphémère, sur cette machine. Ne jamais reproduire ces pratiques sur un Vault réel. La **clé privée** PGP du lab (`pgp/lab-secret.b64`) n'est **pas** dans le dépôt : elle reste chez l'opérateur et n'est montée que dans le runner local.

## Arborescence du lab

| Chemin (dans `lab1/`) | Rôle |
|---|---|
| `vault/` | scripts Docker : `vault.sh` (init PGP + unseal + login), `vault-connect.sh`, `vault-restart.sh`, `cleanup-install.sh`, `vault-key.txt` (artefact de fuite n° 1) |
| `pgp/` | clé PGP du lab : `lab-pub.b64` committée, `lab-secret.b64` locale (gitignorée) |
| `policies/templates/` | policies HCL appliquées par le job (`secretreader`, `secretwriter`, `operator`) |
| `ci/Dockerfile` | image de job (`vault` 2.0.1 + gnupg + jq) |
| `.gitlab-ci.yml` | pipeline du lab (`vault-configure`, `vault-generate-root`), inclus par le `.gitlab-ci.yml` racine |

## Prérequis

- Docker, CLI `vault` 2.0.1 (`lab1/vault/install-cli.sh`), `gpg` 2.4+ ;
- un projet GitLab.com privé, le conteneur `gitlab/gitlab-runner` ;
- pour l'étape MCP : un PAT GitLab scope `read_api`.

Les commandes se lancent depuis la racine du dépôt (`1001hourswithvault`).

---

## Mise en place (une seule fois)

### A. Clé PGP du lab

Déjà committée (`lab1/pgp/lab-pub.b64`, empreinte `DABE82446C2F55FEF76EBD6430A215E3012F5379`). Pour la régénérer :

```bash
mkdir -p lab1/pgp/gnupg && chmod 700 lab1/pgp/gnupg
GNUPGHOME="$PWD/lab1/pgp/gnupg" gpg --batch --generate-key <<'EOF'
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
export GNUPGHOME="$PWD/lab1/pgp/gnupg"
gpg --export | base64 -w0 > lab1/pgp/lab-pub.b64
gpg --export-secret-keys | base64 -w0 > lab1/pgp/lab-secret.b64
chmod 600 lab1/pgp/lab-secret.b64
```

### B. Image de job

```bash
docker build -t 1001lab/vault-ci:2.0.1 -f lab1/ci/Dockerfile .
```

### C. Runner GitLab local

Dans le projet GitLab.com : **Settings → CI/CD → Runners → New project runner** — y renseigner le tag `local` et la description (le workflow d'enregistrement actuel réserve ces champs au serveur). Puis :

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
  --docker-pull-policy if-not-present \
  --docker-allowed-pull-policies "always,if-not-present" \
  --docker-volumes "$PWD/lab1/pgp/lab-secret.b64:/lab/pgp/lab-secret.b64:ro"
```

Sans `--docker-allowed-pull-policies`, le runner refuse la politique `if-not-present` du job (l'image `1001lab/vault-ci:2.0.1` est locale, jamais poussée sur un registre).

Le job tourne **sur le réseau `1001lab`** (il joint Vault sur `http://server01:8200`) et la clé privée lui est **montée en lecture seule** — elle n'est jamais poussée.

### D. MCP GitLab (pour l'étape 7)

Le MCP est configuré pour la flotte par le rôle `agents` de `neural-codes` (wrapper + PAT `0600`). Pour un poste hors flotte :

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

avec `GITLAB_PERSONAL_ACCESS_TOKEN` (scope `read_api`), `GITLAB_API_URL=https://gitlab.com/api/v4`, `GITLAB_PERMISSION_MODE=readonly` et `GITLAB_TOOLSETS=pipelines` (le serveur expose un socle d'outils et active les outils de pipeline par toolset) dans l'environnement.

### E. Configurer le Vault par la CI

Le job `vault-configure` régénère lui-même un root token avec `generate-root` (la clé d'unseal suffit) et simule une session en l'écrivant dans `~/.vault_token` avant de s'y connecter : il ne dépend plus du token committé et peut donc tourner **à tout moment**, même après la révocation de la fuite n° 1. Lancez-le une fois (pipeline sur `main`) avant la démo, ou rejouez-le après.

---

## Déroulé de la démo

### 1. Démarrer et initialiser le Vault

```bash
lab1/vault/cleanup-install.sh   # seulement si un état existe déjà
lab1/vault/vault.sh
```

Le script démarre `server01` (port 8200) et `postgres` sur le réseau `1001lab`, initialise Vault avec une clé d'unseal chiffrée à la source (`-pgp-keys`), la déchiffre, unseal, se logue en root et active l'audit fichier.

Résultat dans `lab1/vault/vault-key.txt` :

```
Unseal Key 1: wcDMA...            <- chiffrée par la clé publique du lab
Initial Root Token: hvs....       <- en clair (fuite n° 1, assumée)
```

### 2. Montrer le Vault

```bash
vault status
```

Ouvrir l'interface : <http://127.0.0.1:8200/ui> (méthode **Token**, avec `hvs....` — ou laisser la session CLI).

### 3. Fuite n° 1 — retrouver le root token et se connecter

```bash
grep 'Initial Root Token' lab1/vault/vault-key.txt
vault login hvs.xxxxxxxx
vault token lookup
```

Attendu : `token_policies ["root"]`, `display_name root`. Le token à droits avancés était dans le dépôt, à la vue de tous.

### 4. L'utiliser

```bash
vault policy list
vault audit list
```

### 5. Révoquer le root token

```bash
vault token revoke -self
```

Vérifier qu'il est bien mort :

```bash
vault token lookup        # -> permission denied / bad token
```

### 6. Fuite n° 2 — la CI régénère un root token

Dans GitLab : **Build → Pipelines → Run pipeline** (branche `main`), puis **jouer manuellement** le job `vault-generate-root`.

Le job ne demande aucun token : le `vault.hcl` du lab active le mode reprise (`enable_unauthenticated_access = ["generate-root"]`), la famille `generate-root` est donc non authentifiée. Le job utilise seulement la clé d'unseal (déchiffrée par le runner avec la clé privée montée) et la procédure `vault operator generate-root`. Son log affiche le token neuf en clair :

```
hvs....
```

### 7. Retrouver le token via le MCP et se reconnecter

Demander à l'agent (ou ouvrir le log du job) de lire la sortie du job — via le MCP `gitlab` et l'outil `get_pipeline_job_output` — puis :

```bash
vault login hvs.<nouveau-token>
vault token lookup
```

Retour en root : la révocation du premier token n'a pas fermé la porte, la clé d'unseal suffit.

### 8. Révoquer une session root régénérée

Toujours dans **Build → Pipelines**, **jouer manuellement** le job `vault-revoke` : il est autonome — il régénère un root token (même procédure), simule une session en l'écrivant dans `~/.vault_token`, contrôle le token puis le révoque.

```bash
vault token lookup          # display_name root, policies [root]
vault token revoke -self
vault token lookup          # -> Error looking up token (révoqué)
```

### 9. Nettoyer

```bash
lab1/vault/cleanup-install.sh
```

---

## Dépannage

- **Vault scellé après un redémarrage** : `lab1/vault/vault-restart.sh` (relance les conteneurs + unseal + login) ou `lab1/vault/vault-connect.sh`.
- **Le job ne trouve pas Vault** : le réseau `1001lab` doit exister et `server01` tourner avant le job ; vérifier `docker network inspect 1001lab`.
- **`vault-configure` échoue** : vérifier que la clé d'unseal se déchiffre (clé privée PGP montée) et que `server01` tourne ; le job ne dépend plus du token committé.
- **`root generation already in progress`** : un essai `generate-root` précédent est resté en suspens (job interrompu) ; l'annuler avec `vault operator generate-root -cancel` (famille non authentifiée dans le lab).
- **Le runner ne démarre pas le job** : vérifier le tag `local` et que l'URL du projet correspond.
- **Nouvelle init** : `vault-key.txt` change ; le committer à nouveau pour garder l'artefact de fuite cohérent avec le Vault vivant.

## Vérifications (traçabilité)

- **2026-09-29** — `lab1/vault/vault.sh` exécuté : Vault 2.0.1 (`hashicorp/vault:2.0.1`), init `-pgp-keys`, unseal par déchiffrement PGP, login root, audit activé ; cycle `vault operator seal` → `lab1/vault/vault-connect.sh` → `Sealed false` + `policies [root]` vérifié. CLI hôte `vault` v2.0.1, `gpg` 2.4.8.
- **2026-09-29** — pipeline exécuté sur le runner local (gitlab-runner 19.3.3, image `1001lab/vault-ci:2.0.1`, réseau `1001lab`) : `vault-configure` en succès, `vault policy list` montre `secretreader`, `secretwriter`, `operator` ; `vault-generate-root` en succès, son log contient `Root Token: hvs....` ; ce token a permis `vault login` (policies `[root]`) puis a été révoqué. Lecture MCP vérifiée : `@zereight/mcp-gitlab` 2.1.67 en stdio (toolset `pipelines`), `get_pipeline_job_output` renvoie le log du job et le token `hvs.` qu'il contient.
- Mode reprise activé dans `lab1/vault/vault.hcl` (`enable_unauthenticated_access = ["generate-root"]`) : le job régénère un root token avec la seule clé d'unseal, sans aucun token ; vérifié par un `vault operator generate-root -init` sans token (OTP + nonce reçus).
- **2026-09-30** — nouveaux jobs `vault-configure` et `vault-revoke` rejoués localement contre `server01` (CLI hôte `vault` v2.0.1, `jq` 1.8.1, `gpg` 2.4.8), commandes copiées du YAML :
  - `vault-configure` : `generate-root` complet, sortie brute de `-decode` = `hvs.…` (28 caractères), écrite dans `~/.vault_token` (29 octets) ; `vault login` → `display_name root`, `policies [root]` ; policies `secretreader`, `secretwriter`, `operator` écrites puis listées ; token de test révoqué en fin de vérification.
  - `vault-revoke` : même procédure, `vault token lookup` → `policies [root]`, `vault token revoke -self`, puis `vault token lookup` → `Error looking up token` (révocation confirmée).
  - `~/.vault-token` sauvegardé/restauré, `~/.vault_token` supprimé, `vault status` → `Sealed false`. Le pipeline GitLab n'a pas été relancé (aucun push) : les jobs sont validés par ce rejeu local, à confirmer au prochain pipeline.
