# Use the latest-dev tag for the 'build' stage.
FROM cgr.dev/chainguard/python:latest-dev AS builder

ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/app/venv/bin:$PATH"

WORKDIR /app

RUN python -m venv /app/venv
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Use the 'latest' tag for runtime.
FROM cgr.dev/chainguard/python:latest

WORKDIR /app

ENV PYTHONUNBUFFERED=1
ENV PATH="/venv/bin:$PATH"

# Copy the required dependencies we installed with pip into the runtime image.
COPY --from=builder /app/venv /venv

COPY app.py app.png ./

ENTRYPOINT [ "python", "/app/app.py" ]
