# MongoDB с шардированием и репликацией, API с кэшированием

В данной папке разворачивается MongoDB с шардированием c репликами, и API с кэшированием запросов через Redis.

## Запуск

```shell
docker compose -f docker/compose.yaml --profile api up -d
```

Поднимется MongoDB, API и Redis. При желании можно поднять MongoDB Express и Redis Insight:

```shell
docker compose -f docker/compose.yaml --profile api --profile mongo-express --profile redis-insight up -d
```

После чего интерактивная документация API будет доступна на http://localhost:8080/docs.

Инициализируем конфигурационный сервер, роутер и шарды, наполняем MongoDB данными:

```shell
../3-sharding-repl/scripts/mongodb-init.sh
```

После этого в коллекции `users` появится 1000 пользователей, равномерно распределенных по шардам.
