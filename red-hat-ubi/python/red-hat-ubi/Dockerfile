FROM registry.access.redhat.com/ubi9/python-312:latest

ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/app/venv/bin:$PATH"

WORKDIR /app

RUN python -m venv /app/venv
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py app.png ./

ENTRYPOINT [ "python", "/app/app.py" ]
