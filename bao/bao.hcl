ui = true

disable_mlock = true

storage "file" {
  path = "/bao/file"
}

# HTTP listener
listener "tcp" {
  address     = "0.0.0.0:8300"
  tls_disable = 1
}

# HTTP listener
listener "tcp" {
  address     = "0.0.0.0:8400"
  tls_disable = 1
}

audit "file" "to-stdout" {
  description = "Default audit device"
  options = {
    file_path = "/bao/file/audit/audit.log"
    log_raw = "false"
  }
}

# HTTPS listener
# listener "tcp" {
#   address       = "0.0.0.0:8300"
#   tls_cert_file = "/opt/vault/tls/tls.crt"
#   tls_key_file  = "/opt/vault/tls/tls.key"
# }
