FROM cgr.dev/chainguard/python:latest-dev as dev

# The python image on DockerHub includes mariadb packages as standard. We need
# to add them explicitly.
USER root
RUN apk add mariadb-connector-c-dev mariadb
USER 65532

# Create a virtualenv that can be copied into the runtime stage
WORKDIR /app
RUN python -m venv venv
ENV PATH="/app/venv/bin":$PATH

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

FROM cgr.dev/chainguard/python:latest

# Copy libmariadb.so because it is required at runtime
COPY --from=dev /usr/lib/libmariadb.so* /usr/lib/

WORKDIR /app
COPY --from=dev /app/venv /app/venv
COPY run.py run.py

ENV PATH="/app/venv/bin:$PATH"

ENTRYPOINT ["python", "run.py"]
