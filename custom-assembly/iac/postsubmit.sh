#!/bin/bash

set -euo pipefail

org_name="${1:?Must provide organization name as the first argument.}"

tmp_dir=$(mktemp -d)
trap "rm -rf ${tmp_dir}" EXIT

# Apply each yaml file
while read -r f; do
  repo="${f#images/}"
  repo="${repo%.yaml}"
  repo="${repo%.yml}"

  echo "${f}: applying..." 2>/dev/null  
  chainctl image repo build apply --yes \
    --parent="${org_name}" \
    --repo="${repo}" \
    -f "${f}"
done < <(find images -type f -name '*.yaml' -o -name '*.yml')
