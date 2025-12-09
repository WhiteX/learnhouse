# LearnHouse Deployment Fix Documentation

## Overview
This document outlines the comprehensive fixes applied to resolve Docker build failures, security vulnerabilities, and 502 Bad Gateway errors in the LearnHouse deployment pipeline.

## Issues Resolved

### 1. Docker Build Failures (pnpm lockfile issues)
**Problem**: `ERR_PNPM_OUTDATED_LOCKFILE` when building in Coolify with monorepo workspace.

**Root Cause**: The `Dockerfile_coolify` was missing critical workspace configuration files that pnpm needs to properly install dependencies in a monorepo.

**Solution**: 
- Added workspace root files to Docker build context before installing dependencies
- Copy `package.json`, `pnpm-lock.yaml`, `pnpm-workspace.yaml`, and `.npmrc` to the builder stage
- These files must be copied before the apps to establish the workspace context

**Files Modified**: `Dockerfile_coolify`

```dockerfile
# Copy workspace configuration files first (including .npmrc for pnpm settings)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./

# Copy the web app (includes apps/web/pnpm-lock.yaml)
COPY ./apps/web ./apps/web
```

### 2. Security Vulnerability - CVE-2025-66478
**Problem**: Next.js 16.0.1 contained a critical RCE vulnerability (CVSS 10.0).

**Solution**: 
- Merged upstream/dev branch which included Next.js 16.0.7 with security patches
- Also resolved CVE-2025-29927 (Middleware bypass) in the same upgrade

**Next.js Versions Used**:
- Started with: 16.0.1 (vulnerable)
- Tested with: 15.3.6 (transitional)
- Final: 16.0.7 (patched, from upstream)

**Files Modified**: `apps/web/package.json`, `pnpm-lock.yaml`

### 3. TypeScript Null-Safety Errors (Next.js 16 Breaking Changes)
**Problem**: Next.js 16 hooks (`useSearchParams()`, `useParams()`, `usePathname()`) now return `null` in certain conditions, breaking type safety.

**Solution**: Added optional chaining (`?.`) and fallback values throughout the codebase.

**Files Fixed** (9 files total):
- `apps/web/app/auth/reset/reset.tsx` - `searchParams?.get()`
- `apps/web/app/auth/signup/signup.tsx` - `searchParams?.get()`
- `apps/web/app/orgs/[orgslug]/(withmenu)/courses/courses.tsx` - `searchParams?.get()`
- `apps/web/app/orgs/[orgslug]/(withmenu)/search/page.tsx` - `searchParams?.get()`, `searchParams?.entries()`
- `apps/web/app/orgs/[orgslug]/dash/assignments/[assignmentuuid]/page.tsx` - `params?.assignmentuuid`, `searchParams?.get()`
- `apps/web/app/payments/stripe/connect/oauth/page.tsx` - `searchParams?.get()`
- `apps/web/components/Contexts/OrgContext.tsx` - `pathname || ''` fallback
- `apps/web/components/Security/AdminAuthorization.tsx` - `pathname || ''` fallback

**Example Pattern**:
```typescript
// Before (breaks with null)
const searchCode = searchParams.get('resetCode')

// After (safe with null)
const searchCode = searchParams?.get('resetCode')
```

### 4. Next.js API Changes - revalidateTag()
**Problem**: The `revalidateTag()` API changed between Next.js versions.

**Solution**: Updated to use the correct API signature for Next.js 16.0.7 (requires 2 arguments).

**Files Modified**: `apps/web/app/api/revalidate/route.ts`

```typescript
// Next.js 16.0.7 requires the second argument
revalidateTag(tag, {})
```

### 5. 502 Bad Gateway - Frontend Not Starting
**Problem**: The `server-wrapper.js` was unable to find `server.js` due to monorepo path structure issues.

**Root Cause**: Next.js standalone output in monorepo builds mirrors the workspace directory structure:
```
.next/standalone/
├── apps/
│   └── web/
│       ├── server.js          ← actual server location
│       ├── .next/
│       └── package.json
├── node_modules/
└── (other workspace files)
```

When copying just `/app/apps/web/.next/standalone/apps/web` to `/app/web/`, critical dependencies like `node_modules` at the root level of standalone were being ignored.

**Solution**: 
1. Copy the **entire** `.next/standalone` directory to preserve the complete monorepo structure
2. Update `start.sh` to `cd` to the correct nested path before starting the server
3. Place `server-wrapper.js` in the correct location alongside `server.js`

**Files Modified**: `Dockerfile_coolify`, `extra/start.sh`

```dockerfile
# Copy the entire standalone output (preserves all node_modules and structure)
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/.next/static ./apps/web/.next/static

# Copy server wrapper to the correct nested location
COPY --chown=nextjs:nodejs apps/web/server-wrapper.js ./apps/web/
```

**start.sh Update**:
```bash
# Start Next.js frontend from the correct directory
cd /app/web/apps/web
pm2 start server-wrapper.js --name learnhouse-web
```

## Summary of Dockerfile_coolify Improvements

The final `Dockerfile_coolify` now includes:

### **Multi-stage Build Architecture**
- **Builder Stage**: Builds Next.js app with proper monorepo configuration
- **Runner Stage**: Combines frontend and backend into a single production image

### **Key Features**
1. **Workspace-aware building**: Copies root workspace files before app files
2. **Production optimizations**:
   - NODE_ENV=production environment variable
   - Proper user permissions (nextjs user with UID 1001)
   - Standalone Next.js output (optimized bundle)
3. **Server wrapper integration**: Handles runtime environment variable injection for Next.js
4. **Complete stack**: Includes Node.js, Python, Nginx, PM2, and required system dependencies
5. **Health checks**: Configured for orchestration platforms

### **Port Exposure**
- Port 80: Nginx reverse proxy
- Port 8000: Next.js frontend (internal)
- Port 9000: Python backend via Uvicorn (internal)

## Testing and Validation

✅ **Build Success**: Docker builds complete without errors
✅ **Container Startup**: All services (frontend, backend, nginx) start successfully
✅ **Networking**: Inter-container communication works correctly
✅ **Health Checks**: API endpoints respond properly
✅ **Frontend Access**: 502 Bad Gateway resolved, application accessible
✅ **Backend Connectivity**: Frontend can communicate with Python API

## Deployment Instructions

1. **Push changes** to your repository:
   ```bash
   git add .
   git commit -m "deployment: fix Docker build and 502 gateway errors"
   git push origin dev
   ```

2. **Trigger new Coolify deployment** with the updated `Dockerfile_coolify`

3. **Verify deployment**:
   - Check Coolify build logs for successful completion
   - Confirm application is accessible without 502 errors
   - Verify both frontend and backend are responsive

## Related Configuration Files

### Docker Compose (Local Development)
- **File**: `docker-compose.yml`
- **Note**: Uses standard `Dockerfile` for local builds
- **Use Case**: Development and testing before Coolify deployment

### Docker Compose (Coolify)
- **File**: `docker-compose-coolify.yml`
- **Status**: Uses `Dockerfile_coolify` for production deployments
- **Features**: Includes PostgreSQL, Redis, and ChromaDB services

### Production Deployment Script
- **File**: `extra/start.sh`
- **Role**: Manages service startup sequence and logging
- **Updated**: Now handles correct working directory for monorepo structure

## Key Takeaways

1. **Monorepo Awareness**: Always preserve complete workspace structure when copying build artifacts
2. **Security First**: Monitor upstream for security patches and apply promptly
3. **Version Compatibility**: API changes between minor versions (e.g., `revalidateTag()`) require careful migration
4. **Workspace Configuration**: In Docker builds, workspace root files must be copied before app-specific files
5. **Path Alignment**: Ensure `start.sh` and other scripts use paths matching the actual directory structure in the image

## Git Commits Applied

All changes have been committed and pushed to `origin/dev`:

1. Workspace configuration files in Dockerfile
2. Next.js security upgrade and null-safety fixes
3. revalidateTag API fix for Next.js 16
4. Standalone output path corrections
5. start.sh path updates for monorepo structure

The deployment is now fully functional and ready for production use.
