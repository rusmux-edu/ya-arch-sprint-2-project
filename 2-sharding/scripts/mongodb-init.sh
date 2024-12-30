#!/usr/bin/env bash

set -euxo pipefail

dc_exec() {
  docker compose -f docker/compose.yaml exec -T "$@"
}

dc_exec mongodb-configSrv mongosh --port 27019 <<EOF
rs.initiate(
    {
        _id: "config-server",
        configsvr: true,
        members: [{_id: 0, host: "mongodb-configSrv:27019"}]
    }
);
EOF

dc_exec mongodb-shard-1 mongosh --port 27018 <<EOF
rs.initiate(
    {
        _id: "shard-1",
        members: [{_id: 0, host: "mongodb-shard-1-1:27018"}]
    }
);
EOF

dc_exec mongodb-shard-2 mongosh --port 27018 <<EOF
rs.initiate(
    {
        _id: "shard-2",
        members: [{_id: 0, host: "mongodb-shard-2-1:27018"}]
    }
);
EOF

sleep 5  # wait for the config server to be ready

dc_exec mongos-router mongosh <<EOF
sh.addShard("shard-1/mongodb-shard-1-1:27018");
sh.addShard("shard-2/mongodb-shard-2-1:27018");
sh.enableSharding("somedb");
sh.shardCollection("somedb.users", {"name": "hashed"});

use somedb
for (var i = 0; i < 1000; i++) db.users.insertOne({age: i, name: "User " + i});
EOF
