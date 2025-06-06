## Java Example 1

Example of a SpringBoot application with a single stage build using the `maven` image.

```
docker build -t java-example:1 ./step1-orig
```

Run
```
docker run -d -p 8081:8080 java-example:1
```

## Java Example 2

Example of a SpringBoot application with a multi stage build using the `maven` and `eclipse-temurin` images.

```
docker build -t java-example:2 ./step2-orig-multi
```

Run
```
docker run  -d -p 8082:8080 java-example:2
```

## Java Example 3

Example of a SpringBoot application with a multi stage build using Chainguard `maven` and `jre` images.

```
docker build -t java-example:3 ./step3-cg-multi
```

Run
```
docker run  -d -p 8082:8080 java-example:3
```

