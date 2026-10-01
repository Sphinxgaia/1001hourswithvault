# Lab 2 — plan pour un lab exécutable

**Statut : plan projeté, non exécuté.** Aucune commande de ce document n'a été lancée : il décrit le travail nécessaire pour transformer la référence [`lab2/README.md`](README.md) en démonstration tournante. Tant que ces chantiers ne sont pas terminés **et vérifiés** (commandes exactes, versions, résultats), lab2 reste marqué « non exécutable ».

## Prérequis bloquants

| Prérequis | Détail |
|---|---|
| Licence Vault Enterprise | Fichier `.hclic` **hors dépôt**, copié/monté en `0600` (ex. `~/secrets/vault-ent.hclic`) et référencé par `VAULT_LICENSE`/`license_path` ; jamais committé, jamais dans un log |
| Image Vault Enterprise | `hashicorp/vault-enterprise` avec tag figé (à choisir et consigner) |
| Docker | Réseau dédié (ex. `1002lab`) ; 2 clusters = 6 conteneurs Vault + LB si la DR est retenue |
| Terraform | Version figée + provider `hashicorp/vault` 5.2.1 (déjà épinglé dans les modules) |
| Backends Kubernetes | 3 clusters réels, ou 3 clusters éphémères (kind/k3d) pour la démo, ou repli sur `userpass` seul |

## Décisions à prendre avant de coder

1. **Ansible ou shell ?** Les tasks de `reference/tasks/` sont des tasks de rôle : soit les porter dans un mini-rôle avec un inventaire réduit, soit les réécrire en scripts shell autour de la CLI `vault`. Le lab1 a choisi le shell ; garder la même logique d'apprentissage est cohérent.
2. **DR pour de vrai ?** Un flux DR complet demande un second cluster et des tokens d'opération ; alternative : ne démontrer que l'activation du secondaire (`__enable_dr_secondary.yml`) et la promotion (`__dr_cluster_promote.yml`) avec des URLs locales.
3. **Kubernetes** : vrais clusters (lourd) ou mocks (kind ×3, léger) ; dans les deux cas, un backend kube par environnement (dev/préprod/prod).
4. **Backend Terraform** : local, mais le state contient des secrets (mots de passe générés) → état chiffré ou supprimé après la démo ; `.gitignore` strict.
5. **Namespaces** : figer `root → admin → team-a…team-d`, les policies par namespace et les montages KV v2.

## Chantiers

### 1. Socle Vault Enterprise (Docker)

- `lab2/vault/` : scripts dans l'esprit de `lab1/vault/` (`vault.sh`, `cleanup-install.sh`, `vault-connect.sh`) — démarrage du conteneur ENT avec licence montée, init, unseal, login, audit.
- `lab2/vault/vault.hcl` : storage Raft, listener TLS (certificats auto-signés du lab), `license_path`.
- `.gitignore` : état runtime, licence, clés, state Terraform.

### 2. Namespaces, authentification, secrets

- Root module Terraform appelant les quatre modules avec des variables d'exemple (un workspace par namespace, comme `reference/tasks/tf_addons/_namespaces.yml`).
- `userpass` + MFA TOTP pour l'opérateur ; policies `policy-operator*` depuis `terraform/namespaces/policies/`.
- 3 backends Kubernetes (dev/préprod/prod) : configuration d'un rôle par environnement, test d'authentification (token de service).
- Montages KV v2 `secure-secrets` / `k8s-secrets` par namespace + écriture/lecture d'un secret de test.

### 3. Exploitation

- Audit par namespace (`audit_logs`), vérification du fichier d'audit.
- Snapshot automatique Raft (`__enable_autosnapshot.yml`) et snapshot manuel (`__snapshot.yml`), restauration (`__restore.yml`).
- Rekey (`__rekey.yml`) : déroulé complet init → update → generate-root.

### 4. Réplication DR (si retenue)

- Second cluster ENT, activation du primaire (`sys/replication/dr/primary/enable`), du secondaire (`__enable_dr_secondary.yml`), promotion (`__dr_cluster_promote.yml`) et démotion (`__dr_cluster_demote.yml`).
- Vérifications : `vault read sys/replication/status` avant/après.

### 5. CI GitLab

- `lab2/.gitlab-ci.yml` inclus par le `.gitlab-ci.yml` racine ; runner local tag `local`, comme lab1.
- Les secrets (licence, tokens) arrivent par variables CI protégées ou montage runner — jamais par le dépôt.

### 6. Gates de vérification (mêmes exigences que lab1)

- Chaque étape du README de lab2 doit porter une entrée « Vérifications » : commande exacte, version d'outil, date, résultat observé.
- Pas de mesure ni de sortie inventée ; ce qui n'est pas vérifiable est écrit comme tel.
- Interdiction de committer licence, tokens, clés ou state Terraform en clair.

## Risques connus

- **Expiration/limite de la licence** : la démo doit pouvoir se rejouer ; prévoir la manipulation de licence hors dépôt.
- **Ressources** : 6 conteneurs Vault ENT + LB ; vérifier la RAM disponible avant de retenir la DR.
- **TLS** : les tasks référencent des certificats ; le lab doit fournir sa propre PKI locale (hors périmètre de cette référence).
- **State Terraform sensible** : les mots de passe `random_password` finissent dans le state ; ne jamais appliquer depuis un dépôt public sans backend chiffré.
