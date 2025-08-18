#!/bin/bash

# ============================================
# EMPLOYEE REGISTRATION TEST SCRIPT
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKEND_URL=${BACKEND_URL:-"http://localhost:5001"}
API_BASE="$BACKEND_URL/api/v1"
TIMESTAMP=$(date +%s)

# Check if we have owner credentials
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <company_bin> [owner_token] [workspace_id]${NC}"
    echo "Example: $0 123456789012"
    echo ""
    echo "Or set environment variables:"
    echo "  COMPANY_BIN, OWNER_TOKEN, WORKSPACE_ID"
    exit 1
fi

# Get parameters
COMPANY_BIN=${1:-$COMPANY_BIN}
OWNER_TOKEN=${2:-$OWNER_TOKEN}
WORKSPACE_ID=${3:-$WORKSPACE_ID}

# Employee test data
EMPLOYEE_EMAIL="employee${TIMESTAMP}@prometric.kz"
EMPLOYEE_PASSWORD="EmployeePass123!"
EMPLOYEE_FIRSTNAME="Асет"
EMPLOYEE_LASTNAME="Тест${TIMESTAMP}"
EMPLOYEE_PHONE="+7702${TIMESTAMP: -7}"

echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}EMPLOYEE REGISTRATION TEST${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo "Company BIN: $COMPANY_BIN"
echo "Employee Email: $EMPLOYEE_EMAIL"
echo ""

# Step 1: Pre-registration with company BIN
echo -e "${GREEN}Step 1: Pre-registration with company BIN${NC}"

PRE_REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/pre-register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMPLOYEE_EMAIL\",
        \"password\": \"$EMPLOYEE_PASSWORD\",
        \"firstName\": \"$EMPLOYEE_FIRSTNAME\",
        \"lastName\": \"$EMPLOYEE_LASTNAME\",
        \"phone\": \"$EMPLOYEE_PHONE\",
        \"companyBin\": \"$COMPANY_BIN\",
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
    
    # Check if company exists
    if echo "$PRE_REGISTER_RESPONSE" | grep -q "not found"; then
        echo -e "${YELLOW}⚠️ Company with BIN $COMPANY_BIN might not exist${NC}"
        echo "Please make sure to register an owner first with this BIN"
    fi
    exit 1
fi

# Step 2: Email verification
echo ""
echo -e "${GREEN}Step 2: Email verification${NC}"

VERIFICATION_CODE="123456"
sleep 2

VERIFY_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/verify-email" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMPLOYEE_EMAIL\",
        \"code\": \"$VERIFICATION_CODE\"
    }")

EMPLOYEE_TOKEN=$(echo $VERIFY_RESPONSE | jq -r '.accessToken' 2>/dev/null)

if [ -n "$EMPLOYEE_TOKEN" ] && [ "$EMPLOYEE_TOKEN" != "null" ]; then
    echo -e "${GREEN}✅ Email verified successfully${NC}"
    echo "Token received: ${EMPLOYEE_TOKEN:0:50}..."
else
    echo -e "${RED}❌ Email verification failed${NC}"
    echo $VERIFY_RESPONSE | jq '.'
    exit 1
fi

# Step 3: Select employee role
echo ""
echo -e "${GREEN}Step 3: Select employee role${NC}"

SELECT_ROLE_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/select-role" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $EMPLOYEE_TOKEN" \
    -d "{
        \"role\": \"employee\",
        \"companyBin\": \"$COMPANY_BIN\",
        \"position\": \"Software Developer\",
        \"departmentPreference\": \"IT\"
    }")

REQUEST_ID=$(echo $SELECT_ROLE_RESPONSE | jq -r '.data.joinRequest.id' 2>/dev/null)
EMPLOYEE_ID=$(echo $SELECT_ROLE_RESPONSE | jq -r '.data.user.id' 2>/dev/null)

if [ -n "$REQUEST_ID" ] || [ -n "$EMPLOYEE_ID" ]; then
    echo -e "${GREEN}✅ Employee role selected${NC}"
    echo "Status: Pending approval"
    echo "Employee ID: $EMPLOYEE_ID"
else
    echo -e "${RED}❌ Role selection failed${NC}"
    echo $SELECT_ROLE_RESPONSE | jq '.'
    exit 1
fi

# Step 4: Complete onboarding (limited)
echo ""
echo -e "${GREEN}Step 4: Complete onboarding (limited access)${NC}"

ONBOARDING_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/complete-onboarding" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $EMPLOYEE_TOKEN" \
    -d "{
        \"preferences\": {
            \"theme\": \"light\",
            \"language\": \"ru\",
            \"notifications\": true,
            \"timezone\": \"Asia/Almaty\"
        },
        \"profileInfo\": {
            \"skills\": [\"JavaScript\", \"React\", \"Node.js\"],
            \"experience\": \"3 years\",
            \"education\": \"Bachelor's in Computer Science\"
        }
    }")

echo -e "${GREEN}✅ Onboarding completed (awaiting approval)${NC}"

# Step 5: Owner approval (if we have owner token)
if [ -n "$OWNER_TOKEN" ] && [ "$OWNER_TOKEN" != "null" ]; then
    echo ""
    echo -e "${BLUE}Step 5: Owner approval process${NC}"
    
    # First, get list of pending employees
    echo "Getting pending employees list..."
    
    PENDING_RESPONSE=$(curl -s -X GET "$API_BASE/workspaces/$WORKSPACE_ID/employee-management/pending-employees" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    echo "Pending employees:"
    echo $PENDING_RESPONSE | jq '.data[]' 2>/dev/null || echo "No pending employees found"
    
    # Approve the employee
    echo ""
    echo "Approving employee..."
    
    APPROVE_RESPONSE=$(curl -s -X POST "$API_BASE/workspaces/$WORKSPACE_ID/employees/$EMPLOYEE_ID/approve" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OWNER_TOKEN" \
        -d "{
            \"departmentId\": \"it-dept\",
            \"position\": \"Senior Developer\",
            \"permissions\": [\"read\", \"write\", \"comment\"]
        }")
    
    APPROVE_SUCCESS=$(echo $APPROVE_RESPONSE | jq -r '.success' 2>/dev/null)
    
    if [ "$APPROVE_SUCCESS" = "true" ]; then
        echo -e "${GREEN}✅ Employee approved by owner${NC}"
    else
        echo -e "${YELLOW}⚠️ Approval might have failed or already approved${NC}"
        echo $APPROVE_RESPONSE | jq '.'
    fi
else
    echo ""
    echo -e "${YELLOW}⚠️ No owner token provided - manual approval required${NC}"
    echo "To approve this employee, the owner should:"
    echo "1. Login to the system"
    echo "2. Go to Employee Management"
    echo "3. Find pending employee: $EMPLOYEE_EMAIL"
    echo "4. Click 'Approve' and assign department"
fi

# Step 6: Test employee login
echo ""
echo -e "${GREEN}Step 6: Test employee login${NC}"

sleep 2  # Give time for approval to process

LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMPLOYEE_EMAIL\",
        \"password\": \"$EMPLOYEE_PASSWORD\"
    }")

LOGIN_SUCCESS=$(echo $LOGIN_RESPONSE | jq -r '.success' 2>/dev/null)
STATUS=$(echo $LOGIN_RESPONSE | jq -r '.user.status' 2>/dev/null)

if [ "$LOGIN_SUCCESS" = "true" ]; then
    echo -e "${GREEN}✅ Employee login successful${NC}"
    echo "Status: $STATUS"
else
    if [ "$STATUS" = "pending_approval" ]; then
        echo -e "${YELLOW}⚠️ Employee login pending (awaiting approval)${NC}"
    else
        echo -e "${RED}❌ Employee login failed${NC}"
    fi
    echo $LOGIN_RESPONSE | jq '.'
fi

# Save credentials
echo ""
echo -e "${YELLOW}=========================================${NC}"
echo -e "${GREEN}EMPLOYEE REGISTRATION COMPLETE${NC}"
echo -e "${YELLOW}=========================================${NC}"

cat > "employee-credentials-${TIMESTAMP}.json" << EOF
{
  "email": "$EMPLOYEE_EMAIL",
  "password": "$EMPLOYEE_PASSWORD",
  "token": "$EMPLOYEE_TOKEN",
  "employeeId": "$EMPLOYEE_ID",
  "companyBin": "$COMPANY_BIN",
  "status": "$STATUS",
  "timestamp": "$(date -Iseconds)"
}
EOF

echo "Credentials saved to: employee-credentials-${TIMESTAMP}.json"
echo ""
echo "Employee details:"
echo "  Email: $EMPLOYEE_EMAIL"
echo "  Password: $EMPLOYEE_PASSWORD"
echo "  Status: ${STATUS:-pending_approval}"
echo ""

if [ "$STATUS" != "active" ]; then
    echo -e "${YELLOW}Note: Employee needs owner approval to access the system${NC}"
fi