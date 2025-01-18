#!/usr/bin/env sh

set -eux

REDIS_CLUSTER_NODES=$(docker ps -a --format "{{.Names}}" | grep -E "redis-cluster-[0-9]+$" |
  awk '{print $0 ":6379"}' | xargs)

docker exec ya-arch-sprint-2-project-redis-cluster-1 sh -c \
  "echo 'yes' | redis-cli --cluster create $REDIS_CLUSTER_NODES --cluster-replicas 1"
