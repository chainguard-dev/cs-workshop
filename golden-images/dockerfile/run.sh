#!/bin/bash

set -euo pipefail

parent="${1:?Must provide organization name as the first argument.}"
repo="${2:?Must provide repository name as the second argument.}"
registry="${3:?Must provide destination registry as the third argument.}"

# Check we have the required tools installed to run the script
cmds="
  chainctl
  docker
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

# Aggregate the most recently built tags by digest, giving us a structure like:
#
# {
#   "digest": "DIGEST",
#   "tags": [
#     "TAG1",
#     "TAG2"
#   ]
# }
#
images=$(chainctl image list \
  --parent=${parent}\
  --repo=${repo} \
  --updated-within=72h \
  -o json \
  | jq -c '
.[].tags | 
group_by(.digest) | 
map({digest: .[0].digest, tags: map(.name)})[]
')

# Iterate over every image
while read image; do
  digest=$(jq -r .digest <<<"${image}")
  src="cgr.dev/${parent}/${repo}@${digest}"

  echo "Building ${digest} $(jq -rc .tags <<<"${image}")" >&2

  # Get the individual digests for each platform so we can annotate them on the
  # appropriate manifest
  digest_amd64=$(docker buildx imagetools inspect "${src}" --raw | jq -r '.manifests[] | select(.platform.architecture == "amd64" and .platform.os == "linux") | .digest')
  digest_arm64=$(docker buildx imagetools inspect "${src}" --raw | jq -r '.manifests[] | select(.platform.architecture == "arm64" and .platform.os == "linux") | .digest')

  # Build our customized images. Pass each destination tag with the -t argument.
  docker buildx build . \
    --push \
    --platform=linux/amd64,linux/arm64 \
    --provenance=false \
    --build-arg "SOURCE_IMAGE=${src}" \
    --annotation "index,manifest:com.example.org.golden.image=true" \
    --annotation "index:org.opencontainers.image.base.digest=${digest}" \
    --annotation "manifest[linux/amd64]:org.opencontainers.image.base.digest=${digest_amd64}" \
    --annotation "manifest[linux/arm64]:org.opencontainers.image.base.digest=${digest_arm64}" \
    $(jq -rc "\"-t \" + ([.tags[] | \"${registry}/${repo}:\" + .] | join(\" -t\"))" <<<"${image}")

  echo >&2
done <<<"${images}"
