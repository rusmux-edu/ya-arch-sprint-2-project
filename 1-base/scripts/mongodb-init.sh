#!/usr/bin/env sh

set -eux

until mongosh --quiet --eval 'db.runCommand("ping").ok'; do
  sleep 1
done

mongosh <<EOF
use example_db
for (var i = 0; i < 1000; i++) db.users.insertOne({age: i, name: "User " + i});
EOF
