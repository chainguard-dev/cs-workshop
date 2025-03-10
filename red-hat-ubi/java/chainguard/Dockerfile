FROM cgr.dev/chainguard/maven AS builder

WORKDIR /app

COPY src src
COPY pom.xml pom.xml

RUN mvn clean package

FROM cgr.dev/chainguard/jre

WORKDIR /app

COPY --from=builder /app/target/app.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
