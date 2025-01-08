#!/bin/bash
export DOCKER_CLI_HINTS=false

UPSTREAM_REGISTRY="cgr.dev/cs-ttt-demo.dev/"
DOWNSTREAM_REGISTRY="localhost:80/library/"

requirements=(docker cosign)
for requirement in "${requirements[@]}"; do
    if ! command -v $requirement &> /dev/null
    then
        echo "$requirement could not be found in \$PATH, please install it."
        exit 1
    fi
done


pull_image() {
    echo "Pulling ${UPSTREAM_REGISTRY}${image}"
    docker pull ${UPSTREAM_REGISTRY}${image}
}

push_image() {
    echo "Pushing ${DOWNSTREAM_REGISTRY}${image}"
    docker tag ${UPSTREAM_REGISTRY}${image} ${DOWNSTREAM_REGISTRY}${image}
    docker push ${DOWNSTREAM_REGISTRY}${image}
}

remove_local_image() {
    echo "Removing local image ${image}"
    docker rmi ${UPSTREAM_REGISTRY}${image} ${DOWNSTREAM_REGISTRY}${image}
}

verify_signature() {
    echo "Verifying attestation for $UPSTREAM_REGISTRY$image"
    cosign verify \
        --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
        --certificate-identity=https://github.com/chainguard-images/images-private/.github/workflows/release.yaml@refs/heads/main \
    $UPSTREAM_REGISTRY/$image -o text
}

echo "Processing ${#images[@]} images from $IMAGE_LIST"

images=($(crane catalog cgr.dev | grep cs-ttt-demo.dev | cut -f 2 -d '/'))

for image in "${images[@]}"; do
    image="$image:latest"
    pull_image
    verify_signature
    if [ $? -eq 0 ]; then
        push_image
        remove_local_image
    else
        echo "!!!!!!!!!! Image $image failed signature verification, not pushing to $DOWNSTREAM_REGISTRY !!!!!!!!!!"
    fi
done