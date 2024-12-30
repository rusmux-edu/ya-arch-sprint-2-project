#!/usr/bin/env bash

set -euxo pipefail

dc_exec() {
  docker compose -f docker/compose.yaml exec -T "$@"
}

dc_exec mongodb-1 mongosh <<EOF
use somedb
for (var i = 0; i < 1000; i++) db.users.insertOne({age: i, name: "User " + i});
EOF
