FROM cgr.dev/chainguard/python:latest-dev AS dev
WORKDIR /app

# Provide the list of packages that need to be deployed in the distroless image
ENV APK_LIST="mariadb-connector-c-dev mariadb"
USER root

COPY main.py main.py
RUN python -m compileall .
ENV PATH="/app/venv/bin":$PATH

# Install specified packages during the build stage
# Comment out or remove if specified system-level packages do not need to be 
# present during the build stage
RUN apk add --no-cache ${APK_LIST}

# Install the packages into a root derived from the distroless image.
COPY --from=cgr.dev/chainguard/python:latest / /base-chroot
RUN apk add --no-commit-hooks --no-cache --root /base-chroot ${APK_LIST}

USER 0

# Install desired Python packages
RUN python -m venv venv
ENV PATH="/app/venv/bin":$PATH

# Install python packages
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r /app/requirements.txt

FROM cgr.dev/chainguard/python:latest

WORKDIR /app

# Replace the filesystem with the one containing the additional packages.
COPY --from=dev /base-chroot /

COPY --from=dev /app/__pycache__ /app/__pycache__
COPY --from=dev /app/venv /app/venv
COPY main.py main.py
USER root

USER 0
ENV PATH="/app/venv/bin:$PATH"
ENTRYPOINT ["python", "__pycache__/main.cpython-313.pyc"]
