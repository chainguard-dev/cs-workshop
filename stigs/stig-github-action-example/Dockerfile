ARG CHAINGUARD_ORG=""

FROM cgr.dev/${CHAINGUARD_ORG}/chainguard-base-fips:latest

USER 0
ENV TZ=US/Eastern
RUN apk add --no-cache tzdata
RUN ln -sf /usr/share/zoneinfo/US/Eastern /etc/localtime
ENV TZPATH=/usr/share/zoneinfo/
USER 65532
