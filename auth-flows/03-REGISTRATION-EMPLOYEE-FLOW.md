# 👥 EMPLOYEE REGISTRATION FLOW - Детальная документация

## 📋 Общее описание
Employee registration flow - это процесс регистрации сотрудника в существующей организации. Сотрудник регистрируется через БИН компании и требует одобрения владельца.

## 🎯 Последовательность шагов
1. Pre-registration с БИН компании (organizationBin)
2. Email verification
3. Onboarding completion с selectedRole="employee"
4. Ожидание одобрения владельца (pending status)
5. Активация после одобрения

⚠️ **ВАЖНО**: Нет endpoint `/select-role`. Роль передается через `selectedRole` при вызове `/onboarding/complete`

## 📊 Детальный процесс

### ШАГ 1: Employee Pre-Registration

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/registration/pre-register
Content-Type: application/json

{
  "email": "employee_1755885515@mail.kz",
  "password": "EmployeePass123!",
  "firstName": "Айгуль",
  "lastName": "Смагулова",
  "phoneNumber": "+77017654321",
  "organizationBin": "987654321098"  // ⚠️ БИН компании для присоединения
  // role, companyName НЕ передаются на этом этапе
}
```

#### 📥 RESPONSE SUCCESS (201 Created)
```json
{
  "success": true,
  "message": "Employee registered successfully. Please verify your email.",
  "data": {
    "userId": "7d103ddc-2f02-46df-90ae-f769d5950c20",
    "email": "employee_1755885515@mail.kz",
    "role": "employee",
    "registrationStatus": "email_verification",
    "emailVerified": false,
    "requiresEmailVerification": true,
    "organizationFound": true,
    "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
    "organizationName": "ТОО Успешный Бизнес Новый"
  }
}
```

#### 📥 RESPONSE ERROR - БИН не найден (404 Not Found)
```json
{
  "success": false,
  "error": {
    "code": "ORGANIZATION_NOT_FOUND",
    "type": "NotFoundError",
    "message": "Организация с указанным БИН не найдена. Проверьте правильность БИН или обратитесь к администратору."
  },
  "path": "/api/v1/auth/registration/pre-register",
  "timestamp": "2025-08-22T18:30:00.000Z"
}
```

#### 📥 RESPONSE ERROR - Email уже зарегистрирован (409 Conflict)
```json
{
  "success": false,
  "error": {
    "code": "EMAIL_EXISTS",
    "type": "ConflictError",
    "message": "Пользователь с таким email уже существует"
  },
  "path": "/api/v1/auth/registration/pre-register",
  "timestamp": "2025-08-22T18:30:00.000Z"
}
```

### ШАГ 2: Email Verification

#### 🔑 Получение кода из базы данных
```bash
PGPASSWORD=prometric01 /opt/homebrew/opt/postgresql@14/bin/psql \
  -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
  -U prometric \
  -d prometric \
  -t -c "SELECT code FROM email_verifications WHERE email = 'employee_1755885515@mail.kz' ORDER BY created_at DESC LIMIT 1;"

# Результат: 584923
```

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/registration/verify-email
Content-Type: application/json

{
  "email": "employee_1755885515@mail.kz",
  "code": "584923"
}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "message": "Email verified successfully",
  "data": {
    "email": "employee_1755885515@mail.kz",
    "userId": "7d103ddc-2f02-46df-90ae-f769d5950c20",
    "emailVerified": true,
    "registrationStatus": "onboarding",
    "nextStep": "complete_onboarding",
    "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a"
  }
}
```

### ШАГ 3: Employee Onboarding Completion

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/registration/onboarding/complete
Content-Type: application/json

{
  "email": "employee_1755885515@mail.kz",
  "userId": "7d103ddc-2f02-46df-90ae-f769d5950c20",
  "selectedRole": "employee",
  "companyName": "ТОО Успешный Бизнес Новый",
  "bin": "987654321098",
  "companyType": "ТОО",
  "industry": "IT"
}
```

#### 📥 RESPONSE SUCCESS (200 OK) - Pending Status
```json
{
  "success": true,
  "message": "Employee onboarding completed. Waiting for admin approval.",
  "accessToken": null,
  "userId": "7d103ddc-2f02-46df-90ae-f769d5950c20",
  "email": "employee_1755885515@mail.kz",
  "firstName": "Айгуль",
  "lastName": "Смагулова",
  "fullName": "Айгуль Смагулова",
  "role": "employee",
  "status": "pending",
  "registrationStatus": "pending",
  "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
  "workspaceId": null,
  "employeeId": "60f9366c-aa3f-4e6a-9ce8-8370f2e3daba",
  "position": null,
  "department": null,
  "departmentId": null,
  "phoneNumber": "+77017654321",
  "avatar": null,
  "onboardingCompleted": false,
  "hasCompany": true,
  "isFirstLogin": true,
  "emailVerified": true,
  "isActive": false,
  "requiresApproval": true,
  "approvalStatus": "pending",
  "message": "Ваша заявка отправлена на рассмотрение администратору организации"
}
```

### ШАГ 4: Попытка входа до одобрения

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/login
Content-Type: application/json

{
  "email": "employee_1755885515@mail.kz",
  "password": "EmployeePass123!"
}
```

#### 📥 RESPONSE ERROR - Pending Approval (403 Forbidden)
```json
{
  "success": false,
  "error": {
    "code": "PENDING_APPROVAL",
    "type": "AuthorizationError",
    "message": "Ваша учетная запись ожидает одобрения администратора",
    "details": {
      "status": "pending",
      "registrationStatus": "pending",
      "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a"
    }
  },
  "path": "/api/v1/auth/login",
  "timestamp": "2025-08-22T18:35:00.000Z"
}
```

## 🔄 Статусы сотрудника

### 1. После регистрации
```json
{
  "status": "pending",
  "registrationStatus": "pending",
  "isActive": false,
  "requiresApproval": true
}
```

### 2. После одобрения владельцем
```json
{
  "status": "active",
  "registrationStatus": "active",
  "isActive": true,
  "requiresApproval": false,
  "departmentId": "fb13e095-f1a5-4ad8-82a1-6b420204f5d6",
  "department": "HR",
  "position": "Junior Developer",
  "workspaceId": "0e7ce9b4-1149-4fb4-ba08-f18a86f47dc2"
}
```

### 3. После отклонения владельцем
```json
{
  "status": "rejected",
  "registrationStatus": "rejected",
  "isActive": false,
  "rejectionReason": "Не подходит по квалификации"
}
```

## 📋 Проверка pending employees (для владельца)

### Получение списка pending сотрудников

#### 📤 REQUEST (Owner Only)
```http
GET http://localhost:5001/api/v1/workspaces/{workspaceId}/employee-management/pending-employees
Authorization: Bearer {OWNER_TOKEN}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "id": "60f9366c-aa3f-4e6a-9ce8-8370f2e3daba",
      "userId": "7d103ddc-2f02-46df-90ae-f769d5950c20",
      "name": "Айгуль Смагулова",
      "email": "employee_1755885515@mail.kz",
      "phone": "+77017654321",
      "registrationStatus": "pending",
      "registeredAt": "2025-08-22T18:33:45.000Z",
      "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
      "requestedRole": "employee",
      "additionalInfo": {
        "department": null,
        "position": null
      }
    }
  ],
  "pagination": {
    "total": 1,
    "page": 1,
    "limit": 10
  }
}
```

## 🔒 Security Features

### БИН Verification
- Сотрудник должен знать БИН организации
- БИН проверяется на существование в системе
- Автоматическая привязка к организации

### Approval Process
- Только владелец может одобрять сотрудников
- Требуется назначение в департамент
- Возможность отклонения с причиной

### Access Control
- Pending сотрудники не могут войти в систему
- После одобрения получают доступ к workspace департамента
- Ограниченные права согласно роли

## 📝 Примеры использования в коде

### JavaScript/TypeScript - Employee Registration
```typescript
async function registerEmployee() {
  try {
    // Шаг 1: Pre-registration с БИН компании
    const preRegResponse = await fetch('http://localhost:5001/api/v1/auth/registration/pre-register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: "employee@mail.kz",
        password: "SecurePass123!",
        firstName: "Айгуль",
        lastName: "Смагулова",
        phone: "+77017654321",
        role: "employee",
        companyName: "ТОО Успешный Бизнес Новый",
        bin: "987654321098",  // БИН существующей организации
        companyType: "ТОО",
        industry: "IT"
      })
    });
    
    const preRegData = await preRegResponse.json();
    
    if (!preRegData.success) {
      if (preRegData.error.code === 'ORGANIZATION_NOT_FOUND') {
        alert('Организация с указанным БИН не найдена');
        return;
      }
    }
    
    const userId = preRegData.data.userId;
    
    // Шаг 2: Verify email
    const verificationCode = prompt('Введите код из email:');
    
    const verifyResponse = await fetch('http://localhost:5001/api/v1/auth/registration/verify-email', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: "employee@mail.kz",
        code: verificationCode
      })
    });
    
    // Шаг 3: Complete onboarding
    const onboardingResponse = await fetch('http://localhost:5001/api/v1/auth/registration/onboarding/complete', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: "employee@mail.kz",
        userId: userId,
        selectedRole: "employee",
        companyName: "ТОО Успешный Бизнес Новый",
        bin: "987654321098",
        companyType: "ТОО",
        industry: "IT"
      })
    });
    
    const onboardingData = await onboardingResponse.json();
    
    if (onboardingData.requiresApproval) {
      alert('Ваша заявка отправлена на рассмотрение администратору');
      // Redirect на страницу ожидания
      window.location.href = '/auth/pending-approval';
    }
    
  } catch (error) {
    console.error('Registration error:', error);
  }
}
```

### Bash Script - Тестирование employee registration
```bash
#!/bin/bash

# Pre-registration сотрудника
RESPONSE=$(curl -s -X POST http://localhost:5001/api/v1/auth/registration/pre-register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test_employee@mail.kz",
    "password": "Test123!",
    "firstName": "Test",
    "lastName": "Employee",
    "phone": "+77017654321",
    "role": "employee",
    "companyName": "ТОО Успешный Бизнес Новый",
    "bin": "987654321098",
    "companyType": "ТОО",
    "industry": "IT"
  }')

USER_ID=$(echo $RESPONSE | jq -r '.data.userId')
ORG_ID=$(echo $RESPONSE | jq -r '.data.organizationId')

echo "Employee registered with userId: $USER_ID"
echo "Found organization: $ORG_ID"

# Get verification code
CODE=$(PGPASSWORD=prometric01 psql -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
  -U prometric -d prometric -t \
  -c "SELECT code FROM email_verifications WHERE email = 'test_employee@mail.kz' ORDER BY created_at DESC LIMIT 1;" | xargs)

# Verify email
curl -X POST http://localhost:5001/api/v1/auth/registration/verify-email \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"test_employee@mail.kz\", \"code\": \"$CODE\"}"

# Complete onboarding
ONBOARDING_RESPONSE=$(curl -s -X POST http://localhost:5001/api/v1/auth/registration/onboarding/complete \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"test_employee@mail.kz\",
    \"userId\": \"$USER_ID\",
    \"selectedRole\": \"employee\",
    \"companyName\": \"ТОО Успешный Бизнес Новый\",
    \"bin\": \"987654321098\",
    \"companyType\": \"ТОО\",
    \"industry\": \"IT\"
  }")

echo "Employee status: $(echo $ONBOARDING_RESPONSE | jq -r '.status')"
echo "Requires approval: $(echo $ONBOARDING_RESPONSE | jq -r '.requiresApproval')"
```

## ✅ Проверенные сценарии

1. ✅ Успешная регистрация сотрудника с правильным БИН
2. ✅ Блокировка регистрации с несуществующим БИН
3. ✅ Email верификация работает
4. ✅ Статус "pending" после onboarding
5. ✅ Блокировка входа до одобрения
6. ✅ Сотрудник появляется в списке pending
7. ✅ Уникальность email проверяется

## 🚨 Известные проблемы

1. **Email Invitation отключен**
   - Владелец не может отправлять приглашения
   - Сотрудники должны знать БИН

2. **Deduplication Service**
   - Содержит только TODO placeholders
   - Дубликаты могут создаваться

3. **Workspace Assignment**
   - Сотрудник не получает workspace до одобрения
   - После одобрения требуется назначение в департамент

## 🔗 Связанные endpoints

- `/api/v1/workspaces/{id}/employee-management/employees/{id}/approve` - Одобрение сотрудника
- `/api/v1/workspaces/{id}/departments` - Получение списка департаментов
- `/api/v1/auth/login` - Вход после одобрения
- `/api/v1/auth/profile` - Проверка статуса