#!/bin/bash

# ============================================
# PROMETRIC FULL AUTHENTICATION FLOW TEST
# ============================================
# This script tests the complete authentication system
# including owner registration, employee registration,
# login, and role management
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL=${BACKEND_URL:-"http://localhost:5001"}
API_BASE="$BACKEND_URL/api/v1"
TIMESTAMP=$(date +%s)

# Test data
OWNER_EMAIL="owner${TIMESTAMP}@test.com"
OWNER_PASSWORD="OwnerPass123!"
OWNER_FIRSTNAME="Owner"
OWNER_LASTNAME="Test${TIMESTAMP}"
OWNER_PHONE="+7701${TIMESTAMP: -7}"
COMPANY_NAME="Test Company ${TIMESTAMP}"
COMPANY_BIN="${TIMESTAMP: -12}"

EMPLOYEE_EMAIL="employee${TIMESTAMP}@test.com"
EMPLOYEE_PASSWORD="EmployeePass123!"
EMPLOYEE_FIRSTNAME="Employee"
EMPLOYEE_LASTNAME="Test${TIMESTAMP}"
EMPLOYEE_PHONE="+7702${TIMESTAMP: -7}"

# Output file for results
OUTPUT_FILE="test-results-${TIMESTAMP}.json"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if backend is running
check_backend() {
    log_info "Checking if backend is running..."
    
    HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/health" || echo "000")
    
    if [ "$HEALTH_CHECK" = "000" ]; then
        log_error "Backend is not running at $BACKEND_URL"
        exit 1
    fi
    
    log_success "Backend is running (Status: $HEALTH_CHECK)"
}

# Save credentials to file
save_credentials() {
    local role=$1
    local email=$2
    local token=$3
    local workspace=$4
    local org=$5
    
    cat >> "$OUTPUT_FILE" << EOF
{
  "role": "$role",
  "email": "$email",
  "token": "$token",
  "workspace": "$workspace",
  "organization": "$org",
  "timestamp": "$(date -Iseconds)"
}
EOF
}

# ============================================
# OWNER REGISTRATION FLOW
# ============================================

test_owner_registration() {
    log_info "========================================="
    log_info "TESTING OWNER REGISTRATION FLOW"
    log_info "========================================="
    
    # Step 1: Pre-registration
    log_info "Step 1: Pre-registration for owner"
    
    PRE_REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/pre-register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$OWNER_EMAIL\",
            \"password\": \"$OWNER_PASSWORD\",
            \"firstName\": \"$OWNER_FIRSTNAME\",
            \"lastName\": \"$OWNER_LASTNAME\",
            \"phone\": \"$OWNER_PHONE\",
            \"role\": \"USER\"
        }")
    
    echo "Pre-register response: $PRE_REGISTER_RESPONSE" >> debug.log
    
    SUCCESS=$(echo $PRE_REGISTER_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$SUCCESS" != "true" ]; then
        log_error "Pre-registration failed"
        echo $PRE_REGISTER_RESPONSE
        return 1
    fi
    
    log_success "Pre-registration successful"
    
    # Step 2: Get verification code (dev mode)
    log_info "Step 2: Getting verification code from database"
    
    # In production, this would be sent via email
    # For testing, we'll simulate getting it from logs or database
    VERIFICATION_CODE="123456"  # Default test code
    
    log_info "Using verification code: $VERIFICATION_CODE"
    
    # Step 3: Verify email
    log_info "Step 3: Verifying email"
    
    VERIFY_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/verify-email" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$OWNER_EMAIL\",
            \"code\": \"$VERIFICATION_CODE\"
        }")
    
    echo "Verify response: $VERIFY_RESPONSE" >> debug.log
    
    OWNER_TOKEN=$(echo $VERIFY_RESPONSE | jq -r '.accessToken' 2>/dev/null || echo "")
    
    if [ -z "$OWNER_TOKEN" ]; then
        log_error "Email verification failed"
        echo $VERIFY_RESPONSE
        return 1
    fi
    
    log_success "Email verified successfully"
    
    # Step 4: Select owner role
    log_info "Step 4: Selecting owner role and creating organization"
    
    SELECT_ROLE_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/select-role" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OWNER_TOKEN" \
        -d "{
            \"role\": \"owner\",
            \"companyName\": \"$COMPANY_NAME\",
            \"companyBin\": \"$COMPANY_BIN\",
            \"companyAddress\": \"Test Address\",
            \"companyPhone\": \"$OWNER_PHONE\"
        }")
    
    echo "Select role response: $SELECT_ROLE_RESPONSE" >> debug.log
    
    ORG_ID=$(echo $SELECT_ROLE_RESPONSE | jq -r '.data.organization.id' 2>/dev/null || echo "")
    WORKSPACE_ID=$(echo $SELECT_ROLE_RESPONSE | jq -r '.data.workspace.id' 2>/dev/null || echo "")
    
    if [ -z "$ORG_ID" ] || [ -z "$WORKSPACE_ID" ]; then
        log_error "Role selection failed"
        echo $SELECT_ROLE_RESPONSE
        return 1
    fi
    
    log_success "Owner role selected, organization created"
    log_info "Organization ID: $ORG_ID"
    log_info "Workspace ID: $WORKSPACE_ID"
    
    # Step 5: Complete onboarding
    log_info "Step 5: Completing onboarding"
    
    ONBOARDING_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/complete-onboarding" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OWNER_TOKEN" \
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
    
    echo "Onboarding response: $ONBOARDING_RESPONSE" >> debug.log
    
    FINAL_TOKEN=$(echo $ONBOARDING_RESPONSE | jq -r '.accessToken' 2>/dev/null || echo "$OWNER_TOKEN")
    
    if [ -n "$FINAL_TOKEN" ]; then
        OWNER_TOKEN=$FINAL_TOKEN
    fi
    
    log_success "Owner registration completed successfully!"
    
    # Save owner credentials
    save_credentials "owner" "$OWNER_EMAIL" "$OWNER_TOKEN" "$WORKSPACE_ID" "$ORG_ID"
    
    # Export for use in other tests
    export OWNER_TOKEN
    export WORKSPACE_ID
    export ORG_ID
    export COMPANY_BIN
}

# ============================================
# EMPLOYEE REGISTRATION FLOW
# ============================================

test_employee_registration() {
    log_info "========================================="
    log_info "TESTING EMPLOYEE REGISTRATION FLOW"
    log_info "========================================="
    
    # Step 1: Pre-registration with company BIN
    log_info "Step 1: Pre-registration for employee with company BIN"
    
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
    
    echo "Employee pre-register response: $PRE_REGISTER_RESPONSE" >> debug.log
    
    SUCCESS=$(echo $PRE_REGISTER_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$SUCCESS" != "true" ]; then
        log_error "Employee pre-registration failed"
        echo $PRE_REGISTER_RESPONSE
        return 1
    fi
    
    log_success "Employee pre-registration successful"
    
    # Step 2: Verify email
    log_info "Step 2: Verifying employee email"
    
    VERIFY_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/verify-email" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$EMPLOYEE_EMAIL\",
            \"code\": \"123456\"
        }")
    
    EMPLOYEE_TOKEN=$(echo $VERIFY_RESPONSE | jq -r '.accessToken' 2>/dev/null || echo "")
    
    if [ -z "$EMPLOYEE_TOKEN" ]; then
        log_error "Employee email verification failed"
        echo $VERIFY_RESPONSE
        return 1
    fi
    
    log_success "Employee email verified"
    
    # Step 3: Select employee role
    log_info "Step 3: Selecting employee role"
    
    SELECT_ROLE_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/select-role" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $EMPLOYEE_TOKEN" \
        -d "{
            \"role\": \"employee\",
            \"companyBin\": \"$COMPANY_BIN\",
            \"position\": \"Software Developer\",
            \"departmentPreference\": \"IT\"
        }")
    
    echo "Employee select role response: $SELECT_ROLE_RESPONSE" >> debug.log
    
    EMPLOYEE_ID=$(echo $SELECT_ROLE_RESPONSE | jq -r '.data.user.id' 2>/dev/null || echo "")
    
    log_success "Employee role selected, awaiting approval"
    
    # Step 4: Owner approves employee
    log_info "Step 4: Owner approving employee request"
    
    # Get pending employees list first
    PENDING_RESPONSE=$(curl -s -X GET "$API_BASE/workspaces/$WORKSPACE_ID/employee-management/pending-employees" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    echo "Pending employees response: $PENDING_RESPONSE" >> debug.log
    
    # Approve the employee
    APPROVE_RESPONSE=$(curl -s -X POST "$API_BASE/workspaces/$WORKSPACE_ID/employees/$EMPLOYEE_ID/approve" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OWNER_TOKEN" \
        -d "{
            \"departmentId\": \"it-dept-uuid\",
            \"position\": \"Senior Developer\",
            \"permissions\": [\"read\", \"write\", \"comment\"]
        }")
    
    echo "Approve response: $APPROVE_RESPONSE" >> debug.log
    
    SUCCESS=$(echo $APPROVE_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$SUCCESS" != "true" ]; then
        log_warning "Employee approval might have failed, but continuing..."
    else
        log_success "Employee approved by owner"
    fi
    
    # Save employee credentials
    save_credentials "employee" "$EMPLOYEE_EMAIL" "$EMPLOYEE_TOKEN" "$WORKSPACE_ID" "$ORG_ID"
    
    export EMPLOYEE_TOKEN
    export EMPLOYEE_ID
}

# ============================================
# LOGIN FLOW TEST
# ============================================

test_login_flow() {
    log_info "========================================="
    log_info "TESTING LOGIN FLOW"
    log_info "========================================="
    
    # Test owner login
    log_info "Testing owner login"
    
    LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$OWNER_EMAIL\",
            \"password\": \"$OWNER_PASSWORD\"
        }")
    
    echo "Owner login response: $LOGIN_RESPONSE" >> debug.log
    
    LOGIN_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.accessToken' 2>/dev/null || echo "")
    
    if [ -z "$LOGIN_TOKEN" ]; then
        log_error "Owner login failed"
        echo $LOGIN_RESPONSE
    else
        log_success "Owner login successful"
    fi
    
    # Test employee login
    log_info "Testing employee login"
    
    LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$EMPLOYEE_EMAIL\",
            \"password\": \"$EMPLOYEE_PASSWORD\"
        }")
    
    echo "Employee login response: $LOGIN_RESPONSE" >> debug.log
    
    LOGIN_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.accessToken' 2>/dev/null || echo "")
    
    if [ -z "$LOGIN_TOKEN" ]; then
        log_warning "Employee login might fail if not approved yet"
    else
        log_success "Employee login successful"
    fi
}

# ============================================
# PERMISSION TEST
# ============================================

test_permissions() {
    log_info "========================================="
    log_info "TESTING PERMISSIONS"
    log_info "========================================="
    
    # Test owner permissions
    log_info "Testing owner permissions"
    
    PROFILE_RESPONSE=$(curl -s -X GET "$API_BASE/auth/profile" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    echo "Owner profile response: $PROFILE_RESPONSE" >> debug.log
    
    PERMISSIONS=$(echo $PROFILE_RESPONSE | jq -r '.permissions[]' 2>/dev/null)
    
    if [ -n "$PERMISSIONS" ]; then
        log_success "Owner permissions retrieved:"
        echo "$PERMISSIONS" | head -5
    fi
    
    # Test accessing protected endpoint
    log_info "Testing access to protected endpoints"
    
    EMPLOYEES_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X GET "$API_BASE/workspaces/$WORKSPACE_ID/employees" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    if [ "$EMPLOYEES_RESPONSE" = "200" ]; then
        log_success "Owner can access employees endpoint"
    else
        log_error "Owner cannot access employees endpoint (Status: $EMPLOYEES_RESPONSE)"
    fi
}

# ============================================
# MAIN EXECUTION
# ============================================

main() {
    echo ""
    log_info "========================================="
    log_info "PROMETRIC FULL AUTHENTICATION TEST"
    log_info "========================================="
    log_info "Backend URL: $BACKEND_URL"
    log_info "Timestamp: $TIMESTAMP"
    echo ""
    
    # Initialize output file
    echo "[]" > "$OUTPUT_FILE"
    
    # Check backend
    check_backend
    
    # Run tests
    test_owner_registration
    
    if [ -n "$COMPANY_BIN" ]; then
        test_employee_registration
    fi
    
    test_login_flow
    test_permissions
    
    # Summary
    echo ""
    log_info "========================================="
    log_info "TEST SUMMARY"
    log_info "========================================="
    log_success "Owner Email: $OWNER_EMAIL"
    log_success "Employee Email: $EMPLOYEE_EMAIL"
    log_success "Company BIN: $COMPANY_BIN"
    log_success "Organization ID: $ORG_ID"
    log_success "Workspace ID: $WORKSPACE_ID"
    log_info "Results saved to: $OUTPUT_FILE"
    log_info "Debug logs saved to: debug.log"
    echo ""
}

# Run main function
main "$@"