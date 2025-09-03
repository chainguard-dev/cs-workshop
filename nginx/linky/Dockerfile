# Use the Chainguard nginx image
FROM cgr.dev/chainguard/nginx:latest

#Copy the updated nginx config and custom index and image
COPY nginx.conf /etc/nginx/nginx.conf
COPY index.html /usr/share/custom/html/index.html
COPY linky.png /usr/share/custom/html/linky.png