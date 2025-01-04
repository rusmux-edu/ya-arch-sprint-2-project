#!/usr/bin/env sh

set -eux

get_shard_members() {
  shard_number="$1"
  docker ps --filter name=mongodb-shard-"$shard_number" --format "{{.Names}}" | \
    sort -t '-' -k 3n | \
    awk '{ printf "{_id: %d, host: \\\"%s:27018\\\"},", NR-1, $1 }'
}

sleep 5  # wait for the containers to start

docker exec mongodb-configSrv sh -c "echo \"
rs.initiate({
    _id: 'config-server',
    configsvr: true,
    members: [{_id: 0, host: 'mongodb-configSrv:27019'}]
});
\" | mongosh --port 27019"

docker exec mongodb-shard-1-1 sh -c "echo \"
rs.initiate({_id: 'shard-1', members: [$(get_shard_members 1)]});
\" | mongosh --port 27018"

docker exec mongodb-shard-2-1 sh -c "echo \"
rs.initiate({_id: 'shard-2', members: [$(get_shard_members 2)]});
\" | mongosh --port 27018"

sleep 5  # wait for the config server to be ready

docker exec mongos-router sh -c "echo \"
sh.addShard('shard-1/mongodb-shard-1-1:27018');
sh.addShard('shard-2/mongodb-shard-2-1:27018');
sh.enableSharding('somedb');
sh.shardCollection('somedb.users', {'name': 'hashed'});

use somedb;
for (var i = 0; i < 1000; i++) db.users.insertOne({age: i, name: 'User ' + i});
\" | mongosh"
