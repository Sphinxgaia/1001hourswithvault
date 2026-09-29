# piloter les namespaces enfants de nsadmin (namespace d'accueil des authentifications autres que les opérateurs)
path "nsadmin/sys/namespaces*" {
  capabilities = ["create","update","read", "list"]
}

path "nsadmin/+/sys/namespaces*" {
  capabilities = ["create","update","read", "list"]
}

# Create and manage ACL policies broadly across Vault

# List existing policies
path "nsadmin/sys/policies/acl" {
  capabilities = ["list"]
}

# Create and manage ACL policies
path "nsadmin/sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault
# Allow managing leases
path "nsadmin/sys/leases/*" {
  capabilities = ["read", "update", "list","sudo"]
}


# # Manage auth methods broadly across Vault
path "nsadmin/auth/*" {
  capabilities = [ "create", "read", "update", "delete", "list",]
}

# List auth methods
path "nsadmin/sys/auth" {
  capabilities = ["read"]
}

# Manage identity
path "nsadmin/identity/entity*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "nsadmin/identity/group*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "nsadmin/identity/lookup/group" {
  capabilities = ["read","list"]
}

path "nsadmin/identity/lookup/identity" {
  capabilities = ["read","list"]
}

# Manage K8S
# path "nsadmin/transit-k8s*" {
#   capabilities = ["create", "read", "update", "delete", "list"]
# }
