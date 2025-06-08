#! env bash
. ../base.sh

for i in $(docker images -q node-example); do
  docker rmi $i
done

clear
banner "Here's an existing Dockerfile for a node application."
pe "$BATCAT ./not-linky/Dockerfile"
pe "docker build -t node-example:not-linky ./not-linky"
pe "docker run --rm node-example:not-linky"

banner "Let's migrate it to a Chainguard image."
pe "git diff --no-index -U1000 ./not-linky/Dockerfile ./linky/Dockerfile"
pe "docker build -t node-example:linky ./linky"
pe "docker run --rm node-example:linky"

banner "It should be significantly smaller."
pe "docker images node-example"

banner "And have significantly less vulnerabilities."
pe "grype node-example:not-linky"
pe "grype node-example:linky"
