# 1001hourswithvault

Dépôt des labs de démo du talk **« Mes 1001 Heures avec Vault — De Vault à OpenBao, récits de survie d'un SRE »** (Volcamp 2026, 1<sup>er</sup>-2 octobre). Chaque lab vit dans son propre dossier, avec son README didactique : but, prérequis, commandes exactes et résultat attendu.

> ⚠️ **Le lab1 met en scène des fuites de secrets volontaires.** Les root tokens et clés qu'on y trouve ne contrôlent qu'un Vault local éphémère, sur une seule machine. Ne jamais reproduire ces pratiques sur un Vault réel.

## Labs

| Lab | But | Statut |
|---|---|---|
| [`lab1/`](lab1/) | Fuites de root token : (1) le token d'init est committé dans le dépôt public, (2) après révocation, un job GitLab régénère un root token avec `generate-root` et l'affiche dans son log, récupérable via le MCP GitLab ; (3) un job manuel régénère une session root dans `~/.vault_token`, la contrôle puis la révoque. | prêt |
| [`lab2/`](lab2/) | Vault Enterprise : namespaces et policies, `userpass` + MFA, KV v2, audit, snapshot automatique, réplication DR — templates Terraform et tasks Ansible **de référence** (PR [hashistack#167](https://github.com/wescale/hashistack/pull/167)) + schéma d'architecture. | référence, non exécutable ([plan](lab2/PLAN-executable.md)) |
| [`lab3/`](lab3/) | OpenBao (Raft) : namespaces racine et `admin`, deux réseaux Docker à CIDR fixe et listeners liés aux IP statiques, deux proxys nginx — nginx2 force `X-Vault-Namespace: admin`. `userpass` et KV v2 par namespace, `docker compose`. | prêt |

## Structure du dépôt

| Chemin | Rôle |
|---|---|
| `lab1/` | scripts Vault, clé PGP du lab, policies, image de job CI, README |
| `lab2/` | modules Terraform (namespaces, userpass/MFA, KV v2, audit), tasks Ansible de référence (DR, rekey, snapshot/restore), schéma d'architecture, README et plan d'exécution |
| `lab3/` | `docker compose` OpenBao (Raft) + deux nginx, init/unseal one-shot, networks à CIDR fixe, README |
| `.gitlab-ci.yml` | point d'entrée CI : inclut le pipeline de chaque lab exécutable (`lab1/.gitlab-ci.yml`) |
| `bao/` | scripts OpenBao (exploration Acte 3), hors lab pour l'instant |

## Prérequis communs

- Docker (et l'accès au socket pour le runner) ;
- CLI `vault` 2.0.1 sur l'hôte (`lab1/vault/install-cli.sh`) ; CLI `bao` 2.5.x pour les vérifications du lab3 ;
- `gpg` 2.4+ ;
- un projet GitLab.com privé et un runner GitLab local (voir `lab1/README.md`) ;
- pour la lecture MCP : un PAT GitLab scope `read_api`.

## Remotes

- GitHub (canonique, public) : `git@github.com:Sphinxgaia/1001hourswithvault.git`
- GitLab (CI, privé) : `git@gitlab.com:SphinxGaia/1001hourswithvault.git`
