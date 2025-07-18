#! env bash
. ../../base.sh

for i in $(docker images -q advanced); do
  docker rmi $i
done

clear
banner "Idea 1: Simple COPY command to copy a file from a builder image to a final image"
$BATCAT Dockerfile.1
pe "docker build . -t advanced:1 -f Dockerfile.1"
pe "docker images advanced"
pe "docker image history advanced:1"

wait
banner "Idea 2: Using the -dev tag variant and removing packages"
$BATCAT Dockerfile.2
pe "docker build . -t advanced:2 -f Dockerfile.2"
pe "docker images advanced"
pe "docker image history advanced:2"

wait
banner "Idea 3: Using a chroor'ed apk add"
$BATCAT Dockerfile.3
pe "docker build . -t advanced:3 -f Dockerfile.3"
pe "docker images advanced"
pe "docker image history advanced:3"

