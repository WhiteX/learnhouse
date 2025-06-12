#!/bin/bash

# NextAuth Cookie Isolation Test Script
# Tests whether the NextAuth session cookies are properly isolated between deployments

echo "=============================================================="
echo "NextAuth Cookie Isolation Test"
echo "=============================================================="

# Define deployment URLs
DEV_URL="http://adr-lms.whitex.cloud"
LIVE_URL="http://edu.adradviser.ro"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is not installed. Please install curl first.${NC}"
    exit 1
fi

# Function to check if jq is installed (for prettier output)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq is not installed. JSON output will not be formatted.${NC}"
    JQ_CMD="cat"
else
    JQ_CMD="jq"
fi

echo -e "${BLUE}Step 1: Checking NextAuth configuration in DEV environment...${NC}"
curl -s "${DEV_URL}/api/v1/debug/session" | $JQ_CMD
echo

echo -e "${BLUE}Step 2: Checking NextAuth configuration in LIVE environment...${NC}"
curl -s "${LIVE_URL}/api/v1/debug/session" | $JQ_CMD
echo

echo -e "${BLUE}Step 3: Testing cookie isolation with test cookies...${NC}"
echo "Setting test cookies on DEV deployment..."
curl -s -c /tmp/dev_cookies.txt "${DEV_URL}/api/v1/debug/cookies" > /dev/null
echo "Setting test cookies on LIVE deployment..."
curl -s -c /tmp/live_cookies.txt "${LIVE_URL}/api/v1/debug/cookies" > /dev/null

echo -e "${BLUE}Step 4: Checking for cookie isolation...${NC}"
echo "Sending DEV cookies to LIVE deployment..."
DEV_COOKIES_ON_LIVE=$(curl -s -b /tmp/dev_cookies.txt "${LIVE_URL}/api/v1/debug/cookies" | grep -o "isolation-test-DEV")
echo "Sending LIVE cookies to DEV deployment..."
LIVE_COOKIES_ON_DEV=$(curl -s -b /tmp/live_cookies.txt "${DEV_URL}/api/v1/debug/cookies" | grep -o "isolation-test-LIVE")

echo

if [[ -z "$DEV_COOKIES_ON_LIVE" && -z "$LIVE_COOKIES_ON_DEV" ]]; then
    echo -e "${GREEN}SUCCESS: Cookie isolation is working correctly!${NC}"
    echo "The DEV cookies are not visible to the LIVE deployment, and vice versa."
    echo "This means that sessions should be properly isolated."
else
    echo -e "${RED}FAILURE: Cookie isolation is NOT working!${NC}"
    
    if [[ ! -z "$DEV_COOKIES_ON_LIVE" ]]; then
        echo "- DEV cookies are visible to the LIVE deployment"
    fi
    
    if [[ ! -z "$LIVE_COOKIES_ON_DEV" ]]; then
        echo "- LIVE cookies are visible to the DEV deployment"
    fi
    
    echo
    echo "This means session contamination will occur between deployments."
    echo "Please ensure each deployment has a unique cookie domain set with:"
    echo "  LEARNHOUSE_COOKIE_DOMAIN=adr-lms.whitex.cloud  (for DEV)"
    echo "  LEARNHOUSE_COOKIE_DOMAIN=edu.adradviser.ro     (for LIVE)"
fi

echo
echo -e "${BLUE}Step 5: Checking domain and cookie settings...${NC}"
echo "DEV settings:"
curl -s "${DEV_URL}/api/v1/debug/deployment" | grep -E "cookie_domain|api_domain" | $JQ_CMD
echo
echo "LIVE settings:"
curl -s "${LIVE_URL}/api/v1/debug/deployment" | grep -E "cookie_domain|api_domain" | $JQ_CMD

echo
echo -e "${BLUE}Cleaning up temporary files...${NC}"
rm -f /tmp/dev_cookies.txt /tmp/live_cookies.txt

echo
echo "=============================================================="
echo "Test complete!"
echo "=============================================================="
