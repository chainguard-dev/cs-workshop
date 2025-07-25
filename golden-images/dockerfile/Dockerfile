ARG SOURCE_IMAGE
ARG WORK_IMAGE=cgr.dev/chainguard/busybox

# Use an image with a shell to concatenate ca-certificates.crt from the source
# image with our custom CA certs.
FROM ${SOURCE_IMAGE} AS src
FROM ${WORK_IMAGE} AS work

WORKDIR /work

COPY --from=src /etc/ssl/certs/ca-certificates.crt ca-certificates.crt.src
COPY resources/custom-*.crt .
RUN cat ca-certificates.crt.src custom-*.crt > ca-certificates.crt

# Copy the appended certificate bundle and the rest of the files into the image
FROM ${SOURCE_IMAGE}

COPY --from=work /work/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY resources/custom-*.crt /usr/local/share/ca-certificates/
COPY resources/repositories /etc/apk/repositories
COPY resources/*.rsa.pub /etc/apk/keys/
