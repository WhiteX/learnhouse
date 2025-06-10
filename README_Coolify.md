# LearnHouse Deployment Guide for Coolify

This document provides instructions for deploying LearnHouse using Coolify, ensuring proper configuration and persistent storage.

## Prerequisites

- A Coolify instance up and running
- Access to the LearnHouse GitHub repository
- Domain name for your LearnHouse instance
- Email provider credentials (if using email functionality)

## Deployment Steps

### 1. Create a New Resource in Coolify

- Log in to your Coolify dashboard
- Click on "Create Resource"
- Select "GitHub Repository" as the source

### 2. Configure Docker Compose Build

- Select "Docker Compose" as the build method
- Choose `docker-compose-coolify.yml` as the compose file
- Make sure the "Volume" configuration is set to store persistent data

### 3. Configure Domain Settings

- Add your domain (e.g., `learnhouse.com`) in the resource settings
- Enable HTTPS if needed (recommended for production)
- Configure any necessary redirects

### 4. Environment Variables

Add the following environment variables. Replace placeholder values with your actual configuration:

```
# LearnHouse Core Configuration
LEARNHOUSE_SITE_NAME=Your LMS Name
LEARNHOUSE_SITE_DESCRIPTION=Your platform description
LEARNHOUSE_SELF_HOSTED=true
LEARNHOUSE_SSL=true
LEARNHOUSE_CONTACT_EMAIL=contact@example.com

# Domain Configuration
NEXT_PUBLIC_LEARNHOUSE_DOMAIN=learnhouse.com
LEARNHOUSE_COOKIE_DOMAIN=learnhouse.com
NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN=learnhouse.com

# Authentication
NEXTAUTH_SECRET=your_generated_secret_key
NEXTAUTH_URL=https://learnhouse.com

# API URLs
NEXT_PUBLIC_API_URL=https://learnhouse.com/api/v1/
NEXT_PUBLIC_LEARNHOUSE_API_URL=https://learnhouse.com/api/v1/
NEXT_PUBLIC_LEARNHOUSE_BACKEND_URL=https://learnhouse.com/

# Organization Settings
NEXT_PUBLIC_LEARNHOUSE_MULTI_ORG=false
NEXT_PUBLIC_LEARNHOUSE_DEFAULT_ORG=default

# Database Configuration
POSTGRES_USER=learnhouse
POSTGRES_PASSWORD=strong_database_password
POSTGRES_DB=learnhouse
LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse:strong_database_password@db:5432/learnhouse

# Redis Configuration
REDIS_PASSWORD=strong_redis_password
LEARNHOUSE_REDIS_CONNECTION_STRING=redis://default:strong_redis_password@redis:6379/learnhouse

# ChromaDB Configuration
LEARNHOUSE_CHROMADB_HOST=chromadb

# Email Configuration (optional)
LEARNHOUSE_EMAIL_PROVIDER=resend
LEARNHOUSE_RESEND_API_KEY=re_your_resend_api_key
```

### 5. Start the Build Process

- Click on "Deploy" to start the build and deployment process
- Monitor the build logs for any errors
- Once complete, verify that your LearnHouse instance is accessible at your domain

### 6. Verify Persistent Storage

- After deployment, upload some content (course materials, organization logos, etc.)
- Restart the service to confirm that uploaded files persist across restarts

## Troubleshooting

- **File uploads not persisting**: Ensure the volume mount in `docker-compose-coolify.yml` points to `/app/api/content` which is where the application stores uploaded files.
- **Database connection errors**: Verify the database credentials and connection string.
- **UI rendering issues**: Check that all Next.js related environment variables are correctly set.

## Additional Resources

- [LearnHouse Documentation](https://docs.learnhouse.io/)
- [Coolify Documentation](https://coolify.io/docs)