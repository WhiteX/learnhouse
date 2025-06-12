# Environment Variables for Coolify Deployments

> ⚠️ **SECURITY NOTE**: This file contains placeholder values only. Replace ALL `YOUR_*` placeholders with your actual secure values before deployment. Never commit actual secrets to version control.

## Placeholder Values to Replace:
- `YOUR_DEV_REDIS_PASSWORD` - Strong password for development Redis instance
- `YOUR_LIVE_REDIS_PASSWORD` - Strong password for production Redis instance  
- `YOUR_DEV_DB_PASSWORD` - Strong password for development database
- `YOUR_LIVE_DB_PASSWORD` - Strong password for production database
- `YOUR_DEV_NEXTAUTH_SECRET` - Cryptographically secure random string for dev auth
- `YOUR_LIVE_NEXTAUTH_SECRET` - Cryptographically secure random string for production auth
- `YOUR_RESEND_API_KEY` - Your actual Resend API key for email delivery
- `your-dev-domain.com` - Your development domain name
- `your-prod-domain.com` - Your production domain name
- `contact@.com` - Your organization contact email

## DEV Environment
```
DEPLOYMENT_NAME=dev
LEARNHOUSE_DOMAIN=your-dev-domain.com
LEARNHOUSE_COOKIE_DOMAIN=your-dev-domain.com
LEARNHOUSE_CONTACT_EMAIL=contact@.com
LEARNHOUSE_EMAIL_PROVIDER=resend
LEARNHOUSE_IS_AI_ENABLED=false
LEARNHOUSE_REDIS_CONNECTION_STRING=redis://default:YOUR_DEV_REDIS_PASSWORD@redis-dev:6379/1  # Use deployment-specific Redis hostname
LEARNHOUSE_RESEND_API_KEY=YOUR_RESEND_API_KEY
LEARNHOUSE_SELF_HOSTED=true
LEARNHOUSE_SITE_DESCRIPTION=ADR LMS is platform tailored for learning experiences.
LEARNHOUSE_SITE_NAME=ADR LMS
LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse_dev:YOUR_DEV_DB_PASSWORD@db-dev:5432/learnhouse_dev  # Use deployment-specific database hostname
LEARNHOUSE_SSL=true
LEARNHOUSE_SYSTEM_EMAIL_ADDRESS=contact@.com
NEXTAUTH_SECRET=YOUR_DEV_NEXTAUTH_SECRET
NEXTAUTH_URL=https://your-dev-domain.com
NEXT_PUBLIC_API_URL=https://your-dev-domain.com/api/v1/
NEXT_PUBLIC_LEARNHOUSE_API_URL=https://your-dev-domain.com/api/v1/
NEXT_PUBLIC_LEARNHOUSE_BACKEND_URL=https://your-dev-domain.com/
NEXT_PUBLIC_LEARNHOUSE_DEFAULT_ORG=default
NEXT_PUBLIC_LEARNHOUSE_DOMAIN=your-dev-domain.com
NEXT_PUBLIC_LEARNHOUSE_MULTI_ORG=false
NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN=your-dev-domain.com
POSTGRES_DB=learnhouse_dev
POSTGRES_PASSWORD=YOUR_DEV_DB_PASSWORD
POSTGRES_USER=learnhouse_dev
REDIS_PASSWORD=YOUR_DEV_REDIS_PASSWORD
```

## LIVE Environment
```
DEPLOYMENT_NAME=live
LEARNHOUSE_DOMAIN=your-prod-domain.com
LEARNHOUSE_COOKIE_DOMAIN=your-prod-domain.com
LEARNHOUSE_CONTACT_EMAIL=contact@.com
LEARNHOUSE_EMAIL_PROVIDER=resend
LEARNHOUSE_IS_AI_ENABLED=false
LEARNHOUSE_REDIS_CONNECTION_STRING=redis://default:YOUR_LIVE_REDIS_PASSWORD@redis-live:6379/0  # Use deployment-specific Redis hostname
LEARNHOUSE_RESEND_API_KEY=YOUR_RESEND_API_KEY
LEARNHOUSE_SELF_HOSTED=true
LEARNHOUSE_SITE_DESCRIPTION=ADR LMS is platform tailored for learning experiences.
LEARNHOUSE_SITE_NAME=ADR LMS
LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse:YOUR_LIVE_DB_PASSWORD@db-live:5432/learnhouse  # Use deployment-specific database hostname
LEARNHOUSE_SSL=true
LEARNHOUSE_SYSTEM_EMAIL_ADDRESS=contact@.com
NEXTAUTH_SECRET=YOUR_LIVE_NEXTAUTH_SECRET
NEXTAUTH_URL=https://your-prod-domain.com
NEXT_PUBLIC_API_URL=https://your-prod-domain.com/api/v1/
NEXT_PUBLIC_LEARNHOUSE_API_URL=https://your-prod-domain.com/api/v1/
NEXT_PUBLIC_LEARNHOUSE_BACKEND_URL=https://your-prod-domain.com/
NEXT_PUBLIC_LEARNHOUSE_DEFAULT_ORG=default
NEXT_PUBLIC_LEARNHOUSE_DOMAIN=your-prod-domain.com
NEXT_PUBLIC_LEARNHOUSE_MULTI_ORG=false
NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN=your-prod-domain.com
POSTGRES_DB=learnhouse
POSTGRES_PASSWORD=YOUR_LIVE_DB_PASSWORD
POSTGRES_USER=learnhouse
REDIS_PASSWORD=YOUR_LIVE_REDIS_PASSWORD
```

## Key Differences for Isolation

The critical environment variables that ensure complete isolation:

1. **DEPLOYMENT_NAME**: Different for each environment (`dev` vs `live`)
2. **Domain Variables**: Point to different domains 
3. **Database Hostnames**: Use deployment-specific hostnames (`db-dev` vs `db-live`)
4. **Redis Hostnames**: Use deployment-specific hostnames (`redis-dev` vs `redis-live`)
5. **Database Credentials**: Different databases and users
6. **Redis Connection**: Different Redis databases (1 vs 0)
7. **Secrets**: Different NEXTAUTH_SECRET values

## Deployment Isolation Strategy

To prevent cross-deployment contamination:

1. **Database Isolation**: Each deployment must use its own separate database server with a unique hostname
2. **Redis Isolation**: Each deployment must use its own Redis instance with a unique hostname
3. **Domain Isolation**: Each deployment must use its own domain and cookie domain
4. **URL Patching**: The Dockerfile includes runtime patching of hardcoded URLs
5. **Network Isolation**: Each deployment should use its own Docker network

See `DATABASE_ISOLATION_FIX.md` for detailed implementation steps.
