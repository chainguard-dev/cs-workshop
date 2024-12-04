FROM cgr.dev/chainguard/python:latest-dev AS dev
WORKDIR /app
# Provide the list of packages that need to be deployed in the distroless image
ENV APK_LIST="mariadb-connector-c-dev mariadb"
USER root

# Install specified packages during the build stage
# Comment out or remove if specified system-level packages do not need to be present during the build stage
RUN apk add --no-cache ${APK_LIST}

# Build a script used to install packages during the distroless stage
# The find commands allow us to avoid hardcoding the version number of libapk.so
RUN echo "cp /lib/libapk.so $(find /lib -name 'libapk.so*')" > /add_apks.sh
RUN echo "apk add --no-cache ${APK_LIST}" >> /add_apks.sh
RUN echo "rm $(find /lib -name 'libapk.so*')" >> /add_apks.sh
RUN cp $(find /lib -name 'libapk.so*') /lib/libapk.so
USER 0

# Install desired Python packages
RUN python -m venv venv
ENV PATH="/app/venv/bin":$PATH

# Install python packages
COPY requirements.txt /app/
RUN pip install --upgrade pip setuptools wheel && \
   pip install --no-cache-dir -r /app/requirements.txt

FROM cgr.dev/chainguard/python:latest

WORKDIR /app
COPY --from=dev add_apks.sh add_apks.sh
COPY --from=dev /app/venv /app/venv
COPY run.py run.py
USER root

# Mount resources needed to install apks and run the install script
RUN --mount=type=bind,from=dev,target=/sbin/apk,source=/sbin/apk \
   --mount=type=bind,from=dev,target=/bin/busybox,source=/bin/busybox \
   --mount=type=bind,from=dev,target=/bin/sh,source=/bin/sh \
   --mount=type=bind,from=dev,target=/bin/cp,source=/bin/cp \
   --mount=type=bind,from=dev,target=/bin/rm,source=/bin/rm \
   --mount=type=bind,from=dev,target=/etc/apk/keys,source=/etc/apk/keys,rw \
   --mount=type=bind,from=dev,target=/etc/apk/repositories,source=/etc/apk/repositories,rw \
   --mount=type=bind,from=dev,target=/etc/apk/protected_paths.d,source=/etc/apk/protected_paths.d,rw \
   --mount=type=bind,from=dev,target=/lib/libapk.so,source=/lib/libapk.so,rw \
   --mount=type=bind,from=dev,target=/add_apks.sh,source=/add_apks.sh,rw \
   /bin/sh /add_apks.sh

USER 0
ENV PATH="/app/venv/bin:$PATH"
ENTRYPOINT ["python", "run.py"]
