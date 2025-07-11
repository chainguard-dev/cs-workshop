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
banner "Step 1: Using multistage to eliminate unwanted layers"
pe "git diff --no-index -U1000 ../layers/Dockerfile.1 Dockerfile.1"
pe "docker build . -t mstage:1 -f Dockerfile.1"
pe "docker images mstage"
pe "docker images layers"

pe "docker image history mstage:1"
pe "docker image history layers:2"

wait
banner "Step 2: Copying a dependency to a final stage w/out a package manager"
pe "$BATCAT Dockerfile.2"
pe "docker build . -t mstage:2 -f Dockerfile.2"
pe "docker run --rm -it mstage:2"

wait
banner "Step 2a: Find out what libraries are needed, target the builder image."
pe "docker build -t mstage:2b -f Dockerfile.2 --target=builder ."
pe "docker run --rm --entrypoint sh -u root mstage:2b -c 'apk info --no-cache -L jq'"
pe "docker run --rm --entrypoint sh -u root mstage:2b -c 'apk add --no-cache cmd:ldd && ldd /usr/bin/jq'"

wait
banner "Step 2b: Copy the .so file(s) to the final image"
pe "git diff --no-index -U1000 Dockerfile.2 Dockerfile.3"
pe "docker build . -t mstage:3 -f Dockerfile.3"
pe "docker run --rm -it mstage:3"

wait
banner "Step 2c: Use the base-chroot method instead"
pe "git diff --no-index -U1000 Dockerfile.3 Dockerfile.4"
pe "docker build . -t mstage:4 -f Dockerfile.4"
pe "docker run --rm -it mstage:4"
pe "docker images mstage"
