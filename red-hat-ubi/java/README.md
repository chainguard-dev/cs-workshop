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
git diff --no-index red-hat-ubi/Dockerfile chainguard/Dockerfile
```

```diff
diff --git a/red-hat-ubi/Dockerfile b/chainguard/Dockerfile
index 538bac4..76b3214 100644
--- a/red-hat-ubi/Dockerfile
+++ b/chainguard/Dockerfile
@@ -1,4 +1,6 @@
-FROM registry.access.redhat.com/ubi9/openjdk-17:latest AS builder
+# Chainguard have a dedicated image for maven with tags for each supported
+# version of OpenJDK.
+FROM cgr.dev/chainguard/maven AS builder

 WORKDIR /app

@@ -7,10 +9,23 @@ COPY pom.xml pom.xml

 RUN mvn clean package

-FROM registry.access.redhat.com/ubi9/openjdk-17-runtime
+# Chainguard's runtime image for Java is called jre.
+FROM cgr.dev/chainguard/jre

 WORKDIR /app

 COPY --from=builder /app/target/app.jar app.jar

-CMD ["java", "-jar", "app.jar"]
+# The Red Hat UBI runtime image doesn't set an ENTRYPOINT, so the CMD is ran
+# as it is provided.
+#
+# In the Chainguard image the ENTRYPOINT is set by the base image to java. This
+# means that if we leave the CMD statement as it is, then the resulting
+# container will run something like:
+#
+#   java java -jar app.jar
+#
+# Note the repetition of 'java', which is obviously invalid.
+#
+# That's why we replace the CMD with a custom ENTRYPOINT.
+ENTRYPOINT ["java", "-jar", "app.jar"]
```
