# all configuration options: https://developer.hashicorp.com/vault/docs/configuration
# lab sage

ui = true

disable_mlock = true

# Mode reprise : la famille generate-root est traitée comme non authentifiée
# (doc : enable_unauthenticated_access). C'est ce qui permet au job CI de
# régénérer un root token avec la seule clé d'unseal, même après révocation
# du root token initial. Rechargeable par SIGHUP.
enable_unauthenticated_access = ["generate-root"]

storage "file" {
  path = "/vault/file"
}

# HTTP listener
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}


# HTTPS listener
# listener "tcp" {
#   address       = "0.0.0.0:8200"
#   tls_cert_file = "/opt/vault/tls/tls.crt"
#   tls_key_file  = "/opt/vault/tls/tls.key"
# }
