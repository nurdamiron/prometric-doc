# 🚀 OWNER REGISTRATION FLOW - Детальная документация

## 📋 Общее описание
Owner registration flow - это процесс регистрации владельца бизнеса и создания организации. Включает в себя предварительную регистрацию, верификацию email и завершение onboarding.

## 🎯 Последовательность шагов
1. Pre-registration (создание пользователя)
2. Email verification (подтверждение email)
3. Onboarding completion с selectedRole="owner" (создание организации)

⚠️ **ВАЖНО**: Нет отдельного endpoint `/select-role`. Роль передается в параметре `selectedRole` при вызове `/onboarding/complete`

## 📊 Детальный процесс

### ШАГ 1: Pre-Registration (Предварительная регистрация)

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/registration/pre-register
Content-Type: application/json

{
  "email": "owner_test_1755882547@mybusiness.kz",
  "password": "MySecurePass123!",
  "firstName": "Асылбек",
  "lastName": "Нурланов",
  "phoneNumber": "+77012345678"
  // role, companyName, bin НЕ передаются на этом этапе!
  // Они будут переданы в onboarding/complete
}
```

#### 📥 RESPONSE SUCCESS (201 Created)
```json
{
  "success": true,
  "message": "User registered successfully. Please verify your email.",
  "data": {
    "userId": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
    "email": "owner_test_1755882547@mybusiness.kz",
    "role": "owner",
    "registrationStatus": "email_verification",
    "emailVerified": false,
    "requiresEmailVerification": true
  }
}
```

#### 📥 RESPONSE ERROR - Email уже существует (409 Conflict)
```json
{
  "success": false,
  "error": {
    "code": "EMAIL_EXISTS",
    "type": "ConflictError",
    "message": "Пользователь с таким email уже существует"
  },
  "path": "/api/v1/auth/registration/pre-register",
  "timestamp": "2025-08-22T18:20:15.000Z"
}
```

#### 📥 RESPONSE ERROR - БИН уже зарегистрирован (409 Conflict)
```json
{
  "success": false,
  "error": {
    "code": "BIN_EXISTS",
    "type": "ConflictError",
    "message": "Организация с таким БИН уже зарегистрирована"
  },
  "path": "/api/v1/auth/registration/pre-register",
  "timestamp": "2025-08-22T18:20:15.000Z"
}
```

#### 📥 RESPONSE ERROR - Невалидный пароль (400 Bad Request)
```json
{
  "success": false,
  "error": {
    "code": "INVALID_PASSWORD",
    "type": "ValidationError",
    "message": "Пароль должен содержать минимум 8 символов, включая заглавную букву, цифру и специальный символ"
  },
  "path": "/api/v1/auth/registration/pre-register",
  "timestamp": "2025-08-22T18:20:15.000Z"
}
```

### ШАГ 2: Email Verification (Подтверждение email)

После pre-registration создается код верификации в базе данных.

#### 🔑 Получение кода из базы данных (для тестирования)
```bash
# PostgreSQL запрос для получения реального кода верификации
PGPASSWORD=prometric01 /opt/homebrew/opt/postgresql@14/bin/psql \
  -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
  -U prometric \
  -d prometric \
  -t -c "SELECT code FROM email_verifications WHERE email = 'owner_test_1755882547@mybusiness.kz' ORDER BY created_at DESC LIMIT 1;"

# Результат: 287645
```

#### ⚠️ ВАЖНО: Заблокированные тестовые коды
Следующие коды заблокированы системой безопасности:
- 123456
- 000000
- 111111
- 999999

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/registration/verify-email
Content-Type: application/json

{
  "email": "owner_test_1755882547@mybusiness.kz",
  "code": "287645"
}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "message": "Email verified successfully",
  "data": {
    "email": "owner_test_1755882547@mybusiness.kz",
    "userId": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
    "emailVerified": true,
    "registrationStatus": "onboarding",
    "nextStep": "complete_onboarding"
  }
}
```

#### 📥 RESPONSE ERROR - Неверный код (400 Bad Request)
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CODE",
    "type": "ValidationError",
    "message": "Invalid verification code"
  },
  "path": "/api/v1/auth/registration/verify-email",
  "timestamp": "2025-08-22T18:21:00.000Z"
}
```

#### 📥 RESPONSE ERROR - Код истек (400 Bad Request)
```json
{
  "success": false,
  "error": {
    "code": "CODE_EXPIRED",
    "type": "ValidationError",
    "message": "Verification code has expired"
  },
  "path": "/api/v1/auth/registration/verify-email",
  "timestamp": "2025-08-22T18:21:00.000Z"
}
```

### ШАГ 3: Onboarding Completion (Завершение настройки)

⚠️ **ВАЖНО**: Нет отдельного endpoint `/select-role`. Роль передается через `selectedRole` параметр!

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/registration/onboarding/complete
Content-Type: application/json
Authorization: Bearer {token_from_verify_email}

{
  "email": "owner_test_1755882547@mybusiness.kz",
  "userId": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
  "selectedRole": "owner",  // ⚠️ ОБЯЗАТЕЛЬНО! Без этого будет ошибка 400
  "companyName": "ТОО Успешный Бизнес Новый",
  "companyBin": "987654321098",  // ⚠️ ОБЯЗАТЕЛЬНО 12 цифр! Уникальный!
  "companyType": "ТОО",
  "industry": "IT"
}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "message": "Onboarding completed successfully",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Im93bmVyX3Rlc3RfMTc1NTg4MjU0N0BteWJ1c2luZXNzLmt6Iiwic3ViIjoiZTkxOGQ2ZGUtOWQ3Mi00ZGM2LWIyMjMtOTZjZjEzYTczYmZjIiwicm9sZSI6Im93bmVyIiwicmVnaXN0cmF0aW9uU3RhdHVzIjoiYWN0aXZlIiwic3RhdHVzIjoiYWN0aXZlIiwib3JnYW5pemF0aW9uSWQiOiJjMzQ0NjU0OS1jYjg3LTRmMzgtOWJhNi1kNWJlYmJmODM4MGEiLCJ3b3Jrc3BhY2VJZCI6ImRmMDgyY2I4LWE4ODAtNDQ4Zi04YWJmLTZkMjllOTE4ZTE4NiIsImVtcGxveWVlSWQiOm51bGwsIm9uYm9hcmRpbmdDb21wbGV0ZWQiOnRydWUsImlhdCI6MTc1NTg4NjI5NiwiZXhwIjoxNzU1OTA3ODk2LCJpc3MiOiJwcm9tZXRyaWMtYXBpIn0.cFmRqVCXYOUhJy7KZ--DhWyPTT6HRmjjcOofqXZS7DDKKE",
  "userId": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
  "email": "owner_test_1755882547@mybusiness.kz",
  "firstName": "Асылбек",
  "lastName": "Нурланов",
  "fullName": "Асылбек Нурланов",
  "role": "owner",
  "status": "active",
  "registrationStatus": "active",
  "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
  "workspaceId": "df082cb8-a880-448f-8abf-6d29e918e186",
  "employeeId": null,
  "position": null,
  "department": null,
  "departmentId": null,
  "phoneNumber": "+77012345678",
  "avatar": null,
  "onboardingCompleted": true,
  "hasCompany": true,
  "isFirstLogin": true,
  "emailVerified": true,
  "isActive": true,
  "organizationInfo": {
    "id": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
    "name": "ТОО Успешный Бизнес Новый",
    "bin": "987654321098",
    "type": "ТОО",
    "industry": "IT",
    "createdDepartments": [
      "Руководство",
      "Продажи",
      "Логистика",
      "Маркетинг",
      "Финансы",
      "Производство",
      "Закупки",
      "HR"
    ]
  }
}
```

#### 📥 RESPONSE ERROR - Email не верифицирован (400 Bad Request)
```json
{
  "success": false,
  "error": {
    "code": "EMAIL_NOT_VERIFIED",
    "type": "ValidationError",
    "message": "Email must be verified before completing onboarding"
  },
  "path": "/api/v1/auth/registration/onboarding/complete",
  "timestamp": "2025-08-22T18:22:00.000Z"
}
```

## 🏗️ Автоматически создаваемые структуры

### Департаменты (создаются автоматически)
При завершении onboarding автоматически создаются 8 департаментов:
1. **Руководство** - для топ-менеджмента
2. **Продажи** - отдел продаж
3. **Логистика** - управление поставками
4. **Маркетинг** - маркетинговые активности
5. **Финансы** - финансовое управление
6. **Производство** - производственные процессы
7. **Закупки** - управление закупками
8. **HR** - управление персоналом

### Workspace
Создается главный workspace компании с уникальным ID, который используется для всех последующих операций.

## 🔒 Security Features

### Password Requirements
- Минимум 8 символов
- Минимум 1 заглавная буква (A-Z)
- Минимум 1 строчная буква (a-z)
- Минимум 1 цифра (0-9)
- Минимум 1 специальный символ (!@#$%^&*)

### Email Verification
- 6-значный код действителен 15 минут
- Блокировка тестовых кодов (123456, 000000, etc.)
- Максимум 3 попытки ввода кода

### БИН Validation
- Проверка уникальности БИН
- Проверка формата (12 цифр)
- Блокировка повторной регистрации

## 📝 Примеры использования в коде

### JavaScript/TypeScript - Полный flow
```typescript
async function registerOwner() {
  // Шаг 1: Pre-registration
  const preRegResponse = await fetch('http://localhost:5001/api/v1/auth/registration/pre-register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: "owner@company.kz",
      password: "SecurePass123!",
      firstName: "Асылбек",
      lastName: "Нурланов",
      phone: "+77012345678",
      role: "owner",
      companyName: "ТОО Моя Компания",
      bin: "123456789012",
      companyType: "ТОО",
      industry: "IT"
    })
  });
  
  const preRegData = await preRegResponse.json();
  const userId = preRegData.data.userId;
  
  // Шаг 2: Получить код из email (или из БД для тестирования)
  const verificationCode = await getVerificationCode(); // "287645"
  
  // Шаг 3: Verify email
  const verifyResponse = await fetch('http://localhost:5001/api/v1/auth/registration/verify-email', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: "owner@company.kz",
      code: verificationCode
    })
  });
  
  // Шаг 4: Complete onboarding
  const onboardingResponse = await fetch('http://localhost:5001/api/v1/auth/registration/onboarding/complete', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: "owner@company.kz",
      userId: userId,
      selectedRole: "owner",
      companyName: "ТОО Моя Компания",
      bin: "123456789012",
      companyType: "ТОО",
      industry: "IT"
    })
  });
  
  const onboardingData = await onboardingResponse.json();
  
  // Сохраняем данные
  localStorage.setItem('accessToken', onboardingData.accessToken);
  localStorage.setItem('organizationId', onboardingData.organizationId);
  localStorage.setItem('workspaceId', onboardingData.workspaceId);
  
  // Redirect на dashboard
  window.location.href = '/dashboard';
}
```

### Bash Script - Полный тест
```bash
#!/bin/bash

# Pre-registration
RESPONSE=$(curl -s -X POST http://localhost:5001/api/v1/auth/registration/pre-register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@company.kz",
    "password": "Test123!",
    "firstName": "Test",
    "lastName": "Owner",
    "phone": "+77012345678",
    "role": "owner",
    "companyName": "Test Company",
    "bin": "123456789012",
    "companyType": "ТОО",
    "industry": "IT"
  }')

USER_ID=$(echo $RESPONSE | jq -r '.data.userId')

# Get verification code from database
CODE=$(PGPASSWORD=prometric01 psql -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
  -U prometric -d prometric -t \
  -c "SELECT code FROM email_verifications WHERE email = 'test@company.kz' ORDER BY created_at DESC LIMIT 1;" | xargs)

# Verify email
curl -X POST http://localhost:5001/api/v1/auth/registration/verify-email \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"test@company.kz\", \"code\": \"$CODE\"}"

# Complete onboarding
curl -X POST http://localhost:5001/api/v1/auth/registration/onboarding/complete \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"test@company.kz\",
    \"userId\": \"$USER_ID\",
    \"selectedRole\": \"owner\",
    \"companyName\": \"Test Company\",
    \"bin\": \"123456789012\",
    \"companyType\": \"ТОО\",
    \"industry\": \"IT\"
  }"
```

## ✅ Проверенные сценарии

1. ✅ Успешная регистрация нового владельца
2. ✅ Блокировка тестовых кодов верификации
3. ✅ Автоматическое создание департаментов
4. ✅ Создание workspace организации
5. ✅ Получение JWT токена после onboarding
6. ✅ Валидация БИН уникальности
7. ✅ Валидация сложности пароля
8. ✅ Блокировка повторной регистрации с тем же email

## 🚨 Известные проблемы

1. **SMTP Service отключен**
   - Email отправка возвращает fake success
   - Необходимо получать код из базы данных

2. **Deduplication Service**
   - Содержит только TODO placeholders
   - Не работает проверка дубликатов

3. **Refresh Token отсутствует**
   - Только access token на 6 часов
   - Требуется перелогин каждые 6 часов

## 🔗 Связанные endpoints

- `/api/v1/auth/login` - Вход после регистрации
- `/api/v1/auth/registration/employee` - Регистрация сотрудника
- `/api/v1/auth/profile` - Получение профиля
- `/api/v1/workspaces/{id}/departments` - Управление департаментами