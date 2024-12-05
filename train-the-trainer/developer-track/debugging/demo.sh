#!env bash
. ../../base.sh
TYPE_SPEED=80
docker rm -f webserver
rm -rf $(pwd)/data
docker run -d -p 8080:8080 -v $(pwd)/data:/data --name webserver cgr.dev/chainguard/nginx:latest
clear

NO_WAIT=true
banner "We have a "nginx" container based on a distroless image."
p "docker ps"
docker ps | grep -v kind
echo
wait


banner "Check the web site to make sure it's running."
pe "open http://localhost:8080"
wait


banner "Exec in to see what's in /usr/share/nginx/html/index.html"
NO_WAIT=false
pe "docker exec -it webserver bash"
pe "docker exec -it webserver sh"
pe "docker exec -it webserver /bin/sh"
wait

banner "Let's try running the the image and override entrypoint to cat it out"
pe "docker run --rm -it --entrypoint /bin/cat cgr.dev/chainguard/nginx:latest /usr/share/nginx/html/index.html"
wait

clear
banner "Use Docker Debug"
pe "docker debug webserver"
wait

banner "Not on paid Docker account?  Docker Desktop free tier UI has options..."
wait

clear
banner "Not on Docker Desktop at all?  cdebug is an OSS CLI tool that can help."
pe "cdebug exec -it --rm webserver"
pe "cdebug exec -it --rm --privileged webserver"

clear
banner "What about containers running in Kubernetes?"
NO_WAIT=true
$BATCAT demopod.yaml
NO_WAIT=false
pe "kubectl apply -f demopod.yaml"
NO_WAIT=true
pe "kubectl wait --for=condition=ready pod --selector=run=web"
pe "kubectl get pods"
NO_WAIT=false
clear

NO_WAIT=true
banner "Exec isn't going to work for the same reasons as before..."
pe "kubectl exec -it web -- sh"
NO_WAIT=false

wait
banner "But we can use kubectl debug"
pe "kubectl debug -it web --target webserver --image busybox"

clear
banner "kubectl debug does not support --user or --privileged so we need to use a container with that UID as it's default user"
pe "kubectl debug -it web --target webserver --image cgr.dev/chainguard/nginx:latest-dev -- sh"

clear
banner "cdebug supports remote kubernetes pods, and it's a bit simpler to use"
pe "cdebug exec -it pod/web/webserver"

banner "cdebug supports --user"
pe "cdebug exec -it -u 65532 pod/web/webserver"

banner "cdebug supports --privileged"
pe "cdebug exec -it --privileged pod/web/webserver"
