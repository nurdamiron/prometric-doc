# ✉️ EMAIL VERIFICATION FLOW - Детальная документация

## 📋 Общее описание
Email verification flow - это процесс подтверждения email адреса через 6-значный код. Используется при регистрации owner и employee, а также при восстановлении пароля.

## 🎯 Endpoint
```
POST /api/v1/auth/registration/verify-email
```

## 🔄 Жизненный цикл кода верификации

### 1. Создание кода при регистрации
После вызова `/auth/registration/pre-register` автоматически:
- Генерируется 6-значный код
- Сохраняется в таблице `email_verifications`
- Срок действия: 15 минут
- Максимум попыток: 3

### 2. Структура в базе данных
```sql
-- Таблица email_verifications
CREATE TABLE email_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    code VARCHAR(6) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '15 minutes',
    attempts INT DEFAULT 0,
    verified BOOLEAN DEFAULT FALSE,
    user_id UUID REFERENCES users(id)
);
```

## 📊 Детальный процесс верификации

### ШАГ 1: Получение кода из базы данных (для тестирования)

#### 🔑 SQL запрос для получения кода
```bash
PGPASSWORD=prometric01 /opt/homebrew/opt/postgresql@14/bin/psql \
  -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
  -U prometric \
  -d prometric \
  -t -c "SELECT code FROM email_verifications WHERE email = 'owner_test_1755882547@mybusiness.kz' ORDER BY created_at DESC LIMIT 1;"
```

#### 📤 Альтернативный запрос с дополнительной информацией
```sql
SELECT 
    code,
    created_at,
    expires_at,
    attempts,
    verified,
    CASE 
        WHEN expires_at < NOW() THEN 'EXPIRED'
        WHEN verified = true THEN 'ALREADY_USED'
        WHEN attempts >= 3 THEN 'MAX_ATTEMPTS'
        ELSE 'VALID'
    END as status
FROM email_verifications 
WHERE email = 'owner_test_1755882547@mybusiness.kz' 
ORDER BY created_at DESC 
LIMIT 1;
```

### ШАГ 2: Отправка кода верификации

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
    "message": "Invalid verification code",
    "details": {
      "attemptsRemaining": 2
    }
  },
  "path": "/api/v1/auth/registration/verify-email",
  "timestamp": "2025-08-22T18:40:00.000Z"
}
```

#### 📥 RESPONSE ERROR - Тестовый код заблокирован (400 Bad Request)
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CODE",
    "type": "SecurityError",
    "message": "Invalid verification code",
    "details": {
      "reason": "Test code blocked by security policy"
    }
  },
  "path": "/api/v1/auth/registration/verify-email",
  "timestamp": "2025-08-22T18:40:00.000Z"
}
```

#### 📥 RESPONSE ERROR - Код истек (400 Bad Request)
```json
{
  "success": false,
  "error": {
    "code": "CODE_EXPIRED",
    "type": "ValidationError",
    "message": "Verification code has expired. Please request a new one.",
    "details": {
      "expiredAt": "2025-08-22T18:35:00.000Z",
      "canResend": true
    }
  },
  "path": "/api/v1/auth/registration/verify-email",
  "timestamp": "2025-08-22T18:50:00.000Z"
}
```

#### 📥 RESPONSE ERROR - Превышено количество попыток (429 Too Many Requests)
```json
{
  "success": false,
  "error": {
    "code": "MAX_ATTEMPTS_EXCEEDED",
    "type": "RateLimitError",
    "message": "Maximum verification attempts exceeded. Please request a new code.",
    "details": {
      "maxAttempts": 3,
      "usedAttempts": 3,
      "canResend": true
    }
  },
  "path": "/api/v1/auth/registration/verify-email",
  "timestamp": "2025-08-22T18:40:00.000Z"
}
```

#### 📥 RESPONSE ERROR - Email не найден (404 Not Found)
```json
{
  "success": false,
  "error": {
    "code": "EMAIL_NOT_FOUND",
    "type": "NotFoundError",
    "message": "No verification code found for this email. Please register first."
  },
  "path": "/api/v1/auth/registration/verify-email",
  "timestamp": "2025-08-22T18:40:00.000Z"
}
```

## 🔒 Security Features

### Заблокированные тестовые коды
Следующие коды автоматически блокируются системой безопасности:
```javascript
const blockedCodes = [
  '123456',
  '000000',
  '111111',
  '222222',
  '333333',
  '444444',
  '555555',
  '666666',
  '777777',
  '888888',
  '999999',
  '123123',
  '654321'
];
```

### Защита от брутфорса
- Максимум 3 попытки на один код
- Блокировка на 15 минут после превышения
- Rate limiting на endpoint (10 запросов в минуту)

### Временные ограничения
- Срок действия кода: 15 минут
- После истечения требуется новый код
- Использованные коды помечаются как verified

## 📤 Повторная отправка кода

### Endpoint для повторной отправки
```
POST /api/v1/auth/registration/resend-verification
```

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/registration/resend-verification
Content-Type: application/json

{
  "email": "owner_test_1755882547@mybusiness.kz"
}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "message": "New verification code sent successfully",
  "data": {
    "email": "owner_test_1755882547@mybusiness.kz",
    "codeExpiry": "2025-08-22T19:00:00.000Z",
    "canResendAfter": "2025-08-22T18:47:00.000Z"
  }
}
```

#### 📥 RESPONSE ERROR - Слишком частые запросы (429 Too Many Requests)
```json
{
  "success": false,
  "error": {
    "code": "TOO_MANY_REQUESTS",
    "type": "RateLimitError",
    "message": "Please wait 2 minutes before requesting a new code",
    "details": {
      "canResendAfter": "2025-08-22T18:47:00.000Z",
      "waitTimeSeconds": 120
    }
  }
}
```

## 📝 Примеры использования в коде

### JavaScript/TypeScript - Верификация с retry логикой
```typescript
async function verifyEmailWithRetry(email: string, maxAttempts: number = 3) {
  let attempts = 0;
  
  while (attempts < maxAttempts) {
    try {
      const code = prompt(`Введите код верификации (попытка ${attempts + 1}/${maxAttempts}):`);
      
      if (!code) {
        throw new Error('Код не введен');
      }
      
      const response = await fetch('http://localhost:5001/api/v1/auth/registration/verify-email', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, code })
      });
      
      const data = await response.json();
      
      if (data.success) {
        console.log('✅ Email успешно верифицирован!');
        return data;
      }
      
      if (data.error?.code === 'CODE_EXPIRED') {
        const resend = confirm('Код истек. Отправить новый?');
        if (resend) {
          await resendVerificationCode(email);
          attempts = 0; // Reset attempts for new code
          continue;
        }
      }
      
      if (data.error?.code === 'MAX_ATTEMPTS_EXCEEDED') {
        alert('Превышено количество попыток. Запросите новый код.');
        await resendVerificationCode(email);
        attempts = 0;
        continue;
      }
      
      attempts++;
      alert(`Неверный код. Осталось попыток: ${maxAttempts - attempts}`);
      
    } catch (error) {
      console.error('Ошибка верификации:', error);
      attempts++;
    }
  }
  
  throw new Error('Не удалось верифицировать email');
}

async function resendVerificationCode(email: string) {
  const response = await fetch('http://localhost:5001/api/v1/auth/registration/resend-verification', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  });
  
  const data = await response.json();
  
  if (data.success) {
    alert('Новый код отправлен на email');
    return data;
  }
  
  if (data.error?.code === 'TOO_MANY_REQUESTS') {
    const waitTime = data.error.details.waitTimeSeconds;
    alert(`Подождите ${waitTime} секунд перед повторным запросом`);
  }
  
  throw new Error('Не удалось отправить новый код');
}
```

### Bash Script - Автоматическая верификация для тестирования
```bash
#!/bin/bash

EMAIL="test@example.com"

# Функция для получения кода из БД
get_verification_code() {
    local email=$1
    PGPASSWORD=prometric01 /opt/homebrew/opt/postgresql@14/bin/psql \
        -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
        -U prometric \
        -d prometric \
        -t -c "SELECT code FROM email_verifications WHERE email = '$email' ORDER BY created_at DESC LIMIT 1;" | xargs
}

# Функция для проверки статуса кода
check_code_status() {
    local email=$1
    PGPASSWORD=prometric01 /opt/homebrew/opt/postgresql@14/bin/psql \
        -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
        -U prometric \
        -d prometric \
        -t -c "SELECT 
            CASE 
                WHEN expires_at < NOW() THEN 'EXPIRED'
                WHEN verified = true THEN 'ALREADY_USED'
                WHEN attempts >= 3 THEN 'MAX_ATTEMPTS'
                ELSE 'VALID'
            END as status
        FROM email_verifications 
        WHERE email = '$email' 
        ORDER BY created_at DESC 
        LIMIT 1;" | xargs
}

# Проверяем статус кода
STATUS=$(check_code_status "$EMAIL")
echo "Code status: $STATUS"

if [[ "$STATUS" == "VALID" ]]; then
    # Получаем код
    CODE=$(get_verification_code "$EMAIL")
    echo "Verification code: $CODE"
    
    # Верифицируем email
    RESPONSE=$(curl -s -X POST http://localhost:5001/api/v1/auth/registration/verify-email \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$EMAIL\", \"code\": \"$CODE\"}")
    
    SUCCESS=$(echo $RESPONSE | jq -r '.success')
    
    if [[ "$SUCCESS" == "true" ]]; then
        echo "✅ Email verified successfully!"
    else
        ERROR=$(echo $RESPONSE | jq -r '.error.message')
        echo "❌ Verification failed: $ERROR"
    fi
elif [[ "$STATUS" == "EXPIRED" ]]; then
    echo "⏰ Code expired, requesting new one..."
    curl -X POST http://localhost:5001/api/v1/auth/registration/resend-verification \
        -H "Content-Type: application/json" \
        -d "{\"email\": \"$EMAIL\"}"
else
    echo "❌ Code status: $STATUS"
fi
```

## ✅ Проверенные сценарии

1. ✅ Успешная верификация с правильным кодом
2. ✅ Блокировка тестовых кодов (123456, 000000, etc.)
3. ✅ Ошибка при неверном коде
4. ✅ Ошибка при истекшем коде
5. ✅ Ограничение на количество попыток
6. ✅ Повторная отправка кода
7. ✅ Rate limiting на частые запросы

## 🚨 Известные проблемы

1. **SMTP Service отключен**
   - Email не отправляются реально
   - Возвращается fake success
   - Необходимо получать код из БД

2. **No Email Templates**
   - Отсутствуют шаблоны писем
   - Нет локализации сообщений

3. **Missing Monitoring**
   - Нет логирования неудачных попыток
   - Нет алертов при подозрительной активности

## 🔗 Связанные endpoints

- `/api/v1/auth/registration/pre-register` - Инициирует создание кода
- `/api/v1/auth/registration/resend-verification` - Повторная отправка
- `/api/v1/auth/registration/onboarding/complete` - Следующий шаг после верификации
- `/api/v1/auth/forgot-password` - Также использует email верификацию