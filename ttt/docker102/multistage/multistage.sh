#! env bash
. ../../base.sh
# clean out old mstage images
for i in $(docker images -q mstage); do
  docker rmi $i
done

#loop over 1 and 2
for i in 1 2; do
  if [ -z "$(docker images -q layers:$i)" ]; then
    docker build . -t layers:$i -f ../layers/Dockerfile.$i
  fi
done

clear
pe "bat Dockerfile.1"
pe "docker build . -t mstage:1 -f Dockerfile.1"
pe "docker images mstage"
pe "docker images layers"

pe "docker image history mstage:1"
pe "docker image history layers:2"

wait
clear
pe "cat Dockerfile.2"
pe "docker build . -t mstage:2 -f Dockerfile.2"
pe "docker run --rm -it mstage:2"

pe "docker build -t mstage:2b -f Dockerfile.2 --target=builder ."
pe "docker run --rm -it --entrypoint sh mstage:2b"

pe "cat Dockerfile.3"
pe "docker build . -t mstage:3 -f Dockerfile.3"
