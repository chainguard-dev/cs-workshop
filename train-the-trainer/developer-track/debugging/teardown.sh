#!env bash
#ask for confirmation
read -p "Are you sure you want to delete the cluster and all containers? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi
kind delete cluster
docker rm -f $(docker ps -a -q)