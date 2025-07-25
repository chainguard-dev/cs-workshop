# google/go-containerregistry

Examples of using the `google/go-containerregistry` module to mutate images.

- `image.go` demonstrates how to modify a single image for a specific platform
- `index.go` demonstrates how to modify a multi-architecture image

## Usage

1. Start a local container registry.

```
docker run -d -p 5005:5005 --rm --name registry distribution/distribution:latest
```

2. Build `mutate`.

```
go build -o mutate .
```

3. Run `mutate`against one of your images. Provide the source image as the first
   argument and the destination as the second. 

   This will resolve the source image down to the default platform
   (`linux/amd64`), customize it and push it to the destination as a
   single-architecture image.

```
./mutate cgr.dev/your.org/python:latest-dev localhost:5005/python:latest-dev
```

4. Provide the `-multi-arch` flag to mutate each image in the index and push a
   multi-arch image to the destination.

```
./mutate -multi-arch cgr.dev/your.org/python:latest-dev localhost:5005/python:latest-dev
```

## Validation

Inspect the annotations and labels on one of your modified images.

```
crane manifest localhost:5000/python:latest-dev | jq -r .
```

```
crane config localhost:5000/python:latest-dev | jq -r .
```

Inspect the content of the layers.

```
export IMAGE=localhost:5005/python:latest-dev
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
