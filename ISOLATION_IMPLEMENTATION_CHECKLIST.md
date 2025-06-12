# LearnHouse Deployment Isolation Implementation Checklist

This checklist guides you through implementing complete isolation between DEV and LIVE LearnHouse deployments to prevent cross-deployment contamination.

## Issue Overview

We've identified that both DEV and LIVE deployments are accessing the same database and contain hardcoded URLs, causing:
- Data contamination (same courses appear in both deployments)
- Session mixing (logging in on one deployment affects the other)
- Inconsistent user experience (clicking links on DEV may lead to LIVE site)

## Implementation Checklist

### Step 1: Deploy API Changes

- [ ] Pull the latest code with isolation fixes:
  ```bash
  git pull origin dev
  ```

- [ ] Deploy the enhanced debug tools first:
  ```bash
  ./deploy-enhanced-debug.sh
  ```

- [ ] Verify the enhanced debug endpoints are working:
  ```bash
  ls -la apps/api/src/routers/debug.py
  ```

- [ ] Deploy API changes to both environments using your CI/CD system

### Step 2: Update Environment Variables

#### For DEV Environment:

- [ ] Update database connection string:
  ```
  LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse_dev:YOUR_DEV_PASSWORD@db-dev:5432/learnhouse_dev
  ```

- [ ] Update Redis connection string:
  ```
  LEARNHOUSE_REDIS_CONNECTION_STRING=redis://default:YOUR_DEV_REDIS_PASSWORD@redis-dev:6379/1
  ```

- [ ] Ensure domain settings are correct:
  ```
  LEARNHOUSE_DOMAIN=adr-lms.whitex.cloud
  LEARNHOUSE_COOKIE_DOMAIN=adr-lms.whitex.cloud
  NEXT_PUBLIC_LEARNHOUSE_DOMAIN=adr-lms.whitex.cloud
  ```

#### For LIVE Environment:

- [ ] Update database connection string:
  ```
  LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse:YOUR_LIVE_PASSWORD@db-live:5432/learnhouse
  ```

- [ ] Update Redis connection string:
  ```
  LEARNHOUSE_REDIS_CONNECTION_STRING=redis://default:YOUR_LIVE_REDIS_PASSWORD@redis-live:6379/0
  ```

- [ ] Ensure domain settings are correct:
  ```
  LEARNHOUSE_DOMAIN=edu.adradviser.ro
  LEARNHOUSE_COOKIE_DOMAIN=edu.adradviser.ro
  NEXT_PUBLIC_LEARNHOUSE_DOMAIN=edu.adradviser.ro
  ```

### Step 3: Database Infrastructure

- [ ] Ensure each deployment has its own database server:
  - DEV: db-dev
  - LIVE: db-live

- [ ] If using shared infrastructure, ensure logical isolation through server names and proper networking

### Step 4: Rebuild & Deploy

- [ ] Rebuild and deploy both environments with updated environment variables
- [ ] Restart all services to apply changes

### Step 5: Verification

- [ ] Run the comprehensive isolation verification script:
  ```bash
  ./verify-all-isolation.sh
  ```
  This will:
  - Check deployment configuration
  - Verify database isolation
  - Test cookie isolation
  - Check for hardcoded URLs
  - Create a visual cookie isolation demo

- [ ] For more detailed verification, run individual scripts:
  ```bash
  ./verify-enhanced-isolation.sh      # Basic deployment checks
  ./verify-db-isolation.sh            # Database-specific checks
  ./test-nextauth-cookie-isolation.sh # Cookie isolation tests
  ```

- [ ] Test the visual cookie isolation demo:
  ```bash
  ./create-cookie-demo.sh
  # Open the resulting HTML file in a browser
  ```

- [ ] Access debug endpoints directly:
  - DEV: https://adr-lms.whitex.cloud/api/v1/debug/deployment
  - LIVE: https://edu.adradviser.ro/api/v1/debug/deployment
  - DEV: https://adr-lms.whitex.cloud/api/v1/debug/cookies
  - LIVE: https://edu.adradviser.ro/api/v1/debug/cookies
  - DEV: https://adr-lms.whitex.cloud/api/v1/debug/session
  - LIVE: https://edu.adradviser.ro/api/v1/debug/session

- [ ] Test in incognito browsers to verify session isolation

## Troubleshooting

If isolation issues persist after implementation:

1. **Use the Enhanced Debug Tools**:
   - Look at the detailed reports in `/tmp/learnhouse-isolation-report/`
   - Run specific tests: `./test-nextauth-cookie-isolation.sh` for cookie issues
   - Check session configuration: `/api/v1/debug/session` endpoint

2. **Verify Database Connections**:
   - Confirm debug endpoints show different database hosts and names
   - Check actual database servers to confirm connections come from different sources
   - Test with the database isolation script: `./verify-db-isolation.sh`

3. **Clear Browser Data**:
   - Use incognito mode or clear all cookies/cache for proper testing
   - Try the cookie isolation demo to visually check cookie behavior

4. **Check Docker Network Isolation**:
   - Ensure each deployment uses its own Docker network
   - Verify hostnames resolve to different IP addresses within containers

5. **Validate URL Patching**:
   - Run URL debug endpoint to confirm no hardcoded references remain
   - Check the enhanced URL report in `/api/v1/debug/urls` endpoint

For additional help, refer to the full documentation in:
- `ENHANCED_DEBUG_TOOLS.md` - Detailed guide to all debug endpoints
- `DATABASE_ISOLATION_FIX.md` - Database isolation specifics
- `DEPLOYMENT_TROUBLESHOOTING.md` - General deployment troubleshooting
- `ISOLATION_TOOLKIT_README.md` - Overview of all isolation tools
