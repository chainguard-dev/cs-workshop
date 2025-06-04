#! env bash

. ../../base.sh

for i in $(docker images -q python-example); do
  docker rmi $i
done

clear

banner "Here's a simple python application that uses the mysql library and its Dockerfile."
pe "$BATCAT run.py"
pe "$BATCAT Dockerfile"

banner "Build the image and run it."
pe "docker build -t python-example ."
pe "docker run -it --rm python-example"

banner "Check the size."
pe "docker images python-example"

banner "And the vulnerabilities."
pe "grype python-example"

banner "Here's an initial attempt to migrate it to Chainguard."
pe "git diff --no-index -U1000 Dockerfile singlestage-broken.Dockerfile"
pe "docker build -t python-example:singlestage-broken -f singlestage-broken.Dockerfile ."

banner "The Docker Hub image includes mariadb/mysql libraries."
pe 'docker run -it --rm --entrypoint bash python:latest -c "apt list" | grep -E "(mariadb|mysql)"'

banner "We need to install them explicitly."
pe "git diff --no-index -U1000 singlestage-broken.Dockerfile singlestage.Dockerfile"
pe "docker build -t python-example:singlestage -f singlestage.Dockerfile ."
pe "docker run -it --rm python-example:singlestage"

banner "The size won't have changed too much."
pe "docker images python-example"

banner "But there should be significantly less vulnerabilities."
pe "grype python-example:singlestage"

banner "Let's try and make it multi-stage."
pe "git diff --no-index -U1000 singlestage.Dockerfile multistage-broken.Dockerfile"
pe "docker build -t python-example:multistage-broken -f multistage-broken.Dockerfile ."
pe "docker run -it --rm python-example:multistage-broken"

banner "We need to make libmariadb.so available at runtime."
pe "git diff --no-index -U1000 multistage-broken.Dockerfile multistage.Dockerfile"
pe "docker build -t python-example:multistage -f multistage.Dockerfile ."
pe "docker run -it --rm python-example:multistage"

banner "This should be significantly smaller in size."
pe "docker images python-example"

banner "With 0 or almost 0 CVEs."
pe "grype python-example:multistage"

banner "Rather than copying the .so directly, you could use the base chroot method to install the packages into the runtime stage."
pe "git diff --no-index -U1000 multistage.Dockerfile base-chroot.Dockerfile"
pe "docker build -t python-example:base-chroot -f base-chroot.Dockerfile ."
pe "docker run -it --rm python-example:base-chroot"

banner "This will be larger than the previous example because it includes the full contents of the packages."
pe "docker images python-example"

banner "But CVEs should still be low."
pe "grype python-example:base-chroot"
