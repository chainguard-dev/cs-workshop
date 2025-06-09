ARG ORG=chainguard-private
FROM cgr.dev/${ORG}/zig:latest-dev AS builder
WORKDIR /app
ADD . .
RUN apk add --no-cache bash
RUN zig build --release=fast -Dtarget=aarch64-linux-musl -Doptimize=ReleaseFast

FROM cgr.dev/chainguard/static
COPY --from=builder /app/zig-out/bin/app /usr/local/bin/app
ENTRYPOINT ["/usr/local/bin/app"]
