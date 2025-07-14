#! env bash
. ../../base.sh
# clean out old mstage images
for i in $(docker images -q mstage); do
  docker rmi $i
done

clear
banner "Step 1: Using multistage to copy a large folder"
$BATCAT Dockerfile.4
p "docker build . -t mstage:4 -f Dockerfile.4"
docker build . -t mstage:4 -f Dockerfile.4 --quiet
pe "docker run --rm -it mstage:4"
pe "docker images mstage"

pe "docker image history mstage:4"

wait
banner "Step 2: Add --link to the COPY command"
$BATCAT Dockerfile.5
p "diff Dockerfile.4 Dockerfile.5"
diff --color=always Dockerfile.4 Dockerfile.5
p "docker build . -t mstage:5 -f Dockerfile.5"
docker build . -t mstage:5 -f Dockerfile.5 --quiet
pe "docker run --rm -it mstage:5"
pe "docker images mstage"
pe "docker image history mstage:5"
pe "docker image history mstage:4"
