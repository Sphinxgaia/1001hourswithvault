# Variables Vault Enterprise — extraits du rôle `vault` (hashistack)

Extraits **verbatim** de la PR [wescale/hashistack#167 « Manage enterprise »](https://github.com/wescale/hashistack/pull/167), tête `1eecdb2d364b8ba6f298cf96b014625ab21998bd` (mergée le 2026-01-05), importés le 2026-09-30 par `git show`. Seuls les blocs utiles au lab2 sont repris ; les ellipses `[…]` marquent les coupes.

## `roles/vault/defaults/main.yml`

### URL géographique et port Raft

```yaml
hs_vault_geo_url: "{{ __hs_vault_api_protocol }}://{{ hs_vault_service_fqdn }}"
```

```yaml
# * RAFT API port number.
#
hs_vault_raft_port: "{{ hs_vault_api_port }}"
```

`hs_vault_use_custom_ca: false`
```yaml
hs_vault_use_uploaded_ca: false
```

### Télémétrie

```yaml
## Telemetry config

hs_vault_telemetry_prometheus_retention_time: "30s"
# Disabled if not needed
# hs_vault_add_custom_telemetry: >-
#   telemetry {
#     disable_hostname = true
#     enable_hostname_label = false
#     statsd_address = "localhost:8125"
#   }
```

### Post-configuration (audit, namespaces, snapshot automatique)

```yaml
## POST CONFIG

hs_vault_audit_log_filemane: audit.log
hs_vault_audit_log_desc: "Audit log file"

# Enterprise only
hs_vault_namespaces_list: []
# - parent: ""
#   name: admin
# - parent: admin 
#   name: test

hs_vault_autosnap_interval: "24h"
hs_vault_autosnap_retain: 7
hs_vault_autosnap_path: "{{__hs_vault_autosnapshot_dir}}"
hs_vault_autosnap_type: "local"
hs_vault_autosnap_localmaxspace: 10000000
```

> Note : `hs_vault_audit_log_filemane` est bien orthographié ainsi dans la source (coquille `filemane` pour `filename`).

## `roles/vault/vars/main.yml`

```yaml
[…]
__hs_vault_data_dir: "{{ __hs_vault_home_dir }}/data"
__hs_vault_log_dir: "{{ __hs_vault_home_dir }}/audit_logs"
__hs_vault_autosnapshot_dir: "{{ __hs_vault_home_dir }}/snapshots"
[…]
__hs_vault_raft_private_key: "{{ __hs_vault_self_private_key }}"
__hs_vault_raft_certificate: "{{ __hs_vault_self_certificate }}"

__hs_vault_raft_ca_certificate: "{{ __hs_vault_tls_dir }}/{{ hs_vault_local_ca_cert.split('/')[-1] }}"
[…]
__hs_vault_telemetry_prometheus_retention_time: "{{ hs_vault_telemetry_prometheus_retention_time | default('30s') }}"
```

## Variables attendues mais non définies par le rôle

Ces variables sont référencées par les tasks importées (`reference/tasks/`) mais **ne sont pas fournies par le rôle `vault`** : elles viennent de l'inventaire / des `host_vars` du déploiement.

| Variable | Usage observé |
|---|---|
| `hs_vault_root_operator_config` | nom et options du backend `userpass` des opérateurs racine (`.name`, `.conf`) |
| `hs_vault_root_operator` | liste/map des utilisateurs opérateurs et de leurs policies |
| `hs_vault_local_secret_dir` | répertoire local des secrets (root token, clés) chargé par `include_vars` |
| `vault_init_content` | contenu d'init (clés + root token) déchiffré localement |
| `hs_upload_licence` / `hs_vault_local_license_file` | licence Vault Enterprise (le template serveur écrit `license_path` selon ces variables) |

## Provenance

- Source : `wescale/hashistack`, `roles/vault/defaults/main.yml` (lignes 48, 67, 77, 174-201) et `roles/vault/vars/main.yml` (diff de la PR), commit `1eecdb2`.
- Import : 2026-09-30, `git fetch origin refs/pull/167/head` + `git show FETCH_HEAD:<chemin>`.
