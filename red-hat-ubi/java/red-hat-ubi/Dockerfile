FROM registry.access.redhat.com/ubi9/openjdk-17:latest AS builder

WORKDIR /app

COPY src src
COPY pom.xml pom.xml

RUN mvn clean package

FROM registry.access.redhat.com/ubi9/openjdk-17-runtime

WORKDIR /app

COPY --from=builder /app/target/app.jar app.jar

CMD ["java", "-jar", "app.jar"]
