# API для MongoDB

Этот сервис предоставляет базовый API для получения данных из MongoDB.

## Установка

```shell
uv sync --frozen
```

## Запуск

Сервис настраивается через переменные окружения, которые можно указать в файле `.env`.

```shell
export UVICORN_PORT=8080
uvicorn --factory api.app:create_app
```
