# Use the Node.js image from Chainguard
FROM cgr.dev/chainguard/node:latest-dev AS builder

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the image into the container
COPY image.jpg ./image.jpg

# Copy the rest of the application code
COPY . .

FROM cgr.dev/chainguard/node:latest-slim
COPY --from=builder --chown=node:node /usr/src/app /app
ENV PATH=/app/node_modules/.bin:$PATH
WORKDIR /app

# Command to run the Node.js application
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "index.js"]
