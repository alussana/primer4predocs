# Use the official Nginx image as the base image
FROM nginx:latest

# Copy the custom Nginx config file to the container
COPY nginx.conf /etc/nginx/nginx.conf

# Copy the index.html file to the Nginx HTML directory
COPY index.html /usr/share/nginx/html/www/index.html

# Expose port 80 for the Nginx server
EXPOSE 80
