# Lab 3 — serveur OpenBao unique, stockage Raft intégré.
#
# Les listeners sont liés aux IP statiques de bao sur chaque réseau Docker
# (et non à 0.0.0.0) : chaque listener n'est joignable que depuis son réseau.
# Chaque listener ouvre en plus un listener de cluster sur port+1
# (172.28.1.10:8201, 172.28.2.10:8211 et 172.28.3.10:8221).
ui = true

api_addr     = "http://172.28.1.10:8200"
cluster_addr = "http://172.28.1.10:8201"

# Le volume nommé est monté sur /openbao/file, que l'entrypoint de l'image
# appartient déjà à l'utilisateur `openbao` (le serveur abandonne root).
storage "raft" {
  path    = "/openbao/file"
  node_id = "bao"
}

# Listener nginx1 — accès namespace racine, uniquement via root-net.
listener "tcp" {
  address     = "172.28.1.10:8200"
  tls_disable = true
}

# Listener nginx2 — accès namespace admin (en-tête injecté par nginx2),
# uniquement via admin-net.
listener "tcp" {
  address     = "172.28.2.10:8210"
  tls_disable = true
}

# Listener nginx3 — accès namespace admin (réécriture de chemin par nginx3),
# uniquement via rewrite-net.
listener "tcp" {
  address     = "172.28.3.10:8220"
  tls_disable = true
}
