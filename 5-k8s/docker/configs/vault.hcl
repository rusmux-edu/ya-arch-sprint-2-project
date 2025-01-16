api_addr = "http://vault:8200"
cluster_name = "vault-cluster"
ui = true


storage "consul" {
  address = "consul:8500"
  path    = "vault"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}
