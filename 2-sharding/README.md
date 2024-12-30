# MongoDB с шардированием

В данной папке разворачивается MongoDB с шардированием без реплик, и API без кэширования.

## Запуск

```shell
docker compose -f docker/compose.yaml --profile api up -d
```

Поднимется MongoDB и API. При желании можно поднять MongoDB Express:

```shell
docker compose -f docker/compose.yaml --profile api --profile mongo-express up -d
```

После чего интерактивная документация API будет доступна на http://localhost:8080/docs.

Инициализируем конфигурационный сервер, роутер и шарды, наполняем MongoDB данными:

```shell
./scripts/mongodb-init.sh
```

После этого в коллекции `users` появится 1000 пользователей, равномерно распределенных по шардам.
