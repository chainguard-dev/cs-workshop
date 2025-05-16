ARG ORG="chainguard.edu"
ARG IMAGE="python"

FROM cgr.dev/${ORG}/${IMAGE}:latest AS baseimage
FROM cgr.dev/$ORG/$IMAGE:latest-dev AS builder
ARG ORG
ARG APK_LIST="curl"

COPY --from=baseimage / /base-chroot
USER 0

# Configure private apk repo
RUN echo "https://apk.cgr.dev/$ORG" > /base-chroot/etc/apk/repositories

# add packages
RUN --mount=type=secret,id=cgr-token sh -c \
    "export HTTP_AUTH=basic:apk.cgr.dev:user:\$(cat /run/secrets/cgr-token) apk update && apk add --no-commit-hooks --no-cache --root /base-chroot ${APK_LIST}"
USER 65532

FROM baseimage
COPY --from=builder /base-chroot /
