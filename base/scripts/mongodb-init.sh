#!/usr/bin/env bash

set -euxo pipefail

docker compose exec -T mongodb-1 mongosh <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.users.insertOne({age:i, name:"User "+i})
EOF
