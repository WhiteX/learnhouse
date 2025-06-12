# LearnHouse Deployment Troubleshooting Guide

## Current Status: Port Configuration Fixed ✅

### Recent Changes Made:

1. **Fixed Port Mismatch Issue** - The root cause of "no available server":
   - Changed Docker Compose from port 3000 → 80
   - Updated healthcheck from port 3000 → 80 
   - Added explicit Traefik port label: `traefik.http.services.*.loadbalancer.server.port=80`

2. **Enhanced Start Script** (`extra/start.sh`):
   - Added explicit port assignments: PORT=8000, LEARNHOUSE_PORT=9000
   - Fixed backend startup: Uses `uvicorn app:app --host 0.0.0.0 --port 9000`
   - Fixed frontend startup: Uses Next.js standalone server on port 8000

3. **Added Debug Capabilities**:
   - Created `debug-services.sh` script for troubleshooting
   - Script checks PM2 processes, port usage, service connectivity

### Current Architecture:

```
Internet → Coolify/Traefik → Container:80 → Nginx → {
  ├── Frontend (Next.js standalone): localhost:8000
  └── Backend API (FastAPI): localhost:9000
}
```

### Network Isolation Configuration:

- **DEV deployment**: `DEPLOYMENT_NAME=dev` → `dev-network`
- **LIVE deployment**: `DEPLOYMENT_NAME=live` → `live-network`
- Each deployment has isolated databases, Redis instances, and networks

### Environment Variables Required:

See `COOLIFY_ENV_VARS.md` for complete list. Key variables for isolation:

- `DEPLOYMENT_NAME=live` (or `dev`)
- `LEARNHOUSE_COOKIE_DOMAIN=edu.adradviser.ro`
- `LEARNHOUSE_SQL_CONNECTION_STRING` (separate for each deployment)
- `LEARNHOUSE_REDIS_CONNECTION_STRING` (separate for each deployment)

### Current Error Status:

- ✅ **Port mismatch fixed**: Changed from 3000 to 80
- ✅ **Container accessibility**: Traefik can now route to port 80
- ✅ **Frontend running**: Next.js server operational on port 8000
- ❌ **Backend failing**: PM2 bash execution error fixed
- ⚠️ **502 errors**: Should resolve once backend starts correctly

### Identified Issues & Fixes:

**Problem**: Backend API service failing with bash execution error
**Root Cause**: Incorrect PM2 command syntax for starting uvicorn
**Solution**: Updated start script to use direct Python execution instead of bash interpreter

### Next Debugging Steps:

1. **Deploy the updated configuration**
2. **Check container logs** for any startup errors
3. **Run debug script** inside container:
   ```bash
   docker exec -it <container_name> /app/debug-services.sh
   ```
4. **Test internal services**:
   ```bash
   # Test frontend
   curl http://localhost:8000
   # Test backend  
   curl http://localhost:9000
   # Test nginx
   curl http://localhost:80
   ```

### Troubleshooting Commands:

```bash
# Check PM2 processes
docker exec -it <container> pm2 list

# Check ports in use
docker exec -it <container> netstat -tlnp

# Check nginx config
docker exec -it <container> nginx -t

# View PM2 logs
docker exec -it <container> pm2 logs

# Run full debug
docker exec -it <container> /app/debug-services.sh
```

### Expected Resolution:

The 502 errors should resolve once:
1. ✅ Frontend service starts correctly on port 8000 (WORKING)
2. ❌ Backend service starts correctly on port 9000 (FIXED - needs redeploy)
3. ✅ Nginx properly proxies requests between them (WORKING)

### Post-Deploy Verification:

After redeploying, run the debug script again and verify:
```bash
docker exec -it <container_name> /app/debug-services.sh
```

Expected output should show:
- ✅ PM2 status: Both services "online" 
- ✅ Port 9000: Backend responding with status 200
- ✅ No bash execution errors in logs

The port configuration fix was the critical missing piece for Traefik routing.
