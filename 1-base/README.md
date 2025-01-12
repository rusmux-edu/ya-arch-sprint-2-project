# Базовая MongoDB и API

В данной папке развертывается MongoDB без шардирования и репликации, и API без кэширования.

<img src="diagram.png" alt="diagram" height="640">

## Запуск

Все сервисы разделены на профили, чтобы можно было запускать и тестировать их по отдельности.

```shell
docker compose --profile api --profile mongodb up -d
```

Поднимется MongoDB и API. При желании можно поднять MongoDB Express:

```shell
docker compose --profile api --profile mongo-express up -d
```

Чтобы не перечислять все профили, можно указать `--profile "*"`.

При создании контейнера с MongoDB, в коллекции `users` появится 1000 пользователей.

Интерактивная документация API будет доступна на http://localhost:8080/docs.

## Остановка

```shell
docker compose --profile "*" down --remove-orphans --volumes
```
