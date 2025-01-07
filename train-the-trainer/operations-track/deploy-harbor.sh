#!/usr/bin/env bash
DEPLOY_DIR="harbor-non-cg"

# validate envsubst is installed
if ! command -v envsubst &> /dev/null
then
    echo "envsubst could not be found, please install it)"
    echo
    echo "On MacOS: brew install gettext && brew link --force gettext"
    echo "On Debian/Ubuntu: apt-get install gettext-base"
    exit
fi

if ! command -v kind &> /dev/null
then
    echo "kind could not be found, please install it"
    echo
    echo "open https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    exit
fi

if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found, please install it"
    echo
    echo "open https://kubernetes.io/docs/tasks/tools/"
    exit
fi

# Ask if using Chainguard Images or not (default is yes)
read -p "Are you using Chainguard images? (YES/no): " CHAINGUARD_IMAGES
CHAINGUARD_IMAGES=${CHAINGUARD_IMAGES:-yes}

# ask if we should start kind
read -p "A Kubernetes cluster is required, do you want to start a new Kind cluster? (YES/no): " START_KIND
START_KIND=${START_KIND:-yes}
if [ "$START_KIND" == "yes" ]; then
  kind create cluster --name harbor --config ${DEPLOY_DIR}/kind/config.yaml
  kubectl wait --for=condition=Ready node/harbor-control-plane --timeout=1m
fi

kubectl create ns harbor

# if using Chainguard images, ask for the registry URL (default is cgr.dev/cs-ttt-demo.dev )
if [ "$CHAINGUARD_IMAGES" == "yes" ]; then
  DEPLOY_DIR="harbor-cg"
  read -p "Enter the registry URL (default is cgr.dev/cs-ttt-demo.dev): " REGISTRY_URL
  export REGISTRY_URL=${REGISTRY_URL:-cgr.dev/cs-ttt-demo.dev}

  # Ask for pull token user and password
  read -p "Enter the pull token user: " PULL_USER
  read -p "Enter the pull token password: " PULL_PASS

  cat ${DEPLOY_DIR}/manifests/deploy-ingress-nginx.template | envsubst > ${DEPLOY_DIR}/manifests/deploy-ingress-nginx.yaml
  kubectl create ns ingress-nginx
  kubectl create secret docker-registry regcred --docker-server "cgr.dev" --docker-username $PULL_USER --docker-password $PULL_PASS -n ingress-nginx

  cat ${DEPLOY_DIR}/helm/values.template | envsubst > ${DEPLOY_DIR}/helm/values.yaml
  kubectl create secret docker-registry regcred --docker-server "cgr.dev" --docker-username $PULL_USER --docker-password $PULL_PASS -n harbor

fi

kubectl apply -f ${DEPLOY_DIR}/manifests/deploy-ingress-nginx.yaml
kubectl wait --for=condition=Ready -n ingress-nginx pod --selector=app.kubernetes.io/name=ingress-nginx --selector=app.kubernetes.io/component=controller

helm repo add harbor https://helm.goharbor.io
helm upgrade --install harbor harbor/harbor -n harbor -f ${DEPLOY_DIR}/helm/values.yaml --wait

echo "Harbor should now available at http://localhost/harbor"

