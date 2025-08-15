# Dockerfile

This is an example of applying common modifications to Chainguard images using
`docker` and a generic `Dockerfile`.

It adds custom certificates, APK repositories and annotations to images.

## Requirements

- [`chainctl`](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/)
- [`docker`](https://docs.docker.com/engine/install/)
- [`jq`](https://jqlang.org/download/)

## Usage

1. Start a local container registry.

```
docker run -d -p 5000:5000 --rm --name registry distribution/distribution:latest
```

2. Run `mutate.sh` with an image in your organization as the first argument and
   a tag in the destination registry as the second.

```
./mutate.sh cgr.dev/your.org/python:latest-dev localhost:5000/python:latest-dev
```

## Validate

Export the image reference for use in subsequent commands.

```
export IMAGE=localhost:5000/python:latest-dev
```

Pull the image.

```
docker pull ${IMAGE}
```

Inspect the annotations and labels on your modified image.

```
docker buildx imagetools inspect ${IMAGE} --raw | jq -r .
```

```
docker inspect ${IMAGE}
```

Inspect the content of the additional layers.

```
mkdir -p extracted
docker save ${IMAGE} | tar -x -C extracted
tar -tv < "./extracted/$(jq -r '.[].Layers[-1]' < ./extracted/manifest.json)"
tar -tv < "./extracted/$(jq -r '.[].Layers[-2]' < ./extracted/manifest.json)"
tar -tv < "./extracted/$(jq -r '.[].Layers[-3]' < ./extracted/manifest.json)"
tar -tv < "./extracted/$(jq -r '.[].Layers[-4]' < ./extracted/manifest.json)"
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
