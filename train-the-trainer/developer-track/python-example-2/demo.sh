#! env bash

. ../../base.sh

for i in $(docker images -q python-example-2); do
  docker rmi $i
done

clear

banner "We can fix the error in the previous example by copying the required .so into the runtime stage."
pe "git diff --no-index -U1000 ../python-example-1/Dockerfile copyso.Dockerfile"

banner "Build and run it."
pe "docker build -t python-example-2:copyso -f copyso.Dockerfile ."
pe "docker run --rm python-example-2:copyso"

banner "A more stable alternative is the base-chroot method."
pe "git diff --no-index -U1000 copyso.Dockerfile Dockerfile"

banner "Build and run it."
pe "docker build -t python-example-2:base-chroot ."
pe "docker run --rm python-example-2:base-chroot"

banner "The image will be larger because it includes all the files from the mariadb packages."
pe "docker images python-example-2"
