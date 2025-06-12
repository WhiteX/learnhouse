#!/bin/bash

# Master Isolation Verification Script
# This script runs all isolation verification checks in sequence

echo "===================================================================="
echo "LearnHouse Deployment Isolation - Complete Verification Suite"
echo "===================================================================="

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define the deployments
DEV_URL="http://adr-lms.whitex.cloud"
LIVE_URL="http://edu.adradviser.ro"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check requirements
echo -e "${BLUE}Checking requirements...${NC}"
MISSING_TOOLS=0

if ! command_exists curl; then
    echo -e "${RED}Missing required tool: curl${NC}"
    MISSING_TOOLS=1
fi

if ! command_exists jq; then
    echo -e "${YELLOW}Warning: jq is not installed. JSON output will not be formatted.${NC}"
fi

if [ $MISSING_TOOLS -eq 1 ]; then
    echo -e "${RED}Please install the missing tools and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}All required tools are available.${NC}"
echo

# Function to run a verification script and report result
run_verification() {
    script="$1"
    description="$2"
    
    echo -e "${BLUE}Running: ${description}${NC}"
    echo "--------------------------------------------------------------------"
    
    if [ -x "$script" ]; then
        if "$script"; then
            result=$?
            if [ $result -eq 0 ]; then
                echo -e "${GREEN}✓ PASSED: ${description}${NC}"
            else
                echo -e "${RED}✗ FAILED: ${description} (Exit code: $result)${NC}"
            fi
        else
            echo -e "${RED}✗ ERROR: Failed to execute ${description}${NC}"
        fi
    else
        echo -e "${RED}✗ ERROR: Script not found or not executable: ${script}${NC}"
    fi
    
    echo "--------------------------------------------------------------------"
    echo
}

# Create output directory for reports
REPORT_DIR="/tmp/learnhouse-isolation-report"
mkdir -p "$REPORT_DIR"
echo -e "${BLUE}Reports will be saved in: ${REPORT_DIR}${NC}"
echo

# Step 1: Run the enhanced deployment verification
echo -e "${BLUE}STEP 1: Testing basic deployment configuration${NC}"
curl -s "${DEV_URL}/api/v1/debug/deployment" > "${REPORT_DIR}/dev-deployment.json"
curl -s "${LIVE_URL}/api/v1/debug/deployment" > "${REPORT_DIR}/live-deployment.json"
run_verification "./verify-enhanced-isolation.sh" "Enhanced Deployment Verification"

# Step 2: Test database isolation specifically
echo -e "${BLUE}STEP 2: Testing database isolation${NC}"
run_verification "./verify-db-isolation.sh" "Database Isolation Check"

# Step 3: Test NextAuth cookie isolation
echo -e "${BLUE}STEP 3: Testing NextAuth cookies${NC}"
run_verification "./test-nextauth-cookie-isolation.sh" "NextAuth Cookie Isolation Test"

# Step 4: Check for hardcoded URLs in the frontend
echo -e "${BLUE}STEP 4: Checking for hardcoded URLs${NC}"
echo "Checking DEV deployment for LIVE URLs..."
curl -s "${DEV_URL}/api/v1/debug/urls" > "${REPORT_DIR}/dev-urls.json"
DEV_HARDCODED_COUNT=$(grep -o "edu.adradviser.ro" "${REPORT_DIR}/dev-urls.json" | wc -l)

echo "Checking LIVE deployment for DEV URLs..."
curl -s "${LIVE_URL}/api/v1/debug/urls" > "${REPORT_DIR}/live-urls.json"
LIVE_HARDCODED_COUNT=$(grep -o "adr-lms.whitex.cloud" "${REPORT_DIR}/live-urls.json" | wc -l)

if [ $DEV_HARDCODED_COUNT -eq 0 ] && [ $LIVE_HARDCODED_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ PASSED: No cross-deployment hardcoded URLs found${NC}"
else
    echo -e "${RED}✗ FAILED: Found hardcoded URLs:${NC}"
    if [ $DEV_HARDCODED_COUNT -gt 0 ]; then
        echo "  - DEV deployment contains ${DEV_HARDCODED_COUNT} references to LIVE domain"
    fi
    if [ $LIVE_HARDCODED_COUNT -gt 0 ]; then
        echo "  - LIVE deployment contains ${LIVE_HARDCODED_COUNT} references to DEV domain"
    fi
fi
echo "--------------------------------------------------------------------"
echo

# Step 5: Create the cookie isolation demo
echo -e "${BLUE}STEP 5: Creating cookie isolation demonstration tool${NC}"
run_verification "./create-cookie-demo.sh" "Cookie Isolation Demo Creation"

# Summary of all tests
echo "===================================================================="
echo -e "${BLUE}SUMMARY OF ISOLATION VERIFICATION${NC}"
echo "===================================================================="

# Check deployment names
DEV_NAME=$(grep -o '"deployment_name":"[^"]*"' "${REPORT_DIR}/dev-deployment.json" | cut -d'"' -f4)
LIVE_NAME=$(grep -o '"deployment_name":"[^"]*"' "${REPORT_DIR}/live-deployment.json" | cut -d'"' -f4)

# Check database isolation
DEV_DB=$(grep -o '"name":"[^"]*"' "${REPORT_DIR}/dev-deployment.json" | head -1 | cut -d'"' -f4)
LIVE_DB=$(grep -o '"name":"[^"]*"' "${REPORT_DIR}/live-deployment.json" | head -1 | cut -d'"' -f4)

# Check cookie domain isolation
DEV_COOKIE=$(grep -o '"cookie_domain":"[^"]*"' "${REPORT_DIR}/dev-deployment.json" | cut -d'"' -f4)
LIVE_COOKIE=$(grep -o '"cookie_domain":"[^"]*"' "${REPORT_DIR}/live-deployment.json" | cut -d'"' -f4)

echo -e "Deployment Names:"
if [[ "$DEV_NAME" == "DEV" && "$LIVE_NAME" == "LIVE" ]]; then
    echo -e "  ${GREEN}✓ Correct: DEV='$DEV_NAME', LIVE='$LIVE_NAME'${NC}"
else
    echo -e "  ${RED}✗ Incorrect: DEV='$DEV_NAME', LIVE='$LIVE_NAME'${NC}"
fi

echo -e "Database Isolation:"
if [[ "$DEV_DB" != "$LIVE_DB" && "$DEV_DB" != "unknown" && "$LIVE_DB" != "unknown" ]]; then
    echo -e "  ${GREEN}✓ Isolated: DEV='$DEV_DB', LIVE='$LIVE_DB'${NC}"
else
    echo -e "  ${RED}✗ Not isolated: DEV='$DEV_DB', LIVE='$LIVE_DB'${NC}"
fi

echo -e "Cookie Domain Isolation:"
if [[ "$DEV_COOKIE" != "$LIVE_COOKIE" ]]; then
    echo -e "  ${GREEN}✓ Isolated: DEV='$DEV_COOKIE', LIVE='$LIVE_COOKIE'${NC}"
else
    echo -e "  ${RED}✗ Not isolated: DEV='$DEV_COOKIE', LIVE='$LIVE_COOKIE'${NC}"
fi

echo -e "URL Hardcoding:"
if [ $DEV_HARDCODED_COUNT -eq 0 ] && [ $LIVE_HARDCODED_COUNT -eq 0 ]; then
    echo -e "  ${GREEN}✓ No cross-deployment hardcoded URLs${NC}"
else
    echo -e "  ${RED}✗ Found hardcoded URLs: DEV=$DEV_HARDCODED_COUNT, LIVE=$LIVE_HARDCODED_COUNT${NC}"
fi

echo
echo "Report files saved to: ${REPORT_DIR}"
echo "===================================================================="

# Final assessment
if [[ "$DEV_NAME" == "DEV" && "$LIVE_NAME" == "LIVE" && 
      "$DEV_DB" != "$LIVE_DB" && "$DEV_DB" != "unknown" && "$LIVE_DB" != "unknown" && 
      "$DEV_COOKIE" != "$LIVE_COOKIE" && 
      $DEV_HARDCODED_COUNT -eq 0 && $LIVE_HARDCODED_COUNT -eq 0 ]]; then
    echo -e "${GREEN}OVERALL RESULT: PASSED - Deployments appear to be properly isolated!${NC}"
    exit 0
else
    echo -e "${RED}OVERALL RESULT: FAILED - Deployment isolation issues detected!${NC}"
    echo -e "Please refer to the ${BLUE}ISOLATION_IMPLEMENTATION_CHECKLIST.md${NC} to resolve these issues."
    exit 1
fi
