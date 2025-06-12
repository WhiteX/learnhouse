#!/bin/sh

# Set environment variables for consistent ports
export PORT=8000
export LEARNHOUSE_PORT=9000

# Start the services with direct Python execution
cd /app/web && pm2 start server.js --name learnhouse-web > /dev/null 2>&1
cd /app/api && pm2 start app.py --name learnhouse-api --interpreter python3 2>&1

# Check if the services are running and log the status
pm2 status

# Start Nginx in the background
nginx -g 'daemon off;' &

# Tail Nginx error and access logs
pm2 logs
