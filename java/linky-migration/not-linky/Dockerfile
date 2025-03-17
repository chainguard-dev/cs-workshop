FROM maven:latest AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests
COPY image.jpg ./image.jpg

ENTRYPOINT ["java", "-jar", "target/ascii-converter-1.0-SNAPSHOT.jar", "./image.jpg", "120", "60"]