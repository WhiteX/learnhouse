#!/bin/bash

# Script to deploy enhanced isolation debugging tools
# This script will update the debug endpoints on both DEV and LIVE deployments

echo "===================================================================="
echo "LearnHouse Enhanced Debug Tools Deployment"
echo "===================================================================="

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define git branches
DEV_BRANCH="isolation-debug"
MAIN_BRANCH="main"

# Ensure we have the latest code
echo -e "${BLUE}Fetching latest code...${NC}"
git fetch origin
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Create a new branch for our changes
echo -e "${BLUE}Creating branch for debug tools...${NC}"
git checkout -b $DEV_BRANCH

# Check if the debug files exist
if [ ! -f "apps/api/src/routers/debug_enhanced.py" ]; then
    echo -e "${RED}Error: Enhanced debug module not found! Run the setup script first.${NC}"
    git checkout $current_branch
    exit 1
fi

# Stage and commit our changes
echo -e "${BLUE}Committing changes...${NC}"
git add apps/api/src/routers/debug_enhanced.py
git add apps/api/src/router.py
git add verify-enhanced-isolation.sh
git add ENHANCED_DEBUG_TOOLS.md
git commit -m "Add enhanced debug endpoints for deployment isolation troubleshooting"

# Push to origin
echo -e "${BLUE}Pushing changes to origin...${NC}"
if git push -u origin $DEV_BRANCH; then
    echo -e "${GREEN}Successfully pushed changes to origin/$DEV_BRANCH${NC}"
else
    echo -e "${RED}Failed to push changes. Please check your git configuration.${NC}"
    git checkout $current_branch
    exit 1
fi

echo ""
echo "===================================================================="
echo -e "${GREEN}Deployment preparation completed!${NC}"
echo ""
echo -e "To deploy these changes:"
echo -e "1. Create a pull request from ${BLUE}$DEV_BRANCH${NC} to ${BLUE}$MAIN_BRANCH${NC}"
echo -e "2. After review and merge, deploy to both environments"
echo -e "3. Use ${BLUE}./verify-enhanced-isolation.sh${NC} to check isolation"
echo ""
echo -e "Documentation: See ${BLUE}ENHANCED_DEBUG_TOOLS.md${NC} for endpoint usage"
echo "===================================================================="

# Return to original branch
git checkout $current_branch
