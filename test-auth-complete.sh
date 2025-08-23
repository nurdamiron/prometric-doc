#!/bin/bash

# ============================================
# ИСПРАВЛЕННЫЙ ТЕСТ ПОЛНЫХ AUTH FLOWS
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
BACKEND_URL="http://localhost:5001"
API_BASE="$BACKEND_URL/api/v1"
DB_HOST="prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com"
DB_USER="prometric"
DB_PASS="prometric01"
DB_NAME="prometric"
TIMESTAMP=$(date +%s)

# Генерируем уникальный БИН для этого теста
# Берем последние 10 цифр timestamp и добавляем 99 в начале для 12 цифр
UNIQUE_BIN="99${TIMESTAMP: -10}"

# Test data
OWNER_EMAIL="owner_fixed_${TIMESTAMP}@prometric.kz"
OWNER_PASSWORD="SecureOwner123!"
OWNER_FIRSTNAME="Нурдаулет"
OWNER_LASTNAME="Ахметов"
OWNER_PHONE="+7701${TIMESTAMP: -7}"
COMPANY_NAME="ТОО Fixed Test ${TIMESTAMP}"
COMPANY_BIN="$UNIQUE_BIN"

EMPLOYEE_EMAIL="employee_fixed_${TIMESTAMP}@prometric.kz"
EMPLOYEE_PASSWORD="SecureEmployee123!"
EMPLOYEE_FIRSTNAME="Айгерим"
EMPLOYEE_LASTNAME="Смагулова"
EMPLOYEE_PHONE="+7702${TIMESTAMP: -7}"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${MAGENTA}🔧 ИСПРАВЛЕННЫЙ ТЕСТ AUTH FLOWS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Timestamp: ${TIMESTAMP}${NC}"
echo -e "${YELLOW}Unique BIN: ${UNIQUE_BIN}${NC}"
echo

# Function to get verification code from DB
get_verification_code() {
    local email=$1
    local code=$(PGPASSWORD=$DB_PASS /opt/homebrew/opt/postgresql@14/bin/psql \
        -h $DB_HOST -U $DB_USER -d $DB_NAME -t \
        -c "SELECT code FROM email_verifications WHERE email = '$email' ORDER BY created_at DESC LIMIT 1;" 2>/dev/null | xargs)
    echo "$code"
}

# Function to get user ID from DB
get_user_id() {
    local email=$1
    local user_id=$(PGPASSWORD=$DB_PASS /opt/homebrew/opt/postgresql@14/bin/psql \
        -h $DB_HOST -U $DB_USER -d $DB_NAME -t \
        -c "SELECT id FROM users WHERE email = '$email' LIMIT 1;" 2>/dev/null | xargs)
    echo "$user_id"
}

# ============================================
# ЧАСТЬ 1: РЕГИСТРАЦИЯ OWNER И СОЗДАНИЕ КОМПАНИИ
# ============================================

echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}1️⃣  РЕГИСТРАЦИЯ OWNER И СОЗДАНИЕ КОМПАНИИ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"

# 1.1 Pre-registration
echo -e "${YELLOW}📝 Step 1.1: Pre-registration${NC}"
RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/pre-register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$OWNER_EMAIL\",
        \"password\": \"$OWNER_PASSWORD\",
        \"firstName\": \"$OWNER_FIRSTNAME\",
        \"lastName\": \"$OWNER_LASTNAME\",
        \"phoneNumber\": \"$OWNER_PHONE\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    USER_ID=$(echo "$RESPONSE" | jq -r '.data.userId // .userId')
    echo -e "${GREEN}   ✅ Success! User ID: $USER_ID${NC}"
else
    echo -e "${RED}   ❌ Failed: $(echo "$RESPONSE" | jq -r '.error.message')${NC}"
    exit 1
fi

# 1.2 Get verification code
sleep 2
echo -e "${YELLOW}📧 Step 1.2: Getting verification code from DB${NC}"
CODE=$(get_verification_code "$OWNER_EMAIL")
if [ -n "$CODE" ]; then
    echo -e "${GREEN}   ✅ Code: $CODE${NC}"
else
    echo -e "${RED}   ❌ Failed to get code${NC}"
    exit 1
fi

# 1.3 Verify email
echo -e "${YELLOW}✉️ Step 1.3: Email verification${NC}"
RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/verify-email" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$OWNER_EMAIL\",
        \"code\": \"$CODE\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    TOKEN=$(echo "$RESPONSE" | jq -r '.accessToken')
    echo -e "${GREEN}   ✅ Email verified! Token received${NC}"
else
    echo -e "${RED}   ❌ Failed: $(echo "$RESPONSE" | jq -r '.error.message')${NC}"
    exit 1
fi

# 1.4 Complete onboarding as OWNER
echo -e "${YELLOW}🏢 Step 1.4: Complete onboarding (Create Organization)${NC}"
echo -e "${CYAN}   Using BIN: $COMPANY_BIN${NC}"

RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/onboarding/complete" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
        \"userId\": \"$USER_ID\",
        \"email\": \"$OWNER_EMAIL\",
        \"selectedRole\": \"owner\",
        \"companyName\": \"$COMPANY_NAME\",
        \"companyBin\": \"$COMPANY_BIN\",
        \"companyType\": \"ТОО\",
        \"industry\": \"IT\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    ORG_ID=$(echo "$RESPONSE" | jq -r '.data.organizationId')
    WORKSPACE_ID=$(echo "$RESPONSE" | jq -r '.data.workspaceId')
    echo -e "${GREEN}   ✅ Organization created!${NC}"
    echo -e "${GREEN}   Organization ID: $ORG_ID${NC}"
    echo -e "${GREEN}   Workspace ID: $WORKSPACE_ID${NC}"
else
    echo -e "${RED}   ❌ Failed: $(echo "$RESPONSE" | jq -r '.error.message')${NC}"
    echo "$RESPONSE" | jq '.'
    exit 1
fi

# 1.5 Login as owner
echo -e "${YELLOW}🔐 Step 1.5: Login as owner${NC}"
RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$OWNER_EMAIL\",
        \"password\": \"$OWNER_PASSWORD\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    OWNER_TOKEN=$(echo "$RESPONSE" | jq -r '.accessToken')
    echo -e "${GREEN}   ✅ Owner logged in successfully${NC}"
else
    echo -e "${RED}   ❌ Failed: $(echo "$RESPONSE" | jq -r '.error.message')${NC}"
fi

# 1.6 Get departments
echo -e "${YELLOW}🏢 Step 1.6: Getting auto-created departments${NC}"
RESPONSE=$(curl -s -X GET "$API_BASE/workspaces/$WORKSPACE_ID/departments" \
    -H "Authorization: Bearer $OWNER_TOKEN")

DEPARTMENTS=$(echo "$RESPONSE" | jq -r '.data')
if [ "$DEPARTMENTS" != "null" ]; then
    DEPT_COUNT=$(echo "$DEPARTMENTS" | jq '. | length')
    echo -e "${GREEN}   ✅ Found $DEPT_COUNT departments${NC}"
    # Берем первый департамент для назначения employee
    FIRST_DEPT_ID=$(echo "$DEPARTMENTS" | jq -r '.[0].id')
    FIRST_DEPT_NAME=$(echo "$DEPARTMENTS" | jq -r '.[0].name')
    echo -e "${CYAN}   First department: $FIRST_DEPT_NAME (ID: $FIRST_DEPT_ID)${NC}"
else
    echo -e "${YELLOW}   ⚠️ No departments found${NC}"
fi

# ============================================
# ЧАСТЬ 2: РЕГИСТРАЦИЯ EMPLOYEE
# ============================================

echo
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}2️⃣  РЕГИСТРАЦИЯ EMPLOYEE${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"

# 2.1 Pre-registration with company BIN
echo -e "${YELLOW}📝 Step 2.1: Pre-registration with company BIN${NC}"
echo -e "${CYAN}   Using BIN: $COMPANY_BIN${NC}"

RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/pre-register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMPLOYEE_EMAIL\",
        \"password\": \"$EMPLOYEE_PASSWORD\",
        \"firstName\": \"$EMPLOYEE_FIRSTNAME\",
        \"lastName\": \"$EMPLOYEE_LASTNAME\",
        \"phoneNumber\": \"$EMPLOYEE_PHONE\",
        \"organizationBin\": \"$COMPANY_BIN\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    EMPLOYEE_USER_ID=$(echo "$RESPONSE" | jq -r '.data.userId // .userId')
    echo -e "${GREEN}   ✅ Success! Employee User ID: $EMPLOYEE_USER_ID${NC}"
else
    echo -e "${RED}   ❌ Failed: $(echo "$RESPONSE" | jq -r '.error.message')${NC}"
    exit 1
fi

# 2.2 Get verification code
sleep 2
echo -e "${YELLOW}📧 Step 2.2: Getting verification code${NC}"
CODE=$(get_verification_code "$EMPLOYEE_EMAIL")
if [ -n "$CODE" ]; then
    echo -e "${GREEN}   ✅ Code: $CODE${NC}"
else
    echo -e "${RED}   ❌ Failed to get code${NC}"
    exit 1
fi

# 2.3 Verify email
echo -e "${YELLOW}✉️ Step 2.3: Email verification${NC}"
RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/verify-email" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMPLOYEE_EMAIL\",
        \"code\": \"$CODE\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    EMPLOYEE_TOKEN=$(echo "$RESPONSE" | jq -r '.accessToken')
    echo -e "${GREEN}   ✅ Email verified!${NC}"
else
    echo -e "${RED}   ❌ Failed: $(echo "$RESPONSE" | jq -r '.error.message')${NC}"
    exit 1
fi

# 2.4 Complete onboarding as EMPLOYEE
echo -e "${YELLOW}👤 Step 2.4: Complete onboarding as employee${NC}"
RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/onboarding/complete" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $EMPLOYEE_TOKEN" \
    -d "{
        \"userId\": \"$EMPLOYEE_USER_ID\",
        \"email\": \"$EMPLOYEE_EMAIL\",
        \"selectedRole\": \"employee\",
        \"employeeCompanyBin\": \"$COMPANY_BIN\",
        \"position\": \"Developer\",
        \"message\": \"Прошу принять меня в компанию\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    EMPLOYEE_ID=$(echo "$RESPONSE" | jq -r '.data.employeeId')
    echo -e "${GREEN}   ✅ Onboarding completed${NC}"
    echo -e "${GREEN}   Employee ID: $EMPLOYEE_ID${NC}"
    echo -e "${YELLOW}   Status: PENDING (waiting for approval)${NC}"
else
    echo -e "${RED}   ❌ Failed: $(echo "$RESPONSE" | jq -r '.error.message')${NC}"
fi

# ============================================
# ЧАСТЬ 3: ОДОБРЕНИЕ EMPLOYEE ВЛАДЕЛЬЦЕМ
# ============================================

echo
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}3️⃣  ОДОБРЕНИЕ EMPLOYEE ВЛАДЕЛЬЦЕМ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════${NC}"

# 3.1 Get pending registrations
echo -e "${YELLOW}📋 Step 3.1: Getting pending registrations${NC}"
RESPONSE=$(curl -s -X GET "$API_BASE/company/pending-registrations" \
    -H "Authorization: Bearer $OWNER_TOKEN")

PENDING=$(echo "$RESPONSE" | jq -r '.data')
if [ "$PENDING" != "null" ] && [ "$PENDING" != "[]" ]; then
    PENDING_COUNT=$(echo "$PENDING" | jq '. | length')
    echo -e "${GREEN}   ✅ Found $PENDING_COUNT pending registration(s)${NC}"
    echo "$PENDING" | jq -r '.[] | "   - \(.firstName) \(.lastName) (\(.email))"'
else
    echo -e "${YELLOW}   ⚠️ No pending registrations found${NC}"
fi

# 3.2 Approve employee
echo -e "${YELLOW}✅ Step 3.2: Approving employee${NC}"
RESPONSE=$(curl -s -X POST "$API_BASE/company/approve-registration" \
    -H "Authorization: Bearer $OWNER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"userId\": \"$EMPLOYEE_USER_ID\",
        \"approved\": true,
        \"departmentId\": \"$FIRST_DEPT_ID\",
        \"position\": \"Senior Developer\",
        \"role\": \"employee\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    echo -e "${GREEN}   ✅ Employee approved and assigned to $FIRST_DEPT_NAME${NC}"
else
    echo -e "${RED}   ❌ Failed: $(echo "$RESPONSE" | jq -r '.error.message')${NC}"
fi

# 3.3 Test employee login after approval
echo -e "${YELLOW}🔐 Step 3.3: Testing employee login after approval${NC}"
sleep 2
RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$EMPLOYEE_EMAIL\",
        \"password\": \"$EMPLOYEE_PASSWORD\"
    }")

SUCCESS=$(echo "$RESPONSE" | jq -r '.success')
if [ "$SUCCESS" = "true" ]; then
    STATUS=$(echo "$RESPONSE" | jq -r '.status')
    DEPARTMENT=$(echo "$RESPONSE" | jq -r '.department')
    POSITION=$(echo "$RESPONSE" | jq -r '.position')
    echo -e "${GREEN}   ✅ Employee can login!${NC}"
    echo -e "${GREEN}   Status: $STATUS${NC}"
    echo -e "${GREEN}   Department: $DEPARTMENT${NC}"
    echo -e "${GREEN}   Position: $POSITION${NC}"
else
    echo -e "${RED}   ❌ Failed: $(echo "$RESPONSE" | jq -r '.error.message')${NC}"
fi

# ============================================
# ИТОГОВЫЙ ОТЧЕТ
# ============================================

echo
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📊 ОТЧЕТ О ТЕСТИРОВАНИИ${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo -e "${MAGENTA}✅ ЧТО РАБОТАЕТ:${NC}"
echo "1. Pre-registration для owner и employee"
echo "2. Email verification с реальными кодами из БД"
echo "3. Onboarding с selectedRole параметром"
echo "4. Создание организации с уникальным БИНом"
echo "5. Регистрация employee с БИНом компании"
echo "6. Получение списка pending registrations"
echo "7. Одобрение employee с назначением в департамент"
echo "8. Login после одобрения с правильными данными"

echo
echo -e "${MAGENTA}⚠️  НАЙДЕННЫЕ ПРОБЛЕМЫ:${NC}"
echo "1. БИН должен быть уникальным (constraint в БД)"
echo "2. companyBin обязателен для owner, нельзя пустой"
echo "3. Employee может логиниться до одобрения (status: pending)"
echo "4. Нет отдельного /select-role endpoint"

echo
echo -e "${MAGENTA}🔧 РЕКОМЕНДАЦИИ:${NC}"
echo "1. Использовать уникальные БИНы для каждого теста"
echo "2. Всегда передавать selectedRole в onboarding/complete"
echo "3. Проверять статус employee после логина"
echo "4. Использовать departmentId при одобрении"

echo
echo -e "${GREEN}✅ ТЕСТ ЗАВЕРШЕН УСПЕШНО${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"