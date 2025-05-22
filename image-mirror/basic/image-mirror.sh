#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Retrieve positional arguments
src_repo="${1:?Must provide cgr.dev repository as the first argument.}"
dst_repo="${2:?Must provide destination repository as the second argument.}"

# Ensure the cgr.dev repo looks how its supposed to
if [[ ! ${src_repo} =~ ^cgr.dev/[^/]+/[^/:@]+$ ]]; then
  echo "ERROR: first argument '${src_repo}' must look like: cgr.dev/{org_name}/{repo}" >&2
  exit 1
fi

# Extract components from cgr.dev repo
org_name="$(r=${src_repo#*/}; echo ${r%/*})"
repo_name="${src_repo##*/}"

# Check we have the required tools installed to run the script
cmds="
  chainctl
  cosign
  crane
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

# List every tag that has been updated in the last 72h. 
#
# This produces a list of images in the form <repo>:<tag>@<digest>.
image_list=$(
  chainctl image list \
    --parent="${org_name}" \
    --repo="${repo_name}" \
    --updated-within=72h \
    -o json \
    | jq -r --arg src_repo "${src_repo}" '.[].tags[] | $src_repo + ":" + .name + "@" + .digest'
)

# Iterate over each image
while read -r src; do
    tag=$(t=${src#*:}; echo ${t%@*})
    dst="${dst_repo}:${tag}"

    # Verify the signature before we copy it
    echo "Verifying signature for ${src}..."
    cosign verify \
      --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
      --certificate-identity=https://github.com/chainguard-images/images-private/.github/workflows/release.yaml@refs/heads/main \
      "${src}" &>/dev/null

    # You could use `cosign copy` here if you wanted to also copy the
    # signatures/attestations
    echo "Copying ${src} to ${dst}..." >&2
    crane copy "${src}" "${dst}"
done <<<"${image_list}"
