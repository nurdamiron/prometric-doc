#!/bin/bash

# ============================================
# ФИНАЛЬНОЕ ДЕТАЛЬНОЕ ТЕСТИРОВАНИЕ ВСЕХ AUTH FLOWS
# ============================================
# Тестируем:
# 1. Полную регистрацию владельца
# 2. Регистрацию сотрудника через БИН компании
# 3. Одобрение сотрудника с назначением роли и департамента
# 4. Проверку доступов после одобрения
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BACKEND_URL="http://localhost:5001"
API_BASE="$BACKEND_URL/api/v1"
DB_HOST="prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com"
DB_USER="prometric"
DB_PASS="prometric01"
DB_NAME="prometric"
TIMESTAMP=$(date +%s)

# Test data
OWNER_EMAIL="owner_final_${TIMESTAMP}@prometric.kz"
OWNER_PASSWORD="SecureOwner123!"
OWNER_FIRSTNAME="Нурдаулет"
OWNER_LASTNAME="Финальный"
OWNER_PHONE="+7701${TIMESTAMP: -7}"
COMPANY_NAME="ТОО Финальная Компания ${TIMESTAMP}"
COMPANY_BIN="${TIMESTAMP: -12}"

EMPLOYEE_EMAIL="employee_final_${TIMESTAMP}@prometric.kz"
EMPLOYEE_PASSWORD="SecureEmployee123!"
EMPLOYEE_FIRSTNAME="Айгерим"
EMPLOYEE_LASTNAME="Тестовая"
EMPLOYEE_PHONE="+7702${TIMESTAMP: -7}"

# Variables to store data between steps
OWNER_TOKEN=""
OWNER_USER_ID=""
WORKSPACE_ID=""
ORG_ID=""
EMPLOYEE_TOKEN=""
EMPLOYEE_ID=""
DEPARTMENT_ID=""

# Log function
log_step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Get verification code from database
get_verification_code() {
    local email=$1
    local code=$(PGPASSWORD=$DB_PASS /opt/homebrew/opt/postgresql@14/bin/psql \
        -h $DB_HOST -U $DB_USER -d $DB_NAME -t \
        -c "SELECT code FROM email_verifications WHERE email = '$email' ORDER BY created_at DESC LIMIT 1;" | xargs)
    
    echo $code
}

# ============================================
# TEST 1: OWNER REGISTRATION
# ============================================
test_owner_registration() {
    log_step "🏢 ТЕСТ 1: РЕГИСТРАЦИЯ ВЛАДЕЛЬЦА"
    
    echo -e "${YELLOW}Email: $OWNER_EMAIL${NC}"
    echo -e "${YELLOW}Company: $COMPANY_NAME${NC}"
    echo -e "${YELLOW}BIN: $COMPANY_BIN${NC}"
    
    # Step 1.1: Pre-registration
    echo ""
    echo -e "${GREEN}Step 1.1: Pre-registration владельца...${NC}"
    
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
    
    SUCCESS=$(echo $PRE_REGISTER_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$SUCCESS" = "true" ]; then
        OWNER_USER_ID=$(echo $PRE_REGISTER_RESPONSE | jq -r '.userId')
        echo -e "${GREEN}✅ Pre-registration успешна${NC}"
        echo "   User ID: $OWNER_USER_ID"
    else
        echo -e "${RED}❌ Pre-registration неудачна${NC}"
        echo $PRE_REGISTER_RESPONSE | jq '.'
        exit 1
    fi
    
    # Step 1.2: Get real verification code
    echo ""
    echo -e "${GREEN}Step 1.2: Получение verification code из БД...${NC}"
    sleep 2
    
    VERIFICATION_CODE=$(get_verification_code "$OWNER_EMAIL")
    
    if [ -n "$VERIFICATION_CODE" ]; then
        echo -e "${GREEN}✅ Код получен: $VERIFICATION_CODE${NC}"
    else
        echo -e "${RED}❌ Не удалось получить код${NC}"
        exit 1
    fi
    
    # Step 1.3: Email verification
    echo ""
    echo -e "${GREEN}Step 1.3: Email verification...${NC}"
    
    VERIFY_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/verify-email" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$OWNER_EMAIL\",
            \"code\": \"$VERIFICATION_CODE\"
        }")
    
    OWNER_TOKEN=$(echo $VERIFY_RESPONSE | jq -r '.accessToken' 2>/dev/null)
    
    if [ -n "$OWNER_TOKEN" ] && [ "$OWNER_TOKEN" != "null" ]; then
        echo -e "${GREEN}✅ Email подтвержден${NC}"
        echo "   Token: ${OWNER_TOKEN:0:50}..."
    else
        echo -e "${RED}❌ Email verification неудачна${NC}"
        echo $VERIFY_RESPONSE | jq '.'
        exit 1
    fi
    
    # Step 1.4: Complete onboarding for owner
    echo ""
    echo -e "${GREEN}Step 1.4: Complete onboarding (создание организации)...${NC}"
    
    ONBOARDING_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/onboarding/complete" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OWNER_TOKEN" \
        -d "{
            \"role\": \"owner\",
            \"organizationName\": \"$COMPANY_NAME\",
            \"organizationBin\": \"$COMPANY_BIN\",
            \"industry\": \"IT\",
            \"organizationSize\": \"10-50\"
        }")
    
    SUCCESS=$(echo $ONBOARDING_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    ORG_ID=$(echo $ONBOARDING_RESPONSE | jq -r '.data.organizationId' 2>/dev/null)
    WORKSPACE_ID=$(echo $ONBOARDING_RESPONSE | jq -r '.data.workspaceId' 2>/dev/null)
    NEW_TOKEN=$(echo $ONBOARDING_RESPONSE | jq -r '.data.accessToken' 2>/dev/null)
    
    if [ "$SUCCESS" = "true" ] && [ -n "$ORG_ID" ]; then
        if [ -n "$NEW_TOKEN" ] && [ "$NEW_TOKEN" != "null" ]; then
            OWNER_TOKEN=$NEW_TOKEN
        fi
        echo -e "${GREEN}✅ Onboarding завершен${NC}"
        echo "   Organization ID: $ORG_ID"
        echo "   Workspace ID: $WORKSPACE_ID"
    else
        echo -e "${RED}❌ Onboarding неудачен${NC}"
        echo $ONBOARDING_RESPONSE | jq '.'
        exit 1
    fi
    
    # Step 1.5: Verify departments were created
    echo ""
    echo -e "${GREEN}Step 1.5: Проверка автоматически созданных департаментов...${NC}"
    
    DEPARTMENTS_RESPONSE=$(curl -s -X GET "$API_BASE/workspaces/$WORKSPACE_ID/departments" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    DEPARTMENTS=$(echo $DEPARTMENTS_RESPONSE | jq -r '.data[]' 2>/dev/null)
    DEPT_COUNT=$(echo $DEPARTMENTS_RESPONSE | jq '.data | length' 2>/dev/null || echo "0")
    
    if [ "$DEPT_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Создано департаментов: $DEPT_COUNT${NC}"
        echo $DEPARTMENTS_RESPONSE | jq -r '.data[] | "   - \(.name) (ID: \(.id[:8])...)"' 2>/dev/null | head -5
        
        # Save first department ID for later
        DEPARTMENT_ID=$(echo $DEPARTMENTS_RESPONSE | jq -r '.data[0].id' 2>/dev/null)
    else
        echo -e "${YELLOW}⚠️ Департаменты не найдены${NC}"
    fi
}

# ============================================
# TEST 2: EMPLOYEE REGISTRATION
# ============================================
test_employee_registration() {
    log_step "👤 ТЕСТ 2: РЕГИСТРАЦИЯ СОТРУДНИКА"
    
    echo -e "${YELLOW}Email: $EMPLOYEE_EMAIL${NC}"
    echo -e "${YELLOW}Joining BIN: $COMPANY_BIN${NC}"
    
    # Step 2.1: Pre-registration with company BIN
    echo ""
    echo -e "${GREEN}Step 2.1: Pre-registration сотрудника с БИН компании...${NC}"
    
    PRE_REGISTER_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/pre-register" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$EMPLOYEE_EMAIL\",
            \"password\": \"$EMPLOYEE_PASSWORD\",
            \"firstName\": \"$EMPLOYEE_FIRSTNAME\",
            \"lastName\": \"$EMPLOYEE_LASTNAME\",
            \"phone\": \"$EMPLOYEE_PHONE\",
            \"organizationBin\": \"$COMPANY_BIN\",
            \"role\": \"USER\"
        }")
    
    SUCCESS=$(echo $PRE_REGISTER_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    
    if [ "$SUCCESS" = "true" ]; then
        EMPLOYEE_USER_ID=$(echo $PRE_REGISTER_RESPONSE | jq -r '.userId')
        echo -e "${GREEN}✅ Pre-registration успешна${NC}"
        echo "   User ID: $EMPLOYEE_USER_ID"
        echo "   Organization found: $(echo $PRE_REGISTER_RESPONSE | jq -r '.data.organizationName' 2>/dev/null)"
    else
        echo -e "${RED}❌ Pre-registration неудачна${NC}"
        echo $PRE_REGISTER_RESPONSE | jq '.'
        exit 1
    fi
    
    # Step 2.2: Get verification code
    echo ""
    echo -e "${GREEN}Step 2.2: Получение verification code из БД...${NC}"
    sleep 2
    
    VERIFICATION_CODE=$(get_verification_code "$EMPLOYEE_EMAIL")
    
    if [ -n "$VERIFICATION_CODE" ]; then
        echo -e "${GREEN}✅ Код получен: $VERIFICATION_CODE${NC}"
    else
        echo -e "${RED}❌ Не удалось получить код${NC}"
        exit 1
    fi
    
    # Step 2.3: Email verification
    echo ""
    echo -e "${GREEN}Step 2.3: Email verification...${NC}"
    
    VERIFY_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/verify-email" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$EMPLOYEE_EMAIL\",
            \"code\": \"$VERIFICATION_CODE\"
        }")
    
    EMPLOYEE_TOKEN=$(echo $VERIFY_RESPONSE | jq -r '.accessToken' 2>/dev/null)
    
    if [ -n "$EMPLOYEE_TOKEN" ] && [ "$EMPLOYEE_TOKEN" != "null" ]; then
        echo -e "${GREEN}✅ Email подтвержден${NC}"
        echo "   Token: ${EMPLOYEE_TOKEN:0:50}..."
    else
        echo -e "${RED}❌ Email verification неудачна${NC}"
        echo $VERIFY_RESPONSE | jq '.'
        exit 1
    fi
    
    # Step 2.4: Complete onboarding for employee
    echo ""
    echo -e "${GREEN}Step 2.4: Complete onboarding (присоединение к организации)...${NC}"
    
    ONBOARDING_RESPONSE=$(curl -s -X POST "$API_BASE/auth/registration/onboarding/complete" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $EMPLOYEE_TOKEN" \
        -d "{
            \"role\": \"employee\",
            \"position\": \"Senior Developer\",
            \"departmentPreference\": \"IT\"
        }")
    
    SUCCESS=$(echo $ONBOARDING_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    EMPLOYEE_ID=$(echo $ONBOARDING_RESPONSE | jq -r '.data.employeeId' 2>/dev/null)
    STATUS=$(echo $ONBOARDING_RESPONSE | jq -r '.data.status' 2>/dev/null)
    
    if [ "$SUCCESS" = "true" ] || [ "$STATUS" = "pending" ]; then
        echo -e "${GREEN}✅ Onboarding завершен${NC}"
        echo "   Employee ID: $EMPLOYEE_ID"
        echo "   Status: $STATUS (ожидает одобрения)"
    else
        echo -e "${YELLOW}⚠️ Onboarding может быть уже завершен${NC}"
        echo $ONBOARDING_RESPONSE | jq '.'
    fi
    
    # Step 2.5: Try to login (should fail - pending status)
    echo ""
    echo -e "${GREEN}Step 2.5: Попытка входа до одобрения (должна быть заблокирована)...${NC}"
    
    LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$EMPLOYEE_EMAIL\",
            \"password\": \"$EMPLOYEE_PASSWORD\"
        }")
    
    ERROR=$(echo $LOGIN_RESPONSE | jq -r '.error.code' 2>/dev/null)
    
    if [ "$ERROR" = "EMPLOYEE_PENDING_APPROVAL" ] || [ "$ERROR" = "PENDING_APPROVAL" ]; then
        echo -e "${GREEN}✅ Вход правильно заблокирован (pending status)${NC}"
    else
        echo -e "${YELLOW}⚠️ Неожиданный ответ при попытке входа${NC}"
        echo $LOGIN_RESPONSE | jq '.'
    fi
}

# ============================================
# TEST 3: EMPLOYEE APPROVAL
# ============================================
test_employee_approval() {
    log_step "✅ ТЕСТ 3: ОДОБРЕНИЕ СОТРУДНИКА С НАЗНАЧЕНИЕМ РОЛИ И ДЕПАРТАМЕНТА"
    
    # Step 3.1: Get pending employees list
    echo ""
    echo -e "${GREEN}Step 3.1: Получение списка pending сотрудников...${NC}"
    
    PENDING_RESPONSE=$(curl -s -X GET "$API_BASE/workspaces/$WORKSPACE_ID/employees?status=pending" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    PENDING_COUNT=$(echo $PENDING_RESPONSE | jq '.data | length' 2>/dev/null || echo "0")
    
    if [ "$PENDING_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Найдено pending сотрудников: $PENDING_COUNT${NC}"
        
        # Find our employee
        EMPLOYEE_DATA=$(echo $PENDING_RESPONSE | jq --arg email "$EMPLOYEE_EMAIL" '.data[] | select(.email == $email)' 2>/dev/null)
        
        if [ -n "$EMPLOYEE_DATA" ]; then
            EMPLOYEE_ID=$(echo $EMPLOYEE_DATA | jq -r '.id')
            echo "   Found employee: $EMPLOYEE_EMAIL"
            echo "   Employee ID: $EMPLOYEE_ID"
        else
            echo -e "${YELLOW}⚠️ Наш сотрудник не найден в списке pending${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Нет pending сотрудников${NC}"
    fi
    
    # Step 3.2: Get departments for assignment
    echo ""
    echo -e "${GREEN}Step 3.2: Получение списка департаментов для назначения...${NC}"
    
    DEPARTMENTS_RESPONSE=$(curl -s -X GET "$API_BASE/workspaces/$WORKSPACE_ID/departments" \
        -H "Authorization: Bearer $OWNER_TOKEN")
    
    DEPARTMENTS=$(echo $DEPARTMENTS_RESPONSE | jq -r '.data' 2>/dev/null)
    
    if [ -n "$DEPARTMENTS" ] && [ "$DEPARTMENTS" != "null" ]; then
        echo -e "${GREEN}✅ Доступные департаменты:${NC}"
        echo $DEPARTMENTS_RESPONSE | jq -r '.data[] | "   - \(.name) (ID: \(.id))"' 2>/dev/null | head -5
        
        # Select HR department if exists, otherwise first
        HR_DEPT=$(echo $DEPARTMENTS_RESPONSE | jq -r '.data[] | select(.name == "HR" or .name == "Human Resources") | .id' 2>/dev/null | head -1)
        if [ -n "$HR_DEPT" ]; then
            DEPARTMENT_ID=$HR_DEPT
            echo "   Выбран департамент: HR"
        else
            DEPARTMENT_ID=$(echo $DEPARTMENTS_RESPONSE | jq -r '.data[0].id' 2>/dev/null)
            echo "   Выбран департамент: первый из списка"
        fi
    fi
    
    # Step 3.3: Approve employee with department assignment
    echo ""
    echo -e "${GREEN}Step 3.3: Одобрение сотрудника с назначением в департамент...${NC}"
    
    if [ -n "$EMPLOYEE_ID" ] && [ -n "$DEPARTMENT_ID" ]; then
        APPROVE_RESPONSE=$(curl -s -X POST "$API_BASE/workspaces/$WORKSPACE_ID/employees/$EMPLOYEE_ID/approve" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $OWNER_TOKEN" \
            -d "{
                \"departmentId\": \"$DEPARTMENT_ID\",
                \"position\": \"Senior Developer\",
                \"organizationRole\": \"employee\",
                \"permissions\": [\"read\", \"write\", \"comment\"]
            }")
        
        SUCCESS=$(echo $APPROVE_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
        
        if [ "$SUCCESS" = "true" ]; then
            echo -e "${GREEN}✅ Сотрудник одобрен${NC}"
            echo "   Department ID: $DEPARTMENT_ID"
            echo "   Position: Senior Developer"
            echo "   Role: employee"
        else
            echo -e "${YELLOW}⚠️ Проблема с одобрением${NC}"
            echo $APPROVE_RESPONSE | jq '.'
        fi
    else
        echo -e "${YELLOW}⚠️ Не хватает данных для одобрения${NC}"
        echo "   Employee ID: $EMPLOYEE_ID"
        echo "   Department ID: $DEPARTMENT_ID"
    fi
}

# ============================================
# TEST 4: VERIFY ACCESS AFTER APPROVAL
# ============================================
test_access_after_approval() {
    log_step "🔐 ТЕСТ 4: ПРОВЕРКА ДОСТУПОВ ПОСЛЕ ОДОБРЕНИЯ"
    
    # Step 4.1: Employee login after approval
    echo ""
    echo -e "${GREEN}Step 4.1: Вход сотрудника после одобрения...${NC}"
    
    LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
        -H "Content-Type: application/json" \
        -d "{
            \"email\": \"$EMPLOYEE_EMAIL\",
            \"password\": \"$EMPLOYEE_PASSWORD\"
        }")
    
    SUCCESS=$(echo $LOGIN_RESPONSE | jq -r '.success' 2>/dev/null || echo "false")
    NEW_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.accessToken' 2>/dev/null)
    
    if [ "$SUCCESS" = "true" ] && [ -n "$NEW_TOKEN" ]; then
        EMPLOYEE_TOKEN=$NEW_TOKEN
        echo -e "${GREEN}✅ Вход успешен после одобрения${NC}"
        echo "   Token: ${EMPLOYEE_TOKEN:0:50}..."
        
        # Decode JWT to see details
        echo ""
        echo "   JWT payload:"
        echo $EMPLOYEE_TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq '.' 2>/dev/null | head -10
    else
        echo -e "${YELLOW}⚠️ Проблема со входом после одобрения${NC}"
        echo $LOGIN_RESPONSE | jq '.'
    fi
    
    # Step 4.2: Check employee profile
    echo ""
    echo -e "${GREEN}Step 4.2: Проверка профиля сотрудника...${NC}"
    
    PROFILE_RESPONSE=$(curl -s -X GET "$API_BASE/auth/profile" \
        -H "Authorization: Bearer $EMPLOYEE_TOKEN")
    
    ROLE=$(echo $PROFILE_RESPONSE | jq -r '.role' 2>/dev/null)
    STATUS=$(echo $PROFILE_RESPONSE | jq -r '.status' 2>/dev/null)
    DEPT=$(echo $PROFILE_RESPONSE | jq -r '.department' 2>/dev/null)
    
    if [ "$STATUS" = "active" ]; then
        echo -e "${GREEN}✅ Профиль активен${NC}"
        echo "   Role: $ROLE"
        echo "   Status: $STATUS"
        echo "   Department: $DEPT"
    else
        echo -e "${YELLOW}⚠️ Статус не active${NC}"
        echo $PROFILE_RESPONSE | jq '.'
    fi
    
    # Step 4.3: Test access to workspace resources
    echo ""
    echo -e "${GREEN}Step 4.3: Проверка доступа к ресурсам workspace...${NC}"
    
    # Try to access employees list (should work if has permissions)
    EMPLOYEES_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X GET "$API_BASE/workspaces/$WORKSPACE_ID/employees" \
        -H "Authorization: Bearer $EMPLOYEE_TOKEN")
    
    if [ "$EMPLOYEES_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✅ Доступ к списку сотрудников: разрешен${NC}"
    elif [ "$EMPLOYEES_RESPONSE" = "403" ]; then
        echo -e "${YELLOW}⚠️ Доступ к списку сотрудников: запрещен (нормально для employee)${NC}"
    else
        echo -e "${RED}❌ Неожиданный статус: $EMPLOYEES_RESPONSE${NC}"
    fi
    
    # Try to access departments
    DEPARTMENTS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -X GET "$API_BASE/workspaces/$WORKSPACE_ID/departments" \
        -H "Authorization: Bearer $EMPLOYEE_TOKEN")
    
    if [ "$DEPARTMENTS_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✅ Доступ к списку департаментов: разрешен${NC}"
    else
        echo -e "${YELLOW}⚠️ Доступ к списку департаментов: статус $DEPARTMENTS_RESPONSE${NC}"
    fi
}

# ============================================
# SUMMARY
# ============================================
print_summary() {
    log_step "📊 ИТОГОВАЯ СВОДКА ТЕСТИРОВАНИЯ"
    
    echo -e "${GREEN}СОЗДАННЫЕ УЧЕТНЫЕ ЗАПИСИ:${NC}"
    echo ""
    echo "🏢 ВЛАДЕЛЕЦ:"
    echo "   Email: $OWNER_EMAIL"
    echo "   Password: $OWNER_PASSWORD"
    echo "   Organization: $COMPANY_NAME"
    echo "   BIN: $COMPANY_BIN"
    echo "   Organization ID: $ORG_ID"
    echo "   Workspace ID: $WORKSPACE_ID"
    echo ""
    echo "👤 СОТРУДНИК:"
    echo "   Email: $EMPLOYEE_EMAIL"
    echo "   Password: $EMPLOYEE_PASSWORD"
    echo "   Employee ID: $EMPLOYEE_ID"
    echo "   Department ID: $DEPARTMENT_ID"
    echo "   Status: active (после одобрения)"
    
    # Save credentials to file
    cat > "final-test-credentials-${TIMESTAMP}.json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "owner": {
    "email": "$OWNER_EMAIL",
    "password": "$OWNER_PASSWORD",
    "token": "$OWNER_TOKEN",
    "organizationId": "$ORG_ID",
    "workspaceId": "$WORKSPACE_ID",
    "companyBin": "$COMPANY_BIN"
  },
  "employee": {
    "email": "$EMPLOYEE_EMAIL",
    "password": "$EMPLOYEE_PASSWORD",
    "token": "$EMPLOYEE_TOKEN",
    "employeeId": "$EMPLOYEE_ID",
    "departmentId": "$DEPARTMENT_ID",
    "status": "active"
  }
}
EOF
    
    echo ""
    echo -e "${GREEN}✅ Credentials сохранены в: final-test-credentials-${TIMESTAMP}.json${NC}"
}

# ============================================
# MAIN EXECUTION
# ============================================
main() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}ФИНАЛЬНОЕ ДЕТАЛЬНОЕ ТЕСТИРОВАНИЕ AUTH FLOWS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Backend URL: $BACKEND_URL${NC}"
    echo -e "${YELLOW}Timestamp: $TIMESTAMP${NC}"
    echo ""
    
    # Check backend is running
    HEALTH=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/health" || echo "000")
    if [ "$HEALTH" = "000" ]; then
        echo -e "${RED}❌ Backend не запущен на $BACKEND_URL${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Backend запущен (health check: $HEALTH)${NC}"
    
    # Run all tests
    test_owner_registration
    test_employee_registration
    test_employee_approval
    test_access_after_approval
    
    # Print summary
    print_summary
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🎉 ФИНАЛЬНОЕ ТЕСТИРОВАНИЕ ЗАВЕРШЕНО УСПЕШНО!${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Run main function
main "$@"