# Node Migration Example

## Overview
This directory contains an example of migrating a node application from upstream node image to the Chainguard node image.

The example is a simple application that takes an image and prints it to the terminal in ASCII. There is a linky and not linky directory which contains the application and dockerfile for both the upstream (not-linky directory) and Chainguard (linky directory) images.

## Steps
### Using upstream image:
1. cd the not-linky directory
```
cd not-linky
```
2. Build the application

```
docker build -t node-notlinky .
```
3. Run the image:

```
docker run --rm node-notlinky
```
4. Scan the image:
```
grype node-notlinky
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
docker build -t node-linky .
```
3. Run the image:

```
docker run --rm node-linky
```
4. Scan the image:
```
grype node-linky
```

### Compare Image Sizes:
```
docker image list | grep node-
```

### Takeaways:
1. Note that Chainguard image does not run as a root user (by default)
2. 0 Vulnerabilities from the grype scan
3. Number of packages, files, etc.

## Compare Dockerfiles
1. Note that container registries are different.
2. We use a multistage build with Chainguard in order to get a smaller runtime image.
3. Upstream uses cmd since there is a shell, CG doesn't have a shell so it uses Entrypoint.
4. Note that we are using the -slim image for the runtime in the Chainguard dockerfile, this is because we don't need a shell for our example, the latest Chainguard node image does have a shell due to many customers using `npm start` for their applications, if this is not necessary they should be using the slim tag.
5. In the Chainguard image our entrypoint uses dumb-init, this is used to wrap the Node process in order to handle signals properly and allow for graceful shutdown.