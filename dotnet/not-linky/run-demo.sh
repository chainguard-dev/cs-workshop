# build the image
docker build -t dotnetapp .

# run the image
docker run --rm dotnetapp

# scan the image
grype dotnetapp

# compare image size
docker image ls | grep dotnet