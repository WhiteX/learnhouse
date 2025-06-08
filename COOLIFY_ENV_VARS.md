# Environment Variables for Coolify Deployments

## DEV Environment (adr-lms.whitex.cloud)
```
DEPLOYMENT_NAME=dev
LEARNHOUSE_DOMAIN=adr-lms.whitex.cloud
LEARNHOUSE_COOKIE_DOMAIN=adr-lms.whitex.cloud
LEARNHOUSE_CONTACT_EMAIL=adr-lm@whitex.cloud
LEARNHOUSE_EMAIL_PROVIDER=resend
LEARNHOUSE_IS_AI_ENABLED=false
LEARNHOUSE_REDIS_CONNECTION_STRING=redis://default:CfhIfLu2c1VEEpGmhs80NUUvUMzyCq1lmzBZmFJDdrs@redis:6379/1
LEARNHOUSE_RESEND_API_KEY=re_LenY3zNh_S5ShneCyS3Pbf6HX75Yt8jet
LEARNHOUSE_SELF_HOSTED=true
LEARNHOUSE_SITE_DESCRIPTION=ADR LMS is platform tailored for learning experiences.
LEARNHOUSE_SITE_NAME=ADR LMS
LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse_dev:Yvvxnnf1+qr6r+6d92NvbaXWeGuRqmsroFdildw9ez4@db:5432/learnhouse_dev
LEARNHOUSE_SSL=true
LEARNHOUSE_SYSTEM_EMAIL_ADDRESS=adr-lms@whitex.cloud
NEXTAUTH_SECRET=FokIexhXga0KpAF06a7ADqt0HIJf8n9XJeRptZctDG0
NEXTAUTH_URL=https://adr-lms.whitex.cloud
NEXT_PUBLIC_API_URL=https://adr-lms.whitex.cloud/api/v1/
NEXT_PUBLIC_LEARNHOUSE_API_URL=https://adr-lms.whitex.cloud/api/v1/
NEXT_PUBLIC_LEARNHOUSE_BACKEND_URL=https://adr-lms.whitex.cloud/
NEXT_PUBLIC_LEARNHOUSE_DEFAULT_ORG=default
NEXT_PUBLIC_LEARNHOUSE_DOMAIN=adr-lms.whitex.cloud
NEXT_PUBLIC_LEARNHOUSE_MULTI_ORG=false
NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN=adr-lms.whitex.cloud
POSTGRES_DB=learnhouse_dev
POSTGRES_PASSWORD=Yvvxnnf1+qr6r+6d92NvbaXWeGuRqmsroFdildw9ez4
POSTGRES_USER=learnhouse_dev
REDIS_PASSWORD=CfhIfLu2c1VEEpGmhs80NUUvUMzyCq1lmzBZmFJDdrs
```

## LIVE Environment (edu.adradviser.ro)
```
DEPLOYMENT_NAME=live
LEARNHOUSE_DOMAIN=edu.adradviser.ro
LEARNHOUSE_COOKIE_DOMAIN=edu.adradviser.ro
LEARNHOUSE_CONTACT_EMAIL=adr-lm@whitex.cloud
LEARNHOUSE_EMAIL_PROVIDER=resend
LEARNHOUSE_IS_AI_ENABLED=false
LEARNHOUSE_REDIS_CONNECTION_STRING=redis://default:tRK6fpKHGM2lWY8AYvL7L5kRQhncF2gydYOxG4l8vNY@redis:6379/0
LEARNHOUSE_RESEND_API_KEY=re_LenY3zNh_S5ShneCyS3Pbf6HX75Yt8jet
LEARNHOUSE_SELF_HOSTED=true
LEARNHOUSE_SITE_DESCRIPTION=ADR LMS is platform tailored for learning experiences.
LEARNHOUSE_SITE_NAME=ADR LMS
LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse:kOZ8JgUNNSbPKSlfIBDBs5Ycs+ZOVZ3NZZooQrOyOqI@db:5432/learnhouse
LEARNHOUSE_SSL=true
LEARNHOUSE_SYSTEM_EMAIL_ADDRESS=adr-lms@whitex.cloud
NEXTAUTH_SECRET=LPBwWytdQu9QDQHTdHEOHsHGhXDqdu6I686dXLVHH4g
NEXTAUTH_URL=https://edu.adradviser.ro
NEXT_PUBLIC_API_URL=https://edu.adradviser.ro/api/v1/
NEXT_PUBLIC_LEARNHOUSE_API_URL=https://edu.adradviser.ro/api/v1/
NEXT_PUBLIC_LEARNHOUSE_BACKEND_URL=https://edu.adradviser.ro/
NEXT_PUBLIC_LEARNHOUSE_DEFAULT_ORG=default
NEXT_PUBLIC_LEARNHOUSE_DOMAIN=edu.adradviser.ro
NEXT_PUBLIC_LEARNHOUSE_MULTI_ORG=false
NEXT_PUBLIC_LEARNHOUSE_TOP_DOMAIN=edu.adradviser.ro
POSTGRES_DB=learnhouse
POSTGRES_PASSWORD=kOZ8JgUNNSbPKSlfIBDBs5Ycs+ZOVZ3NZZooQrOyOqI
POSTGRES_USER=learnhouse
REDIS_PASSWORD=tRK6fpKHGM2lWY8AYvL7L5kRQhncF2gydYOxG4l8vNY
```

## Key Differences for Isolation

The critical environment variables that ensure complete isolation:

1. **DEPLOYMENT_NAME**: Different for each environment (`dev` vs `live`)
2. **Domain Variables**: Point to different domains
3. **Database Credentials**: Different databases and users
4. **Redis Connection**: Different Redis databases (1 vs 0)
5. **Secrets**: Different NEXTAUTH_SECRET values
