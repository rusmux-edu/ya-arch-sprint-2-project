#!/usr/bin/env bash

set -euxo pipefail

dc_exec() {
  docker compose -f docker/compose.yaml exec -T "$@"
}

dc_exec mongodb-configSrv mongosh --port 27018 <<EOF
rs.initiate(
    {
        _id: "config-server",
        configsvr: true,
        members: [{_id: 0, host: "mongodb-configSrv:27018"}]
    }
);
EOF

dc_exec mongodb-shard-1-1 mongosh --port 27117 <<EOF
rs.initiate(
    {
        _id: "shard-1",
        members: [
            {_id: 0, host: "mongodb-shard-1-1:27117"},
            {_id: 1, host: "mongodb-shard-1-2:27118"},
            {_id: 2, host: "mongodb-shard-1-3:27119"},
        ]
    }
);
EOF

dc_exec mongodb-shard-2-1 mongosh --port 27217 <<EOF
rs.initiate(
    {
        _id: "shard-2",
        members: [
            {_id: 0, host: "mongodb-shard-2-1:27217"},
            {_id: 1, host: "mongodb-shard-2-2:27218"},
            {_id: 2, host: "mongodb-shard-2-3:27219"},
        ]
    }
);
EOF

sleep 5  # wait for the config server to be ready

dc_exec mongos-router mongosh --port 27017 <<EOF
sh.addShard("shard-1/mongodb-shard-1-1:27117");
sh.addShard("shard-2/mongodb-shard-2-1:27217");
sh.enableSharding("somedb");
sh.shardCollection("somedb.users", {"name": "hashed"});

use somedb
for (var i = 0; i < 1000; i++) db.users.insertOne({age: i, name: "User " + i});
EOF
