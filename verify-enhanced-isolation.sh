#!/bin/bash

# Enhanced isolation verification script
# This script helps verify that the DEV and LIVE deployments are properly isolated

echo "==================================================================================="
echo "LearnHouse Deployment Isolation Verification Tool"
echo "==================================================================================="

# Define the URLs of both deployments
DEV_URL="http://adr-lms.whitex.cloud"
LIVE_URL="http://edu.adradviser.ro"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required tools are installed
if ! command_exists curl; then
    echo -e "${RED}Error: curl is not installed. Please install curl and try again.${NC}"
    exit 1
fi

if ! command_exists jq; then
    echo -e "${YELLOW}Warning: jq is not installed. JSON responses will not be formatted nicely.${NC}"
    JSON_PROCESSOR="cat"
else
    JSON_PROCESSOR="jq"
fi

echo -e "${BLUE}Checking deployment configurations...${NC}"
echo ""

# Function to fetch deployment info
fetch_deployment_info() {
    local url="$1"
    local name="$2"
    
    echo -e "${BLUE}Checking ${name} deployment (${url})...${NC}"
    echo "---------------------------------------------------------------------------------"
    
    # Make API call
    response=$(curl -s "${url}/api/v1/debug/deployment" -H "Accept: application/json")
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to connect to ${name} deployment.${NC}"
        return 1
    fi
    
    # Display deployment info
    echo -e "${GREEN}Deployment information:${NC}"
    echo "$response" | $JSON_PROCESSOR
    
    # Extract key information
    deployment_name=$(echo "$response" | grep -o '"deployment_name":"[^"]*"' | cut -d'"' -f4)
    cookie_domain=$(echo "$response" | grep -o '"cookie_domain":"[^"]*"' | cut -d'"' -f4)
    database_host=$(echo "$response" | grep -o '"host":"[^"]*"' | head -1 | cut -d'"' -f4)
    database_name=$(echo "$response" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    echo ""
    echo -e "${BLUE}Summary:${NC}"
    echo "Deployment name: ${deployment_name:-unknown}"
    echo "Cookie domain: ${cookie_domain:-unknown}"
    echo "Database host: ${database_host:-unknown}"
    echo "Database name: ${database_name:-unknown}"
    echo ""
    
    # Check for cookie isolation
    echo -e "${BLUE}Testing cookie isolation...${NC}"
    cookie_response=$(curl -s "${url}/api/v1/debug/cookies" -H "Accept: application/json")
    echo "$cookie_response" | $JSON_PROCESSOR
    echo ""
    
    # Check for hardcoded URLs
    echo -e "${BLUE}Checking for hardcoded URLs...${NC}"
    url_response=$(curl -s "${url}/api/v1/debug/urls" -H "Accept: application/json")
    
    # Count hardcoded references to the other environment
    other_url=""
    if [[ "$url" == "$DEV_URL" ]]; then
        other_url="edu.adradviser.ro"
    else
        other_url="adr-lms.whitex.cloud"
    fi
    
    hardcoded_count=$(echo "$url_response" | grep -o "$other_url" | wc -l)
    
    if [[ $hardcoded_count -gt 0 ]]; then
        echo -e "${RED}Warning: Found $hardcoded_count hardcoded references to $other_url${NC}"
        echo "This could cause isolation issues!"
    else
        echo -e "${GREEN}No hardcoded references to the other environment found.${NC}"
    fi
    
    # Check for session configuration
    echo -e "${BLUE}Testing session configuration...${NC}"
    session_response=$(curl -s "${url}/api/v1/debug/session" -H "Accept: application/json")
    echo "$session_response" | $JSON_PROCESSOR
    
    echo ""
    echo "---------------------------------------------------------------------------------"
}

# Check both deployments
fetch_deployment_info "$DEV_URL" "DEV"
echo ""
fetch_deployment_info "$LIVE_URL" "LIVE" 
echo ""

echo -e "${BLUE}Analyzing isolation status...${NC}"
echo "---------------------------------------------------------------------------------"

# Simple test: check if both deployments respond with the correct deployment name
dev_name=$(curl -s "${DEV_URL}/api/v1/debug/deployment" | grep -o '"deployment_name":"[^"]*"' | cut -d'"' -f4)
live_name=$(curl -s "${LIVE_URL}/api/v1/debug/deployment" | grep -o '"deployment_name":"[^"]*"' | cut -d'"' -f4)

# Check database isolation
dev_db=$(curl -s "${DEV_URL}/api/v1/debug/deployment" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
live_db=$(curl -s "${LIVE_URL}/api/v1/debug/deployment" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)

# Check cookie domain isolation
dev_cookie=$(curl -s "${DEV_URL}/api/v1/debug/deployment" | grep -o '"cookie_domain":"[^"]*"' | cut -d'"' -f4)
live_cookie=$(curl -s "${LIVE_URL}/api/v1/debug/deployment" | grep -o '"cookie_domain":"[^"]*"' | cut -d'"' -f4)

echo "SUMMARY OF ISOLATION STATUS:"
echo ""

if [[ "$dev_name" == "DEV" && "$live_name" == "LIVE" ]]; then
    echo -e "${GREEN}✓ Both deployments report the correct deployment name.${NC}"
else
    echo -e "${RED}✗ Deployment name mismatch! DEV reports '$dev_name', LIVE reports '$live_name'${NC}"
fi

if [[ "$dev_db" != "$live_db" ]]; then
    echo -e "${GREEN}✓ Database isolation: Different database names ($dev_db vs $live_db)${NC}"
else
    echo -e "${RED}✗ Database isolation failure! Both environments use the same database: $dev_db${NC}"
fi

if [[ "$dev_cookie" != "$live_cookie" ]]; then
    echo -e "${GREEN}✓ Cookie domain isolation: Different cookie domains ($dev_cookie vs $live_cookie)${NC}"
else
    echo -e "${RED}✗ Cookie domain isolation failure! Both environments use the same cookie domain: $dev_cookie${NC}"
fi

echo ""
echo "==================================================================================="

if [[ "$dev_db" == "$live_db" || "$dev_cookie" == "$live_cookie" ]]; then
    echo -e "${RED}Isolation verification FAILED! The deployments are not properly isolated.${NC}"
    exit 1
else
    echo -e "${GREEN}Isolation verification PASSED! The deployments appear to be properly isolated.${NC}"
    exit 0
fi
