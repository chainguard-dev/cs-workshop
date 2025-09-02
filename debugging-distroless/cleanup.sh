#! env bash
docker rm -f my-chainguard
rm index.html
kind delete cluster --name debugging
