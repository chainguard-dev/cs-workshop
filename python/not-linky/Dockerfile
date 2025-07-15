ARG IMAGE_REGISTRY="docker.io/library"
FROM ${IMAGE_REGISTRY}/python:latest

ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/venv/bin:$PATH"

WORKDIR /not-linky

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY not-linky.py not-linky.png ./

ENTRYPOINT [ "python", "/not-linky/not-linky.py" ]