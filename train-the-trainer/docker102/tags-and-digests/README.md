# Tags and Digests

A demo that walks through what tags and digests are, how to use them and how a
digest is produced.

## Automated Demo

Run `./demo.sh`.

## Demo

A digest is simply the sha256sum of the image manifest.

```
crane manifest cgr.dev/chainguard/python:latest
crane manifest cgr.dev/chainguard/python:latest | sha256sum
```

We can pull by that digest.

```
DIGEST="sha256:$(crane manifest cgr.dev/chainguard/python:latest | sha256sum | awk '{print $1}')"
docker pull cgr.dev/chainguard/python@${DIGEST}
```

It's also possible include the tag in the reference so it's more obvious what
we're pulling when sharing configuration. Note that the tag is ignored when you
do this.

```
docker pull cgr.dev/chainguard/python:latest@${DIGEST}
docker pull cgr.dev/chainguard/python:carrot@${DIGEST}
```

If you change anything about the manifest, even adding a newline, the digest
changes completely.

```
crane manifest cgr.dev/chainguard/python:latest | jq -Mc
crane manifest cgr.dev/chainguard/python:latest | jq -Mc | sha256sum
```
