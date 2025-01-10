# Базовая MongoDB и API

В данной папке разворачивается MongoDB без шардирования и репликации, и API без кэширования.

<img src="diagram.png" alt="diagram" height="640">

## Запуск

```shell
docker compose up -d
```

Поднимется MongoDB и API. При желании можно поднять MongoDB Express:

```shell
docker compose --profile mongo-express up -d
```

При создании контейнера с MongoDB, в коллекции `users` появится 1000 пользователей.

Интерактивная документация API будет доступна на http://localhost:8080/docs.

## Остановка

```shell
docker compose --profile "*" down --remove-orphans --volumes
```
