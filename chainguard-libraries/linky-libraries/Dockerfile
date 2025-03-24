# Stage 1: Build the Java application
FROM chainguard-libraries-mvn AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run the Java application
FROM cgr.dev/chainguard/jre:latest
WORKDIR /app
COPY image.jpg ./image.jpg
COPY --from=build /app/target/ascii-converter-1.0-SNAPSHOT.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar", "./image.jpg", "120", "60"]