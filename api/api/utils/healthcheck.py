"""
Script to check the health of the FastAPI application.
In distroless images, the `curl` command is not available.
"""

import os

import httpx


def check_health() -> None:
    response = httpx.get(f"http://localhost:{os.environ['UVICORN_PORT']}/livez")
    response.raise_for_status()


if __name__ == "__main__":
    check_health()
