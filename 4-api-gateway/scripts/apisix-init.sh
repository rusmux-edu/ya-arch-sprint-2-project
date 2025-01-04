#!/usr/bin/env sh

set -eux

sleep 3 # wait for the container to start

curl "http://apisix:9180/apisix/admin/routes" -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "id": "consul-mongodb-api-route",
  "uri": "/mongodb-api/*",
  "plugins": {
    "proxy-rewrite": {
      "regex_uri": ["^/mongodb-api/(.*)", "/$1"]
    }
  },
  "upstream": {
    "service_name": "mongodb-api",
    "discovery_type": "consul",
    "type": "roundrobin"
  }
}
'
