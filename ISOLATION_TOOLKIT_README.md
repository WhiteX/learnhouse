# LearnHouse Deployment Isolation Toolkit

This toolkit provides comprehensive tools and documentation for diagnosing and fixing deployment isolation issues between DEV and LIVE LearnHouse instances.

## Background

We identified cross-deployment contamination issues between DEV (adr-lms.whitex.cloud) and LIVE (edu.adradviser.ro) deployments, including:

- Data contamination (both deployments accessing the same database)
- Session mixing (cookies being shared between deployments)
- Inconsistent user experience (hardcoded URLs pointing to the wrong environment)

## Isolation Toolkit Components

### Documentation

1. **[ISOLATION_IMPLEMENTATION_CHECKLIST.md](./ISOLATION_IMPLEMENTATION_CHECKLIST.md)**  
   Step-by-step checklist for implementing complete isolation between deployments.

2. **[DATABASE_ISOLATION_FIX.md](./DATABASE_ISOLATION_FIX.md)**  
   Detailed explanation of database isolation issues and how to fix them.

3. **[DEPLOYMENT_TROUBLESHOOTING.md](./DEPLOYMENT_TROUBLESHOOTING.md)**  
   Guide for troubleshooting deployment and configuration issues.

4. **[ENHANCED_DEBUG_TOOLS.md](./ENHANCED_DEBUG_TOOLS.md)**  
   Documentation for the enhanced debugging endpoints.

5. **[COOLIFY_ENV_VARS.md](./COOLIFY_ENV_VARS.md)**  
   Environment variable templates for Coolify deployments.

### Debugging Tools

1. **Debug API Endpoints**
   - `/api/v1/debug/deployment` - Get detailed deployment configuration
   - `/api/v1/debug/urls` - Scan for hardcoded URLs in the frontend bundle
   - `/api/v1/debug/cookies` - Test cookie isolation between deployments
   - `/api/v1/debug/session` - Verify session configuration

2. **Verification Scripts**
   - `verify-isolation.sh` - Basic isolation verification
   - `verify-enhanced-isolation.sh` - Comprehensive isolation checks
   - `verify-db-isolation.sh` - Database-specific isolation verification
   - `test-nextauth-cookie-isolation.sh` - NextAuth cookie isolation test

3. **Visual Demonstration Tools**
   - `create-cookie-demo.sh` - Creates an HTML tool to visually demonstrate cookie isolation

### Deployment Scripts

1. **`deploy-enhanced-debug.sh`**  
   Deploys the enhanced debugging endpoints to diagnose isolation issues.

2. **`deploy-isolation-fix.sh`**  
   Applies the complete isolation fixes to both deployments.

## Getting Started

1. **Deploy debugging tools:**
   ```bash
   ./deploy-enhanced-debug.sh
   ```

2. **Run the enhanced isolation verification:**
   ```bash
   ./verify-enhanced-isolation.sh
   ```

3. **Test cookie isolation:**
   ```bash
   ./test-nextauth-cookie-isolation.sh
   ```

4. **Create a visual cookie isolation demo:**
   ```bash
   ./create-cookie-demo.sh
   # Then open cookie-isolation-demo.html in your browser
   ```

5. **Follow the implementation checklist:**
   See [ISOLATION_IMPLEMENTATION_CHECKLIST.md](./ISOLATION_IMPLEMENTATION_CHECKLIST.md)

## Key Environment Variables for Isolation

For proper isolation, ensure each deployment has unique values for these variables:

### DEV Environment
```
DEPLOYMENT_NAME=DEV
LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse_dev:PASSWORD@db-dev:5432/learnhouse_dev
LEARNHOUSE_COOKIE_DOMAIN=adr-lms.whitex.cloud
NEXT_PUBLIC_LEARNHOUSE_DOMAIN=adr-lms.whitex.cloud
NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN=whitex.cloud
```

### LIVE Environment
```
DEPLOYMENT_NAME=LIVE
LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse:PASSWORD@db-live:5432/learnhouse
LEARNHOUSE_COOKIE_DOMAIN=edu.adradviser.ro
NEXT_PUBLIC_LEARNHOUSE_DOMAIN=edu.adradviser.ro
NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN=adradviser.ro
```

## Troubleshooting

If you encounter issues during the isolation process, refer to [DEPLOYMENT_TROUBLESHOOTING.md](./DEPLOYMENT_TROUBLESHOOTING.md).
