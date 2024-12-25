FROM python:3.10-slim

ENV \
    # enable bytecode compilation for a faster startup
    UV_COMPILE_BYTECODE=1 \
    # copy from the cache instead of linking since it's a mounted volume
    UV_LINK_MODE=copy \
    PATH="/app/.venv/bin:$PATH"

# fail build if there is an error at any stage in the pipe
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

WORKDIR /app

RUN groupadd -g 1000 user \
    && useradd -u 1000 -g user user

COPY --chown=user:user uv.lock pyproject.toml ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

COPY --chown=user:user api ./api
COPY --chown=user:user README.md ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

USER user

CMD ["uvicorn", "--factory", "api.app:create_app", "--host", "0.0.0.0", "--port", "8080"]
