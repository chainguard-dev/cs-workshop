# red-hat-ubi/java

This is an example of migrating a Dockerfile for a Java application from RedHat
UBI to Chainguard Images.

## Requirements

- `docker`
- `grype`

## Usage

Build the `red-hat-ubi` example.

```
cd red-hat-ubi/
docker build -t red-hat-ubi-java .
```

Run it.

```
docker run --rm red-hat-ubi-java
```

Build the `chainguard` example.

```
cd chainguard/
docker build -t chainguard-java .
```

Run it.

```
docker run --rm chainguard-java
```

Compare the size of the images.

```
docker image ls | grep '.*-java'
```

Scan both images. Observe differences in vulnerabilities.

```
grype red-hat-ubi-java
grype chainguard-java
```

## Differences

You can inspect the differences between the Red Hat UBI and Chainguard examples
with `git diff`.

```shell
git diff --no-index red-hat-ubi chainguard
```

In the following sections we'll talk through the changes.

### Builder Image

We have a dedicated image for `maven` with tags for each supported version of
OpenJDK.

```diff
-FROM registry.access.redhat.com/ubi9/openjdk-17:latest AS builder
+FROM cgr.dev/chainguard/maven AS builder
```

### Runtime Image

Our runtime image for Java is called `jre`.

```diff
-FROM registry.access.redhat.com/ubi9/openjdk-17-runtime
+FROM cgr.dev/chainguard/jre
```

## Cmd vs Entrypoint

The Red Hat UBI runtime image doesn't set an `ENTRYPOINT`, so the `CMD` is ran
as it is provided.

```shell
java -jar app.jar
```

In the Chainguard image the `ENTRYPOINT` is set by the base image to `java`.
This means that if we leave the `CMD` statement as it is, then the resulting
container will run something like:

```shell
java java -jar app.jar
```
Which is invalid.

That's why we replace the `CMD` with a custom `ENTRYPOINT`.

```diff
-CMD ["java", "-jar", "app.jar"]
+ENTRYPOINT ["java", "-jar", "app.jar"]
```

We could also modify `CMD`, like:

```dockerfile
CMD ["-jar", "app.jar"]
```

But I think the `ENTRYPOINT` is more explicit
