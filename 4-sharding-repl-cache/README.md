# Кэширование запросов в Redis

В данной папке разворачивается MongoDB с шардированием и репликацией, API с кэшированием запросов в Redis.

## Запуск

```shell
docker compose -f docker/compose.yaml --profile api up -d
```

Поднимется MongoDB, API и Redis.

При желании можно поднять MongoDB Express и Redis Insight:

```shell
docker compose -f docker/compose.yaml --profile api --profile mongo-express --profile redis-insight up -d
```

При создании контейнера с MongoDB в коллекции `users` появится 1000 пользователей, равномерно распределенных по шардам.

Интерактивная документация API будет доступна на http://localhost:8080/docs.

Проверить работу кэширования можно замерив скорость выполнения запроса `/{collection_name}/users` первый и последующие
разы.
