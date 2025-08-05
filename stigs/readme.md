# STIG Examples
- [STIG Examples](#stig-examples)
  - [Overview](#overview)
  - [Pre-Requisites](#pre-requisites)
  - [STIG scanning of a Registry Container (manual steps):](#stig-scanning-of-a-registry-container-manual-steps)
  - [STIG scanning of a Registry Container (scripted):](#stig-scanning-of-a-registry-container-scripted)
  - [Running STIG Scans in a GitHub Action](#running-stig-scans-in-a-github-action)

## Overview
This directory contains examples for STIG scanning of Chainguard images.  This example covers three scenarios:
1. Manual scanning.
2. STIG scanning in a GitHub Action.

The practice of using Security Technical Implementation Guides, or “STIGs,” to secure various technologies originated with the United States Department of Defense (DoD). If an organization uses a certain kind of software, say MySQL 8.0, they must ensure that their implementation of it meets the requirements of the associated Security Requirements Guides (SRG) in order to qualify as a vendor for the DoD. More recently, other compliance frameworks have begun acknowledging the value of STIGS, with some going so far as to require the use of STIGs in their guidelines.

Chainguard releases a STIG for the [General Purpose Operating System (GPOS) SRG](https://stigviewer.com/stigs/general_purpose_operating_system_security_requirements_guide) — an SRG that specifies security requirements for general purpose operating systems running in a network. The goal for this STIG is that it will help customers confidently and securely integrate Chainguard Containers into their workflows. More details can be found [here](https://edu.chainguard.dev/chainguard/chainguard-images/features/image-stigs/).

The examples below show how you can verify STIG Compliance with Chainguard images. The STIG profile used in the examples below are bundled with the openscap image, the profile itself is maintained [here](https://github.com/chainguard-dev/stigs/tree/main/gpos/xml/scap/ssg/content)


## Pre-Requisites
1. chainctl is installed and user has access to the chainguard org. Chainctl install docs can be found [here](https://edu.chainguard.dev/chainguard/chainctl-usage/how-to-install-chainctl/)
2. Docker installed to run images
3. STIG scanning is only successful on FIPS images, therefore you must have access to at least 1 FIPS image.
4. Access to the OpenSCAP Image from Chainguard, [available in the free tier image catalog](https://images.chainguard.dev/directory/image/openscap/versions)


## STIG scanning of a Registry Container (manual steps):

1. cd to the stigs directory
```
cd stigs/
```

2. Set ORG variable:

```
export ORG=<YOUR CHAINGUARD ORG>
```

3. First start the container you want to scan: 

```
# Start the target image (required by openscap-docker)
docker run --name target -d cgr.dev/$ORG/python-fips:latest tail -f /dev/null
```

4. Run the scan against the running container:
```
# Run the scan image against the target image
# NOTE: This is a highly privileged container since we're scanning a container being run by the host's docker daemon.
docker run --privileged -i --rm -u 0:0 --pid=host \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(pwd)/out:/out \
    --entrypoint sh \
    cgr.dev/chainguard/openscap:latest-dev <<_END_DOCKER_RUN
oscap-docker container target xccdf eval \
--profile "xccdf_basic_profile_.check" \
--report /out/report.html \
--results /out/results.xml \
/usr/share/xml/scap/ssg/content/ssg-chainguard-gpos-ds.xml
_END_DOCKER_RUN
```

5. Clean up the running container:
```
docker stop target && docker rm target
```
## STIG scanning of a Registry Container (scripted):
The demo.sh script can be used to run the above demo, if you have demo magic installed simply run the demo.sh script. Ensure you set the variables at the top of the script to an ORG you have access to and IMAGE to a FIPS image in the ORG:

```
./demo.sh
```

## Running STIG Scans in a GitHub Action
In some cases you may want to run a STIG scan on your own images in a CI/CD pipeline, the example builds an image from a Dockerfile located in the repo and then runs a STIG scan on it, and posts the results as an artifact for later viewing.  If the scan fails it will stop the pipeline and not push the built image to the GHCR.

More details can be found in the [stig-githhub-action-example](stig-github-action-example/readme.md) directory.


