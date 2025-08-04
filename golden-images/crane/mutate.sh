#!/bin/bash

set -euo pipefail

src="${1:?Must provide source image as the first argument.}"

: "${2:?Must provide destination tags as additional arguments.}"
dsts=("${@:2}")

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

echo "Mutating ${src}..." >&2

# Resolve the source image to the underlying digest to ensure we're always
# operating on the same image in separate commands.
#
# Note: we're resolving to a specific platform because `crane mutate` won't
# operate on multi-arch images.
src=$(crane digest --full-ref --platform="${PLATFORM:-linux/amd64}" "${src}")
digest=$(crane digest "${src}")

# Create a temporary directory where we can assemble the files we want to append
# to the images
echo "Creating temporary work directory..." >&2
tmpdir=$(mktemp -d)
trap "rm -rf ${tmpdir}" EXIT
workdir="${tmpdir}/work"

# Copy custom APK repositories and keys into the workdir
echo "Adding custom APK repositories and keys..." >&2
mkdir -p "${workdir}/etc/apk/keys"
cp resources/repositories "${workdir}/etc/apk/repositories"
cp resources/chainguard-extras.rsa.pub "${workdir}/etc/apk/keys/chainguard-extras.rsa.pub"
cp resources/wolfi-signing.rsa.pub "${workdir}/etc/apk/keys/wolfi-signing.rsa.pub"

# Append custom certificates to the CA certs in the image. Add the
# individual certificates to /usr/local/share/ca-certificates/ so they're
# picked up by update-ca-certificates.
#
# This has to pull the layers to get the existing certificates. If you don't
# care about update-ca-certificates and you're managing your own bundle
# entirely, then you could remove the crane export and just copy your bundle
# to ${workdir}/etc/ssl/certs/ca-certificates.crt.
echo "Appending custom certificates..." >&2
crane export "${src}" | ${tar_cmd} -C "${workdir}" -x etc/ssl/certs/ca-certificates.crt
cat resources/custom-*.crt >> "${workdir}/etc/ssl/certs/ca-certificates.crt"
mkdir -p "${workdir}/usr/local/share/ca-certificates"
cp resources/custom-*.crt "${workdir}/usr/local/share/ca-certificates/"

# Create a tar archive. Ensure files are owned by root. Set the mtime and sort
# by name to ensure the archive is reproducible.
echo "Creating layer..." >&2
${tar_cmd} -C "${workdir}" -cf "${tmpdir}/layer.tar" . \
  --sort=name \
  --owner=root:0 \
  --group=root:0 \
  --mtime='UTC 1970-01-01'

# Print the contents of the tarball so we can see what we're adding and the
# permissions.
${tar_cmd} -tv < "${tmpdir}/layer.tar" >&2

# Iterate over every destination tag running `crane mutate` to add the layer
# and push the modified image to the destination.
for dst in ${dsts[@]}; do 
  echo "Pushing ${dst}..." >&2
  crane mutate "${src}" \
    -t "${dst}" \
    --append "${tmpdir}/layer.tar" \
    --annotation "org.opencontainers.image.base.digest=${digest}" \
    --label "org.opencontainers.image.base.digest=${digest}" \
    --annotation "com.example.org.golden.image=true" \
    --label "com.example.org.golden.image=true"
done

