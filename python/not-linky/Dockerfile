FROM python:latest AS builder

ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/not-linky/venv/bin:$PATH"

WORKDIR /not-linky

RUN python -m venv /not-linky/venv
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

FROM python:latest

WORKDIR /not-linky

ENV PYTHONUNBUFFERED=1
ENV PATH="/venv/bin:$PATH"

COPY not-linky.py not-linky.png ./
COPY --from=builder /not-linky/venv /venv

ENTRYPOINT [ "python", "/not-linky/not-linky.py" ]

