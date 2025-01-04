# MongoDB с шардированием

В данной папке разворачивается MongoDB с шардированием и репликами, и API без кэширования.

## Запуск

Без реплик:

```shell
docker compose -f docker/compose.yaml --profile api up -d
```

С репликами:

```shell
docker compose -f docker/compose.yaml --profile api up -d --scale mongodb-shard-1=3 --scale mongodb-shard-2=3
```

Поднимется MongoDB и API. При желании можно поднять MongoDB Express:

```shell
docker compose -f docker/compose.yaml --profile api --profile mongo-express up -d
```

При создании контейнера с MongoDB в коллекции `users` появится 1000 пользователей, равномерно распределенных по шардам.

Интерактивная документация API будет доступна на http://localhost:8080/docs.
