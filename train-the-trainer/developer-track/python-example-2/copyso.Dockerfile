FROM cgr.dev/chainguard/python:latest-dev AS dev

# The python image on DockerHub includes mariadb packages as standard but we
# need to add them explicitly.
USER root
RUN apk add --no-cache mariadb-connector-c-dev mariadb
USER 65532

# Install python packages into a virtual environment so they can be easily
# copied into the runtime stage.
WORKDIR /app
RUN python -m venv venv
ENV PATH="/app/venv/bin":$PATH
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

FROM cgr.dev/chainguard/python:latest

# Copy the required .so from the dev stage into the runtime stage.
COPY --from=dev /usr/lib/libmariadb.so* /usr/lib/

# Copy virtual environment into the runtime stage.
WORKDIR /app
COPY --from=dev /app/venv /app/venv
ENV PATH="/app/venv/bin":$PATH

COPY run.py run.py

ENTRYPOINT ["python", "run.py"]
