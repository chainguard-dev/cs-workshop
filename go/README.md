# Go Migration Example

## Overview
This directory contains an example of migrating a Golang application from the default Go image to the Chainguard Go image.

## Steps
### Using upstream image:
1. cd the not-linky directory
```
cd not-linky
```
2. Build the application

```
docker build -t go-notlinky .
```
3. Run the image:

```
docker run -p 8080:8080 --rm go-notlinky
```
4. Scan the image:
```
grype go-notlinky
```

### Takeaways:
1. Single stage build
2. Vulnerabilities from the grype scan
3. Number of packages, files, etc.

### Using Chainguard images:
#### Go Image
1. cd the linky directory
```
cd linky
```
2. Build the application

```
docker build -t go-linky .
```
3. Run the image:

```
docker run -p 8080:8080 --rm go-linky
```
4. Scan the image:
```
grype go-linky
```
#### Takeaways:
1. 0 Vulnerabilities from the grype scan
2. Multistage build
3. Number of packages, files, etc.

#### Static Image
1. cd the linky-static directory
```
cd linky
```
2. Build the application

```
docker build -t go-linkystatic .
```
3. Run the image:

```
docker run -p 8080:8080 --rm go-linkystatic
```
4. Scan the image:
```
grype go-linkystatic
```

### Compare Image Sizes:
```
docker image list | grep go-
```
#### Takeaways:
1. 0 Vulnerabilities from the grype scan
2. Multistage build
3. Number of packages, files, etc.
4. Size of the image is drastically smaller.

## Compare Dockerfiles
1. Note that container registries are different but can just be a drop in replacement for the upstream image.
2. We used a multistage build with Chainguard to only include what's needed in the final image.
3. In the static example, we can use the static base image to have the absolute minimum needed to run the application.
