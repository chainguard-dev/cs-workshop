# Private APK Repo Examples
- [Private APK Repo Examples](#private-apk-repo-examples)
  - [Overview](#overview)
  - [Pre-requisites](#pre-requisites)
  - [Using Private APK Repo in a -dev Image](#using-private-apk-repo-in-a--dev-image)
  - [Using Private APK Repo to create a Distroless Custom Image](#using-private-apk-repo-to-create-a-distroless-custom-image)
  - [Creating a Long Lived Private APK Repo Token](#creating-a-long-lived-private-apk-repo-token)

## Overview
This directory contains examples for using the private apk repository to customize Chainguard images.  This example covers three scenarios:
1. Setting up a docker file to use the private APK repo and adding packages using the dev image. 
2. Setting up a docker file to use the private APK repo adding packages, and creating a distroless image using the chroot method.
3. Creating a pull token for a long lived credential (used for apk repo mirroring or proxy cache).

## Pre-requisites
1. chainctl is installed and user has access to the chainguard org. Chainctl install docs can be found [here](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/)
2. Docker installed to build images
3. jq installed for json parsing
4. Optional, syft installed to generate an SBOM of the custom images
5. Optional, grype installed to scan the images


## Using Private APK Repo in a -dev Image

1. cd to the private-apk-repo directory
```
cd private-apk-repo
```

2. Set ORG variable:

```
export ORG=<YOUR CHAINGUARD ORG>
```

3. Generate Private APK repo credential

```
export CGR_APK_TOKEN=$(chainctl auth token --audience apk.cgr.dev)
```
3. Build the image:

**Note:** Adjust the build arguments as necessary, if you have the python image in your registry feel free to omit the IMAGE argument.

```
docker build  \
    --build-arg ORG=<YOUR ORG> \
    --build-arg IMAGE=python \
    --build-arg APK_LIST="curl" \
    --secret id=cgr-token,env=CGR_APK_TOKEN \
    -t my-custom-image:latest .
```

4. Run the image to verify the package(s) were installed:
```
docker run --rm --entrypoint apk my-custom-image policy curl
```

5. Optional, run syft to generate an SBOM

```
syft my-custom-image -o table
```

6. Optional, Scan the image using grype:
```
grype my-custom-image
```

## Using Private APK Repo to create a Distroless Custom Image

1. cd to the private-apk-repo/distroless directory
```
cd private-apk-repo/distroless
```

2. Set ORG variable:

```
export ORG=<YOUR CHAINGUARD ORG>
```

3. Generate Private APK repo credential

```
export CGR_APK_TOKEN=$(chainctl auth token --audience apk.cgr.dev)
```

4. Build the image:

**Note:** Adjust the build arguments as necessary, if you have the python image in your registry feel free to omit the IMAGE argument.

```
docker build  \
    --build-arg ORG=<YOUR ORG> \
    --build-arg IMAGE=python \
    --build-arg APK_LIST="curl" \
    --secret id=cgr-token,env=CGR_APK_TOKEN \
    -t my-custom-image-distroless:latest .
```

5. Run the image to verify the package(s) were installed:
```
docker run --rm --entrypoint curl my-custom-image-distroless --version
```

6. Optional, run syft to generate an SBOM

```
syft my-custom-image-distroless -o table
```

7. Optional, Scan the image using grype:
```
grype my-custom-image
```

## Creating a Long Lived Private APK Repo Token

1. Set org variable:
```
export ORG=<YOUR CHAINGUARD ORG>
```

2. Create a pull token with a long time to live:

```
chainctl auth pull-token --parent=${ORG} --ttl 8500h -o json > /tmp/token.json
export IDENTITY=$(jq -r .identity_id /tmp/token.json)
export IDENTITY_TOKEN=$(jq -r .token /tmp/token.json)
rm /tmp/token.json
```

3. Add role to pull from APK repo:

```
chainctl iam role-bindings create \
  --parent=${ORG} \
  --identity=${IDENTITY} \
  --role=apk.pull
```

4. Optionally, remove the registy.pull role from the token:

```
export PULL_RB=$(chainctl iam role-bindings list \
  --parent ${ORG} \
  -o json \
  | jq -r --arg identity ${IDENTITY} \
    '
    .items[] | 
    select(.identity == $identity and .role.name == "registry.pull") 
    | .id
    ')

chainctl iam role-bindings delete ${PULL_RB}
```  

5. Test access:

```
curl \
  -u "${IDENTITY}:${IDENTITY_TOKEN}" \
  "https://apk.cgr.dev/${ORG}/x86_64/APKINDEX.tar.gz" 2>/dev/null \
  | tar -tv
```

The token can now be used for authentication to your APK repo. The username is the value of $IDENTITY and the credential is the value of $IDENTITY_TOKEN
