#! env bash
. ../base.sh

ORGANIZATION="cs-ttt-demo.dev"

clear
banner "Get the id of an image in your organization."
pe "IMAGE_ID=\$(chainctl image repo list --parent ${ORGANIZATION} -o json | jq -r '.items[] | select(.name == \"node\") | .id')"

banner "Get the EOL tag data for that image."
pe "curl -H \"Authorization: Bearer \$(chainctl auth token)\" \"https://console-api.enforce.dev/registry/v1/eoltags?uidp.children_of=\$IMAGE_ID\" 2> /dev/null | jq -r . | head -40"

banner "You could filter the results to find active tags."
pe "curl -H \"Authorization: Bearer \$(chainctl auth token)\" \"https://console-api.enforce.dev/registry/v1/eoltags?uidp.children_of=\$IMAGE_ID\" 2> /dev/null | jq -r '.items[] | select(.tagStatus == \"TAG_ACTIVE\")' | head -38"

banner "Or, filter specifically for LTS versions."
pe "curl -H \"Authorization: Bearer \$(chainctl auth token)\" \"https://console-api.enforce.dev/registry/v1/eoltags?uidp.children_of=\$IMAGE_ID\" 2> /dev/null | jq -r '.items[] | select((.mainPackageVersion != null) and (.mainPackageVersion.lts != \"\") and (.tagStatus == \"TAG_ACTIVE\"))' | head -38"

banner "Tags have a different status when they are in a grace period."
pe "curl -H \"Authorization: Bearer \$(chainctl auth token)\" \"https://console-api.enforce.dev/registry/v1/eoltags?uidp.children_of=\$IMAGE_ID\" 2> /dev/null | jq -r '.items[] | select(.tagStatus == \"TAG_IN_GRACE\")' | head -38"

banner "Some images are not elligible for a grace period at all. Like the tomcat image."
pe "IMAGE_ID=\$(chainctl image repo list --parent ${ORGANIZATION} -o json | jq -r '.items[] | select(.name == \"tomcat\") | .id')"
pe "curl -H \"Authorization: Bearer \$(chainctl auth token)\" \"https://console-api.enforce.dev/registry/v1/eoltags?uidp.children_of=\$IMAGE_ID\" 2> /dev/null | jq -r '.items[] | select(.graceStatus == \"GRACE_NOT_ELIGIBLE\")' | head -38"
