FROM cgr.dev/chainguard/maven:latest-dev AS builder

WORKDIR /work

COPY src/ src/
COPY pom.xml pom.xml

RUN mvn clean package

FROM cgr.dev/chainguard/jre AS runner

WORKDIR /app

COPY --from=builder /work/target/java-demo-app-1.0.0.jar .

ENTRYPOINT ["java", "-jar", "java-demo-app-1.0.0.jar"]
