#!/bin/bash

# Colors for better output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 LearnHouse Deployment Isolation Verification${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check DEV deployment
echo ""
echo -e "${YELLOW}📋 DEV Deployment (adr-lms.whitex.cloud):${NC}"
echo "----------------------------------------"
echo "Testing API connection..."
DEV_RESPONSE=$(curl -s -k https://adr-lms.whitex.cloud/api/v1/debug/deployment 2>/dev/null)
DEV_HEALTH=$(curl -s -k https://adr-lms.whitex.cloud/api/health 2>/dev/null)
DEV_ROOT=$(curl -s -k https://adr-lms.whitex.cloud/ 2>/dev/null | head -200)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ DEV API accessible${NC}"
    echo "   Health: $DEV_HEALTH"
    echo "   Debug Response: $DEV_RESPONSE"
    if [[ "$DEV_ROOT" == *"LearnHouse"* ]] || [[ "$DEV_ROOT" == *"React"* ]] || [[ "$DEV_ROOT" == *"Next"* ]]; then
        echo -e "${GREEN}✅ DEV Frontend serving properly${NC}"
    else
        echo -e "${YELLOW}⚠️  DEV Frontend response unclear${NC}"
        echo "   Root response (first 100 chars): ${DEV_ROOT:0:100}"
    fi
else
    echo -e "${RED}❌ DEV API not accessible${NC}"
fi

echo ""
echo "Testing frontend..."
DEV_FRONTEND=$(curl -s -k -o /dev/null -w "%{http_code}" https://adr-lms.whitex.cloud/ 2>/dev/null)
if [ "$DEV_FRONTEND" = "200" ]; then
    echo -e "${GREEN}✅ DEV Frontend accessible (HTTP $DEV_FRONTEND)${NC}"
else
    echo -e "${RED}❌ DEV Frontend issue (HTTP $DEV_FRONTEND)${NC}"
fi

# Check LIVE deployment
echo ""
echo -e "${YELLOW}📋 LIVE Deployment (edu.adradviser.ro):${NC}"
echo "---------------------------------------"
echo "Testing API connection..."
LIVE_RESPONSE=$(curl -s -k https://edu.adradviser.ro/api/v1/debug/deployment 2>/dev/null)
LIVE_HEALTH=$(curl -s -k https://edu.adradviser.ro/api/health 2>/dev/null)
LIVE_ROOT=$(curl -s -k https://edu.adradviser.ro/ 2>/dev/null | head -200)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ LIVE API accessible${NC}"
    echo "   Health: $LIVE_HEALTH"
    echo "   Debug Response: $LIVE_RESPONSE"
    if [[ "$LIVE_ROOT" == *"LearnHouse"* ]] || [[ "$LIVE_ROOT" == *"React"* ]] || [[ "$LIVE_ROOT" == *"Next"* ]]; then
        echo -e "${GREEN}✅ LIVE Frontend serving properly${NC}"
    else
        echo -e "${YELLOW}⚠️  LIVE Frontend response unclear${NC}"
        echo "   Root response (first 100 chars): ${LIVE_ROOT:0:100}"
    fi
else
    echo -e "${RED}❌ LIVE API not accessible${NC}"
fi

echo ""
echo "Testing frontend..."
LIVE_FRONTEND=$(curl -s -k -o /dev/null -w "%{http_code}" https://edu.adradviser.ro/ 2>/dev/null)
if [ "$LIVE_FRONTEND" = "200" ]; then
    echo -e "${GREEN}✅ LIVE Frontend accessible (HTTP $LIVE_FRONTEND)${NC}"
else
    echo -e "${RED}❌ LIVE Frontend issue (HTTP $LIVE_FRONTEND)${NC}"
fi

# Analysis
echo ""
echo -e "${BLUE}🔍 Cross-Deployment Isolation Analysis:${NC}"
echo "========================================"

# Check for hardcoded URLs
echo -e "\n${BLUE}Checking for hardcoded LIVE URLs in DEV frontend...${NC}"
LIVE_URLS_IN_DEV=$(echo "$DEV_ROOT" | grep -o "http://edu.adradviser.ro[^\"']*\|https://edu.adradviser.ro[^\"']*" | sort -u)

if [[ -n "$LIVE_URLS_IN_DEV" ]]; then
    echo -e "${RED}⚠️  WARNING: Found hardcoded LIVE URLs in DEV frontend:${NC}"
    echo "$LIVE_URLS_IN_DEV"
else
    echo -e "${GREEN}✅ No hardcoded LIVE URLs found in DEV frontend${NC}"
fi

# Check for courses UUIDs
DEV_COURSES=$(echo "$DEV_ROOT" | grep -o "course_[a-zA-Z0-9-]*" | sort -u)
LIVE_COURSES=$(echo "$LIVE_ROOT" | grep -o "course_[a-zA-Z0-9-]*" | sort -u)

echo -e "\n${BLUE}Course UUIDs found in deployments:${NC}"
echo -e "${YELLOW}DEV courses:${NC} $(echo $DEV_COURSES | tr '\n' ' ')"
echo -e "${YELLOW}LIVE courses:${NC} $(echo $LIVE_COURSES | tr '\n' ' ')"

# Find common courses
if [[ -n "$DEV_COURSES" && -n "$LIVE_COURSES" ]]; then
    # Using grep to find common entries
    COMMON_COURSES=""
    for course in $DEV_COURSES; do
        if echo "$LIVE_COURSES" | grep -q "$course"; then
            COMMON_COURSES="$COMMON_COURSES $course"
        fi
    done

    if [[ -n "$COMMON_COURSES" ]]; then
        echo -e "${RED}⚠️  WARNING: Found shared courses between deployments (contamination):${NC}"
        echo "$COMMON_COURSES"
    else
        echo -e "${GREEN}✅ No shared courses found between deployments${NC}"
    fi
fi

# Extract database hosts if responses are valid JSON
if command -v python3 >/dev/null 2>&1; then
    echo -e "\n${BLUE}Database connection analysis:${NC}"
    if [[ "$DEV_RESPONSE" == *"database_host"* ]]; then
        DEV_DB=$(echo "$DEV_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('database_host', 'unknown'))" 2>/dev/null)
        echo -e "DEV database: ${YELLOW}$DEV_DB${NC}"
    else
        echo -e "${RED}⚠️ Cannot analyze DEV database - debug endpoint not working${NC}"
    fi
    
    if [[ "$LIVE_RESPONSE" == *"database_host"* ]]; then
        LIVE_DB=$(echo "$LIVE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('database_host', 'unknown'))" 2>/dev/null)
        echo -e "LIVE database: ${YELLOW}$LIVE_DB${NC}"
    else
        echo -e "${RED}⚠️ Cannot analyze LIVE database - debug endpoint not working${NC}"
    fi
    
    if [[ -n "$DEV_DB" && -n "$LIVE_DB" && "$DEV_DB" != "unknown" && "$LIVE_DB" != "unknown" ]]; then
        if [ "$DEV_DB" = "$LIVE_DB" ]; then
            echo -e "${RED}⚠️  WARNING: Both deployments using same database host: $DEV_DB${NC}"
            echo -e "${RED}   This is likely the cause of cross-deployment contamination!${NC}"
        else
            echo -e "${GREEN}✅ Database isolation confirmed: DEV($DEV_DB) ≠ LIVE($LIVE_DB)${NC}"
        fi
    fi
    
    echo -e "\n${BLUE}Cookie domain analysis:${NC}"
    if [[ "$DEV_RESPONSE" == *"cookie_domain"* ]]; then
        DEV_COOKIE=$(echo "$DEV_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('cookie_domain', 'unknown'))" 2>/dev/null)
        echo -e "DEV cookie domain: ${YELLOW}$DEV_COOKIE${NC}"
    else
        echo -e "${RED}⚠️ Cannot analyze DEV cookie domain - debug endpoint not working${NC}"
    fi
    
    if [[ "$LIVE_RESPONSE" == *"cookie_domain"* ]]; then
        LIVE_COOKIE=$(echo "$LIVE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('cookie_domain', 'unknown'))" 2>/dev/null)
        echo -e "LIVE cookie domain: ${YELLOW}$LIVE_COOKIE${NC}"
    else
        echo -e "${RED}⚠️ Cannot analyze LIVE cookie domain - debug endpoint not working${NC}"
    fi
    
    if [[ -n "$DEV_COOKIE" && -n "$LIVE_COOKIE" && "$DEV_COOKIE" != "unknown" && "$LIVE_COOKIE" != "unknown" ]]; then
        if [ "$DEV_COOKIE" = "$LIVE_COOKIE" ]; then
            echo -e "${RED}⚠️  WARNING: Both deployments using same cookie domain: $DEV_COOKIE${NC}"
            echo -e "${RED}   This could cause session contamination between deployments!${NC}"
        else
            echo -e "${GREEN}✅ Cookie domain isolation confirmed: DEV($DEV_COOKIE) ≠ LIVE($LIVE_COOKIE)${NC}"
        fi
    fi
else
    echo -e "${YELLOW}ℹ️  Python3 not available for JSON analysis${NC}"
fi

echo -e "\n${BLUE}🚀 Next Steps:${NC}"
echo "=============="
echo "1. If debug endpoints are not accessible, deploy the API changes first"
echo "2. Verify database connection strings are different between deployments"
echo "3. Check the Dockerfile_coolify for proper API URL replacement"
echo "4. Clear browser cache/cookies for both domains"
echo "5. Test in incognito mode to verify isolation"
echo "4. Check container logs: docker logs <container_name>"
