# Use the official nginx base image
FROM nginx:alpine

# Define the environment variable
ENV NGINX_HOST=localhost
ENV NGINX_PORT=9090
ENV ROOT_PATH=/usr/share/custom/html

#Copy the template config and custom index
COPY nginx.conf.template /etc/nginx/templates/nginx.conf.template
COPY index.html /usr/share/custom/html/index.html