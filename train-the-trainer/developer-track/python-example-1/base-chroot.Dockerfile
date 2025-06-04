FROM cgr.dev/chainguard/python:latest-dev as dev

# The python image on DockerHub includes mariadb packages as standard. We need
# to add them explicitly.
USER root
RUN apk add mariadb-connector-c-dev mariadb

# Install the packages into a root derived from the distroless image.
COPY --from=cgr.dev/chainguard/python:latest / /base-chroot
RUN apk add --no-commit-hooks --no-cache --root /base-chroot mariadb-connector-c-dev mariadb

USER 65532

# Create a virtualenv that can be copied into the runtime stage
WORKDIR /app
RUN python -m venv venv
ENV PATH="/app/venv/bin":$PATH

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

FROM cgr.dev/chainguard/python:latest

# Replace the filesystem with the one containing the additional packages.
COPY --from=dev /base-chroot /

WORKDIR /app
COPY --from=dev /app/venv /app/venv
COPY run.py run.py

ENV PATH="/app/venv/bin:$PATH"

ENTRYPOINT ["python", "run.py"]
