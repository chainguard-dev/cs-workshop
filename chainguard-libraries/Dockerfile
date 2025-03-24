FROM cgr.dev/chainguard/maven:latest-dev AS build
USER 0

# OPTIONAL, update java keystore if needed, remove these two lines if you don't need to import a certificate to the java truststore
COPY ca.pem /tmp
RUN $JAVA_HOME/bin/keytool -import -trustcacerts -keystore $JAVA_HOME/lib/security/cacerts \
   -storepass changeit -noprompt -alias mycert -file /tmp/ca.pem && rm /tmp/ca.pem

# update mvn settings.xml
COPY mvn-nexus-settings.xml /usr/share/java/maven/conf/settings.xml
# set to default nonroot user
USER 65532