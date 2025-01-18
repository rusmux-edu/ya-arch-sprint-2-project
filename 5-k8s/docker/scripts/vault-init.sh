#!/usr/bin/env sh

set -eu

sleep 5

export VAULT_ADDR='http://vault:8200'

vault operator init -key-shares=1 -key-threshold=1 >keys.txt
vault operator unseal "$(grep 'Unseal Key 1:' keys.txt | awk '{print $4}')"
ROOT_TOKEN=$(grep 'Initial Root Token:' keys.txt | awk '{print $4}')
vault login -no-print "$ROOT_TOKEN"

vault secrets enable -path=secret kv-v2
vault kv put -mount=secret api/mongodb url="${MONGODB__URL}"
vault kv put -mount=secret api/redis url="${REDIS__URL}"

vault policy write secret - <<EOF
path "secret*" {
    capabilities = ["create", "read", "update", "delete", "list", "patch"]
}
EOF

vault auth enable userpass
vault write auth/userpass/users/admin password="${ADMIN_PASSWORD}" policies=secret

vault token revoke "$ROOT_TOKEN"
rm -f keys.txt
