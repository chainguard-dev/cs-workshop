#!/bin/bash

set -euo pipefail

artifactory_url=${ARTIFACTORY_URL:?Must set ARTIFACTORY_URL}
token=${ARTIFACTORY_TOKEN:?Must set ARTIFACTORY_TOKEN}
repository="${1:?Must provide repository as the first argument}"
threshold_days="${2:?Must provide threshold in days as the second argument}"

# Use the search API to discover files in the repository 
files=$(curl "${artifactory_url}/api/search/aql" \
  -sSf \
  -X POST \
  -H "Authorization: Bearer ${token}" \
  -H "Content-Type: text/plain" \
  -d "items.find({\"repo\": {\"\$eq\":\"${repository}\"},\"type\":{\"\$eq\":\"file\"}}).include(\"repo\", \"path\", \"name\")" \
  | jq -rc '.results[]'
)

# Get the stats for each file and use the lastDownloaded timestamp to
# find files that haven't been downloaded since X number of days ago
threshold=$((($(date +%s)-((24*60*60)*threshold_days))))
while read -r f; do
  repo=$(jq -r '.repo' <<<"${f}")
  path=$(jq -r '.path' <<<"${f}")
  name=$(jq -r '.name' <<<"${f}")

  # Ignore any files under .jfrog
  if [[ "${path}" == ".jfrog" ]] || [[ "${path}" == .jfrog/* ]]; then
    continue
  fi

  # Ignore any files that were downloaded more recently than the threshold
  lastDownloaded=$(curl -sSf -H "Authorization: Bearer ${token}" "${artifactory_url}/api/storage/${repo}/${path}/${name}?stats" | jq -r .lastDownloaded)
  if [[ $((lastDownloaded/1000)) -gt ${threshold} ]]; then
    continue
  fi

  # Print the file
  echo "${path}/${name}"
done <<<"${files}"
