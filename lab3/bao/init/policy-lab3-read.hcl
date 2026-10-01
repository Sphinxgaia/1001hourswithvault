# Lecture seule du KV v2 `secret` : données + métadonnées.
path "secret/data/*" {
  capabilities = ["read"]
}

path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
