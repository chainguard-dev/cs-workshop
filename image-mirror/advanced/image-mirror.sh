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

# Create a temp dir where we can write files
tmpdir=$(mktemp -d)

# Clean up the temp dir when the script exits
trap 'rm -rf -- "$tmpdir"' EXIT

function main() {
  # Images will be signed by either the CATALOG_SYNCER or APKO_BUILDER identity in your organization.
  catalog_syncer=$(chainctl iam account-associations describe "${org_name}" -o json | jq -r '.[].chainguard.service_bindings.CATALOG_SYNCER')
  apko_builder=$(chainctl iam account-associations describe "${org_name}" -o json | jq -r '.[].chainguard.service_bindings.APKO_BUILDER')

  # List every tag that has been updated in the last 72h, aggregate by digest into
  # a structure like:
  #
  # [
  #   {
  #     "digest": "",
  #     "tags": [
  #       ""
  #     ]
  #   }
  # ]
  image_list=$(
    chainctl image list \
      --parent="${org_name}" \
      --repo="${repo_name}" \
      --updated-within=72h \
      -o json \
      | jq -c '.[].tags | group_by(.digest) | .[] | { digest: .[0].digest, tags: map(.name) }'
  )

  # If there haven't been any updates in the last 72 hours then the list will be
  # empty.
  if [[ -z "${image_list}" ]]; then
    echo "No recently updated images found. Exiting." >&2
    return 0
  fi

  # Iterate over each image in the list.
  while read -r img; do
    digest=$(jq -r .digest <<<"${img}")

    # Check whether we want to copy this image
    echo "Checking ${digest} $(jq -c .tags <<<"${img}")..." >&2
    if ! should_copy "${img}"; then
      echo "Skipped ${digest}" >&2
      continue
    fi

    src="${src_repo}@${digest}"

    # Verify the signature before we copy the image
    echo "Verifying signature for ${digest}..."
    cosign verify \
      --certificate-oidc-issuer=https://issuer.enforce.dev \
      --certificate-identity-regexp="^https://issuer.enforce.dev/(${catalog_syncer}|${apko_builder})$" \
      "${src}" &>/dev/null

    # Perform the copy
    echo "Copying ${digest} to ${dst_repo}..." >&2
    while read -r tag; do
      dst="${dst_repo}:${tag}"

      echo "Copying ${src} to ${dst}..." >&2
      crane copy "${src}" "${dst}"
    done < <(jq -rc '.tags[]' <<<"${img}")
  done <<<"${image_list}"
}

function should_copy() {
  local img="${1}"
  local digest=$(jq -r .digest <<<"${img}")
  local dst_tags='[]'

  # Figure out the digests for the existing tags in the repository
  while read -r tag; do
    dst_digest=$(crane digest "${dst_repo}:${tag}" 2>/dev/null || true)

    # If the the destination tag doesn't exist at all, then we should copy the
    # image and we can stop here.
    if [[ -z "${dst_digest}" ]]; then
      echo "${dst_repo}:${tag} doesn't exist in the destination" >&2
      return 0
    fi

    dst_tags=$(jq -rc --arg digest "${dst_digest}" --arg tag "${tag}" '. += [{"digest": $digest, "tag": $tag}]' <<<"${dst_tags}")
  done < <(jq -rc '.tags[]' <<<"${img}")

  # If some of the tags in the destination match the new digest, but others
  # don't, then we want to copy to make sure the destination stays consistent
  # between tags.
  local match_count=0
  local total_count=0
  while read -r dst_tag; do
    ((total_count++))
    dst_digest=$(jq -r '.digest' <<<"${dst_tag}")
    if [[ "${dst_digest}" == "${digest}" ]]; then
      ((match_count++))
    fi
  done < <(jq -rc '.[]' <<<"${dst_tags}")
  if [[ ${match_count} -gt 0 && ${match_count} -lt ${total_count} ]]; then
    echo "The destination is out of sync for ${digest}" >&2
    return 0
  fi

  # Finally, where the destination tag is a different image, use chainctl image
  # diff to figure out if the update would resolve any vulnerabilities.
  while read -r tag; do
    dst_digest=$(jq -r '.digest' <<<"${tag}")
    dst_tag=$(jq -r '.tag' <<<"${tag}")

    # Naturally there's no use in diffing two identical images.
    if [[ "${dst_digest}" == "${digest}" ]]; then
      echo "${dst_repo}:${dst_tag} is already up to date"
      continue
    fi

    # Avoid diffing images we've already diffed by saving results to a file
    # derived from the digests
    diff_file="${tmpdir}/${dst_digest}_${digest}.json"

    # Run chainctl image diff
    echo "Diffing ${dst_repo}:${dst_tag} and ${src_repo}@${digest}..." >&2
    if [[ ! -f "${diff_file}" ]]; then
      chainctl image diff "${src_repo}@${dst_digest}" "${src_repo}@${digest}" -o json > "${diff_file}" 2>/dev/null
    fi

    # We don't want to copy if the update doesn't resolve any vulnerabilities
    if [[ -z $(jq -r '.vulnerabilities.removed // [] | .[].id' "${diff_file}") ]]; then
      echo "No vulnerabilities will be removed by copying ${digest} to ${dst_repo}:${dst_tag}" >&2
      continue
    fi

    echo "${digest} resolves vulnerabilties in ${dst_repo}:${dst_tag}" >&2
    return 0
  done < <(jq -rc '.[]' <<<"${dst_tags}")

  return 1
}

main
