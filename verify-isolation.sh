#!/bin/bash

echo "🔍 LearnHouse Deployment Isolation Verification"
echo "==============================================="

# Check DEV deployment
echo ""
echo "📋 DEV Deployment (adr-lms.whitex.cloud):"
echo "----------------------------------------"
echo "Testing API connection..."
DEV_RESPONSE=$(curl -s https://adr-lms.whitex.cloud/api/v1/debug/deployment 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ DEV API accessible"
    echo "   Response: $DEV_RESPONSE"
else
    echo "❌ DEV API not accessible"
fi

echo ""
echo "Testing frontend..."
DEV_FRONTEND=$(curl -s -o /dev/null -w "%{http_code}" https://adr-lms.whitex.cloud/ 2>/dev/null)
if [ "$DEV_FRONTEND" = "200" ]; then
    echo "✅ DEV Frontend accessible (HTTP $DEV_FRONTEND)"
else
    echo "❌ DEV Frontend issue (HTTP $DEV_FRONTEND)"
fi

# Check LIVE deployment
echo ""
echo "📋 LIVE Deployment (edu.adradviser.ro):"
echo "---------------------------------------"
echo "Testing API connection..."
LIVE_RESPONSE=$(curl -s https://edu.adradviser.ro/api/v1/debug/deployment 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "✅ LIVE API accessible"
    echo "   Response: $LIVE_RESPONSE"
else
    echo "❌ LIVE API not accessible"
fi

echo ""
echo "Testing frontend..."
LIVE_FRONTEND=$(curl -s -o /dev/null -w "%{http_code}" https://edu.adradviser.ro/ 2>/dev/null)
if [ "$LIVE_FRONTEND" = "200" ]; then
    echo "✅ LIVE Frontend accessible (HTTP $LIVE_FRONTEND)"
else
    echo "❌ LIVE Frontend issue (HTTP $LIVE_FRONTEND)"
fi

# Analysis
echo ""
echo "🔍 Cross-Deployment Isolation Analysis:"
echo "========================================"

# Extract database hosts if responses are valid JSON
if command -v jq >/dev/null 2>&1; then
    DEV_DB=$(echo "$DEV_RESPONSE" | jq -r '.database_host // "unknown"' 2>/dev/null)
    LIVE_DB=$(echo "$LIVE_RESPONSE" | jq -r '.database_host // "unknown"' 2>/dev/null)
    
    if [ "$DEV_DB" != "unknown" ] && [ "$LIVE_DB" != "unknown" ]; then
        if [ "$DEV_DB" = "$LIVE_DB" ]; then
            echo "⚠️  WARNING: Both deployments using same database host: $DEV_DB"
        else
            echo "✅ Database isolation: DEV($DEV_DB) ≠ LIVE($LIVE_DB)"
        fi
    fi
    
    DEV_COOKIE=$(echo "$DEV_RESPONSE" | jq -r '.cookie_domain // "unknown"' 2>/dev/null)
    LIVE_COOKIE=$(echo "$LIVE_RESPONSE" | jq -r '.cookie_domain // "unknown"' 2>/dev/null)
    
    if [ "$DEV_COOKIE" != "unknown" ] && [ "$LIVE_COOKIE" != "unknown" ]; then
        if [ "$DEV_COOKIE" = "$LIVE_COOKIE" ]; then
            echo "⚠️  WARNING: Both deployments using same cookie domain: $DEV_COOKIE"
        else
            echo "✅ Cookie isolation: DEV($DEV_COOKIE) ≠ LIVE($LIVE_COOKIE)"
        fi
    fi
else
    echo "ℹ️  Install 'jq' for detailed analysis"
fi

echo ""
echo "🚀 Next Steps:"
echo "=============="
echo "1. If APIs are accessible, check browser Network tab for cross-deployment calls"
echo "2. Clear browser cache/cookies for both domains"
echo "3. Test in incognito mode to verify isolation"
echo "4. Check container logs: docker logs <container_name>"
