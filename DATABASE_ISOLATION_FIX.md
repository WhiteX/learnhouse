# Database Isolation Fix for LearnHouse Deployments

## Issues Identified: Multiple Sources of Cross-Deployment Contamination

We have identified several issues causing cross-deployment contamination between DEV (adr-lms.whitex.cloud) and LIVE (edu.adradviser.ro) environments:

### 1. Shared Database Connection

Both deployments are connecting to the same database server, causing data sharing:

- DEV: `postgresql://learnhouse_dev:YOUR_DEV_DB_PASSWORD@db:5432/learnhouse_dev`
- LIVE: `postgresql://learnhouse:YOUR_LIVE_DB_PASSWORD@db:5432/learnhouse`

The container networking is not isolating these properly, causing both deployments to resolve `db` to the same physical database server.

### 2. Hardcoded URLs in Frontend Bundle

The DEV deployment contains hardcoded URLs pointing to the LIVE site:
- `http://edu.adradviser.ro/collections/new`
- `http://edu.adradviser.ro/courses?new=true`

These URLs are embedded in the JavaScript bundles at build time and aren't being properly updated at runtime.

### 3. Container API Access Inconsistencies

The API is accessed differently from inside containers versus from outside:
- Inside container: via `http://localhost:9000`
- External access: via domain's `/api/v1` path

This inconsistency complicates URL patching and can cause references to the wrong domain.

## How to Fix Deployment Isolation

### 1. Database Connection Isolation

Each deployment must use its own fully-qualified database hostname:

1. For DEV deployment:
```
LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse_dev:YOUR_DEV_DB_PASSWORD@db-dev.${DEPLOYMENT_NAME}-network:5432/learnhouse_dev
```

2. For LIVE deployment:
```
LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse:YOUR_LIVE_DB_PASSWORD@db-live.${DEPLOYMENT_NAME}-network:5432/learnhouse
```

This ensures:
- Each deployment uses a uniquely named database server
- The server hostname includes the deployment name for clarity
- The network name is deployment-specific

### 2. Enhanced URL Patching

We've improved the URL patching in Dockerfile_coolify to handle multiple URL formats:

```bash
# Replace all occurrences of edu.adradviser.ro with the current domain
find /app/web/.next -type f -name "*.js" -exec sed -i "s|http://edu.adradviser.ro|$NEXT_PUBLIC_LEARNHOUSE_DOMAIN|g" {} \;
find /app/web/.next -type f -name "*.js" -exec sed -i "s|https://edu.adradviser.ro|$NEXT_PUBLIC_LEARNHOUSE_DOMAIN|g" {} \;
find /app/web/.next -type f -name "*.js" -exec sed -i "s|//edu.adradviser.ro|//$DOMAIN_ONLY|g" {} \;
find /app/web/.next -type f -name "*.js" -exec sed -i "s|\"href\":\"http://edu.adradviser.ro|\"href\":\"$NEXT_PUBLIC_LEARNHOUSE_DOMAIN|g" {} \;
```

### 3. Cookie Domain Isolation

Ensure each deployment uses its own cookie domain:

```
LEARNHOUSE_COOKIE_DOMAIN=adr-lms.whitex.cloud  # For DEV
LEARNHOUSE_COOKIE_DOMAIN=edu.adradviser.ro     # For LIVE
```

### 4. API URL Inside vs Outside Container

Address the inconsistency in how the API is accessed:

1. Inside container: `http://localhost:9000`
2. External access: via domain's `/api/v1` path

Solution:
- Added the debug endpoint at `/api/v1/debug` to ensure it's accessible externally
- Enhanced the URL patching to handle both internal and external URL formats

### 5. API Debug Endpoints

Added comprehensive debug endpoints:

1. `/api/v1/debug/deployment` - Shows deployment configuration details
2. `/api/v1/debug/urls` - Scans for any remaining hardcoded URLs in the frontend bundle

## Verification Process

After implementing these fixes, use this verification process:

1. **Deploy the API changes** to add the debug endpoints:
   ```bash
   git add apps/api/src/routers/debug.py apps/api/src/router.py apps/api/app.py
   git commit -m "Add isolation debug endpoints for deployment verification"
   git push
   # Deploy through your CI/CD process
   ```

2. **Verify database isolation** by accessing the debug endpoints:
   ```bash
   # Check DEV deployment
   curl -k https://adr-lms.whitex.cloud/api/v1/debug/deployment
   
   # Check LIVE deployment
   curl -k https://edu.adradviser.ro/api/v1/debug/deployment
   ```

3. **Check for hardcoded URLs** in the frontend bundle:
   ```bash
   # Check DEV deployment 
   curl -k https://adr-lms.whitex.cloud/api/v1/debug/urls
   
   # Check LIVE deployment
   curl -k https://edu.adradviser.ro/api/v1/debug/urls
   ```

4. **Test with incognito browsers** to ensure sessions don't cross-contaminate

5. **Run the verification script** to perform all checks automatically:
   ```bash
   ./verify-isolation.sh
   ```

Solution:
- Added the debug endpoint at `/api/v1/debug` to ensure it's accessible externally
- Enhanced the URL patching to handle both internal and external URL formats

### 5. API Debug Endpoints

Added comprehensive debug endpoints:

1. `/api/v1/debug/deployment` - Shows deployment configuration details
2. `/api/v1/debug/urls` - Scans for any remaining hardcoded URLs in the frontend bundle

4. **Network Isolation**: Updated docker-compose-coolify.yml to use deployment-specific networks.

## Verification Steps

After implementing these changes:

1. Run `./verify-isolation.sh` to check deployment isolation
2. Verify each deployment has its own database connection using `/api/v1/debug/deployment` endpoint
3. Check that no cross-domain references appear in the frontend

## Implementation Plan

1. Update database connection strings in Coolify environment variables for both deployments
2. Rebuild and redeploy both environments to apply the changes
3. Run the verification script to confirm isolation
4. Clear browser cookies and caches to test with clean state
