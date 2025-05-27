#! env bash

set -e

. ../../base.sh

org_name=${1:?ERROR: Must provide organization name as the first argument.}
repo_name=${2:-busybox}
src_repo="cgr.dev/${org_name}/${repo_name}"
dst_repo="localhost:5000/${repo_name}"

# Check we have the required tools installed to run the demo
cmds="
  chainctl
  cosign
  crane
  docker
  grype
  jq
"
missing_cmds=""
for cmd in ${cmds}; do
  if ! command -v "${cmd}" &> /dev/null; then
    missing_cmds+="${cmd} "
  fi
done
if [[ -n "${missing_cmds}" ]]; then
  echo "Missing required commands: ${missing_cmds}" >&2
  exit 1
fi

# Clean up any existing registry containers
for i in $(docker ps -a --format '{{.Names}}' | grep ^registry$); do
  docker rm -f $i
done

# Run the demo
clear
banner "Step 1: Start a local registry"
pe 'docker run -d -p 5000:5000 --rm --name registry distribution/distribution:latest'

banner "Step 2: Run the script to copy images to the local registry"
pe "./image-mirror.sh ${src_repo} ${dst_repo}"

banner "Step 3: Run the script again. Observe that it skips the copy."
pe "./image-mirror.sh ${src_repo} ${dst_repo}"

banner "Step 4: Copy an old digest to the latest tag"
pe "OLD_DIGEST=\$(chainctl images history --parent=${org_name} ${repo_name}:latest -o json | jq -r '.[-1].digest')"
pe "crane copy ${src_repo}@\${OLD_DIGEST} ${dst_repo}:latest" 

banner "Step 5: Run the script again. Observe that it copies an image because the latest tag is out of sync."
pe "./image-mirror.sh ${src_repo} ${dst_repo}"

banner "Step 6: Copy the old digest to all the tags"
pe "crane ls ${dst_repo} | while read -r tag; do crane copy ${src_repo}@\${OLD_DIGEST} ${dst_repo}:\$tag; done" 

banner "Step 7: Run the script again. Observe that it diffs the images before copying."
pe "./image-mirror.sh ${src_repo} ${dst_repo}"

banner "Step 8: Copy a recent but older digest to all the tags. This digest (probably!) doesn't have any difference in vulnerabilities."
pe "RECENT_DIGEST=\$(chainctl images history --parent=${org_name} ${repo_name}:latest -o json | jq -r '.[1].digest')"
pe "crane ls ${dst_repo} | while read -r tag; do crane copy ${src_repo}@\${RECENT_DIGEST} ${dst_repo}:\$tag; done"

banner "Step 9: Run the script again. Observe that it diffs the images but doesn't copy them."
pe "./image-mirror.sh ${src_repo} ${dst_repo}"
