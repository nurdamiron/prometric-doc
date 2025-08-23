# 🔐 LOGIN FLOW - Детальная документация

## 📋 Общее описание
Login flow позволяет существующим пользователям войти в систему используя email и пароль.

## 🎯 Endpoint
```
POST /api/v1/auth/login
```

## 📊 Последовательность действий

### ШАГ 1: Отправка учетных данных

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/login
Content-Type: application/json

{
  "email": "owner_test_1755882547@mybusiness.kz",
  "password": "MySecurePass123!"
}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6Im93bmVyX3Rlc3RfMTc1NTg4MjU0N0BteWJ1c2luZXNzLmt6Iiwic3ViIjoiZTkxOGQ2ZGUtOWQ3Mi00ZGM2LWIyMjMtOTZjZjEzYTczYmZjIiwicm9sZSI6Im93bmVyIiwicmVnaXN0cmF0aW9uU3RhdHVzIjoiYWN0aXZlIiwic3RhdHVzIjoiYWN0aXZlIiwib3JnYW5pemF0aW9uSWQiOiJjMzQ0NjU0OS1jYjg3LTRmMzgtOWJhNi1kNWJlYmJmODM4MGEiLCJ3b3Jrc3BhY2VJZCI6ImRmMDgyY2I4LWE4ODAtNDQ4Zi04YWJmLTZkMjllOTE4ZTE4NiIsImVtcGxveWVlSWQiOm51bGwsIm9uYm9hcmRpbmdDb21wbGV0ZWQiOnRydWUsImlhdCI6MTc1NTg4NzQ4OCwiZXhwIjoxNzU1OTA5MDg4LCJpc3MiOiJwcm9tZXRyaWMtYXBpIn0.7LxzcwoUhJy7KZ--DhWyPTT6HRmjjcOofqXZS7DDKKE",
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
  "isFirstLogin": false,
  "emailVerified": true,
  "isActive": true,
  "lastLoginAt": "2025-08-22T18:31:28.724Z",
  "refreshTokenWarning": "Токен обновления не был создан. Сессия будет ограничена по времени.",
  "debug": {
    "id": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
    "status": "active",
    "onboardingCompleted": true,
    "isActive": true
  }
}
```

#### 📥 RESPONSE ERROR - Неверный пароль (401 Unauthorized)
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "type": "AuthenticationError",
    "message": "Неверный email или пароль"
  },
  "path": "/api/v1/auth/login",
  "timestamp": "2025-08-22T18:31:28.724Z",
  "requestId": "unique-request-id"
}
```

#### 📥 RESPONSE ERROR - Пользователь не найден (404 Not Found)
```json
{
  "success": false,
  "error": {
    "code": "USER_NOT_FOUND",
    "type": "NotFoundError",
    "message": "Пользователь с таким email не найден"
  },
  "path": "/api/v1/auth/login",
  "timestamp": "2025-08-22T18:31:28.724Z",
  "requestId": "unique-request-id"
}
```

#### 📥 RESPONSE ERROR - Email не подтвержден (403 Forbidden)
```json
{
  "success": false,
  "error": {
    "code": "EMAIL_NOT_VERIFIED",
    "type": "VerificationError",
    "message": "Email не подтвержден. Пожалуйста, подтвердите email перед входом"
  },
  "path": "/api/v1/auth/login",
  "timestamp": "2025-08-22T18:31:28.724Z",
  "requestId": "unique-request-id"
}
```

## 🔑 JWT Token Structure

Декодированный JWT token содержит:
```json
{
  "email": "owner_test_1755882547@mybusiness.kz",
  "sub": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",  // User ID
  "role": "owner",                                   // User role
  "registrationStatus": "active",
  "status": "active",
  "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
  "workspaceId": "df082cb8-a880-448f-8abf-6d29e918e186",
  "employeeId": null,                                // null для owner
  "onboardingCompleted": true,
  "iat": 1755887488,                                 // Issued at
  "exp": 1755909088,                                 // Expiration (6 часов)
  "iss": "prometric-api"                             // Issuer
}
```

## 🔄 Различия для разных ролей

### Owner Login Response
```json
{
  "role": "owner",
  "employeeId": null,
  "position": null,
  "department": null,
  "departmentId": null,
  "workspaceId": "df082cb8-a880-448f-8abf-6d29e918e186"  // Company workspace
}
```

### Employee Login Response
```json
{
  "role": "employee",
  "employeeId": "60f9366c-aa3f-4e6a-9ce8-8370f2e3daba",
  "position": "Junior Developer",
  "department": "HR",
  "departmentId": "fb13e095-f1a5-4ad8-82a1-6b420204f5d6",
  "workspaceId": "0e7ce9b4-1149-4fb4-ba08-f18a86f47dc2"  // Department workspace
}
```

### Manager Login Response
```json
{
  "role": "manager",
  "employeeId": "manager-employee-id",
  "position": "HR Manager",
  "department": "HR",
  "departmentId": "fb13e095-f1a5-4ad8-82a1-6b420204f5d6",
  "workspaceId": "manager-workspace-id"
}
```

## 🔒 Security Features

### 1. Password Requirements
- Минимум 8 символов
- Минимум 1 заглавная буква
- Минимум 1 цифра
- Минимум 1 специальный символ

### 2. Token Expiration
- Access Token: 6 часов
- Refresh Token: НЕ СОЗДАЕТСЯ (отключено)

### 3. Failed Login Attempts
- Rate limiting: НЕ НАСТРОЕН (проблема безопасности)
- Account lockout: НЕ РЕАЛИЗОВАН

## 🚨 Известные проблемы

1. **Refresh Token отсутствует**
   - Система возвращает warning: "Токен обновления не был создан. Сессия будет ограничена по времени."
   - Пользователям придется перелогиниться каждые 6 часов

2. **httpOnly cookies удалены**
   - Токен передается только в response body
   - Фронтенд должен сохранять токен в localStorage/sessionStorage

3. **Rate limiting отсутствует**
   - Нет защиты от brute force атак
   - Можно делать неограниченное количество попыток входа

## 📝 Примеры использования в коде

### JavaScript/TypeScript
```typescript
async function login(email: string, password: string) {
  const response = await fetch('http://localhost:5001/api/v1/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ email, password })
  });

  const data = await response.json();
  
  if (data.success) {
    // Сохраняем токен
    localStorage.setItem('accessToken', data.accessToken);
    localStorage.setItem('userId', data.userId);
    localStorage.setItem('role', data.role);
    localStorage.setItem('workspaceId', data.workspaceId);
    
    // Redirect на dashboard
    window.location.href = '/dashboard';
  } else {
    // Показываем ошибку
    alert(data.error.message);
  }
}
```

### cURL
```bash
curl -X POST http://localhost:5001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "owner_test_1755882547@mybusiness.kz",
    "password": "MySecurePass123!"
  }'
```

### Postman
```
Method: POST
URL: http://localhost:5001/api/v1/auth/login
Headers: 
  Content-Type: application/json
Body (raw JSON):
{
  "email": "owner_test_1755882547@mybusiness.kz",
  "password": "MySecurePass123!"
}
```

## ✅ Проверенные сценарии

1. ✅ Успешный login владельца
2. ✅ Успешный login сотрудника после одобрения
3. ✅ Login с неверным паролем
4. ✅ Login несуществующего пользователя
5. ⚠️ Login с неподтвержденным email (не полностью протестирован)

## 🔗 Связанные endpoints

- `/api/v1/auth/registration/pre-register` - Регистрация нового пользователя
- `/api/v1/auth/logout` - Выход из системы
- `/api/v1/auth/profile` - Получение профиля текущего пользователя
- `/api/v1/auth/forgot-password` - Восстановление пароля

