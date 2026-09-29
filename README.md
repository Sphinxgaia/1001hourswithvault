# 1001hourswithvault

Dépôt des labs de démo du talk **« Mes 1001 Heures avec Vault — De Vault à OpenBao, récits de survie d'un SRE »** (Volcamp 2026, 1<sup>er</sup>-2 octobre). Chaque lab vit dans son propre dossier, avec son README didactique : but, prérequis, commandes exactes et résultat attendu.

> ⚠️ **Ce dépôt met en scène des fuites de secrets volontaires.** Les root tokens et clés qu'on y trouve ne contrôlent qu'un Vault local éphémère, sur une seule machine. Ne jamais reproduire ces pratiques sur un Vault réel.

## Labs

| Lab | But | Statut |
|---|---|---|
| [`lab1/`](lab1/) | Fuites de root token : (1) le token d'init est committé dans le dépôt public, (2) après révocation, un job GitLab régénère un root token avec `generate-root` et l'affiche dans son log, récupérable via le MCP GitLab. | prêt |
| `lab2/` | à venir | — |

## Structure du dépôt

| Chemin | Rôle |
|---|---|
| `lab1/` | scripts Vault, clé PGP du lab, policies, image de job CI, README |
| `.gitlab-ci.yml` | point d'entrée CI : inclut le pipeline de chaque lab (`lab1/.gitlab-ci.yml`) |
| `bao/` | scripts OpenBao (exploration Acte 3), hors lab pour l'instant |

## Prérequis communs

- Docker (et l'accès au socket pour le runner) ;
- CLI `vault` 2.0.1 sur l'hôte (`lab1/vault/install-cli.sh`) ;
- `gpg` 2.4+ ;
- un projet GitLab.com privé et un runner GitLab local (voir `lab1/README.md`) ;
- pour la lecture MCP : un PAT GitLab scope `read_api`.

## Remotes

- GitHub (canonique, public) : `git@github.com:Sphinxgaia/1001hourswithvault.git`
- GitLab (CI, privé) : `git@gitlab.com:SphinxGaia/1001hourswithvault.git`
