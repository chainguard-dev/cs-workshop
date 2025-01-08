#!/bin/bash

UPSTREAM_REGISTRY="cgr.dev/cs-ttt-demo.dev/"
DOWNSTREAM_REGISTRY="localhost:80/library/"

requirements=(cosign)
for requirement in "${requirements[@]}"; do
    if ! command -v $requirement &> /dev/null
    then
        echo "$requirement could not be found in \$PATH, please install it."
        exit 1
    fi
done

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
    verify_signature
        if [ $? -eq 0 ]; then
          cosign copy $UPSTREAM_REGISTRY$image $DOWNSTREAM_REGISTRY$image
        else
            echo "!!!!!!!!!! Image $image failed signature verification, not copying to $DOWNSTREAM_REGISTRY !!!!!!!!!!"
        fi
done