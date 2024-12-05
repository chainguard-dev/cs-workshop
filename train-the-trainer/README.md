# Chainguard Train the Trainer Workshop

## Overview
This repository contains the materials for the Chainguard Train the Trainer Workshop. The workshop is designed to help you understand the Chainguard platform and how to teach others about it. The workshop is broken down into the following sections:
1. Chainguard Overview
  * Explaining Chainguard Images to your teams
2. Docker 102
  * Deep dive into container images
  * Hands on exercises to learn tactics needed for hardened, distroless-type images
3. Chainguard Migration Basics
  * Review the differences from using a Chainguard Image (Wolfi) and other Linux distributions
  * Language Migration and Examples
  * Walkthrough examples of various languages (Java, Python, etc) and understand how to leverage multi-stage build to minimalist secure image
4. Debugging Tactics
  * Learn various debugging strategies for Distroless images
5. Image Tags
  * Understand tags and Chainguard images
6. CLI Tools and Demos 
  * Understand the different CLI tools and how to gain knowledge from your Chainguard images (compare, tags, scan, SBOMs and more)

### Prerequisites
It is expected that attendees have a working knowledge of containers, images, and the common tools used to build and run them such as the command line "docker run", "docker build", etc. A basic understanding of simple Dockerfiles and the concepts around pushing and pulling to registries is also required.

In order to participate in the hands-on sections of the class, please make sure you have access to the following tools (or the ability to install them) and note the network connectivity requirements:

#### Mandatory items:
* A Docker-compatible runtime (i.e. [Docker Desktop](https://www.docker.com/products/docker-desktop/) or [docker cli](https://docs.docker.com/engine/install/))
* [git](https://git-scm.com/)
* an IDE /  code editor (i.e. [VS Code](https://code.visualstudio.com/), [Jetbrains IDE](https://www.jetbrains.com/), [vim](https://www.vim.org/), etc)

#### Optional but helpful:
* [crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane.md)
* [chainctl](https://edu.chainguard.dev/chainguard/chainctl/)
* [jq](https://jqlang.github.io/jq/) 
* [cdebug](https://github.com/iximiuz/cdebug) 
* [kubectl](https://kubernetes.io/docs/tasks/tools/) (for local kubernetes experiments - comes with Docker Desktop)
* [Kind](https://kind.sigs.k8s.io/), [MiniKube](https://minikube.sigs.k8s.io/) or Docker Desktop Kubernetes (or any Kubernetes cluster sandbox you have access too to deploy and debug in)

#### Network access requirements:
Our full platform access requirements are documented here: https://edu.chainguard.dev/chainguard/administration/network-requirements/

If you have a private mirror of your Chainguard registry images and/or apk package repositories, those may be used with minor modifications that we will address in the workshops.

In addition, internet access to the following will be needed:
* [github.com](http://github.com/)
* [DockerHub](https://hub.docker.com/) (or internal proxy to it)
  * This is optional, we can work around it if DockerHub images are not available.