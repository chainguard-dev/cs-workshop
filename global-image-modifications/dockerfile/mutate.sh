#!/bin/bash

set -euo pipefail

src="${1:?Must provide source image as the first argument.}"

: "${2:?Must provide destination tags as additional arguments.}"
dsts=("${@:2}")

# Check we have at least one tag to push to
if [[ "${#dsts[@]}" -lt 1 ]]; then
  echo "Must provide at least one destination tag" >&2
  exit 1
fi

# Check we have the required tools installed to run the script
cmds="
  awk
  chainctl
  docker
  jq
  sha256sum
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

# Resolve the digest of the source image. This ensures that every command we run
# is targeting the same source image.
digest="sha256:$(docker buildx imagetools inspect "${src}" --raw | sha256sum | awk '{print $1}')"
src="${src//@*}@${digest}"

docker_args=()

# Add each destination tag to the list of arguments passed to docker buildx
# build
for dst in ${dsts[@]}; do
  docker_args+=("-t" "${dst}")
done

# Get the annotations from the source index. Docker does not persist these
# when it builds a new image, so we have to add them explicitly.
while read -r annotation; do
  docker_args+=("--annotation" "\"index:${annotation}\"")
done < <(docker buildx imagetools inspect "${src}" --raw \
  | jq -r '
.annotations |
to_entries[] | 
select(.key != "org.opencontainers.image.base.digest") | 
.key + "=" + .value
'
)

# Set platform-specific annotations
for arch in amd64 arm64; do
  # Add org.opencontainers.image.base.digest annotation
  digest_arch=$(docker buildx imagetools inspect "${src}" --raw \
    | jq -r ".manifests[] | select(.platform.architecture == \"${arch}\" and .platform.os == \"linux\") | .digest"
  )
  docker_args+=("--annotation" "manifest[linux/${arch}]:org.opencontainers.image.base.digest=${digest_arch}")

  # Add annotations from the source image
  while read -r annotation; do
    docker_args+=("--annotation" "\"manifest[linux/${arch}]:${annotation}\"")
  done < <(docker buildx imagetools inspect "${src//@*}@${digest_arch}" --raw \
    | jq -r '
    .annotations |
    to_entries[] | 
    select(.key != "org.opencontainers.image.base.digest") | 
    .key + "=" + .value
    '
  )
done

echo "Mutating ${src}" >&2

# Add each destination tag to the list of arguments passed to docker buildx
# build
for dst in ${dsts[@]}; do
  echo -e "\t-> ${dst}" >&2
  docker_args+=("-t" "${dst}")
done

# Build the image.
#
# Note: unlike with annotations, docker buildx build does not allow you to set
# labels per-platform so we aren't setting the
# org.opencontainers.image.base.digest label.
eval docker buildx build . \
  -q \
  --push \
  --platform=linux/amd64,linux/arm64 \
  --provenance=false \
  --build-arg "SOURCE_IMAGE=${src}" \
  --label "com.example.org.golden.image=true" \
  --annotation "index,manifest:com.example.org.golden.image=true" \
  --annotation "index:org.opencontainers.image.base.digest=${digest}" \
  "${docker_args[@]}"
