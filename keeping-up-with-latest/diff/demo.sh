#! env bash
. ../../base.sh

ORGANIZATION="cs-ttt-demo.dev"

tmpdir=$(mktemp -d)
trap "rm -rf ${tmpdir}" EXIT
diff_file="${tmpdir}/diff.json"

clear
banner "Get the digest for the current version of python:latest"
pe "DIGEST_NEW=\$(chainctl image history --parent ${ORGANIZATION} python:latest -o json | jq -r '.[0].digest')"

banner "Get the digest for the previous version of python:latest"
pe "DIGEST_OLD=\$(chainctl image history --parent ${ORGANIZATION} python:latest -o json | jq -r '.[1].digest')"

banner "Run chainctl image diff to compare the two images."
pe "chainctl image diff cgr.dev/${ORGANIZATION}/python@\${DIGEST_OLD} cgr.dev/${ORGANIZATION}/python@\${DIGEST_NEW} > ${diff_file}"
pe "jq -r '.' ${diff_file}"

banner "You could use the diff to decide when to update an image. For instance, check if it removes any vulnerabilities."
pe "jq -e '(.vulnerabilities.removed? | length) > 0' ${diff_file}"

banner "And/or, ignore updates that only change packages versions and don't add or remove any packages."
pe "jq -e '(.packages.added? + .packages.removed? | length) == 0' ${diff_file}"
