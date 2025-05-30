# Image Mirror Example: Basic 

This is a simple example of a custom script that mirrors images from a
repository in `cgr.dev` to another registry.

To make the script more efficient, it only copies images that were updated in
the last three days. Supported tags of Chainguard images are updated on a daily
basis.

## Requirements

- [`chainctl`](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/)
- [`cosign`](https://github.com/sigstore/cosign)
- [`crane`](https://github.com/google/go-containerregistry/tree/main/cmd/crane)
- [`jq`](https://github.com/jqlang/jq)

## Usage

There are two arguments:

1. The source repository in `cgr.dev`.
2. The destination repository.

```sh
./image-mirror.sh cgr.dev/org.name/python example.registry/chainguard/python
```

Before running the script, ensure you have logged into Chainguard and the
destination registry.

```
docker login -u username -p password example.registry
chainctl auth login
chainctl auth configure-docker
```

## Demo

1. Start a local registry.

```
docker run -d -p 5000:5000 --rm --name registry distribution/distribution:latest
```

2. Run the script to copy images to the registry.

```
export ORG_NAME=your.org
export IMAGE_NAME=busybox

./image-mirror.sh cgr.dev/${ORG_NAME}/${IMAGE_NAME} localhost:5000/${IMAGE_NAME}
```

3. List tags in the registry.

```
crane ls localhost:5000/${IMAGE_NAME}
```
