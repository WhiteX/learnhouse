#!/bin/bash
# Database Isolation Verification Script
# This script will verify database isolation between DEV and LIVE deployments

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Database Isolation Verification Script ===${NC}"
echo -e "${YELLOW}This script will verify database isolation between DEV and LIVE deployments${NC}"
echo ""

# First check API debug endpoints for database information
echo -e "${BLUE}Checking API debug endpoints for database information...${NC}"
DEV_URL="https://adr-lms.whitex.cloud"
LIVE_URL="https://edu.adradviser.ro"

DEV_DEBUG=$(curl -s -m 10 -k "$DEV_URL/api/v1/debug/deployment" || echo '{"error":"Failed to connect"}')
LIVE_DEBUG=$(curl -s -m 10 -k "$LIVE_URL/api/v1/debug/deployment" || echo '{"error":"Failed to connect"}')

# Extract values using Python if available
if command -v python3 &> /dev/null; then
  echo -e "${GREEN}✓${NC} Python3 available for JSON parsing"
  DEV_DB_HOST=$(echo "$DEV_DEBUG" | python3 -c "import sys, json; print(json.load(sys.stdin).get('database_host', 'unknown'))" 2>/dev/null)
  LIVE_DB_HOST=$(echo "$LIVE_DEBUG" | python3 -c "import sys, json; print(json.load(sys.stdin).get('database_host', 'unknown'))" 2>/dev/null)
  DEV_DB_NAME=$(echo "$DEV_DEBUG" | python3 -c "import sys, json; print(json.load(sys.stdin).get('database_name', 'unknown'))" 2>/dev/null)
  LIVE_DB_NAME=$(echo "$LIVE_DEBUG" | python3 -c "import sys, json; print(json.load(sys.stdin).get('database_name', 'unknown'))" 2>/dev/null)
  
  echo -e "${YELLOW}From API Debug:${NC}"
  echo -e "DEV DB: Host=${DEV_DB_HOST}, Name=${DEV_DB_NAME}"
  echo -e "LIVE DB: Host=${LIVE_DB_HOST}, Name=${LIVE_DB_NAME}"
  
  if [ "$DEV_DB_HOST" == "$LIVE_DB_HOST" ]; then
    echo -e "${RED}⚠️  WARNING: Both deployments using same database host: $DEV_DB_HOST${NC}"
  else
    if [ "$DEV_DB_HOST" != "unknown" ] && [ "$LIVE_DB_HOST" != "unknown" ]; then
      echo -e "${GREEN}✓ Database hosts are properly isolated between deployments${NC}"
    else
      echo -e "${YELLOW}⚠️  Could not verify database hosts from API - falling back to manual checking${NC}"
    fi
  fi
else
  echo -e "${YELLOW}Python3 not available for JSON parsing - falling back to manual checking${NC}"
fi

echo -e "\n${BLUE}Continuing with direct database verification...${NC}"

# Function to extract database connection details from environment variables
extract_db_details() {
  # Get connection string from environment
  local conn_string="$1"
  
  # Extract username, password, host, port, and database name
  local username=$(echo "$conn_string" | sed -E 's/^postgresql:\/\/([^:]+):.*/\1/')
  local password=$(echo "$conn_string" | sed -E 's/^postgresql:\/\/[^:]+:([^@]+)@.*/\1/')
  local host=$(echo "$conn_string" | sed -E 's/^postgresql:\/\/[^@]+@([^:]+):.*/\1/')
  local port=$(echo "$conn_string" | sed -E 's/^postgresql:\/\/[^@]+@[^:]+:([^\/]+)\/.*/\1/')
  local dbname=$(echo "$conn_string" | sed -E 's/^postgresql:\/\/[^@]+@[^\/]+\/([^?]+).*/\1/')
  
  echo "Username: $username"
  echo "Password: [HIDDEN]"
  echo "Host: $host"
  echo "Port: $port"
  echo "Database: $dbname"
  
  # Return values in a specific format for later use
  echo "$host|$port|$dbname|$username|$password"
}

# Function to test database connection
test_db_connection() {
  local details="$1"
  local host=$(echo "$details" | cut -d'|' -f1)
  local port=$(echo "$details" | cut -d'|' -f2)
  local dbname=$(echo "$details" | cut -d'|' -f3)
  local username=$(echo "$details" | cut -d'|' -f4)
  local password=$(echo "$details" | cut -d'|' -f5)
  
  echo -e "${BLUE}Testing connection to $dbname on $host:$port...${NC}"
  
  # Try to connect and run a simple query
  if PGPASSWORD="$password" psql -h "$host" -p "$port" -U "$username" -d "$dbname" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Successfully connected to database $dbname on $host${NC}"
    return 0
  else
    echo -e "${RED}✗ Failed to connect to database $dbname on $host${NC}"
    return 1
  fi
}

# Function to test if two databases share the same server
test_db_isolation() {
  local dev_details="$1"
  local live_details="$2"
  
  local dev_host=$(echo "$dev_details" | cut -d'|' -f1)
  local live_host=$(echo "$live_details" | cut -d'|' -f1)
  
  echo -e "${BLUE}Checking database isolation...${NC}"
  
  if [ "$dev_host" == "$live_host" ]; then
    echo -e "${RED}✗ ISOLATION FAILURE: DEV and LIVE environments are using the same database host: $dev_host${NC}"
    echo -e "${RED}  This will cause cross-deployment contamination!${NC}"
    return 1
  else
    echo -e "${GREEN}✓ Database isolation confirmed: DEV($dev_host) ≠ LIVE($live_host)${NC}"
    return 0
  fi
}

# Main execution

# Get connection strings from environment or prompt user
if [ -z "$DEV_DB_URL" ]; then
  echo -e "${YELLOW}DEV database connection string not found in environment.${NC}"
  echo -e "Enter DEV database connection string (postgresql://user:pass@host:port/dbname):"
  read -p "> " DEV_DB_URL
fi

if [ -z "$LIVE_DB_URL" ]; then
  echo -e "${YELLOW}LIVE database connection string not found in environment.${NC}"
  echo -e "Enter LIVE database connection string (postgresql://user:pass@host:port/dbname):"
  read -p "> " LIVE_DB_URL
fi

# Extract connection details
echo -e "\n${BLUE}DEV Database Details:${NC}"
DEV_DETAILS=$(extract_db_details "$DEV_DB_URL")
echo ""

echo -e "${BLUE}LIVE Database Details:${NC}"
LIVE_DETAILS=$(extract_db_details "$LIVE_DB_URL")
echo ""

# Test connections
DEV_CONNECTION_OK=false
LIVE_CONNECTION_OK=false

if test_db_connection "$DEV_DETAILS"; then
  DEV_CONNECTION_OK=true
fi

if test_db_connection "$LIVE_DETAILS"; then
  LIVE_CONNECTION_OK=true
fi

# If both connections work, test isolation
if $DEV_CONNECTION_OK && $LIVE_CONNECTION_OK; then
  test_db_isolation "$DEV_DETAILS" "$LIVE_DETAILS"
  ISOLATION_RESULT=$?
else
  echo -e "${YELLOW}⚠️ Could not verify isolation because one or both database connections failed.${NC}"
  ISOLATION_RESULT=2
fi

echo ""
echo -e "${BLUE}=== Verification Results ===${NC}"
if [ $ISOLATION_RESULT -eq 0 ]; then
  echo -e "${GREEN}✓ SUCCESS: Databases are properly isolated${NC}"
elif [ $ISOLATION_RESULT -eq 1 ]; then
  echo -e "${RED}✗ FAILURE: Databases are not isolated!${NC}"
  echo -e "${YELLOW}Action required: Update your database connection strings to use different hosts.${NC}"
  echo -e "See DATABASE_ISOLATION_FIX.md for details."
else
  echo -e "${YELLOW}⚠️ INCONCLUSIVE: Could not verify isolation${NC}"
  echo -e "Fix connection issues and try again."
fi

exit $ISOLATION_RESULT
