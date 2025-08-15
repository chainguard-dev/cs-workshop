# Crane

An example of using `crane mutate` to modify Chainguard Containers.

## Requirements

- [`chainctl`](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/)
- [`crane`](https://github.com/google/go-containerregistry/tree/main/cmd/crane)
- [`gnu-tar`](https://formulae.brew.sh/formula/gnu-tar) (for MacOS)

## Usage

1. Start a local container registry.

```
docker run -d -p 5000:5000 --rm --name registry distribution/distribution:latest
```

2. Run `mutate.sh` with an image in your organization as the first argument and
   a tag in the destination registry as the second.

   By default the script targets the `linux/amd64` platform. You can change
   this with the `PLATFORM` environment variable.

```
export PLATFORM=linux/arm64
./mutate.sh cgr.dev/your.org/python:latest-dev localhost:5000/python:latest-dev
```

## Validate

Export the image reference for use in subsequent commands.

```
export IMAGE=localhost:5000/python:latest-dev
```

Inspect the annotations and labels on your modified image.

```
crane manifest ${IMAGE} | jq -r .
```

```
crane config ${IMAGE} | jq -r .
```

Inspect the content of the additional layer.

```
crane blob ${IMAGE}@$(crane manifest ${IMAGE} | jq -r '.layers[-1].digest') | tar -tv
```

Run the image and check that the changes have been
applied.

```
docker run -it --rm --entrypoint bash -u root --pull always ${IMAGE}
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
