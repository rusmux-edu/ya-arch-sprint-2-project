# Базовая MongoDB и API

В данной папке разворачивается MongoDB без шардирования и репликации, и API без кэширования для работы с ней.

## Запуск

```shell
docker compose --profile api up -d
```

Поднимется MongoDB и API. При желании можно поднять MongoDB Express:

```shell
docker compose --profile api --profile mongo-express up -d
```

После чего интерактивная документация API будет доступна на http://localhost:8080/docs.

Заполняем MongoDB данными:

```shell
./scripts/mongodb-init.sh
```
