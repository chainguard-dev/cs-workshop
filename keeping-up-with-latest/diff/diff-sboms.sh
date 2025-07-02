#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 <image1> <image2> [artifact-type...]"
    echo "Scans two container images with syft and diffs the packages."
    echo "Outputs JSON with 'added', 'removed' and 'changed' packages."
    echo "Optional artifact types filter packages (e.g., apk deb rpm python)."
    exit 1
}

if [ $# -lt 2 ]; then
    usage
fi

# Check we have the required tools installed to run the script
cmds="
  crane
  jq
  syft
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

# Resolve the images to a digest so we can be sure which images we're scanning 
image1=$(crane digest --full-ref "${1}")
image2=$(crane digest --full-ref "${2}")

shift 2

# Remaining arguments are artifact types. Convert them to a json array for jq.
artifact_types='[]'
if [ $# -gt 0 ]; then
  artifact_types=$(printf '"%s"\n' "${@}" | jq -s .)
fi

# Save output files to a tempdir
tmpdir=$(mktemp -d)
trap "rm -rf ${tmpdir}" EXIT
sbom1="${tmpdir}/image1-sbom.json"
sbom2="${tmpdir}/image2-sbom.json"

# Generate SBOMs for each image with syft
echo "Generating SBOM for $image1 with syft..." >&2
syft "$image1" -o syft-json > "$sbom1"

echo "Generating SBOM for $image2 with syft..." >&2
syft "$image2" -o syft-json > "$sbom2"

# Diff the sboms with jq
echo "Calculating diff..." >&2
jq -n -s \
  --slurpfile sbom1 "$sbom1" \
  --slurpfile sbom2 "$sbom2" \
  --argjson artifact_types "$artifact_types" '
# Extract packages from a syft-json SBOM
def extract_packages(sbom):
  sbom[0].artifacts |
  (if ($artifact_types | length) > 0 then map(select(.type as $t | $artifact_types | index($t))) else . end) |
  map(
    {
      purl: .purl,
      name: .name,
      version: .version,
      type: .type
    }
  ) |
  unique_by(.purl) |
  sort_by(.purl);

# Create a normalized purl we can compare by removing the version.
def normalized_purl(purl): 
  purl | gsub("@[^?]*";"@0.0.0");

# Identify that packages that have been added, removed and changed between the
# two lists of packages.
def diff_packages(old; new):
  {
    added: (
      new |
      map(select(normalized_purl(.purl) as $p | (old | map(normalized_purl(.purl))) | index($p) | not))
    ),
    removed: (
      old |
      map(select(normalized_purl(.purl) as $np | (new | map(normalized_purl(.purl))) | index($np) | not))
    ),
    changed: ([
      new[] as $new_pkg |
      old[] as $old_pkg |
      select(normalized_purl($new_pkg.purl) == normalized_purl($old_pkg.purl) and $new_pkg.version != $old_pkg.version) |
      {
        name: $new_pkg.name,
        type: $new_pkg.type,
        current: {
          version: $new_pkg.version,
          reference: $new_pkg.purl
        },
        previous: {
          version: $old_pkg.version,
          reference: $old_pkg.purl
        }
      }
    ])
  };

diff_packages(extract_packages($sbom1); extract_packages($sbom2))
'
