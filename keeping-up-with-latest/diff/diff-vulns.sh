#!/bin/bash

set -euo pipefail

usage() {
    echo "Usage: $0 <image1> <image2>"
    echo "Scans two container images with grype and compares the vulnerabilities."
    echo "Outputs JSON with 'added' and 'removed' vulnerabilites (id, severity)."
    exit 1
}

if [ $# -ne 2 ]; then
    usage
fi

# Check we have the required tools installed to run the script
cmds="
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

# Resolve the images to a digest so we can be sure which images we're scanning 
image1=$(crane digest --full-ref "${1}")
image2=$(crane digest --full-ref "${2}")

# Save output files to a tempdir
tmpdir=$(mktemp -d)
trap "rm -rf ${tmpdir}" EXIT
scan1="${tmpdir}/image1.json"
scan2="${tmpdir}/image2.json"

# Scan each SBOM with grype
echo "Scanning ${image1} with grype..." >&2
grype "${image1}" -o json > "${scan1}"

echo "Scanning ${image2} with grype..." >&2
grype "${image2}" -o json > "${scan2}"

# Diff the sboms and the scans
echo "Calculating diff..." >&2
jq -n -s --slurpfile scan1 "${scan1}" --slurpfile scan2 "${scan2}" '
# Extract CVEs from grype output
def extract_cves(cves):
  cves[0].matches |
  map(
    {
      id: .vulnerability.id,
      severity: .vulnerability.severity,
    }
  ) |
  unique_by(.id) |
  sort_by(.id);

# Identify the vulnerabilities that have been added or removed between two lists
# of vulnerabilities.
def diff_vulnerabilities(old; new):
  {
    added: (new | map(select(.id as $id | (old | map(.id)) | index($id) | not))),
    removed: (old | map(select(.id as $id | (new | map(.id)) | index($id) | not)))
  };

diff_vulnerabilities(extract_cves($scan1); extract_cves($scan2))
'
