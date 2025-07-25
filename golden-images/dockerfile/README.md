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
docker run -d -p 5000:5000 --rm --name registry cgr.dev/chainguard/distribution:latest
```

2. Run `run.sh` with your organization name, the repository you want to ingest and
   the address of your target registry.

```
./run.sh your.org python localhost:5000
```

## Validate

Inspect the annotations on one of your modified images.

```
crane manifest localhost:5000/python | jq -r .
crane manifest --platform=linux/arm64 localhost:5000/python | jq -r .
crane manifest --platform=linux/amd64 localhost:5000/python | jq -r .
```

Inspect the content of the layers.

```
export IMAGE=localhost:5000/python
crane blob ${IMAGE}@$(crane manifest --platform=linux/amd64 ${IMAGE} | jq -r '.layers[-1].digest') | tar -tv
crane blob ${IMAGE}@$(crane manifest --platform=linux/amd64 ${IMAGE} | jq -r '.layers[-2].digest') | tar -tv
crane blob ${IMAGE}@$(crane manifest --platform=linux/amd64 ${IMAGE} | jq -r '.layers[-3].digest') | tar -tv
crane blob ${IMAGE}@$(crane manifest --platform=linux/amd64 ${IMAGE} | jq -r '.layers[-4].digest') | tar -tv
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
