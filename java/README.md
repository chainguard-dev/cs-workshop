## Java Example 1

Example of a SpringBoot application with a single stage build using the `maven` image.

Build (from `java-example-1-orig` directory)
```
docker build . -t java-example:1
```

Run
```
docker run -d -p 8081:8080 java-example:1
```

## Java Example 2

Example of a SpringBoot application with a multi stage build using the `maven` and `eclipse-temurin` images.

Build (from `java-example-2-orig-multi` directory)
```
docker build . -t java-example:2
```

Run
```
docker run  -d -p 8082:8080 java-example:2
```

## Java Example 3

Example of a SpringBoot application with a multi stage build using Chainguard `maven` and `jre` images.

Build (from `java-example-3-cg-multi` directory)
```
docker build . -t java-example:3
```

Run
```
docker run  -d -p 8082:8080 java-example:3
```

