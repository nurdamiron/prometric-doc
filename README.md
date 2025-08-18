# 📚 PROMETRIC AUTHENTICATION SYSTEM DOCUMENTATION

## 🏗️ Архитектура системы авторизации

Система авторизации Prometric построена на многоэтапном процессе регистрации с верификацией email и ролевой моделью доступа.

## 📁 Структура документации

```
documentation/
├── auth-flows/              # Описание всех процессов авторизации
│   ├── owner-registration/  # Регистрация владельца организации
│   ├── employee-registration/ # Регистрация сотрудника
│   ├── login-authentication/  # Процесс входа в систему
│   ├── password-management/   # Управление паролями
│   └── role-management/       # Управление ролями
├── api-endpoints/           # Документация API эндпоинтов
│   └── ... (такая же структура)
└── test-scripts/           # Тестовые скрипты для каждого flow
    └── ... (такая же структура)
```


## 🔐 Основные роли в системе

| Роль | Описание | Права доступа |
|------|----------|---------------|
| **OWNER** | Владелец организации | Полный доступ ко всем функциям, управление сотрудниками, настройки организации |
| **MANAGER** | Менеджер | Управление отделом, одобрение заявок, ограниченный доступ к настройкам |
| **EMPLOYEE** | Сотрудник | Базовый доступ, работа в рамках своего отдела |
| **USER** | Базовый пользователь | Временная роль после регистрации до выбора основной роли |

## 🌐 Базовые URL

- **Backend API**: `http://localhost:5001/api/v1`
- **Frontend**: `http://localhost:3000`
- **Database**: `prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com:5432`

## 🔄 Основные Authentication Flows

### 1. Регистрация владельца организации (Owner Registration)
[Подробная документация →](./auth-flows/owner-registration/README.md)

**Шаги:**
1. Pre-registration с данными компании
2. Email verification
3. Выбор роли (owner)
4. Создание организации и workspace
5. Завершение onboarding

### 2. Регистрация сотрудника (Employee Registration)
[Подробная документация →](./auth-flows/employee-registration/README.md)

**Шаги:**
1. Pre-registration с BIN компании
2. Email verification
3. Выбор роли (employee)
4. Ожидание одобрения от owner/manager
5. Получение доступа к workspace

### 3. Процесс входа (Login)
[Подробная документация →](./auth-flows/login-authentication/README.md)

**Варианты:**
- Email + Password
- OAuth (Google)
- Refresh token

### 4. Управление паролями
[Подробная документация →](./auth-flows/password-management/README.md)

**Функции:**
- Forgot password
- Reset password
- Change password

## 🔑 JWT Token Structure

```json
{
  "email": "user@example.com",
  "sub": "user-uuid",
  "role": "owner|manager|employee",
  "registrationStatus": "active",
  "status": "active",
  "organizationId": "org-uuid",
  "workspaceId": "workspace-uuid",
  "employeeId": "employee-uuid",
  "onboardingCompleted": true,
  "iat": 1234567890,
  "exp": 1234567890,
  "iss": "prometric-api"
}
```

## 📊 Database Schema

### Users Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'USER',
    status VARCHAR(50) DEFAULT 'pending_verification',
    registration_status VARCHAR(50) DEFAULT 'incomplete',
    email_verified BOOLEAN DEFAULT false,
    onboarding_completed BOOLEAN DEFAULT false,
    organization_id UUID,
    workspace_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Email Verifications Table
```sql
CREATE TABLE email_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    email VARCHAR(255) NOT NULL,
    code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🚀 Quick Start

### Запуск backend
```bash
cd prometric-backend
docker-compose up -d
npm run start:dev
```

### Запуск frontend
```bash
cd prometric-platform
npm run dev
```

### Тестирование
```bash
cd documentation/test-scripts
./test-full-flow.sh
```

## 📝 Важные замечания

1. **Email верификация обязательна** для всех новых пользователей
2. **BIN компании** используется для связывания сотрудников с организацией
3. **Workspace isolation** - каждая организация имеет изолированный workspace
4. **Pending approval** - сотрудники требуют одобрения от owner/manager
5. **JWT tokens** имеют срок жизни 6 часов (configurable)

## 🔗 Полезные ссылки

- [API Endpoints Documentation](./api-endpoints/README.md)
- [Test Scripts Collection](./test-scripts/README.md)
- [Error Codes Reference](./error-codes.md)
- [Security Best Practices](./security.md)

## 📞 Контакты для вопросов

- **Backend Issues**: Check logs in `docker logs prometric-backend`
- **Database Issues**: Connect to PostgreSQL at `prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com`
- **Frontend Issues**: Check browser console for errors

---

*Последнее обновление: 2025-08-18*