FROM cgr.dev/chainguard/go:latest-dev as builder

WORKDIR /app 
ADD . ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags="-s -w" --installsuffix cgo -o main .


FROM cgr.dev/chainguard/static:latest

WORKDIR /app
COPY --from=builder /app/main  /app/main

ENTRYPOINT ["/app/main"]
