# Base image that we start with
FROM golang:latest

# Change the working directory
WORKDIR /app

# Copy local code to the container image
COPY go.* ./

# Execute commands
RUN go mod download

# Copy local code to the container image
COPY . ./

# Execute commands
RUN go build -o hello-world .

# Specify default executable when container is run
ENTRYPOINT ["./hello-world"]