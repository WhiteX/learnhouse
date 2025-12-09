#!/bin/sh

# Set environment variables for proper Python logging
export PYTHONUNBUFFERED=1
export PYTHONIOENCODING=utf-8

# Wait for database and redis if connection strings point to external services
# (In docker-compose, depends_on handles this, but useful for standalone)
if [ -n "$LEARNHOUSE_SQL_CONNECTION_STRING" ]; then
    DB_HOST=$(echo "$LEARNHOUSE_SQL_CONNECTION_STRING" | sed -n 's/.*@\([^:]*\):\([0-9]*\)\/.*/\1/p')
    if [ -n "$DB_HOST" ] && [ "$DB_HOST" != "localhost" ] && [ "$DB_HOST" != "127.0.0.1" ] && [ "$DB_HOST" != "db" ]; then
        echo "Waiting for external database at $DB_HOST..."
        timeout 30 sh -c 'until nc -z '"$DB_HOST"' 5432; do sleep 1; done' || true
    fi
fi

echo "=== Starting LearnHouse Services ==="

# Set PORT for Next.js frontend (override if needed)
export PORT=${PORT:-8000}
export HOSTNAME=${HOSTNAME:-0.0.0.0}

# Start Next.js frontend with server-wrapper for runtime env injection
echo "Starting Next.js frontend on port $PORT..."
cd /app/web/apps/web
pm2 start server-wrapper.js --name learnhouse-web --log /var/log/pm2-web.log

# Start Python backend
echo "Starting Python backend on port ${LEARNHOUSE_PORT:-9000}..."
cd /app/api
pm2 start uv --name learnhouse-api -- run app.py --log /var/log/pm2-api.log

# Wait a moment for services to initialize
sleep 2

# Check if the services are running and log the status
echo "=== PM2 Service Status ==="
pm2 status

# Start Nginx in the background
echo "Starting Nginx on port 80..."
nginx -g 'daemon off;' &

# Tail PM2 logs with proper formatting
echo "=== Following application logs ==="
pm2 logs --raw
