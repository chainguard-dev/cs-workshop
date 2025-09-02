#! env bash
. ../base.sh

CHOMP=$(docker rm -f my-chainguard)

clear
banner "Step 1: Start a container to debug"
pe "docker run -d --name my-chainguard -p 8080:8080 cgr.dev/chainguard/nginx"
pe "docker ps -l"

banner "Step 2: Exec into that container"
pe "docker exec -it my-chainguard sh"

banner "Step 3: Start a debug container attached to the target"
pe "docker run --rm -it --pid container:my-chainguard --network container:my-chainguard cgr.dev/chainguard/wolfi-base"

banner "Step 4: Start a debug container with the same UID as the target"
pe "docker run --rm -it --pid container:my-chainguard --network container:my-chainguard --user 65532:65532 cgr.dev/chainguard/wolfi-base"

banner "Step 5: Start a debug container in privileged mode"
pe "docker run --rm -it --pid container:my-chainguard --network container:my-chainguard --privileged cgr.dev/chainguard/wolfi-base"

banner "Extras: docker diff and cp"
pe "docker diff my-chainguard"
pe "docker cp my-chainguard:/var/lib/nginx/html/index.html index.html"
p "$BATCAT index.html"
$BATCAT index.html

