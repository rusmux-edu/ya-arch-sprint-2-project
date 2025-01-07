# MongoDB с шардированием

В данной папке разворачивается MongoDB с шардированием и репликами, и API без кэширования.

<img src="diagram.png" alt="diagram" height="640">

## Запуск

Без реплик:

```shell
docker compose up -d
```

С репликами:

```shell
docker compose up -d --scale mongodb-shard-1=3 --scale mongodb-shard-2=3
```

Поднимется MongoDB и API. При желании можно поднять MongoDB Express:

```shell
docker compose --profile mongo-express up -d
```

При создании контейнера с MongoDB в коллекции `users` появится 1000 пользователей, равномерно распределенных по шардам.

Интерактивная документация API будет доступна на http://localhost:8080/docs.

## Остановка

```shell
docker compose --profile "*" down --remove-orphans --volumes
```
