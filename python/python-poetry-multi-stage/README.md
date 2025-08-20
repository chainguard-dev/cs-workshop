# ChainLabs Roadshow Workshop

Welcome to the ChainLabs Roadshow Workshop Repo! In this README, you'll get hands-on experience migrating applications from traditional open source base images to Chainguard’s secure, near-zero CVE images. In this workshop, you’ll learn how to:

- Migrate applications without adding package managers, installing development tools, or building new pipelines
- Customize secure images while preserving end-to-end integrity for open source software
- Leverage Chainguard’s CVE remediation SLA to maintain security over time

This example uses a multi-stage image build for a 'Hello World' Python image leveraging poetry, but there are many more Migration Guides available at [https://edu.chainguard.dev/chainguard/migration/](https://edu.chainguard.dev/chainguard/migration/).

**If you need assistance with any steps in the workshop, please raise your hand and a Chainguard Engineer will come by to assist you.**

## Prerequisites

- Docker
- Grype, Trivy, and/or Docker Scout
- Access to the Chainguard Private Registry

## 0. Setup

```sh
git clone https://github.com/chainguard-dev/cs-workshop.git
cd cs-workshop/python/python-poetry-multi-stage
```

### 1a. Benchmark Your Base Image

- Container Hardening Priorities (CHPs) Scorer: [https://github.com/chps-dev/chps-scorer](https://github.com/chps-dev/chps-scorer)
- _Scanners will yield different results, so it's important to choose wisely in order to combat false negatives and false positives_

```sh
docker inspect python:3.10

docker scout cves python:3.10
trivy image python:3.10
grype python:3.10

docker run --privileged ghcr.io/chps-dev/chps-scorer:latest python:3.10
```

### 1b. Build & Test Your Application

```sh
docker build -t python-poetry-deb:latest -f Dockerfile.deb
docker run --rm --name poetry -p 8000:8000 python-poetry-deb:latest

# INFO:     Started server process [1]
# INFO:     Waiting for application startup.
# INFO:     Application startup complete.
# INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

You should see the hello world page now at http://0.0.0.0:8000

### 1c. Evaluate Your Application's Final Attack Surface

```sh
docker scout cves python-poetry-deb:latest
trivy image python-poetry-deb:latest
grype python-poetry-deb:latest
```

### 2. Migrate Your Application to an Alternate Base Image

1. Size & UID
2. CVEs
3. CHPs
4. Dockerfile updates

### 3. Harden Your Application Using a Multi-Stage Build

1. Start a new build stage based on the `python:3.10-dev` container image and call it `builder`
2. Create a new virtual environment to cleanly hold the application’s dependencies
3. Start a new build stage based on the `python:3.10` image
4. Copy the dependencies in the virtual environment from the builder stage, and the source code from the current directory

### 4. Use Dockerfile Convertor (DFC) to Migrate Your Application to a Secure Base Image

- Dockerfile Convertor (DFC): [https://github.com/chainguard-dev/dfc](https://github.com/chainguard-dev/dfc)
- _Update DFC packages_
- _Fix ORG in Dockerfile.chainguard_

### 5. Use Custom Assembly (CA) to Reduce Complexity

To do...

### 6. Eliminate Even-More OSS Supply Chain Risk Using Chainguard Libraries

- Chainguard Libraries Overview: [https://edu.chainguard.dev/chainguard/libraries/overview/](https://edu.chainguard.dev/chainguard/libraries/overview/)