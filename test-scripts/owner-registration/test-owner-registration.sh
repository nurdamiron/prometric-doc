#!/bin/bash

# ============================================
# OWNER REGISTRATION TEST SCRIPT
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
BACKEND_URL=${BACKEND_URL:-"http://localhost:5001"}
API_BASE="$BACKEND_URL/api/v1"
TIMESTAMP=$(date +%s)

# Test data
EMAIL="owner${TIMESTAMP}@prometric.kz"
PASSWORD="SecurePass123!"
FIRSTNAME="Жасулан"
LASTNAME="Тестов"
PHONE="+7701${TIMESTAMP: -7}"
COMPANY_NAME="ТОО Тестовая Компания ${TIMESTAMP}"
COMPANY_BIN="${TIMESTAMP: -12}"

echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}OWNER REGISTRATION TEST${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo "Email: $EMAIL"
echo "Company: $COMPANY_NAME"
echo "BIN: $COMPANY_BIN"
echo ""

# Step 1: Pre-registration
echo -e "${GREEN}Step 1: Pre-registration${NC}"

PRE_REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/pre-register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMAIL\",
        \"password\": \"$PASSWORD\",
        \"firstName\": \"$FIRSTNAME\",
        \"lastName\": \"$LASTNAME\",
        \"phone\": \"$PHONE\",
        \"role\": \"USER\"
    }")

SUCCESS=$(echo $PRE_REGISTER_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")

if [ "$SUCCESS" = "true" ]; then
    echo -e "${GREEN}✅ Pre-registration successful${NC}"
    USER_ID=$(echo $PRE_REGISTER_RESPONSE | jq -r '.userId')
    echo "User ID: $USER_ID"
else
    echo -e "${RED}❌ Pre-registration failed${NC}"
    echo $PRE_REGISTER_RESPONSE | jq '.'
    exit 1
fi

# Step 2: Email verification
echo ""
echo -e "${GREEN}Step 2: Email verification${NC}"

# In dev mode, we use a default code
VERIFICATION_CODE="123456"

# Wait a moment for email to be "sent"
sleep 2

VERIFY_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/verify-email" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMAIL\",
        \"code\": \"$VERIFICATION_CODE\"
    }")

TOKEN=$(echo $VERIFY_RESPONSE | jq -r '.accessToken' 2>/dev/null)

if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
    echo -e "${GREEN}✅ Email verified successfully${NC}"
    echo "Token received: ${TOKEN:0:50}..."
else
    echo -e "${RED}❌ Email verification failed${NC}"
    echo $VERIFY_RESPONSE | jq '.'
    exit 1
fi

# Step 3: Select owner role
echo ""
echo -e "${GREEN}Step 3: Select owner role${NC}"

SELECT_ROLE_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/select-role" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
        \"role\": \"owner\",
        \"companyName\": \"$COMPANY_NAME\",
        \"companyBin\": \"$COMPANY_BIN\",
        \"companyAddress\": \"г. Алматы, ул. Абая 100\",
        \"companyPhone\": \"$PHONE\"
    }")

ORG_ID=$(echo $SELECT_ROLE_RESPONSE | jq -r '.data.organization.id' 2>/dev/null)
WORKSPACE_ID=$(echo $SELECT_ROLE_RESPONSE | jq -r '.data.workspace.id' 2>/dev/null)

if [ -n "$ORG_ID" ] && [ "$ORG_ID" != "null" ]; then
    echo -e "${GREEN}✅ Owner role selected${NC}"
    echo "Organization ID: $ORG_ID"
    echo "Workspace ID: $WORKSPACE_ID"
else
    echo -e "${RED}❌ Role selection failed${NC}"
    echo $SELECT_ROLE_RESPONSE | jq '.'
    exit 1
fi

# Step 4: Complete onboarding
echo ""
echo -e "${GREEN}Step 4: Complete onboarding${NC}"

ONBOARDING_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/complete-onboarding" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
        \"preferences\": {
            \"theme\": \"light\",
            \"language\": \"ru\",
            \"notifications\": true,
            \"timezone\": \"Asia/Almaty\"
        },
        \"organizationSettings\": {
            \"industry\": \"IT\",
            \"employeeCount\": \"10-50\",
            \"fiscalYearStart\": \"01-01\"
        }
    }")

FINAL_TOKEN=$(echo $ONBOARDING_RESPONSE | jq -r '.accessToken' 2>/dev/null)
ONBOARDING_SUCCESS=$(echo $ONBOARDING_RESPONSE | jq -r '.success' 2>/dev/null)

if [ "$ONBOARDING_SUCCESS" = "true" ] || [ -n "$FINAL_TOKEN" ]; then
    echo -e "${GREEN}✅ Onboarding completed${NC}"
    
    if [ -n "$FINAL_TOKEN" ] && [ "$FINAL_TOKEN" != "null" ]; then
        TOKEN=$FINAL_TOKEN
    fi
else
    echo -e "${YELLOW}⚠️ Onboarding might already be completed${NC}"
fi

# Step 5: Test login
echo ""
echo -e "${GREEN}Step 5: Test login${NC}"

LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMAIL\",
        \"password\": \"$PASSWORD\"
    }")

LOGIN_SUCCESS=$(echo $LOGIN_RESPONSE | jq -r '.success' 2>/dev/null)

if [ "$LOGIN_SUCCESS" = "true" ]; then
    echo -e "${GREEN}✅ Login successful${NC}"
else
    echo -e "${RED}❌ Login failed${NC}"
    echo $LOGIN_RESPONSE | jq '.'
fi

# Save credentials
echo ""
echo -e "${YELLOW}=========================================${NC}"
echo -e "${GREEN}OWNER REGISTRATION COMPLETE${NC}"
echo -e "${YELLOW}=========================================${NC}"

cat > "owner-credentials-${TIMESTAMP}.json" << EOF
{
  "email": "$EMAIL",
  "password": "$PASSWORD",
  "token": "$TOKEN",
  "organizationId": "$ORG_ID",
  "workspaceId": "$WORKSPACE_ID",
  "companyBin": "$COMPANY_BIN",
  "timestamp": "$(date -Iseconds)"
}
EOF

echo "Credentials saved to: owner-credentials-${TIMESTAMP}.json"
echo ""
echo "You can now use these credentials to:"
echo "1. Register employees with BIN: $COMPANY_BIN"
echo "2. Login with email: $EMAIL"
echo "3. Access workspace: $WORKSPACE_ID"