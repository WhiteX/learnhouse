# Enhanced Debug Endpoints for Isolation Troubleshooting

This document describes the enhanced debugging tools available to diagnose cross-deployment isolation issues between DEV and LIVE environments.

## Available Debug Endpoints

The following endpoints are available for diagnosing isolation issues:

### 1. Deployment Information

**Endpoint:** `/api/v1/debug/deployment`

This endpoint provides detailed information about the current deployment, including:
- Deployment name
- Hostname and container ID
- Database connection details (host, user, database name)
- Redis connection details
- Cookie domain configuration
- Environment variables related to deployment URLs

**Example Usage:**
```bash
curl https://adr-lms.whitex.cloud/api/v1/debug/deployment
```

### 2. URL Hardcoding Detection

**Endpoint:** `/api/v1/debug/urls`

This endpoint scans the NextJS bundle for hardcoded URLs that could lead to cross-contamination between deployments:
- Detects references to both DEV and LIVE domains
- Identifies NextAuth configuration issues
- Shows environment variables related to API URLs

**Example Usage:**
```bash
curl https://adr-lms.whitex.cloud/api/v1/debug/urls
```

### 3. Cookie Isolation Testing

**Endpoint:** `/api/v1/debug/cookies`

This endpoint tests cookie isolation by:
- Setting a test cookie with the current deployment name
- Detecting any test cookies from other deployments
- Reporting the cookie domain in use
- Showing headers from the request

**Example Usage:**
```bash
curl https://adr-lms.whitex.cloud/api/v1/debug/cookies -v
```

### 4. Session Configuration Check

**Endpoint:** `/api/v1/debug/session`

This endpoint examines session-related configuration:
- Shows request headers related to origins
- Reports NextAuth URL configuration
- Indicates where session requests would be sent

**Example Usage:**
```bash
curl https://adr-lms.whitex.cloud/api/v1/debug/session
```

## Using the Enhanced Verification Script

We've also created an enhanced isolation verification script that checks both DEV and LIVE deployments and provides a summary of their isolation status:

```bash
./verify-enhanced-isolation.sh
```

The script will:
1. Check deployment configuration on both environments
2. Test cookie isolation
3. Look for hardcoded URLs
4. Verify session configuration
5. Analyze database isolation
6. Provide a summary of isolation status

## Resolving Isolation Issues

If the verification indicates isolation issues, ensure the following settings are unique between deployments:

1. **Database Connections**: Each deployment should use its own database
   ```
   # DEV environment
   LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse_dev:YOUR_DEV_PASSWORD@db-dev:5432/learnhouse_dev
   
   # LIVE environment
   LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse:YOUR_LIVE_PASSWORD@db-live:5432/learnhouse
   ```

2. **Cookie Domains**: Each deployment should have its own cookie domain
   ```
   # DEV environment
   LEARNHOUSE_COOKIE_DOMAIN=adr-lms.whitex.cloud
   
   # LIVE environment
   LEARNHOUSE_COOKIE_DOMAIN=edu.adradviser.ro
   ```

3. **Top Domain Configuration**: Ensure each deployment has the correct top domain
   ```
   # DEV environment
   NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN=whitex.cloud
   
   # LIVE environment
   NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN=adradviser.ro
   ```

4. **Deployment Name**: Set a descriptive name to help with debugging
   ```
   # DEV environment
   DEPLOYMENT_NAME=DEV
   
   # LIVE environment
   DEPLOYMENT_NAME=LIVE
   ```
