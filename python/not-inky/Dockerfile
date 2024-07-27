FROM python:latest AS builder

ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/not-inky/venv/bin:$PATH"

WORKDIR /not-inky

RUN python -m venv /not-inky/venv
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

FROM python:latest

WORKDIR /not-inky

ENV PYTHONUNBUFFERED=1
ENV PATH="/venv/bin:$PATH"

COPY not-inky.py not-inky.png ./
COPY --from=builder /not-inky/venv /venv

ENTRYPOINT [ "python", "/not-inky/not-inky.py" ]

