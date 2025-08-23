# ✅ ПРАВИЛЬНЫЙ AUTH FLOW (БЕЗ /select-role!)

## 🎯 ВАЖНО: `/select-role` НЕ СУЩЕСТВУЕТ!

Этот endpoint есть только в старом файле `auth.controller.old.ts`. В актуальном коде его НЕТ!

## 📋 ПРАВИЛЬНАЯ ПОСЛЕДОВАТЕЛЬНОСТЬ

### 1️⃣ Для OWNER (Создание компании)

```bash
# Шаг 1: Pre-registration
POST /api/v1/auth/registration/pre-register
{
  "email": "owner@company.kz",
  "password": "SecurePass123!",
  "firstName": "Нурдаулет",
  "lastName": "Ахметов",
  "phoneNumber": "+77011234567"
}

# Шаг 2: Verify email
POST /api/v1/auth/registration/verify-email
{
  "email": "owner@company.kz",
  "code": "123456"  # Из БД или email
}

# Шаг 3: Complete onboarding (БЕЗ /select-role!)
POST /api/v1/auth/registration/onboarding/complete
{
  "userId": "uuid-from-step-1",
  "email": "owner@company.kz",
  "selectedRole": "owner",  # ← РОЛЬ ПЕРЕДАЕТСЯ ЗДЕСЬ!
  "companyName": "ТОО Моя Компания",
  "companyBin": "123456789012",  # 12 цифр!
  "companyType": "ТОО",
  "industry": "IT"
}
```

### 2️⃣ Для EMPLOYEE (Присоединение к компании)

```bash
# Шаг 1: Pre-registration с БИНом компании
POST /api/v1/auth/registration/pre-register
{
  "email": "employee@company.kz",
  "password": "SecurePass123!",
  "firstName": "Айгерим",
  "lastName": "Смагулова",
  "phoneNumber": "+77021234567",
  "organizationBin": "123456789012"  # БИН компании!
}

# Шаг 2: Verify email
POST /api/v1/auth/registration/verify-email
{
  "email": "employee@company.kz",
  "code": "654321"
}

# Шаг 3: Complete onboarding (БЕЗ /select-role!)
POST /api/v1/auth/registration/onboarding/complete
{
  "userId": "uuid-from-step-1",
  "email": "employee@company.kz",
  "selectedRole": "employee",  # ← РОЛЬ ПЕРЕДАЕТСЯ ЗДЕСЬ!
  "employeeCompanyBin": "123456789012",
  "position": "Developer",
  "message": "Прошу принять меня в компанию"
}
```

## ❌ ЧТО НЕ НАДО ДЕЛАТЬ

```bash
# ❌ НЕ НАДО вызывать /select-role - его НЕТ!
POST /api/v1/auth/select-role  # ← НЕ СУЩЕСТВУЕТ!

# ❌ НЕ НАДО onboarding без selectedRole
POST /api/v1/auth/registration/onboarding/complete
{
  "userId": "...",
  # selectedRole отсутствует - ОШИБКА 400!
}

# ❌ НЕ НАДО пустой БИН для owner
{
  "selectedRole": "owner",
  "companyBin": ""  # ← ОШИБКА! БИН обязателен!
}
```

## ✅ РЕЗУЛЬТАТ ТЕСТИРОВАНИЯ

```
🟢 Owner registration: РАБОТАЕТ
🟢 Email verification: РАБОТАЕТ  
🟢 Organization creation: РАБОТАЕТ
🟢 Employee registration: РАБОТАЕТ
🟢 Employee approval: РАБОТАЕТ

🔴 /select-role endpoint: НЕ СУЩЕСТВУЕТ (и не должен!)
```

## 📝 ЗАМЕТКИ

1. `selectedRole` передается в `/onboarding/complete`, НЕ в отдельном endpoint
2. БИН должен быть ровно 12 цифр
3. БИН должен быть уникальным для каждой организации
4. Employee создается со статусом `pending` до одобрения owner'ом