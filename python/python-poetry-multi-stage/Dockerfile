FROM cgr.dev/chainguard-private/python:3.10-dev as builder

USER root

RUN apk update && apk add shadow

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_HOME='/opt/venv/usr/' \
    POETRY_CACHE_DIR='/var/cache/pypoetry'

RUN python3.10 -m venv /opt/venv
ENV PATH="/opt/venv/usr/bin:$PATH"

WORKDIR /app

COPY ./app ./
COPY poetry.lock pyproject.toml ./

RUN pip3 install --upgrade pip && \
    pip3 install poetry==1.7.1 && \
    pip3 install urllib3==1.26.18 && \
    pip3 install aiohttp==3.9.1 && \
    pip install uvicorn[full] && \
    pip install --no-cache-dir fastapi && \
    poetry config --local virtualenvs.create true && \
    poetry config --local virtualenvs.in-project true 
    
ARG GITHUB_PAT
RUN if [ -n "$GITHUB_PAT" ]; then \
        poetry config http-basic.github-mlutils x-access-token $GITHUB_PAT; \
    fi

RUN poetry install --no-cache --no-root --only main --no-interaction

RUN poetry config --local virtualenvs.create true && \
    poetry config --local virtualenvs.in-project true && \
    poetry config --unset http-basic.github-mlutils

ENV PYTHONPATH ".:./ml_aeb:${PYTHONPATH}:/"
ENV WEB_CONCURRENCY 5

RUN chown -R nonroot:nonroot . .

FROM cgr.dev/chainguard-private/python:3.10

WORKDIR /app

COPY --from=builder $POETRY_HOME $POETRY_HOME
COPY --from=builder /etc/ /etc
COPY --from=builder /app/ .
COPY --from=builder /usr/bin/ /usr/bin
COPY --from=builder /usr/lib/python3.10/site-packages /usr/lib/python3.10/site-packages

EXPOSE 8000

ENTRYPOINT ["poetry", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
