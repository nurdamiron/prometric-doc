# 🔐 Login & Authentication Flow

## Обзор

Процесс аутентификации в системе Prometric поддерживает несколько методов входа и использует JWT токены для управления сессиями.

## 📊 Методы аутентификации

### 1. Email + Password Login
### 2. Google OAuth
### 3. Refresh Token
### 4. Auto-login (Remember Me)

---

## 🔑 Standard Login Flow

### Endpoint: `POST /api/v1/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "UserPassword123!"
}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Login successful",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_here",
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "firstName": "Иван",
    "lastName": "Иванов",
    "role": "owner",
    "status": "active",
    "organizationId": "org-uuid",
    "workspaceId": "workspace-uuid",
    "employeeId": "employee-uuid",
    "onboardingCompleted": true
  },
  "organization": {
    "id": "org-uuid",
    "name": "ТОО Моя Компания",
    "bin": "123456789012"
  },
  "workspace": {
    "id": "workspace-uuid",
    "name": "Main Workspace",
    "type": "main"
  },
  "permissions": [
    "organization.manage",
    "employees.manage",
    "workspace.manage"
  ]
}
```

### Что происходит на backend:

1. **Валидация входных данных**
   - Проверка формата email
   - Проверка наличия пароля

2. **Поиск пользователя**
   ```sql
   SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL
   ```

3. **Проверка пароля**
   - Сравнение с bcrypt hash
   - Проверка количества неудачных попыток

4. **Проверка статуса аккаунта**
   - `active` - можно входить
   - `pending_verification` - требуется верификация email
   - `pending_approval` - ожидает одобрения
   - `suspended` - аккаунт заблокирован

5. **Генерация токенов**
   - Access Token (6 часов)
   - Refresh Token (30 дней)

6. **Логирование события**
   ```sql
   INSERT INTO audit_logs (user_id, action, ip_address, user_agent)
   VALUES ($1, 'LOGIN', $2, $3)
   ```

---

## 🔄 Refresh Token Flow

### Endpoint: `POST /api/v1/auth/refresh`

**Request Body:**
```json
{
  "refreshToken": "refresh_token_here"
}
```

**Response (Success):**
```json
{
  "success": true,
  "accessToken": "new_access_token",
  "refreshToken": "new_refresh_token"
}
```

### Логика обновления:

1. Проверка refresh token в базе данных
2. Проверка срока действия
3. Генерация нового access token
4. Опционально: ротация refresh token
5. Invalidate старый refresh token

---

## 🌐 Google OAuth Flow

### Step 1: Redirect to Google

**Endpoint:** `GET /api/v1/auth/google`

**Response:** Redirect to Google OAuth consent screen

### Step 2: Google Callback

**Endpoint:** `GET /api/v1/auth/google/callback?code={auth_code}`

**Process:**
1. Exchange code for Google tokens
2. Get user info from Google
3. Find or create user in database
4. Generate JWT tokens
5. Redirect to frontend with tokens

**Frontend Redirect:**
```
http://localhost:3000/auth/callback?token={jwt_token}&refresh={refresh_token}
```

---

## 🔒 Logout Flow

### Endpoint: `POST /api/v1/auth/logout`

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response (Success):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

**Backend Process:**
1. Extract token from header
2. Add token to blacklist
3. Revoke refresh tokens
4. Clear session data
5. Log audit event

---

## 🛡️ Security Measures

### 1. Rate Limiting
```javascript
// 5 login attempts per minute per IP
@Throttle({ limit: 5, ttl: 60000 })
```

### 2. Account Lockout
- After 5 failed attempts: 15 minutes lockout
- After 10 failed attempts: 1 hour lockout
- After 20 failed attempts: account suspension

### 3. Token Security
- **Access Token**: Short-lived (6 hours)
- **Refresh Token**: Long-lived (30 days)
- **Token Rotation**: On each refresh
- **Blacklisting**: On logout

### 4. Password Requirements
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 number
- At least 1 special character

---

## 📱 Frontend Integration

### Storing Tokens

```javascript
// localStorage (простой вариант)
localStorage.setItem('accessToken', response.accessToken);
localStorage.setItem('refreshToken', response.refreshToken);

// Secure storage (рекомендуется)
// Access token в памяти
// Refresh token в httpOnly cookie
```

### Axios Interceptor

```javascript
// Request interceptor
axios.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor для refresh
axios.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      const refreshToken = localStorage.getItem('refreshToken');
      const { data } = await axios.post('/auth/refresh', { refreshToken });
      localStorage.setItem('accessToken', data.accessToken);
      return axios(error.config);
    }
    return Promise.reject(error);
  }
);
```

---

## 🔍 Profile Endpoint

### Endpoint: `GET /api/v1/auth/profile`

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user-uuid",
    "email": "user@example.com",
    "firstName": "Иван",
    "lastName": "Иванов",
    "phone": "+77011234567",
    "role": "owner",
    "status": "active",
    "emailVerified": true,
    "onboardingCompleted": true,
    "organization": {
      "id": "org-uuid",
      "name": "ТОО Моя Компания",
      "bin": "123456789012"
    },
    "workspace": {
      "id": "workspace-uuid",
      "name": "Main Workspace"
    },
    "department": {
      "id": "dept-uuid",
      "name": "IT Department"
    },
    "permissions": ["..."]
  }
}
```

---

## ⚠️ Error Responses

### Invalid Credentials
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid email or password"
  }
}
```

### Account Locked
```json
{
  "success": false,
  "error": {
    "code": "ACCOUNT_LOCKED",
    "message": "Account is temporarily locked due to multiple failed login attempts",
    "lockedUntil": "2025-08-18T12:00:00Z"
  }
}
```

### Email Not Verified
```json
{
  "success": false,
  "error": {
    "code": "EMAIL_NOT_VERIFIED",
    "message": "Please verify your email before logging in",
    "action": "RESEND_VERIFICATION"
  }
}
```

### Account Suspended
```json
{
  "success": false,
  "error": {
    "code": "ACCOUNT_SUSPENDED",
    "message": "Your account has been suspended. Please contact support."
  }
}
```

---

## 🧪 Testing

### Test Credentials

```bash
# Owner account
EMAIL="jasulan80770@gmail.com"
PASSWORD="[secure_password]"

# Test login
curl -X POST http://localhost:5001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"'$EMAIL'","password":"'$PASSWORD'"}'
```

### Test Script
```bash
./test-scripts/login-authentication/test-login.sh
```

---

## 📝 Best Practices

1. **Never store passwords in plain text**
2. **Always use HTTPS in production**
3. **Implement token refresh before expiry**
4. **Clear tokens on logout**
5. **Monitor failed login attempts**
6. **Use secure password reset flow**
7. **Implement 2FA for sensitive operations**

---

## 🔗 Related Documentation

- [Password Management](../password-management/README.md)
- [API Security](../../security.md)
- [Error Codes](../../error-codes.md)
- [Test Scripts](../../test-scripts/login-authentication/README.md)