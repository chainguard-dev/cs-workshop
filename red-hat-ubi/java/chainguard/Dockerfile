# Chainguard have a dedicated image for maven with tags for each supported
# version of OpenJDK.
FROM cgr.dev/chainguard/maven AS builder

WORKDIR /app

COPY src src
COPY pom.xml pom.xml

RUN mvn clean package

# Chainguard's runtime image for Java is called jre.
FROM cgr.dev/chainguard/jre

WORKDIR /app

COPY --from=builder /app/target/app.jar app.jar

# The Red Hat UBI runtime image doesn't set an ENTRYPOINT, so the CMD is ran
# as it is provided.
#
# In the Chainguard image the ENTRYPOINT is set by the base image to java. This
# means that if we leave the CMD statement as it is, then the resulting
# container will run something like:
#
#   java java -jar app.jar
#
# Note the repetition of 'java', which is obviously invalid.
#
# That's why we replace the CMD with a custom ENTRYPOINT.
ENTRYPOINT ["java", "-jar", "app.jar"]
