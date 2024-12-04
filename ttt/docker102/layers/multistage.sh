#! env bash
. ../../base.sh
docker rmi layers:3

#loop over 1 and 2
for i in 1 2; do
  if [ -z "$(docker images -q layers:$i)" ]; then
    docker build . -t layers:$i -f Dockerfile.$i
  fi
done

clear
pe "cat Dockerfile.3"
pe "docker build . -t layers:3 -f Dockerfile.3"
pe "docker images layers"

pe "docker image history layers:3"
pe "docker image history layers:1"