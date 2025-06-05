#! env bash

. ../../base.sh

for i in $(docker images -q python-example-1); do
  docker rmi $i
done

clear

banner "Here's a simple python application and its Dockerfile."
pe "$BATCAT run.py"
pe "$BATCAT not-linky.Dockerfile"

banner "Build the image and run it."
pe "docker build -t python-example-1:not-linky -f not-linky.Dockerfile ."
pe "docker run --rm python-example-1:not-linky"

banner "Check the size."
pe "docker images python-example-1"

banner "And the vulnerabilities."
pe "grype python-example-1:not-linky"

banner "Let's migrate it to a Chainguard image."
pe "git diff --no-index -U1000 not-linky.Dockerfile Dockerfile"
pe "docker build -t python-example-1:linky ."

banner "It should be signficantly smaller."
pe "docker images python-example-1"

banner "And it should have a lot less CVEs."
pe "grype python-example-1:linky"

banner "However, when we try to run it..."
pe "docker run --rm python-example-1:linky"
