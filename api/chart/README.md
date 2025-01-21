# api

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.1.0](https://img.shields.io/badge/AppVersion-0.1.0-informational?style=flat-square)

A Helm chart for Python API of Yandex.Practicum architecture course sprint 2 project

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `10` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| autoscaling.targetMemoryUtilizationPercentage | string | `nil` |  |
| externalSecrets.enabled | bool | `false` |  |
| externalSecrets.provider | string | `nil` |  |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `nil` |  |
| image.tag | string | `"0.1.0-distroless"` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `nil` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"api.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| knative.enabled | bool | `false` |  |
| knative.maxScale | int | `10` |  |
| knative.metric | string | `"rps"` |  |
| knative.target | int | `50` |  |
| networkPolicy.enabled | bool | `false` |  |
| replicaCount | int | `2` |  |
| resources.limits.cpu | string | `"250m"` |  |
| resources.limits.ephemeral-storage | string | `"500Mi"` |  |
| resources.limits.memory | string | `"256Mi"` |  |
| resources.requests.cpu | string | `"50m"` |  |
| resources.requests.ephemeral-storage | string | `"100Mi"` |  |
| resources.requests.memory | string | `"64Mi"` |  |
| service.port | int | `8080` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `nil` |  |
| settings.dummy | string | `nil` |  |
| settings.mongodb.dbName | string | `nil` |  |
| settings.mongodb.url | string | `""` |  |
| settings.mongodb.writeConcern | string | `nil` |  |
| settings.redis.isCluster | string | `nil` |  |
| settings.redis.url | string | `""` |  |

