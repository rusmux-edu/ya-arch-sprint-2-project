FROM python:3.10-slim AS build

# fail build if there is an error at any stage in the pipe
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

ENV \
    # enable bytecode compilation for a faster startup
    UV_COMPILE_BYTECODE=1 \
    # copy from the cache instead of linking since it's a mounted volume
    UV_LINK_MODE=copy

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

WORKDIR /app

COPY uv.lock pyproject.toml ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

COPY api ./api
COPY README.md ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

FROM nvcr.io/nvidia/distroless/python:3.10-v3.4.4

COPY --from=build /app /app

ENV PATH="/app/.venv/bin:$PATH" \
    UVICORN_PORT=8080

CMD ["uvicorn", "--factory", "api.app:create_app", "--host", "0.0.0.0"]
