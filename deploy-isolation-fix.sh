#!/bin/bash
# Deployment Isolation Fix Script
# This script will deploy the isolation fixes to both environments

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== LearnHouse Deployment Isolation Fix Script ===${NC}"
echo -e "${YELLOW}This script will apply deployment isolation fixes${NC}"

# Verify script is running from correct directory
if [ ! -d "./apps/api" ] || [ ! -d "./apps/web" ]; then
  echo -e "${RED}Error: This script must be run from the root of the learnhouse project${NC}"
  exit 1
fi

# Check if we have git access
if ! git status &>/dev/null; then
  echo -e "${RED}Error: Unable to access git repository${NC}"
  exit 1
fi

# Ensure we have the latest code
echo -e "\n${BLUE}Fetching latest code...${NC}"
git fetch

# Check for uncommitted changes
if [[ -n $(git status -s) ]]; then
  echo -e "${YELLOW}Warning: There are uncommitted changes in the repository${NC}"
  echo -e "Current changes:"
  git status -s
  
  read -p "Do you want to continue and commit these changes? (y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Fix aborted. Please commit or stash your changes first.${NC}"
    exit 1
  fi
  
  # Commit changes
  git add apps/api/src/routers/debug.py apps/api/src/router.py apps/api/app.py Dockerfile_coolify
  git commit -m "Add deployment isolation fixes"
fi

# Display what will be deployed
echo -e "\n${BLUE}The following fixes will be deployed:${NC}"
echo -e "1. Debug endpoints at /api/v1/debug/deployment and /api/v1/debug/urls"
echo -e "2. Enhanced URL patching in Dockerfile_coolify"
echo -e "3. Updated environment variable templates for database isolation"

read -p "Do you want to deploy these fixes now? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Deployment aborted.${NC}"
  exit 1
fi

# Push changes
echo -e "\n${BLUE}Pushing changes to repository...${NC}"
git push || { echo -e "${RED}Failed to push changes${NC}"; exit 1; }

echo -e "${GREEN}✓${NC} Code changes pushed successfully"

# Instructions for deployment
echo -e "\n${BLUE}=== Next Steps ===${NC}"
echo -e "1. Deploy the changes to both environments using your CI/CD system"
echo -e "2. Update environment variables for each deployment:"
echo -e "${YELLOW}   DEV:${NC} LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse_dev:YOUR_PASSWORD@db-dev:5432/learnhouse_dev"
echo -e "${YELLOW}   LIVE:${NC} LEARNHOUSE_SQL_CONNECTION_STRING=postgresql://learnhouse:YOUR_PASSWORD@db-live:5432/learnhouse"
echo -e "3. Verify deployment isolation using the verification scripts:"
echo -e "   ${YELLOW}./verify-isolation.sh${NC}"
echo -e "   ${YELLOW}./verify-db-isolation.sh${NC}"
echo -e "4. Restart both deployments after updating environment variables"

echo -e "\n${BLUE}=== Verification URLs ===${NC}"
echo -e "DEV debug endpoint: ${YELLOW}https://adr-lms.whitex.cloud/api/v1/debug/deployment${NC}"
echo -e "LIVE debug endpoint: ${YELLOW}https://edu.adradviser.ro/api/v1/debug/deployment${NC}"
echo -e "DEV URL check: ${YELLOW}https://adr-lms.whitex.cloud/api/v1/debug/urls${NC}"
echo -e "LIVE URL check: ${YELLOW}https://edu.adradviser.ro/api/v1/debug/urls${NC}"
