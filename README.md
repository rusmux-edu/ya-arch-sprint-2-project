# Шардирование, репликация, кэширование и маршрутизация

В этом проекте реализовано шардирование и репликация MongoDB, кэширование запросов к API в Redis и маршрутизация через
Apache APISIX.

В папках развертываются:

- [1-base](1-base) – MongoDB без шардирования и репликации, API без кэширования.

- [2-sharding-repl](2-sharding-repl) – MongoDB с шардированием и репликами (или без), API без кэширования.

- [3-sharding-repl-cache](3-sharding-repl-cache) – API с кэшированием запросов в Redis, MongoDB с шардированием и
  репликами.

- [4-api-gateway](4-api-gateway) – несколько экземпляров API с маршрутизацией через Apache APISIX и кэшированием
  запросов в Redis, MongoDB с шардированием и репликами.

- [5-k8s](5-k8s) – Helm-чарт API в Kubernetes с кэшированием запросов в Redis, MongoDB с шардированием и репликами.

> [!IMPORTANT]
> Для запуска проектов требуется Docker Compose версии 2.24.4 или выше, а также доступ к Docker сокету по пути
`/var/run/docker.sock`.

## Схема

<img src="4-api-gateway/diagram.drawio.png" alt="diagram" height="720">
