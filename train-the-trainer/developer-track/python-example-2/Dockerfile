FROM cgr.dev/chainguard/python:latest-dev AS dev
WORKDIR /app
# Provide the list of packages that need to be deployed in the distroless image
ENV APK_LIST="mariadb-connector-c-dev mariadb"
USER root

# Install specified packages during the build stage
# Comment out or remove if specified system-level packages do not need to be present during the build stage
RUN apk add --no-cache ${APK_LIST}

# Install the packages into a root derived from the distroless image.
COPY --from=cgr.dev/chainguard/python:latest / /base-chroot
RUN apk add --no-commit-hooks --no-cache --root /base-chroot ${APK_LIST}

USER 65532

# Install desired Python packages
RUN python -m venv venv
ENV PATH="/app/venv/bin":$PATH

# Install python packages
COPY requirements.txt /app/
RUN pip install --upgrade pip setuptools wheel && \
   pip install --no-cache-dir -r /app/requirements.txt

FROM cgr.dev/chainguard/python:latest

# Replace the filesystem with the one containing the additional packages.
COPY --from=dev /base-chroot /

WORKDIR /app
COPY --from=dev /app/venv /app/venv
COPY run.py run.py

ENV PATH="/app/venv/bin:$PATH"

ENTRYPOINT ["python", "run.py"]
