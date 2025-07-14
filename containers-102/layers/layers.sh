#! env bash
. ../../base.sh
TAGS=$(docker images layers --format json  | jq -r .Tag)
for tag in $TAGS; do
  docker rmi layers:$tag
done
clear
banner "Step 1: Get a big file, untar it, and remove the tarball"
$BATCAT Dockerfile.1
p "docker build . -t layers:1 -f Dockerfile.1"
docker build . -t layers:1 -f Dockerfile.1 --quiet
pe "docker images layers"
pe "docker image history layers:1"
wait

banner "Step 2: Concatenate operations into a single RUN line"
$BATCAT Dockerfile.2
p "docker build . -t layers:2 -f Dockerfile.2"
docker build . -t layers:2 -f Dockerfile.2 --quiet
pe "docker images layers"
p "diff Dockerfile.1 Dockerfile.2"
diff --color=always Dockerfile.1 Dockerfile.2
pe "docker image history layers:1"
pe "docker image history layers:2"
