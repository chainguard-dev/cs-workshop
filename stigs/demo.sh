#! env bash
. ../base.sh

ORG="<CHAINGUARD ORG>"

# Ensure IMAGE is set to a FIPS image in the ORG's registry
IMAGE="python-fips"

# create directory to store the results, and ensure scan.sh has proper permissions
mkdir -p out
chmod +x scan.sh

clear

banner "Starting the $IMAGE container to run the STIG scan"
pe "docker run --name target -d cgr.dev/$ORG/$IMAGE:latest tail -f /dev/null"

banner "View the script that will be used to scan the running container"
pe "cat scan.sh"

banner "Run the scan against the running container"
CMD="docker run --privileged -i --rm -u 0:0 --pid=host \\
  -v /var/run/docker.sock:/var/run/docker.sock \\
  -v \$(pwd)/out:/out \\
  -v \$(pwd)/scan.sh:/scan.sh \\
  --entrypoint sh \\
  cgr.dev/chainguard/openscap:latest-dev /scan.sh"

p "$CMD"
eval "$CMD"

banner "Cleanup the running container:"
pe "docker stop target && docker rm target"

banner "View the results of the scan"
pe "open out/report.html"