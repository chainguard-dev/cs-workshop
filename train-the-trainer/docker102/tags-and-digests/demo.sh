#! env bash

. ../../base.sh

banner "A tag provides a friendly, addressable name for a specific image manifest or index."
pe "crane manifest cgr.dev/chainguard/python:latest | jq -r ."
echo

banner "The digest is the sha256 checksum of the manifest/index. Note that the content returned by crane doesn't include a new line."
pe "crane manifest cgr.dev/chainguard/python:latest"
pe "echo"
pe "crane manifest cgr.dev/chainguard/python:latest | sha256sum"

banner "We can see the digest when we pull an image."
pe "docker pull cgr.dev/chainguard/python:latest"

banner "We can also pull images by their digest."
pe "docker pull cgr.dev/chainguard/python@$(crane digest cgr.dev/chainguard/python:latest)"

banner "It's also possible include the tag in the reference so it's more obvious what we're pulling when sharing configuration."
pe "docker pull cgr.dev/chainguard/python:latest@$(crane digest cgr.dev/chainguard/python:latest)"

banner "When you do this, the tag is actually ignored. But it's good for informational purposes."
pe "docker pull cgr.dev/chainguard/python:carrot@$(crane digest cgr.dev/chainguard/python:latest)"

banner "Any modification to the manifest at all changes the digest. Even, for instance, jq adding a newline."
pe "crane manifest cgr.dev/chainguard/python:latest | jq -Mc"
pe "git diff --no-index -U1000 <(crane manifest cgr.dev/chainguard/python:latest) <(crane manifest cgr.dev/chainguard/python:latest | jq -Mc)"
pe "crane manifest cgr.dev/chainguard/python:latest | jq -Mc | sha256sum"
pe "docker pull cgr.dev/chainguard/python@sha256:$(crane manifest cgr.dev/chainguard/python:latest | jq -Mc | sha256sum | awk '{print $1}')"

banner "Tags can change a lot, even for very specific tags. That's why it's often preferable to use digests in a number of sitations."
pe "chainctl image history --parent=cs-ttt-demo.dev python:3.13.3-r2"

