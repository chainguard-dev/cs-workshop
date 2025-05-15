ARG ORG="chainguard.edu"
ARG IMAGE="python"

FROM cgr.dev/$ORG/$IMAGE:latest-dev
ARG ORG
ARG APK_LIST="curl"
USER 0

# Configure private apk repo
RUN echo "https://apk.cgr.dev/$ORG" > /etc/apk/repositories

# add packages
RUN --mount=type=secret,id=cgr-token sh -c \
    "export HTTP_AUTH=basic:apk.cgr.dev:user:\$(cat /run/secrets/cgr-token) apk update && apk add ${APK_LIST}"

USER 65532