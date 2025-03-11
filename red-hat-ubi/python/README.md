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

The Chainguard example migrates this to a multi-stage build.

```diff
-FROM registry.access.redhat.com/ubi9/python-312:latest
+# Use the latest-dev tag for the 'build' stage.
+FROM cgr.dev/chainguard/python:latest-dev AS builder

 ENV LANG=C.UTF-8
 ENV PYTHONDONTWRITEBYTECODE=1
@@ -12,6 +13,17 @@ COPY requirements.txt .

 RUN pip install --no-cache-dir -r requirements.txt

+# Use the 'latest' tag for runtime.
+FROM cgr.dev/chainguard/python:latest
+
+WORKDIR /app
+
+ENV PYTHONUNBUFFERED=1
+ENV PATH="/venv/bin:$PATH"
+
+# Copy the required dependencies we installed with pip into the runtime image.
+COPY --from=builder /app/venv /venv
+
 COPY app.py app.png ./

 ENTRYPOINT [ "python", "/app/app.py" ]
```
