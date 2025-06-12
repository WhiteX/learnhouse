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

- [ ] Verify the debug endpoint files exist:
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

- [ ] Run verification scripts:
  ```bash
  ./verify-isolation.sh
  ./verify-db-isolation.sh
  ```

- [ ] Access debug endpoints directly:
  - DEV: https://adr-lms.whitex.cloud/api/v1/debug/deployment
  - LIVE: https://edu.adradviser.ro/api/v1/debug/deployment

- [ ] Check URLs in frontend:
  - DEV: https://adr-lms.whitex.cloud/api/v1/debug/urls
  - LIVE: https://edu.adradviser.ro/api/v1/debug/urls

- [ ] Test in incognito browsers to verify session isolation

## Troubleshooting

If isolation issues persist after implementation:

1. **Verify Database Connections**:
   - Confirm debug endpoints show different database hosts
   - Check actual database servers to confirm connections come from different sources

2. **Clear Browser Data**:
   - Use incognito mode or clear all cookies/cache for proper testing

3. **Check Docker Network Isolation**:
   - Ensure each deployment uses its own Docker network
   - Verify hostnames resolve to different IP addresses within containers

4. **Validate URL Patching**:
   - Run URL debug endpoint to confirm no hardcoded references remain

For additional help, refer to the full documentation in:
- `DATABASE_ISOLATION_FIX.md`
- `DEPLOYMENT_TROUBLESHOOTING.md`
