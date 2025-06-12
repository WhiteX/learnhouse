#!/bin/sh

# Set environment variables for consistent ports
export PORT=8000
export LEARNHOUSE_PORT=9000

# Start the services with explicit ports
cd /app/web && pm2 start server.js --name learnhouse-web > /dev/null 2>&1
cd /app/api && pm2 start "uvicorn app:app --host 0.0.0.0 --port 9000" --name learnhouse-api --interpreter bash 2>&1

# Check if the services are running qnd log the status
pm2 status

# Start Nginx in the background
nginx -g 'daemon off;' &

# Tail Nginx error and access logs
pm2 logs
