#!/bin/sh

# Replace environment variables in nginx.conf and overwrite the file
envsubst '${API_SERVICE_HOST} ${API_SERVICE_PORT}' < /etc/nginx/nginx.conf | tee /etc/nginx/nginx.conf > /dev/null

# Set to read-only after substitution
chmod 644 /etc/nginx/nginx.conf

# Execute the main process
exec "$@"