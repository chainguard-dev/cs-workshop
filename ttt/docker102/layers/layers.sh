#! env bash
. ../../base.sh
TAGS=$(docker images layers --format json  | jq -r .Tag)
for tag in $TAGS; do
  docker rmi layers:$tag
done
clear
pe "cat Dockerfile.1"
pe "docker build . -t layers:1 -f Dockerfile.1"
pe "docker images layers"
#pe "docker image history layers.1"

pe "cat Dockerfile.2"
pe "docker build . -t layers:2 -f Dockerfile.2"
pe "docker images layers"
pe "diff Dockerfile.1 Dockerfile.2"

pe "docker image history layers:1"
pe "docker image history layers:2"