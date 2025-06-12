# Network Isolation Setup for LearnHouse Deployments

This setup provides complete network isolation between your DEV and LIVE LearnHouse deployments using a single dynamic Docker Compose file and environment variables.

> ⚠️ **NOTE**: This document uses example placeholder domains. Replace all example values with your actual domains before deployment. See [`COOLIFY_ENV_VARS.md`](COOLIFY_ENV_VARS.md) for a complete list of environment variables.

## Single Dynamic Compose File

- `docker-compose-coolify.yml` - Works for both DEV and LIVE deployments using environment variables

## Key Environment Variables for Isolation

### Required for Network Isolation
- `DEPLOYMENT_NAME` - Unique identifier for each deployment (e.g., "dev", "live", "staging")
- `LEARNHOUSE_DOMAIN` - Domain for this specific deployment
- `LEARNHOUSE_COOKIE_DOMAIN` - Exact domain for cookies (should match LEARNHOUSE_DOMAIN)

### How It Works
The compose file uses `${DEPLOYMENT_NAME:-learnhouse}` patterns to create:
- **Networks**: `{DEPLOYMENT_NAME}-network` (e.g., `dev-network`, `live-network`)
- **Traefik Routes**: `{DEPLOYMENT_NAME}` router names
- **Volumes**: Handled automatically by Coolify (each deployment gets isolated volumes)

## Coolify Deployment Instructions

### For DEV Environment

1. In Coolify, create a new resource/service
2. Use the standard `docker-compose-coolify.yml` file
3. Set these **key environment variables**:
   ```
   DEPLOYMENT_NAME=dev
   LEARNHOUSE_DOMAIN=your-dev-domain.example.com
   LEARNHOUSE_COOKIE_DOMAIN=your-dev-domain.example.com
   NEXTAUTH_URL=https://your-dev-domain.example.com
   # ... your other DEV environment variables
   ```

### For LIVE Environment

1. In Coolify, create a new resource/service  
2. Use the same `docker-compose-coolify.yml` file
3. Set these **key environment variables**:
   ```
   DEPLOYMENT_NAME=live
   LEARNHOUSE_DOMAIN=your-prod-domain.example.com
   LEARNHOUSE_COOKIE_DOMAIN=your-prod-domain.example.com
   NEXTAUTH_URL=https://your-prod-domain.example.com
   # ... your other LIVE environment variables
   ```

## Network Isolation Results

With `DEPLOYMENT_NAME=dev`:
- Network: `dev-network`
- Traefik Router: `dev`
- Volumes: Automatically isolated by Coolify

With `DEPLOYMENT_NAME=live`:
- Network: `live-network`  
- Traefik Router: `live`
- Volumes: Automatically isolated by Coolify

## Benefits

✅ **Single File Maintenance**: One compose file for all environments
✅ **Complete Backend Isolation**: Different networks prevent cross-communication
✅ **Separate Data Storage**: Coolify automatically isolates volumes per deployment
✅ **Unique Traefik Routes**: No router name conflicts
✅ **Exact Cookie Domain Matching**: Prevents any cookie sharing
✅ **Environment Flexibility**: Easy to add new environments (staging, testing, etc.)

## Verification

After deployment, verify isolation:

1. **Check Docker networks**:
   ```bash
   docker network ls | grep -E "(dev|live)-network"
   ```

2. **Verify volumes** (Coolify handles this automatically):
   ```bash
   docker volume ls | grep your-project-name
   ```

3. **Test cookie domains** in browser DevTools:
   - DEV cookies: domain `your-dev-domain.example.com`
   - LIVE cookies: domain `your-prod-domain.example.com`

## Adding New Environments

To add a staging environment:
```
DEPLOYMENT_NAME=staging
LEARNHOUSE_DOMAIN=your-staging-domain.example.com
LEARNHOUSE_COOKIE_DOMAIN=your-staging-domain.example.com
```

This automatically creates `staging-network` and Coolify handles volume isolation.

## Current Status

✅ **Port Configuration Fixed**: Changed from port 3000 to 80 to match nginx configuration  
✅ **Network Isolation Implemented**: Using `DEPLOYMENT_NAME` for unique networks  
✅ **Environment Variables Configured**: Complete isolation between deployments  
⚠️ **In Progress**: Resolving 404 API routing issues

## Troubleshooting

If you encounter issues after deployment, use the debug script:
```bash
docker exec -it <container_name> /app/debug-services.sh
```

See `DEPLOYMENT_TROUBLESHOOTING.md` for detailed troubleshooting steps.
