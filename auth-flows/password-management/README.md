# 🔑 Password Management Flow

## Обзор

Система управления паролями в Prometric включает процессы восстановления забытого пароля, смены пароля и управления безопасностью паролей.

## 📊 Процессы управления паролями

### 1. Forgot Password Flow
### 2. Reset Password Flow  
### 3. Change Password Flow
### 4. Password Security Requirements

---

## 🔄 Forgot Password Flow

### Step 1: Request Password Reset

**Endpoint:** `POST /api/v1/auth/password/forgot`

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Password reset link has been sent to your email",
  "email": "user@example.com"
}
```

**Что происходит на backend:**
1. Проверка существования пользователя
2. Генерация уникального reset token
3. Сохранение токена в таблице `password_resets`
4. Отправка email с ссылкой для сброса
5. Установка срока действия токена (1 час)

### Step 2: Verify Reset Token

**Endpoint:** `GET /api/v1/auth/password/verify-token?token={reset_token}`

**Response (Success):**
```json
{
  "success": true,
  "valid": true,
  "email": "user@example.com",
  "expiresAt": "2025-08-18T11:00:00Z"
}
```

### Step 3: Reset Password

**Endpoint:** `POST /api/v1/auth/password/reset`

**Request Body:**
```json
{
  "token": "reset-token-here",
  "newPassword": "NewSecurePassword123!",
  "confirmPassword": "NewSecurePassword123!"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Password has been reset successfully",
  "redirectTo": "/auth/login"
}
```

**Backend Process:**
1. Валидация токена
2. Проверка срока действия
3. Валидация нового пароля
4. Хеширование пароля с bcrypt
5. Обновление пароля в базе данных
6. Инвалидация всех существующих токенов
7. Отправка email-уведомления об изменении

---

## 🔐 Change Password Flow (Authorized)

### Endpoint: `POST /api/v1/auth/password/change`

**Headers:**
```
Authorization: Bearer {access_token}
```

**Request Body:**
```json
{
  "currentPassword": "CurrentPassword123!",
  "newPassword": "NewSecurePassword456!",
  "confirmPassword": "NewSecurePassword456!"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Password changed successfully",
  "requiresRelogin": true
}
```

**Backend Process:**
1. Проверка текущего пароля
2. Валидация нового пароля
3. Проверка, что новый пароль отличается от текущего
4. Хеширование и сохранение
5. Инвалидация всех токенов
6. Требование повторного входа

---

## 🛡️ Password Security Requirements

### Минимальные требования:

```javascript
const passwordRequirements = {
  minLength: 8,
  maxLength: 128,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true,
  specialChars: '!@#$%^&*()_+-=[]{}|;:,.<>?',
  preventCommonPasswords: true,
  preventUserInfo: true
};
```

### Валидация пароля:

```json
{
  "errors": [
    "Password must be at least 8 characters long",
    "Password must contain at least one uppercase letter",
    "Password must contain at least one number",
    "Password must contain at least one special character"
  ]
}
```

### Проверка сложности:

| Уровень | Требования | Пример |
|---------|------------|--------|
| **Weak** | < 8 символов, простой | `pass123` |
| **Fair** | 8+ символов, 2 типа символов | `Password1` |
| **Good** | 8+ символов, 3 типа символов | `Password1!` |
| **Strong** | 12+ символов, все типы | `MyP@ssw0rd2024!` |

---

## 📧 Email Templates

### Password Reset Email

```html
Subject: Password Reset Request

Dear {{firstName}},

We received a request to reset your password for your Prometric account.

Click the link below to reset your password:
{{resetLink}}

This link will expire in 1 hour.

If you didn't request this, please ignore this email.

Best regards,
Prometric Team
```

### Password Changed Notification

```html
Subject: Your Password Has Been Changed

Dear {{firstName}},

Your Prometric account password was successfully changed.

Details:
- Date: {{changeDate}}
- IP Address: {{ipAddress}}
- Location: {{location}}

If you didn't make this change, please contact support immediately.

Best regards,
Prometric Team
```

---

## 🔒 Security Measures

### 1. Rate Limiting
```javascript
// Password reset requests
@Throttle({ limit: 3, ttl: 3600000 }) // 3 attempts per hour
```

### 2. Token Security
- Cryptographically secure random tokens
- Single use tokens
- Short expiration time (1 hour)
- Stored as hashed values

### 3. Password History
```sql
CREATE TABLE password_history (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```
- Prevent reuse of last 5 passwords
- Store only hashed passwords

### 4. Account Lockout
- Lock account after 5 failed password attempts
- Require email verification to unlock

---

## ⚠️ Error Responses

### Invalid Current Password
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CURRENT_PASSWORD",
    "message": "Current password is incorrect"
  }
}
```

### Weak Password
```json
{
  "success": false,
  "error": {
    "code": "WEAK_PASSWORD",
    "message": "Password does not meet security requirements",
    "requirements": [
      "Minimum 8 characters",
      "At least one uppercase letter",
      "At least one number",
      "At least one special character"
    ]
  }
}
```

### Token Expired
```json
{
  "success": false,
  "error": {
    "code": "TOKEN_EXPIRED",
    "message": "Password reset token has expired",
    "action": "REQUEST_NEW_TOKEN"
  }
}
```

### Too Many Attempts
```json
{
  "success": false,
  "error": {
    "code": "TOO_MANY_ATTEMPTS",
    "message": "Too many password reset attempts. Please try again later.",
    "retryAfter": "2025-08-18T12:00:00Z"
  }
}
```

---

## 🧪 Testing Password Flows

### Test Password Reset
```bash
# Request reset
curl -X POST http://localhost:5001/api/v1/auth/password/forgot \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}'

# Reset with token
curl -X POST http://localhost:5001/api/v1/auth/password/reset \
  -H "Content-Type: application/json" \
  -d '{
    "token":"reset-token-here",
    "newPassword":"NewPassword123!",
    "confirmPassword":"NewPassword123!"
  }'
```

### Test Script
```bash
./test-scripts/password-management/test-password-flows.sh
```

---

## 🔐 Best Practices

1. **Never send passwords in plain text**
2. **Always use secure random tokens**
3. **Implement rate limiting on all password endpoints**
4. **Send notifications for all password changes**
5. **Log all password-related activities**
6. **Use strong hashing algorithms (bcrypt with salt)**
7. **Enforce password complexity requirements**
8. **Implement password history to prevent reuse**
9. **Consider implementing 2FA for password changes**
10. **Educate users about password security**

---

## 📊 Password Strength Calculator

```javascript
function calculatePasswordStrength(password) {
  let strength = 0;
  
  // Length
  if (password.length >= 8) strength += 20;
  if (password.length >= 12) strength += 20;
  if (password.length >= 16) strength += 20;
  
  // Character types
  if (/[a-z]/.test(password)) strength += 10;
  if (/[A-Z]/.test(password)) strength += 10;
  if (/[0-9]/.test(password)) strength += 10;
  if (/[^a-zA-Z0-9]/.test(password)) strength += 10;
  
  // Patterns
  if (!/(.)\1{2,}/.test(password)) strength += 10; // No repeating chars
  if (!/^[0-9]+$/.test(password)) strength += 10;   // Not only numbers
  
  return {
    score: strength,
    level: strength < 40 ? 'weak' : 
           strength < 60 ? 'fair' : 
           strength < 80 ? 'good' : 'strong'
  };
}
```

---

## 🔗 Related Documentation

- [Login & Authentication](../login-authentication/README.md)
- [Security Best Practices](../../security.md)
- [API Endpoints](../../api-endpoints/password-management/README.md)
- [Test Scripts](../../test-scripts/password-management/README.md)

---

*Last Updated: 2025-08-18*