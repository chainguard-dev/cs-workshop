# Java Migration Example

## Overview
This directory contains an example of migrating a java application from upstream Openjdk image to the Chainguard Java image.

The example is a simple application that takes an image and prints it to the terminal in ASCII. There is a linky and not linky directory which contains the application and dockerfile for both the upstream (not-linky directory) and Chainguard (linky directory) images.

Note: This example uses a maven build process.

## Steps
### Using upstream image:
1. cd the not-linky directory
```
cd not-linky
```
2. Build the application

```
docker build -t java-notlinky .
```
3. Run the image:

```
docker run --rm java-notlinky
```
4. Scan the image:
```
grype java-notlinky
```

### Takeaways:
1. Note that the upstream image runs by default as the root user (bad practice)
2. Vulnerabilities from the grype scan
3. Number of packages, files, etc.

### Using Chainguard images:
1. cd the linky directory
```
cd linky
```
2. Build the application

```
docker build -t java-linky .
```
3. Run the image:

```
docker run --rm java-linky
```
4. Scan the image:
```
grype java-linky
```

### Compare Image Sizes:
```
docker image list | grep java-
```

### Takeaways:
1. Note that Chainguard image does not run as a root user (by default)
2. 0 Vulnerabilities from the grype scan
3. Number of executables, files, etc.

## Compare Dockerfiles
1. Note that container registries are different.
2. Chainguard example uses a multistaged build with the jre image for runtime.