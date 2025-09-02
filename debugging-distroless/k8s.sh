#! env bash
. ../base.sh

clear
banner "Step 0: Checking that Kubernetes cluster is running"
# Check for a kind cluster named debugging exists and if it doesn't start one
if ! kind get clusters | grep -q debugging; then
  kind create cluster --name debugging
else
  # make sure kubectl is set to the kind cluster context
  kubectl config use-context kind-debugging
  # make sure the nginx-chainguard pod is destroyed
  kubectl delete pod nginx-chainguard
fi

banner "Step 1: Start a container to debug"
pe "kubectl run nginx-chainguard --image=cgr.dev/chainguard/nginx:latest"
pe "kubectl wait --for=condition=ready pod/nginx-chainguard"
pe "kubectl get pod nginx-chainguard"
pe "kubectl exec -it nginx-chainguard -- /bin/sh"
pe "kubectl exec -it nginx-chainguard -- /bin/bash"

banner "Step 2: Start a debug container attached to the target"
pe "kubectl debug -it nginx-chainguard --image=cgr.dev/chainguard/wolfi-base:latest --target=nginx-chainguard"

banner "Step 3: Use a variant with correct UID"
pe "kubectl debug -it nginx-chainguard --image=cgr.dev/chainguard/busybox:latest --target=nginx-chainguard -- /bin/sh"

banner "Step 4: Use sysadmin profile"
pe "kubectl debug -it nginx-chainguard --image=cgr.dev/chainguard/wolfi-base:latest --target=nginx-chainguard --profile sysadmin -- /bin/sh"