#!/bin/bash

# cgr details
ORG_NAME="<ORG NAME>"

# deployment variables
NS="nexus"                  # Namespace to deploy Nexus to
CERT_NAME="nexus-reg-cert"  # Name of the Certificate for cert-manager to create
SECRET_NAME="nexus-reg-cert-secret" # Certificate secret
REGISTRY_HOST="demo.nexus.dev"  # Hostname for nexus

# create ns if it doesn't already exist
kubectl create namespace ${NS} --dry-run=client -o yaml | kubectl apply -f -

# Create cert for registry using cert-manager
# These settings may need to be changed for your cert-manager deployment
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
    name: cg-ca-issuer
    kind: ClusterIssuer
    group: cert-manager.io
  dnsNames:
    - ${REGISTRY_HOST}
  subject:
    organizations:
      - chainguard
EOF
echo "${REG_CERT}" | kubectl apply -f -

# add helm repo for Sonatype
helm repo add sonatype https://sonatype.github.io/helm3-charts/
helm repo update

# Install nexus
# based on this: https://github.com/sonatype/nxrm3-helm-repository/blob/main/nexus-repository-manager/values.yaml
# update image tag based on: https://hub.docker.com/r/sonatype/nexus3/tags
helm upgrade --install nexus-repo sonatype/nexus-repository-manager --wait --debug --namespace ${NS} \
  --set image.tag="3.78.2" \
  --set ingress.enabled=true \
  --set ingress.host=${REGISTRY_HOST} \
  --set ingress.ingressClassName=nginx \
  --set ingress.tls\[0\].secretName=${SECRET_NAME} \
  --set ingress.tls\[0\].hosts\[0\]=${REGISTRY_HOST} \
  --set ingress.hostRepo=${REGISTRY_HOST} 

# Get default admin password
# shell into pod get file, this is a hack because the old helm chart doesn't provide a way to set the admin pass at install
POD_NAME=$(kubectl get pods --no-headers=true -n $NS -o name | awk -F "/" '{print $2}')
ADMIN_PASS=$(kubectl exec $POD_NAME -n nexus -- cat /nexus-data/admin.password)
echo $ADMIN_PASS

# set anonymys access
curl -X PUT -u admin:${ADMIN_PASS} "https://${REGISTRY_HOST}/service/rest/v1/security/anonymous" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H 'NX-ANTI-CSRF-TOKEN: 0.2000863451060393' \
  -H 'X-Nexus-UI: true' \
  -d '{
  "enabled": true,
  "userId": "anonymous",
  "realmName": "NexusAuthenticatingRealm"
}'

# Get creds for CG Libraries java
chainctl auth login
CREDS_OUTPUT=$(chainctl auth pull-token --library-ecosystem=java --parent="${ORG_NAME}" -o json)
CGR_USERNAME=$(echo $CREDS_OUTPUT | jq -r '.identity_id')
CGR_TOKEN=$(echo $CREDS_OUTPUT | jq -r '.token')
echo $CGR_USERNAME
#echo $CGR_TOKEN

# Verify our credentials with chainguard maven repo:
curl -v -X GET \
  'https://libraries.cgr.dev/maven/com/fasterxml/jackson/core/jackson-core/2.18.2/jackson-core-2.18.2.jar' \
  -u "$CGR_USERNAME:$CGR_TOKEN"  --output jackson.jar


# Create CG Library proxy repo in nexus:
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

# Build docker container:
docker build -t chainguard-libraries-mvn .

# do a test with dependency get and our docker container
# Note: you may need to add --add-host $REGISTRY_HOST:<IP of ingress controller> if the registry hostname isn't resolvable via dns.
docker run --rm chainguard-libraries-mvn dependency:get -Dartifact=commons-io:commons-io:2.15.0:jar:sources


# build linky
cd linky-chibbies
docker build -t linky-chibbies .
docker run --rm linky-chibbies

# teardown
# helm delete nexus-repo -n ${NS}
# kubectl delete certificate ${CERT_NAME} -n ${NS}
# kubectl delete ns ${NS}
# docker rmi chainguard-libraries-mvn
# docker rmi linky-libraries
