#!env bash
export DOCKER_CLI_HINTS=false
set -x
kind create cluster 

# Warming up docker image caches
docker pull cgr.dev/chainguard/nginx:latest-dev
docker pull cgr.dev/chainguard/nginx:latest
docker pull busybox:latest
docker pull busybox:musl

# Waiting for kind node to be ready
kubectl wait --for=condition=ready node kind-control-plane

# Warming up kind image caches
kubectl apply -f demopod.yaml
kubectl run bbox --image=busybox
kubectl run dbug --image=cgr.dev/chainguard/nginx:latest-dev

kubectl wait --for=condition=ready pod --selector=run=web
kubectl wait --for=condition=ready pod --selector=run=dbug
kubectl wait --for=condition=completed pod --selector=run=bbox

kubectl delete -f demopod.yaml
kubectl delete pod bbox
kubectl delete pod dbug

