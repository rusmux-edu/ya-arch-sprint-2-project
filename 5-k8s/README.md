# Helm-чарт API в Kubernetes

В данной папке развертывается Helm-чарт API в Kubernetes с кэшированием запросов в Redis, MongoDB с шардированием и
репликами.

## Запуск внешних зависимостей

Все сервисы разделены на профили, чтобы можно было запускать и тестировать их по отдельности.

```shell
docker compose --profile mongodb --profile redis --profile vault --profile registry up -d
```

Поднимется MongoDB, Redis, реестр секретов HashiCorp Vault, хранилище Consul и реестр образов.

При создании контейнера с MongoDB в коллекции `users` появится 1000 пользователей, равномерно распределенных по шардам.

### Остановка

```shell
docker compose --profile "*" down --remove-orphans --volumes
```

## Подготовка кластера Kubernetes

Для установки чарта нужен действующий кластер Kubernetes, если его нет, то можно развернуть локальный кластер с помощью
Minikube:

```shell
./scripts/minikube-create.sh
```

Создастся кластер с 2 узлами, развернутся Helm-чарты: Metrics Server, External Secrets, ChartMuseum.

Чтобы использовать внешний реестр секретов Vault, нужно создать секрет `api-vault-password` для подключения
ESO (External Secrets Operator) к Vault.
Вставьте закодированный пароль вместо `data.password` в манифест `manifests/vault-secret.yaml`:

```shell
echo -n 'password' | base64
```

Примените манифест:

```shell
kubectl create ns api
kubectl apply -f manifests/vault-secret.yaml -n api
```

## Установка Helm-чарта

Для использования локального образа, нужно загрузить его в локальный реестр образов:

```shell
docker tag ya-arch-sprint-2-project-api:0.1.0-distroless localhost:5000/ya-arch-sprint-2-project-api:0.1.0-distroless
docker push localhost:5000/ya-arch-sprint-2-project-api:0.1.0-distroless
```

Чтобы чарт можно было установить через локальный реестр чартов ChartMuseum, загрузите его в реестр:

```shell
helm package ../api/chart
curl --data-binary "@api-0.1.0.tgz" "http://<node_ip>:30080/api/charts"
helm repo add local "http://<node_ip>:30080"
helm repo update
```

Где `<node_ip>` – IP-адрес одного из узлов кластера. Для кластера Minikube его можно узнать через команду `minikube ip`.

### Serverless

Для использования Knative, нужно установить его в кластер:

```shell
kubectl apply -f https://github.com/knative/operator/releases/latest/download/operator.yaml --wait
kubectl apply -f manifests/knative-serving.yaml
```

В файле `helm/values/api.yaml` укажите в переменной `knative.enabled` значение `true` и установите чарт:

```shell
helm install api local/api -f helm/values/api.yaml -n api --create-namespace
```

Чтобы обратится к сервису извне кластера, нужно установить домен для балансировщика Kourier:

```shell
kubectl patch configmap/config-domain -n knative-serving --type merge -p '{"data":{"example.com":""}}'
```

После чего протестировать работу сервиса можно командой:

```shell
curl -H "Host: api.api.example.com" http://<node_ip>:<node_http_port>
```

Где `<node_http_port` – внешний порт балансировщика Kourier.

### HPA

Вместо Knative можно использовать горизонтальное автомасштабирование, для этого в файле `helm/values/api.yaml` укажите
`knative.enabled: false` и `autoscaling.enabled: true`, и установите чарт:

```shell
helm install api local/api -f helm/values/api.yaml -n api --create-namespace
```

Чтобы обратиться к сервису извне кластера, можно создать NodePort сервис:

```shell
kubectl expose deploy api --name api-node --type NodePort --port 8080 -n api
```

И обратиться к сервису по адресу `http://<node_ip>:<node_port>`.
