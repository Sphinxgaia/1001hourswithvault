# Policies du lab

Trois policies sont appliquées au Vault local par le job `vault-configure`
du pipeline (`.gitlab-ci.yml`), directement depuis les fichiers du dépôt :

| Fichier | Policy Vault | Contenu |
|---|---|---|
| `templates/policy-secretreader.hcl` | `secretreader` | lecture/listing sur `secure-secrets/*` |
| `templates/policy-secretwriter.hcl` | `secretwriter` | create/update/delete/read/list sur `secure-secrets/*` |
| `templates/policy-operator.hcl` | `operator` | droits d'exploitation Vault (santé, audit, policies, auth, mounts, identity…) |

`policy-operator.hcl` contient aussi des chemins Enterprise (`sys/license`,
`sys/replication/*`, `sys/namespaces*`) : inertes sur un Vault OSS, mais la
policy reste valide à écrire. C'est la policy de démonstration « droits
avancés » du lab.

Non appliquées par le job :

- `templates/policy-operator-nsadmin.hcl`, `policy-operator-childadmin.hcl`,
  `policy-admin-childns.hcl` : chemins de namespaces (Enterprise uniquement) ;
- `templates/vault-server.hcl.j2`, `vault.service.j2` : modèles de
  déploiement VM (systemd), hors périmètre du lab Docker.
