# API для MongoDB

Этот сервис предоставляет базовый API для получения данных из MongoDB.

## Установка

```shell
uv sync --frozen
```

## Запуск

```shell
uvicorn --factory api.app:create_app --port 8080
```
