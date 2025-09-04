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

  # Extract the custom overlay from the file
  custom_overlay="${tmp_dir}/${repo}.yaml"
  yq '.custom_overlay' "${f}" > "${tmp_dir}/${repo}.yaml" 

  echo "${f}: checking if repo exists..." >&2
  if [[ -z $(chainctl image repo list --parent="${org_name}" --repo="${repo}" -o id) ]]; then
    # If the repo doesn't exist, then we can use the --save-as functionality to
    # create it from the 'source'
    echo "${f}: creating repo..." >&2
    source=$(yq '.source' "${f}")

    editor_sh="${tmp_dir}/${repo}-editor.sh"
    echo -e '#!/bin/bash\ncat '"${custom_overlay}"' > "$1"' > "${editor_sh}"
    chmod +x "${editor_sh}" 

    EDITOR="${editor_sh}" chainctl image repo build edit \
      --parent="${org_name}" \
      --repo="${source}" \
      --save-as="${repo}" \
      <<<y
  else
    # If it does exist then apply the custom overlay to it
    echo "${f}: applying..." >&2
    chainctl image repo build apply --yes \
      --parent="${org_name}" \
      --repo="${repo}" \
      -f "${custom_overlay}"
  fi
done < <(find images -type f -name '*.yaml' -o -name '*.yml')
