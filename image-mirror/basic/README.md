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

