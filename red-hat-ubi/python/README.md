# red-hat-ubi/python

This is an example of migrating an image for a Python application from RedHat
UBI to Chainguard Images.

## Requirements

- `docker`
- `grype`

## Usage

Build the `red-hat-ubi` example.

```
cd red-hat-ubi/
docker build -t red-hat-ubi-python .
```

Run it.

```
docker run --rm red-hat-ubi-python
```

Build the `chainguard` example.

```
cd chainguard/
docker build -t chainguard-python .
```

Run it.

```
docker run --rm chainguard-python
```

Compare the size of the images.

```
docker image ls | grep '.*-python'
```

Scan both images. Observe differences in vulnerabilities.

```
grype red-hat-ubi-python
grype chainguard-python
```

## Differences

You can inspect the differences between the Red Hat UBI and Chainguard examples
with `git diff`.

```shell
git diff --no-index red-hat-ubi chainguard
```

The Red Hat UBI example does not use a multi-stage build because there is no
minimal, runtime version of the `python-312` image. This means the created image
still contains superfluous software like `pip`.

For the Chainguard example, we use the `latest-dev` tag of the `python` image
to install dependencies in a virtualenv with `pip` and then we copy that
virtualenv into a second stage that uses the more minimal `latest` tag.

This ensures our application has the dependencies it needs at runtime, without
the extra bloat of the build time image.

```diff
-FROM registry.access.redhat.com/ubi9/python-312:latest
+FROM cgr.dev/chainguard/python:latest-dev AS builder

 ENV LANG=C.UTF-8
 ENV PYTHONDONTWRITEBYTECODE=1
@@ -12,6 +12,14 @@ COPY requirements.txt .

 RUN pip install --no-cache-dir -r requirements.txt

+FROM cgr.dev/chainguard/python:latest
+
+WORKDIR /app
+
+ENV PYTHONUNBUFFERED=1
+ENV PATH="/venv/bin:$PATH"
+
 COPY app.py app.png ./
+COPY --from=builder /app/venv /venv

 ENTRYPOINT [ "python", "/app/app.py" ]
```
