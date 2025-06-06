#! env bash

. ../../base.sh

for i in $(docker images -q java-example); do
  docker rmi $i
done

clear

banner "Here's the Dockerfile for a single stage java build."
pe "$BATCAT java-example-1-orig/Dockerfile"

banner "Build and run it. Use Ctrl+C to stop the app."
pe "docker build -t java-example:1-orig ./java-example-1-orig"
pe "docker run -p 8080:8080 --rm java-example:1-orig"

banner "Check the size."
pe "docker images java-example"

banner "And scan it with grype."
pe "grype java-example:1-orig"

banner "Let's convert it to a multi-stage build."
pe "git diff --no-index -U1000 java-example-1-orig/Dockerfile java-example-2-orig-multi/Dockerfile" 

banner "Build and run it. Use Ctrl+C to stop the app."
pe "docker build -t java-example:2-orig-multi ./java-example-2-orig-multi"
pe "docker run -p 8080:8080 --rm java-example:2-orig-multi"

banner "It should be smaller."
pe "docker images java-example"

banner "And have less vulnerabilities and components."
pe "grype java-example:2-orig-multi"

banner "Now we'll migrate to Chainguard images."
pe "git diff --no-index -U1000 java-example-2-orig-multi/Dockerfile java-example-3-cg-multi/Dockerfile"

banner "Build and run it. Use Ctrl+C to stop the app."
pe "docker build -t java-example:3-cg-multi ./java-example-3-cg-multi"
pe "docker run -p 8080:8080 --rm java-example:3-cg-multi"

banner "It should be even smaller."
pe "docker images java-example"

banner "And have signficantly less vulnerabilties and components."
pe "grype java-example:3-cg-multi"

banner "If we scan the base image, we'll see that most, if not all, of the vulnerabilities have been introduced by the application."
pe "grype cgr.dev/chainguard/jre"
