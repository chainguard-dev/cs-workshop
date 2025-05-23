# Image Mirror Example: Chainctl Image Diff

This is an example of a custom script that mirrors images from a
repository in `cgr.dev` to another registry, using `chainctl image diff` to
select updates that meaningfully reduce CVEs.

It avoids copying an image unless:

1. It introduces a new tag that doesn't already exist in the destination
   repository.
2. It resolves a vulnerability that is present in an existing tag.
3. The image has already been partially copied to some of the tags in the
   destination. Copying in this scenario ensures consistency across tags in the
   destination.

This is intended to minimize the volume of changes, hopefully reducing the
toil that may be involved in reviewing and staying up to date with updates.

To make the script more efficient, it only copies images that were updated in
the last three days. Supported tags of Chainguard images are updated on a daily
basis.

## Requirements

- [`chainctl`](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/)
- [`cosign`](https://github.com/sigstore/cosign)
- [`crane`](https://github.com/google/go-containerregistry/tree/main/cmd/crane)
- [`grype`](https://github.com/anchore/grype)
- [`jq`](https://github.com/jqlang/jq)

## Usage

There are two arguments:

1. The source repository in `cgr.dev`.
2. The destination repository.

```sh
./image-mirror.sh cgr.dev/org.name/python registry.org.name.internal/cgr/python
```

Before running the script, ensure you have logged into Chainguard and the
destination registry.

```
docker login -u username -p password example.registry
chainctl auth login
chainctl auth configure-docker
```
