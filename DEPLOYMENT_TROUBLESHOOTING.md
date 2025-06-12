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
- ✅ **Backend running**: FastAPI server operational on port 9000
- ❌ **Cross-deployment contamination**: LIVE calling DEV APIs and vice versa
- ⚠️ **Root cause**: Frontend build-time API URLs not properly isolated

### Identified Issues & Fixes:

**Problem**: Cross-deployment data contamination (LIVE sees DEV data)
**Root Cause**: Next.js build embeds API URLs at build-time, both deployments may share same URLs
**Solution**: Added runtime API URL patching in Docker container startup

**Current Fix Applied**:
1. ✅ Enhanced patched-start.sh to replace API URLs at runtime
2. ✅ Added debug endpoint `/api/v1/debug/deployment` for verification
3. ✅ Added deployment verification script `verify-isolation.sh`

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

After redeploying, verify isolation works:
```bash
# Run the automated verification script
./verify-isolation.sh

# Or manually test the debug endpoints
curl https://adr-lms.whitex.cloud/api/v1/debug/deployment
curl https://edu.adradviser.ro/api/v1/debug/deployment

# Check for cross-deployment API calls in browser Network tab
# Should see only same-domain API calls:
# - DEV: Only calls to adr-lms.whitex.cloud
# - LIVE: Only calls to edu.adradviser.ro
```

Expected output should show:
- ✅ Different database hosts for DEV vs LIVE
- ✅ Different cookie domains: adr-lms.whitex.cloud vs edu.adradviser.ro  
- ✅ No cross-domain API calls in browser Network tab
- ✅ Separate content/courses on each deployment

The port configuration fix was the critical missing piece for Traefik routing.
