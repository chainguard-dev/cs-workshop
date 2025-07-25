#!/bin/bash

set -euo pipefail

parent="${1:?Must provide organization name as the first argument.}"
repo="${2:?Must provide repository name as the second argument.}"
registry="${3:?Must provide destination registry as the third argument.}"

# We need to use some features of tar that aren't available on MacOS, so use
# gnu-tar if we're on that platform.
tar_cmd=tar
if [ $(uname -s) = "Darwin" ]; then
  tar_cmd=gtar
fi

# Check we have the required tools installed to run the script
cmds="
  chainctl
  crane
  jq
  ${tar_cmd}
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

# Create a temporary directory where we can assemble the files we want to append
# to the images
echo "Creating temporary work directory..." >&2
tmpdir=$(mktemp -d)
trap "rm -rf ${tmpdir}" EXIT
workdir="${tmpdir}/work"

# Create a layer that contains custom apk repositories and keys.
echo "Creating apk repository layer..." >&2
workdir_apk="${workdir}/apk"
mkdir -p "${workdir_apk}/etc/apk/keys"
cp resources/repositories "${workdir_apk}/etc/apk/repositories"
cp resources/chainguard-extras.rsa.pub "${workdir_apk}/etc/apk/keys/chainguard-extras.rsa.pub"
cp resources/wolfi-signing.rsa.pub "${workdir_apk}/etc/apk/keys/wolfi-signing.rsa.pub"
${tar_cmd} -C "${workdir_apk}" -cf "${tmpdir}/apk.tar" . \
  --sort=name \
  --owner=root:0 \
  --group=root:0 \
  --mtime='UTC 1970-01-01'

# Print the contents of the tarball so we can see what we're adding and the
# permissions.
${tar_cmd} -tv < "${tmpdir}/apk.tar" >&2

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
  src=$(crane digest --full-ref --platform="${PLATFORM:-linux/amd64}" "cgr.dev/${parent}/${repo}@${digest}")
  digest=$(crane digest "${src}")

  echo "Customizing ${digest} $(jq -rc .tags <<<"${image}")" >&2

  # Append custom certificates to the CA certs in the image. Add the
  # individual certificates to /usr/local/share/ca-certificates/ so they're
  # picked up by update-ca-certificates.
  #
  # This has to pull the layers to get the existing certificates. If you don't
  # care about update-ca-certificates and you're managing your own bundle
  # entirely, then you could remove the crane export and just copy your bundle
  # to ${workdir_certs}/etc/ssl/certs/ca-certificates.crt.
  echo "Appending custom CA certificates to ${digest}..." >&2
  workdir_certs="${workdir}/certs/${digest}"
  mkdir -p "${workdir_certs}"
  crane export "${src}" | ${tar_cmd} -C "${workdir_certs}" -x etc/ssl/certs/ca-certificates.crt
  cat resources/custom-*.crt >> "${workdir_certs}/etc/ssl/certs/ca-certificates.crt"
  mkdir -p "${workdir_certs}/usr/local/share/ca-certificates"
  cp resources/custom-*.crt "${workdir_certs}/usr/local/share/ca-certificates/"

  # Create a layer with the updated certificates
  ${tar_cmd} -C "${workdir_certs}" -cf "${tmpdir}/${digest}-certs.tar" . \
  --sort=name \
  --owner=root:0 \
  --group=root:0 \
  --mtime='UTC 1970-01-01'

  # Print the contents of the tarball so we can see what we're adding and the
  # permissions.
  ${tar_cmd} -tv < "${tmpdir}/${digest}-certs.tar" >&2

  # Iterate over every tag running `crane mutate` to add the layer and push the
  # image with the tag to the destination.
  while read tag; do 
    dst="${registry}/${repo}:${tag}"

    # Mutate the image and push it to the tag
    echo "Pushing ${dst}..." >&2
    crane mutate "${src}" \
      -t "${dst}" \
      --append "${tmpdir}/apk.tar" \
      --append "${tmpdir}/${digest}-certs.tar" \
      --annotation "org.opencontainers.image.base.digest=${digest}" \
      --label "org.opencontainers.image.base.digest=${digest}" \
      --annotation "com.example.org.golden.image=true" \
      --label "com.example.org.golden.image=true"

  done < <(jq -r '.tags[]' <<<"${image}")

  echo >&2
done <<<"${images}"
