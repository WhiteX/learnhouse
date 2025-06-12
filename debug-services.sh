#!/bin/bash
echo "=== LearnHouse Service Debug Script ==="
echo
echo "1. Checking PM2 processes:"
pm2 list
echo
echo "2. Checking which ports are in use:"
netstat -tlnp 2>/dev/null || ss -tlnp
echo
echo "3. Testing internal service connections:"
echo "  - Testing frontend (port 8000):"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8000/ || echo "Frontend not responding"
echo "  - Testing backend (port 9000):"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:9000/ || echo "Backend not responding"
echo "  - Testing nginx (port 80):"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:80/ || echo "Nginx not responding"
echo
echo "4. Checking nginx configuration:"
nginx -t
echo
echo "5. Recent PM2 logs (last 10 lines):"
pm2 logs --lines 10
echo
echo "=== Debug Complete ==="
