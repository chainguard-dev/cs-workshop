# STIG Scanning GitHub Action Example
- [STIG Scanning GitHub Action Example](#stig-scanning-github-action-example)
  - [Overview](#overview)
  - [Pre-requisites](#pre-requisites)
  - [Steps](#steps)

## Overview
This example shows how to perform a STIG scan of a Chainguard image.  This is based on the publicly available documentation that can be found [here](https://edu.chainguard.dev/chainguard/chainguard-images/features/image-stigs/).

This documents how to setup the GitHub action, a working version of the GitHub action can be found [here](https://github.com/jasonbishay/cg-stig-scan/actions/workflows/oscap.yaml)

**Note:** Only FIPS images will pass the STIG scan.

This action performs the following steps:
1. Builds the dockerfile found in the root of the project.
2. Uses the Chainguard [openscap](https://images.chainguard.dev/directory/image/openscap/overview?utm_source=cg-academy&utm_medium=referral&utm_campaign=dev-enablement&utm_content=edu-content-chainguard-chainguard-images-working-with-images-image-stigs) container to perform the STIG scan using the the [datastream](https://raw.githubusercontent.com/chainguard-dev/stigs/main/gpos/xml/scap/ssg/content/ssg-chainguard-gpos-ds.xml) file sourced from the [Chainguard STIGs](https://github.com/chainguard-dev/stigs/tree/main/gpos/xml/scap/ssg/content) registry.
3. If the scan is successful the image is built for multiple platforms and pushed to GitHub container repository, if the scan fails the images are not pushed to the repo.
4. Regardless if the scan passes or fails, the scan results are then uploaded as an artifact to the action.

## Pre-requisites
1. Access to a Chainguard registry that has at least one FIPS image.
2. Permissions to create an assumable identity using chainctl in order to pull the FIPS image from your Chainguard registry.
3. This example leverages the GitHub container registry to push the images, you will need access to a GHCR or update the action to use a different registry.   

## Steps
1. Follow the steps [here](https://edu.chainguard.dev/chainguard/chainguard-registry/authenticating/#authenticating-with-github-actions) to create an assumable identity for your GitHub repo to authenticate to your Chainguard registry, for e.g.:

```
chainctl iam identity create github [GITHUB-IDENTITY] \
  --github-repo=${GITHUB_ORG}/${GITHUB_REPO} \
  --github-ref=refs/heads/main \
  --role=registry.pull
```

2. Copy and store the ID of the output
3. Create a token with the appropriate permissions to login and push images to GHCR:
    - Go to https://github.com/settings/tokens
    - Click "Generate new token" (choose Classic for most Docker use cases)
    - Set a name and expiration
    - Select the correct scopes:
    - For public repositories: read:packages, write:packages
    - For private repositories: repo, read:packages, write:packages
    - Click "Generate token"
4. Store the token as a secret for the action e.g. GHCR_TOKEN 
5. Create the oscap.yaml file under .github/workflows/oscap.yaml and copy the example from this repo.
6. Update the setup-chainctl step, replace the identity with the output from Step 1 above:
    ```
      - uses: chainguard-dev/setup-chainctl@main
        with:
          identity: "<Output of Step 1>" 
    ```
7. Update the docker/login-action with the name of the secret you created in Step 4:
    ```
      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3.3.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }} 
    ```
8. Update the Build Image docker/build-push-action, update the CHAINGUARD_ORG build org to your Chainguard Org name.
    ```
      - name: Build Image
        uses: docker/build-push-action@v6.18.0
        id: build-and-push
        with:
          platforms: linux/amd64
          push: false
          load: true
          tags: stig-scan-example:latest-temp
          build-args: |
            CHAINGUARD_ORG=<YOUR CHAINGUARD ORG>  
    ```
    **NOTE:** Update this in both places where the docker/build-push-action is used.
9. Update the Rebuild and Push step docker/build-push-action to specify the GitHub registry to push to:
    ```
      - name: Rebuild and Push (after scan passes)
        uses: docker/build-push-action@v6.18.0
        with:
          platforms: linux/amd64,linux/arm64
          push: true
          tags: ghcr.io/<YOUR GITHUB REGISTRY>/stig-example/stig-scan-example:latest
          build-args: |
            CHAINGUARD_ORG=<YOUR CHAINGUARD ORG> 
    ```

10. Save/commit the .github/workflows/oscap.yaml file.
11. Create a Dockerfile in the root of the repo, you can use the existing file in this repo or your own.  The important thing to note is that the STIG scan will only pass on a Chainguard FIPS image.
12. Run the Action by selecting Actions->STIG Scan->Run Workflow
13. Once the Action has completed, select the Actions tab in the repo -> Select the run, scroll to the Artifacts section at the bottom of the page, you can download the "stig-scan-results" to view the results of the scan.


