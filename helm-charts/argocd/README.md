# Chainguard Helm Charts Catalog

# Kind Setup

Deploy a 3 node kind cluster

```bash
git clone git@github.com:ky-rafaels/kind-cluster.git

cd kind-cluster/

./kind-cluster-deploy 1 cluster1
```

# Helm basics with Chainguard iamguarded charts

```bash
# First login with chainctl, helm will use your local docker credentials to authenticate to the OCI repo
chainctl auth login && chainctl auth configure-docker --pull-token --save
# check if you can view the chart and its values
helm show values oci://cgr.dev/ky-rafaels.example.com/iamguarded-charts/keycloak
# OR 
helm show all oci://cgr.dev/ky-rafaels.example.com/iamguarded-charts/keycloak
# Then install the chart 
helm upgrade --install keycloak \
-n keycloak \
--create-namespace \
oci://cgr.dev/ky-rafaels.example.com/iamguarded-charts/keycloak
```

# Using ArgoCD

```bash
helm repo add argocd https://argoproj.github.io/argo-helm
helm upgrade --install argocd argocd/argo-cd \
    --namespace argocd \
    --create-namespace \
    --values argo/argo-values.yaml
```

## Static Pull Token Example

### Create pull token on kind nodes for cgr registry

Your pull token should already be created if you followed the steps above to deploy keycloak. Run script to add the pull token to each of the nodes

```bash
# Create a pull token
chainctl auth configure-docker --pull-token --save --ttl 8760h0m0s # 1 year expiration

# ---SAMPLE OUTPUT---
  ✔ Selected folder ky-rafaels.example.com.

To use this pull token in another environment, run this command:

    docker login "cgr.dev" --username "45a0c61ea6fd977f050c5fb9ac06a69eed764595/095b0c7ea9d68679" --password "eyJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJodHRwczovL2lzc3Vlci5lbmZvcmNlLmRldiIsImV4cCI6MTc0OTczODQ2NSwiaWF0IjoxNzQ5NjUyMDY2LCJpc3MiOiJodHRwczovL3B1bGx0b2tlbi5pc3N1ZXIuY2hhaW5ndWFyZC5kZXYiLCJzdWIiOiJwdWxsLXRva2VuLTAxY2MwODkwYzA5N2ZmMzk1MDUyMWY4NWFmYmEyZDUwMGM0ODQxOWEifQ.ET7ywPUkMk5wN6p0INqhNtdnOVELySqdjp-qWedVmJkLrWlZhdFodU43P4uuR-LJ3Z9mVmd9fjDWpBtZnsCFHbczkENPzOiAFP9fsJhO_2dXT3rXCPK84ddJgRLe6oDlMA3VSa0XEclfTyBcaG4RlrgkVaGhtS7gone4Egff7bKX5Y6-TUxxLiVvCA_l_YmOixUss_Mj1Qxxb81sCeh7x4FSpOGWtmU2Z7Hy6B_rGk17zXMO_GYcuyzAMxfFdQl1Ov18t7KxymQwIoS7UF1fx_5ECR8fgArLM8NikGOjzkiQZuSzeI_hl_GnUFdPTAAhmjpJEWO0isiSPWgpkUPx5scoSUm6jzfduvRgGcmjRxT_pq6MWzFJNw9gv9gVehJuW5lKzNIgMTfJXO5Roba8WCwwxiUknhZXP8DeD_kdAN2-JbkfOYg3aPVU5jFTtA6TJKlh0uQA5OGN5hG_PnyzIr0vu4VVninJTWm66RppdlffhG-1xY9lpXgD2k2TIhygFL8iEBNszq0siLVA3uTH6NZY8iGRFqziUAGnyD80aHn52tIeCBBAOyS6qfcRLzqO6dQX95uscdCOuy-5rxU9n4208m5duLXdZtVWa9gp2vg-OmxnCPVdXmPCTA6RF43gDVkxKGMfvkUkTW1nKNvIUx_ikC9tLHDuZdi8FKLeYEg"

Configuring identity "45a0c61ea6fd977f050c5fb9ac06a69eed764595/095b0c7ea9d68679" for pulls from cgr.dev (expires 2025-06-12T09:27:45-05:00).
Overwriting existing credentials.
```

Next you can then run script to copy token to all kind k8s nodes

```bash
./scripts/kind-chainguard-pull-token.sh

# ---SAMPLE OUTPUT---
Configuring identity "b25cd7fccd73dc9a14b3ec891625c5f172624a75/a67f8d22d75f8832" for pulls from cgr.dev (expires 2025-08-13T12:20:03-05:00).
Moving credentials to kind cluster name='kind1' nodes ...
Successfully copied 3.07kB to kind1-control-plane:/var/lib/kubelet/config.json
Successfully copied 3.07kB to kind1-worker2:/var/lib/kubelet/config.json
Successfully copied 3.07kB to kind1-worker:/var/lib/kubelet/config.json
Done!
Removing /var/folders/v_/hp44vp812712ftk9gnzyxj880000gn/T/tmp.DFw44UWmsG/*
```

Then save credentials as env vars to be used later in configuration

```bash
export HELMUSER=45a0c61ea6fd977f050c5fb9ac06a69eed764595/095b0c7ea9d68679

export HELMPASS=eyJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJodHRwczovL2lzc3Vlci5lbmZvcmNlLmRldiIsImV4cCI6MTc0OTczODQ2NSwiaWF0IjoxNzQ5NjUyMDY2LCJpc3MiOiJodHRwczovL3B1bGx0b2tlbi5pc3N1ZXIuY2hhaW5ndWFyZC5kZXYiLCJzdWIiOiJwdWxsLXRva2VuLTAxY2MwODkwYzA5N2ZmMzk1MDUyMWY4NWFmYmEyZDUwMGM0ODQxOWEifQ.ET7ywPUkMk5wN6p0INqhNtdnOVELySqdjp-qWedVmJkLrWlZhdFodU43P4uuR......
```

### Create a secret for ArgoCD Repo Server

```bash
cat << EOF >> cgr-helm-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: cgr-oci-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: helm
  name: cgr-oci-repo
  url: cgr.dev/ky-rafaels.example.com/iamguarded-charts
  enableOCI: "true"
  ForceHttpBasicAuth: "true"
  username: ${HELMUSER} 
  password: ${HELMPASS} 
EOF

kubectl apply -f cgr-helm-secret.yaml
```

You can also use the argocd tool to create your repository. First ensure you login

```bash
# Install with brew 
brew install argocd

kubectl port-forward svc/argocd-server -n argocd 8080:8080

argocd login http://localhost:8080 --username admin --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo) 

argocd repo add oci://cgr.dev/ky-rafaels.example.com/iamguarded-charts \
    --enable-oci \
    --type helm \
    --name cgr-oci-repo \
    --username ${HELMUSER} \
    --password ${HELMPASS}
```

### Deploy an app from a chart

Charts have been packaged as ArgoCD applications easing in the deployment. To deploy a chart:
```bash
kubectl apply -f apps/redis-cluster.yaml
```

You can then view ArgoCD to confirm application has properly rolled out

![argo app sync](img/app-rollout.png)
<!-- 
# Dynamic AuthN using ArgoCD Config Plugin

## Create a plugin using custom-assembly

First, ensure that you have the packages necessary for the argocd-plugin available in your private apk repo as well as the chainguard-base image. 

```bash
cat << EOF >> argocd-plugin.yaml
contents:
  packages:
    - jq
    - yq 
    - helm 
    - bash-binsh
    - chainctl 
EOF
```

Then generate a package file and create the image we will use as our argocd plugin. We will use this plugin help the argocd repo server to authenticate with the chainguard registry to read charts.

```bash
chainctl image repo build apply -f custom-assembly/argo-plugin-apks.yaml --parent ky-rafaels.example.com --repo custom-base
``` -->
