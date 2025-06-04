FROM cgr.dev/chainguard/python:latest-dev

# The python image on DockerHub includes mariadb packages as standard. We need
# to add them explicitly.
USER root
RUN apk add mariadb-connector-c-dev mariadb
USER 65532

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY run.py run.py

ENTRYPOINT ["python", "run.py"]
