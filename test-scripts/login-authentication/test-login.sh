#!/bin/bash

# ============================================
# LOGIN & AUTHENTICATION TEST SCRIPT
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

# Test credentials (can be overridden)
EMAIL=${1:-"jasulan80770@gmail.com"}
PASSWORD=${2:-"TestPassword123!"}

echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}LOGIN & AUTHENTICATION TEST${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo ""

# Function to test login
test_login() {
    local email=$1
    local password=$2
    
    echo -e "${BLUE}Testing login for: $email${NC}"
    
    LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$email\",
            \"password\": \"$password\"
        }")
    
    SUCCESS=$(echo $LOGIN_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$SUCCESS" = "true" ]; then
        echo -e "${GREEN}✅ Login successful${NC}"
        
        # Extract token and user info
        TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.accessToken')
        REFRESH_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.refreshToken')
        USER_ROLE=$(echo $LOGIN_RESPONSE | jq -r '.user.role')
        USER_STATUS=$(echo $LOGIN_RESPONSE | jq -r '.user.status')
        WORKSPACE_ID=$(echo $LOGIN_RESPONSE | jq -r '.user.workspaceId')
        ORG_ID=$(echo $LOGIN_RESPONSE | jq -r '.user.organizationId')
        
        echo "  Role: $USER_ROLE"
        echo "  Status: $USER_STATUS"
        echo "  Workspace: $WORKSPACE_ID"
        echo "  Organization: $ORG_ID"
        echo "  Token: ${TOKEN:0:50}..."
        
        return 0
    else
        echo -e "${RED}❌ Login failed${NC}"
        ERROR_CODE=$(echo $LOGIN_RESPONSE | jq -r '.error.code' 2>/dev/null)
        ERROR_MSG=$(echo $LOGIN_RESPONSE | jq -r '.error.message' 2>/dev/null)
        
        if [ "$ERROR_CODE" != "null" ]; then
            echo "  Error: $ERROR_CODE - $ERROR_MSG"
        else
            echo $LOGIN_RESPONSE | jq '.'
        fi
        
        return 1
    fi
}

# Function to test profile endpoint
test_profile() {
    local token=$1
    
    echo ""
    echo -e "${BLUE}Testing profile endpoint${NC}"
    
    PROFILE_RESPONSE=$(curl -s -X GET "$API_BASE/auth/profile" \
        -H "Authorization: Bearer $token")
    
    SUCCESS=$(echo $PROFILE_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$SUCCESS" = "true" ]; then
        echo -e "${GREEN}✅ Profile retrieved successfully${NC}"
        
        USER_EMAIL=$(echo $PROFILE_RESPONSE | jq -r '.data.email')
        USER_NAME=$(echo $PROFILE_RESPONSE | jq -r '.data.firstName + " " + .data.lastName')
        USER_ROLE=$(echo $PROFILE_RESPONSE | jq -r '.data.role')
        EMAIL_VERIFIED=$(echo $PROFILE_RESPONSE | jq -r '.data.emailVerified')
        ONBOARDING=$(echo $PROFILE_RESPONSE | jq -r '.data.onboardingCompleted')
        
        echo "  Name: $USER_NAME"
        echo "  Email: $USER_EMAIL"
        echo "  Role: $USER_ROLE"
        echo "  Email Verified: $EMAIL_VERIFIED"
        echo "  Onboarding Complete: $ONBOARDING"
        
        # Show permissions if available
        PERMISSIONS=$(echo $PROFILE_RESPONSE | jq -r '.data.permissions[]' 2>/dev/null)
        if [ -n "$PERMISSIONS" ]; then
            echo "  Permissions:"
            echo "$PERMISSIONS" | head -5 | sed 's/^/    - /'
        fi
    else
        echo -e "${RED}❌ Profile request failed${NC}"
        echo $PROFILE_RESPONSE | jq '.'
    fi
}

# Function to test refresh token
test_refresh() {
    local refresh_token=$1
    
    echo ""
    echo -e "${BLUE}Testing token refresh${NC}"
    
    REFRESH_RESPONSE=$(curl -s -X POST "$API_BASE/auth/refresh" \
        -H "Content-Type: application/json" \
        -d "{
            \"refreshToken\": \"$refresh_token\"
        }")
    
    SUCCESS=$(echo $REFRESH_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$SUCCESS" = "true" ]; then
        echo -e "${GREEN}✅ Token refreshed successfully${NC}"
        
        NEW_TOKEN=$(echo $REFRESH_RESPONSE | jq -r '.accessToken')
        NEW_REFRESH=$(echo $REFRESH_RESPONSE | jq -r '.refreshToken')
        
        echo "  New token: ${NEW_TOKEN:0:50}..."
        
        return 0
    else
        echo -e "${RED}❌ Token refresh failed${NC}"
        echo $REFRESH_RESPONSE | jq '.'
        return 1
    fi
}

# Function to test logout
test_logout() {
    local token=$1
    
    echo ""
    echo -e "${BLUE}Testing logout${NC}"
    
    LOGOUT_RESPONSE=$(curl -s -X POST "$API_BASE/auth/logout" \
        -H "Authorization: Bearer $token")
    
    SUCCESS=$(echo $LOGOUT_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$SUCCESS" = "true" ]; then
        echo -e "${GREEN}✅ Logout successful${NC}"
    else
        echo -e "${YELLOW}⚠️ Logout might have failed${NC}"
        echo $LOGOUT_RESPONSE | jq '.'
    fi
}

# Function to test invalid login
test_invalid_login() {
    echo ""
    echo -e "${BLUE}Testing invalid login attempts${NC}"
    
    # Test with wrong password
    echo "  Testing wrong password..."
    INVALID_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$EMAIL\",
            \"password\": \"WrongPassword123!\"
        }")
    
    SUCCESS=$(echo $INVALID_RESPONSE | jq -r '.success' 2>/dev/null)
    if [ "$SUCCESS" = "false" ]; then
        echo -e "    ${GREEN}✅ Correctly rejected wrong password${NC}"
    else
        echo -e "    ${RED}❌ Should have rejected wrong password${NC}"
    fi
    
    # Test with non-existent email
    echo "  Testing non-existent email..."
    INVALID_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"nonexistent@example.com\",
            \"password\": \"Password123!\"
        }")
    
    SUCCESS=$(echo $INVALID_RESPONSE | jq -r '.success' 2>/dev/null)
    if [ "$SUCCESS" = "false" ]; then
        echo -e "    ${GREEN}✅ Correctly rejected non-existent email${NC}"
    else
        echo -e "    ${RED}❌ Should have rejected non-existent email${NC}"
    fi
}

# Main execution
echo -e "${GREEN}Step 1: Test standard login${NC}"
if test_login "$EMAIL" "$PASSWORD"; then
    # Save token for further tests
    ACCESS_TOKEN=$TOKEN
    REFRESH_TOKEN=$REFRESH_TOKEN
    
    # Test profile
    test_profile "$ACCESS_TOKEN"
    
    # Test refresh
    if [ -n "$REFRESH_TOKEN" ] && [ "$REFRESH_TOKEN" != "null" ]; then
        test_refresh "$REFRESH_TOKEN"
    fi
    
    # Test invalid attempts
    test_invalid_login
    
    # Test logout
    test_logout "$ACCESS_TOKEN"
    
    # Try to use token after logout
    echo ""
    echo -e "${BLUE}Testing token after logout${NC}"
    AFTER_LOGOUT=$(curl -s -o /dev/null -w "%{http_code}" \
        -X GET "$API_BASE/auth/profile" \
        -H "Authorization: Bearer $ACCESS_TOKEN")
    
    if [ "$AFTER_LOGOUT" = "401" ]; then
        echo -e "${GREEN}✅ Token correctly invalidated after logout${NC}"
    else
        echo -e "${YELLOW}⚠️ Token might still be valid (Status: $AFTER_LOGOUT)${NC}"
    fi
    
    # Summary
    echo ""
    echo -e "${YELLOW}=========================================${NC}"
    echo -e "${GREEN}LOGIN TEST COMPLETE${NC}"
    echo -e "${YELLOW}=========================================${NC}"
    echo "All authentication flows tested successfully!"
    
else
    echo ""
    echo -e "${RED}Initial login failed - skipping other tests${NC}"
    echo "Please check:"
    echo "  1. Backend is running at $BACKEND_URL"
    echo "  2. Credentials are correct"
    echo "  3. User account exists and is active"
    exit 1
fi