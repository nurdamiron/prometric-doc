# 🧪 Test Scripts Collection

## Обзор

Коллекция тестовых скриптов для проверки всех authentication flows в системе Prometric.

## 📁 Структура

```
test-scripts/
├── test-full-flow.sh                # Полный тест всех flows
├── owner-registration/
│   └── test-owner-registration.sh   # Тест регистрации владельца
├── employee-registration/
│   └── test-employee-registration.sh # Тест регистрации сотрудника
├── login-authentication/
│   └── test-login.sh                # Тест входа и аутентификации
├── password-management/
│   └── test-password-flows.sh       # Тест управления паролями
└── role-management/
    └── test-role-transitions.sh     # Тест изменения ролей
```

## 🚀 Quick Start

### Запуск полного теста

```bash
# Тестирует весь flow от регистрации до входа
./test-full-flow.sh
```

### Индивидуальные тесты

```bash
# Регистрация владельца
./owner-registration/test-owner-registration.sh

# Регистрация сотрудника (требует BIN компании)
./employee-registration/test-employee-registration.sh 123456789012

# Тест входа
./login-authentication/test-login.sh email@example.com password123
```

## 📋 Предварительные требования

1. **Backend должен быть запущен**
   ```bash
   cd prometric-backend
   docker-compose up -d
   npm run start:dev
   ```

2. **Установлен jq для обработки JSON**
   ```bash
   # macOS
   brew install jq
   
   # Ubuntu/Debian
   sudo apt-get install jq
   ```

3. **Установлен curl**
   - Обычно предустановлен в большинстве систем

## 🔧 Конфигурация

### Переменные окружения

```bash
# Backend URL (по умолчанию: http://localhost:5001)
export BACKEND_URL="http://localhost:5001"

# Для тестирования с существующими данными
export COMPANY_BIN="123456789012"
export OWNER_TOKEN="jwt-token-here"
export WORKSPACE_ID="workspace-uuid"
```

### Тестовые учетные данные

```bash
# Существующий owner для тестирования
EMAIL="jasulan80770@gmail.com"
PASSWORD="[secure_password]"

# Тестовый BIN для новых организаций
TEST_BIN="010203040506"
```

## 📊 Тестовые сценарии

### 1. Полная регистрация новой организации

```bash
./test-full-flow.sh
```

**Что тестируется:**
- ✅ Регистрация владельца
- ✅ Верификация email
- ✅ Создание организации
- ✅ Регистрация сотрудника
- ✅ Одобрение сотрудника
- ✅ Проверка прав доступа

### 2. Добавление сотрудника к существующей организации

```bash
# Сначала получите BIN существующей организации
COMPANY_BIN="123456789012"

# Запустите тест регистрации сотрудника
./employee-registration/test-employee-registration.sh $COMPANY_BIN
```

### 3. Тестирование аутентификации

```bash
# Тест с существующими credentials
./login-authentication/test-login.sh "email@example.com" "password"

# Тест refresh token
./login-authentication/test-refresh-token.sh
```

### 4. Тестирование восстановления пароля

```bash
./password-management/test-password-reset.sh "email@example.com"
```

## 📝 Формат вывода

Все скрипты сохраняют результаты в JSON файлы:

```json
{
  "role": "owner",
  "email": "owner@example.com",
  "token": "jwt-token",
  "workspace": "workspace-uuid",
  "organization": "org-uuid",
  "timestamp": "2025-08-18T10:00:00Z"
}
```

## 🔍 Отладка

### Включение debug режима

```bash
# Включить подробный вывод
DEBUG=1 ./test-full-flow.sh

# Сохранить все запросы и ответы
./test-full-flow.sh 2>&1 | tee debug.log
```

### Проверка логов backend

```bash
# Docker logs
docker logs prometric-backend

# Application logs
tail -f prometric-backend/logs/app.log
```

### Проверка базы данных

```bash
# Подключение к PostgreSQL
PGPASSWORD=prometric01 psql \
  -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
  -U prometric \
  -d prometric

# Проверка пользователей
SELECT email, role, status FROM users;

# Проверка верификационных кодов
SELECT * FROM email_verifications WHERE email = 'test@example.com';
```

## ⚠️ Известные проблемы

### 1. 404 на registration endpoints

**Проблема:** Endpoint `/api/v1/auth/register` не существует

**Решение:** Используйте правильный endpoint:
```bash
/api/v1/auth/registration/pre-register
```

### 2. Email verification code

**Проблема:** Не приходит email с кодом

**Решение:** В dev режиме используйте код `123456` или проверьте логи:
```bash
docker logs prometric-backend | grep "Verification code"
```

### 3. Company BIN not found

**Проблема:** При регистрации сотрудника компания не найдена

**Решение:** Убедитесь, что owner зарегистрирован с этим BIN:
```bash
# Проверить в базе данных
SELECT bin FROM organizations;
```

## 🎯 CI/CD Integration

### GitHub Actions

```yaml
name: Auth Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Start backend
      run: |
        docker-compose up -d
        npm run start:dev &
        sleep 10
    
    - name: Run auth tests
      run: |
        ./documentation/test-scripts/test-full-flow.sh
    
    - name: Upload results
      uses: actions/upload-artifact@v2
      with:
        name: test-results
        path: test-results-*.json
```

### GitLab CI

```yaml
auth-tests:
  stage: test
  script:
    - docker-compose up -d
    - npm run start:dev &
    - sleep 10
    - ./documentation/test-scripts/test-full-flow.sh
  artifacts:
    paths:
      - test-results-*.json
    expire_in: 1 week
```

## 🔗 Связанная документация

- [Authentication Flows](../auth-flows/README.md)
- [API Endpoints](../api-endpoints/README.md)
- [Security Best Practices](../security.md)

---

*Last Updated: 2025-08-18*