# Chainguard Libraries Demo with Nexus
- [Chainguard Libraries Demo with Nexus](#chainguard-libraries-demo-with-nexus)
  - [Overivew](#overivew)
  - [Pre-requisites](#pre-requisites)
  - [Demo Steps](#demo-steps)
    - [Install Nexus](#install-nexus)
    - [Configure Nexus](#configure-nexus)
    - [Configure Maven Image](#configure-maven-image)
    - [Build Java App Using Nexues Repo](#build-java-app-using-nexues-repo)
  - [Teardown](#teardown)

## Overivew
This guide is an end-to-end walkthrough of using Chainguard Libraries. The guide covers the following:
1. Walks through setting up Chainguard libraries using a Nexus Artifact repository
2. Modifiying the Chainguard Maven image to use the Nexues repo as the default repository
3. Builds a Java application using the Nexus repository instead of maven central to pull dependencies.

## Pre-requisites
1. Kubernetes environment to deploy the Nexus repo, the K8s environment should also have an ingress controller installed.
2. Ensure you have granted the entitlements to the org you will be using by following the directions [here](https://chainguard.atlassian.net/wiki/spaces/Sales/pages/99844105/How+do+I+enable+a+customer+for+access+to+Chainguard+Libraries)
   * Make sure you follow the steps closely, and you verify that you have access to the Java artifact repo prior to following the steps here.
3. This guide uses cert-manager to provide certificates for Nexus, you don't need to set up TLS everything should still work without it. If you want to use TLS for the Nexus repo you will need to ensure you have a cert-manager issuer installed and configured in your cluster.

## Demo Steps
### Install Nexus
We will be deploying Nexus into a K8s cluster.  There is currently no supported helm chart for deploying Nexus OSS in K8s, but the currently deprecated helm chart still works with the latest versions with some workarounds that this guide will walk you through.

1. Set some variable for our deployment:
Set the namespace for the Nexus deployment, name of the certificate, name of the secret for the certificate and the hostname for the Nexus instance.

```
# deployment variables
NS="nexus"                  # Namespace to deploy Nexus to
CERT_NAME="nexus-reg-cert"  # Name of the Certificate for cert-manager to create
SECRET_NAME="nexus-reg-cert-secret" # Certificate secret
REGISTRY_HOST="demo.nexus.dev"  # Hostname for nexus
```

2. Create the Namespace:
```
# create ns if it doesn't already exist
kubectl create namespace ${NS} --dry-run=client -o yaml | kubectl apply -f -
```

3. Create the cert for Nexus using cert-manager, note this step is optional, you can provide your own cert in a secret, or not use a certificate at all. You may need to update the details below for your cert-manager issuer.
```
# Create cert for registry using cert-manager
read -r -d '' REG_CERT <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${CERT_NAME}
  namespace: ${NS}
  labels:
    app.kubernetes.io/name: ${CERT_NAME}
spec:
  secretName: ${SECRET_NAME}
  secretTemplate:
  renewBefore: 72h
  privateKey:
    rotationPolicy: Always
  issuerRef:
    name: <YOUR CERT MANAGER ISSUER>
    kind: ClusterIssuer
    group: cert-manager.io
  dnsNames:
    - ${REGISTRY_HOST}
  subject:
    organizations:
      - chainguard
EOF
echo "${REG_CERT}" | kubectl apply -f -
```

4. Deploy Nexus
If you are not using a certificate, modify the ingress settings below.
```
# add repo
helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm repo update

# Install nexus
# based on this: https://github.com/sonatype/nxrm3-helm-repository/blob/main/nexus-repository-manager/values.yaml
# update image tag based on: https://hub.docker.com/r/sonatype/nexus3/tags
helm upgrade --install nexus-repo sonatype/nexus-repository-manager --wait --namespace ${NS} \
  --set image.tag="3.78.2" \
  --set ingress.enabled=true \
  --set ingress.host=${REGISTRY_HOST} \
  --set ingress.ingressClassName=nginx \
  --set ingress.tls\[0\].secretName=${SECRET_NAME} \
  --set ingress.tls\[0\].hosts\[0\]=${REGISTRY_HOST} \
  --set ingress.hostRepo=${REGISTRY_HOST} # \
```
5. Get the Admin Password

The admin password can be retrieved from the pod, this is one of those weird things from using the deprecated helm chart, it doesn't allow you to set a password on install.

```
# get default admin password
# shell into pod get file, this is a hack because the old helm chart doesn't provide a way to set the admin pass at install
POD_NAME=$(kubectl get pods --no-headers=true -n $NS -o name | awk -F "/" '{print $2}')
ADMIN_PASS=$(kubectl exec $POD_NAME -n nexus -- cat /nexus-data/admin.password)
echo $ADMIN_PASS
```

You should be able to login to the UI at https://$REGISTRY_NAME using the username admin and the password from above.

The remainder of the Nexus setup steps can be performed from within the UI if you'd like, but this guide will use the REST API to finish the setup.

**NOTE:** Even if you wish to configure the rest of this from the command line, you still need to login and accept the license before the repo will work.

### Configure Nexus

6. Configure Anonymous Access

This step is optional (and not best practice) but it avoids dealing with credentials in maven when accessing the repo:

```
# set anonymous access
curl -vX PUT -u admin:${ADMIN_PASS} "https://${REGISTRY_HOST}/service/rest/v1/security/anonymous" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'NX-ANTI-CSRF-TOKEN: 0.2000863451060393' \
  -H 'X-Nexus-UI: true' \
  -d '{
  "enabled": true,
  "userId": "anonymous",
  "realmName": "NexusAuthenticatingRealm"
}'
```

7. Get credentials to Chainguard Java artifact repo:

```
chainctl auth login
CREDS_OUTPUT=$(chainctl auth pull-token --library-ecosystem=java --parent="${ORG_NAME}" -o json)
CGR_USERNAME=$(echo $CREDS_OUTPUT | jq -r '.identity_id')
CGR_TOKEN=$(echo $CREDS_OUTPUT | jq -r '.token')
```

8. Verify Credentials
Note this should have been done as part of the pre-requisites but to double check we can make sure the credentials work for the Chainguard artifact repo:

```
# Verify our credentials with Chainguard repo:
curl -v -X GET \
  'https://libraries.cgr.dev/maven/com/fasterxml/jackson/core/jackson-core/2.18.2/jackson-core-2.18.2.jar' \
  -u "$CGR_USERNAME:$CGR_TOKEN"  --output jackson.jar
```

This should download the jackson-core 2.18.2 jar file directly from the repo.  If this command doesn't work, or returns a 4XX error, fix the access prior to continuing with this guide.

9.  Create the Chainguard proxy maven repo in Nexus

```
CGR_MAVEN_REPO="https://libraries.cgr.dev/maven/"
NEXUS_CG_REPO_NAME="mavencentral-cg"
curl -vX POST -u admin:${ADMIN_PASS} "https://${REGISTRY_HOST}/service/rest/v1/repositories/maven/proxy" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'NX-ANTI-CSRF-TOKEN: 0.2000863451060393' \
  -H 'X-Nexus-UI: true' \
  -d '{
  "name": "'${NEXUS_CG_REPO_NAME}'",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "cleanup": {
    "policyNames": [
      "string"
    ]
  },
  "proxy": {
    "remoteUrl": "'${CGR_MAVEN_REPO}'",
    "contentMaxAge": -1,
    "metadataMaxAge": 1440
  },
  "negativeCache": {
    "enabled": true,
    "timeToLive": 1440
  },
  "httpClient": {
    "blocked": false,
    "autoBlock": true,
    "authentication": {
      "type": "username",
      "username": "'${CGR_USERNAME}'",
      "password": "'${CGR_TOKEN}'"
    }
  },
  "routingRule": "string",
  "replication": {
    "preemptivePullEnabled": false,
    "assetPathRegex": "string"
  },
  "maven": {
    "versionPolicy": "RELEASE",
    "layoutPolicy": "STRICT",
    "contentDisposition": "INLINE"
  }
}'
```

10. Create the Maven group in Nexus so failed attempts will default to maven central

```
# Create Maven group repo:
NEXUS_MAVEN_GROUP_REPO_NAME="mavencentral-chainguard"
curl -vX POST -u admin:${ADMIN_PASS} "https://${REGISTRY_HOST}/service/rest/v1/repositories/maven/group" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'NX-ANTI-CSRF-TOKEN: 0.2000863451060393' \
  -H 'X-Nexus-UI: true' \
 -d '{
  "name": "'${NEXUS_MAVEN_GROUP_REPO_NAME}'",
  "online": true,
  "storage": {
    "blobStoreName": "default",
    "strictContentTypeValidation": true
  },
  "group": {
    "memberNames": [
      "'${NEXUS_CG_REPO_NAME}'",
      "maven-central"
    ]
  }
}'
```
### Configure Maven Image
10. Generate Maven settings.xml

We will generate a Maven settings file to force maven to only use the Nexus repo for pulling dependencies, this ensures all dependencies will come from our repo instead of defaulting to maven central.  This file will be used in the Maven image to override the defaults.

```
# Generate a maven settings.xml file to force maven to use our nexus repo:
cat > mvn-nexus-settings.xml <<EOF
<settings>
  <mirrors>
    <mirror>
      <!--This sends everything else to /public -->
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>https://${REGISTRY_HOST}/repository/${NEXUS_MAVEN_GROUP_REPO_NAME}/</url>
    </mirror>
  </mirrors>
  <profiles>
    <profile>
      <id>nexus</id>
      <!--Enable snapshots for the built in central repo to direct -->
      <!--all requests to nexus via the mirror -->
      <repositories>
        <repository>
          <id>central</id>
          <url>http://central</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </repository>
      </repositories>
     <pluginRepositories>
        <pluginRepository>
          <id>central</id>
          <url>http://central</url>
          <releases><enabled>true</enabled></releases>
          <snapshots><enabled>true</enabled></snapshots>
        </pluginRepository>
      </pluginRepositories>
    </profile>
  </profiles>
  <activeProfiles>
    <!--make the profile active all the time -->
    <activeProfile>nexus</activeProfile>
  </activeProfiles>
</settings>
EOF
```

11. Customize the Maven Chainguard Image with our Nexus settings (and import the certificate if need be). If you don't need to import a certificate remove those lines from the docker file:

```
FROM cgr.dev/chainguard/maven:latest-dev AS build
USER 0
# update java keystore if needed, remove the two lines below if you don't need to add a certificate.
COPY ca.pem /tmp
RUN $JAVA_HOME/bin/keytool -import -trustcacerts -keystore $JAVA_HOME/lib/security/cacerts \
   -storepass changeit -noprompt -alias mycert -file /tmp/ca.pem && rm /tmp/ca.pem

# update mvn settings.xml
COPY mvn-nexus-settings.xml /usr/share/java/maven/conf/settings.xml
# set back to default nonroot user
USER 65532
```

12. Build Custom Maven Image

```
# Build docker container:
docker build -t chainguard-libraries-mvn .
```

13. Test the image to ensure it works:
Note: in the command below we add a host entry to resolve the Nexus instance from our local machine, this may not be needed in your case.

```
# do a test with dependency get and our docker container
# Note: you may need to add --add-host $REGISTRY_HOST:<IP of ingress controller> if the registry hostname isn't resolvable via DNS.
docker run --rm chainguard-libraries-mvn dependency:get -Dartifact=commons-io:commons-io:2.15.0:jar:sources

```
You should see Maven pull the dependency from Nexus.

**Note:** You can tag and push the custom maven image to a remote repo if needed.

### Build Java App Using Nexues Repo

14. Build sample Java app

If everything has gone well, you should now be able to build the sample java app.

```
cd linky-libraries
docker build -t linky-libraries .
docker run --rm linky-libraries
```
15. If you log back into the Nexus repo you can see the libraries that were pulled from the Chainguard repository:
* Login to the UI
* Select Browse
* Select the Chainguard repository
* You can also select "Search" -> More Criteria -> Repository Name -> Enter the Chainguard Repository -> Hit Enter

## Teardown

To remove everything, run the following commands:
```
# teardown
helm delete nexus-repo -n ${NS}
kubectl delete certificate ${CERT_NAME} -n ${NS}
kubectl delete ns ${NS}
docker rmi chainguard-libraries-mvn
docker rmi linky-libraries
```