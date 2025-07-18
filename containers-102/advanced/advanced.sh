#! env bash
. ../../base.sh
clear
banner "Step 1:   "
$BATCAT Dockerfile.1
pe "docker build . -t advanced:1 -f Dockerfile.1"
pe "docker images advanced"

pe "docker image history mstage:1"
pe "docker image history layers:2"

wait
banner "Step 2: Copying a dependency to a final stage w/out a package manager"
$BATCAT Dockerfile.2
pe "docker build . -t mstage:2 -f Dockerfile.2"
pe "docker run --rm -it mstage:2"

wait
banner "Step 2a: Find out what libraries are needed, target the builder image"
pe "docker build -t mstage:2b -f Dockerfile.2 --target=builder ."
pe "docker run --rm -it --entrypoint sh -u root mstage:2b"

wait
banner "Step 2b: Copy the .so file(s) to the final image"
$BATCAT Dockerfile.3
pe "docker build . -t mstage:3 -f Dockerfile.3"
pe "docker run --rm -it mstage:3"