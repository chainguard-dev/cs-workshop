# Crane

An example of using `crane mutate` to modify Chainguard Containers.

It lists all the recently updated images in a Chainguard repository, applies
some global configuration to them and pushes them to another registry.

## Requirements

- [`chainctl`](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/)
- [`crane`](https://github.com/google/go-containerregistry/tree/main/cmd/crane)
- [`gnu-tar`](https://formulae.brew.sh/formula/gnu-tar) (for MacOS)

## Usage

1. Start a local container registry.

```
docker run -d -p 5005:5005 --rm --name registry distribution/distribution:latest
```

2. Run `run.sh` with your organization name, the repository you want to ingest and
   the address of your target registry.

   By default the script targets the `linux/amd64` platform. You can change
   this with the `PLATFORM` environment variable.

```
export PLATFORM=linux/arm64
./run.sh your.org python localhost:5005
```

## Validate

Inspect the annotations and labels on one of your modified images.

```
crane manifest localhost:5000/python | jq -r .
```

```
crane config localhost:5000/python | jq -r .
```

Inspect the content of the layers.

```
export IMAGE=localhost:5005/python
crane blob ${IMAGE}@$(crane manifest ${IMAGE} | jq -r '.layers[-1].digest') | tar -tv
crane blob ${IMAGE}@$(crane manifest ${IMAGE} | jq -r '.layers[-2].digest') | tar -tv
```

Run one of your modified `-dev` images and verify that the changes have been
applied.

```
docker run -it --rm --entrypoint bash -u root --pull always localhost:5000/python:latest-dev
```

Check that the APK repositories have been configured. Ensure that the keys exist.

```
bash-5.3# cat /etc/apk/repositories
bash-5.3# ls -l /etc/apk/keys/
```

Verify that the custom certificate is in the bundle.

```
bash-5.3# apk add --no-cache openssl
bash-5.3# while openssl x509 -noout -text; do :; done < /etc/ssl/certs/ca-certificates.crt | grep 'Example Org'
```

Run `update-ca-certificates` and ensure the custom certificate is still in the
bundle.

```
bash-5.3# apk add --no-cache ca-certificates
bash-5.3# update-ca-certificates 
bash-5.3# while openssl x509 -noout -text; do :; done < /etc/ssl/certs/ca-certificates.crt | grep 'Example Org'
```
