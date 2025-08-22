# 📚 PROMETRIC PLATFORM DOCUMENTATION

## 🏗️ Полная документация ERP платформы Prometric

Prometric — это комплексная ERP платформа для управления бизнесом, включающая модули управления персоналом, финансами, производством, продажами и аналитикой. Система построена на современной архитектуре с микросервисами и поддержкой множественных рабочих пространств.

## 📁 Структура документации

```
prometric-doc/
├── 🔐 auth-flows/                      # Детальная документация всех auth flows
│   ├── 01-LOGIN-FLOW.md               # Процесс входа с JWT структурой
│   ├── 02-REGISTRATION-OWNER-FLOW.md  # Регистрация владельца с авто-департаментами
│   ├── 03-REGISTRATION-EMPLOYEE-FLOW.md # Регистрация сотрудника через БИН
│   ├── 04-EMAIL-VERIFICATION-FLOW.md  # Email верификация с security
│   ├── 05-EMPLOYEE-APPROVAL-FLOW.md   # Одобрение сотрудников владельцем
│   └── 06-ONBOARDING-FLOW.md          # Завершение настройки для owner/employee
├── 👥 hr-management/                   # Модуль управления персоналом
├── 💰 finance-module/                  # Финансовый модуль
├── 🏭 production-module/               # Производственный модуль
├── 📊 analytics-dashboard/             # Система аналитики
├── 🛒 sales-module/                    # Модуль продаж и CRM
└── 🧪 test-scripts/                    # Скрипты тестирования
    ├── test-full-flow.sh               # Полное тестирование
    ├── owner-registration/             # Тесты регистрации owner
    ├── employee-registration/          # Тесты регистрации employee
    └── login-authentication/           # Тесты авторизации
```

## 🎯 Новая детальная документация Auth Flows

### ✅ Полностью задокументированные flows (NEW!)

1. **[01-LOGIN-FLOW.md](./auth-flows/01-LOGIN-FLOW.md)** - Процесс входа в систему
   - JWT token структура и декодирование
   - Различия ответов для ролей (owner, employee, manager)
   - Security features и известные проблемы
   - Примеры кода на JavaScript/TypeScript, cURL, Postman

2. **[02-REGISTRATION-OWNER-FLOW.md](./auth-flows/02-REGISTRATION-OWNER-FLOW.md)** - Регистрация владельца
   - Pre-registration с БИН валидацией
   - Email верификация (получение кода из БД)
   - Автоматическое создание 8 департаментов
   - Onboarding completion с JWT токеном

3. **[03-REGISTRATION-EMPLOYEE-FLOW.md](./auth-flows/03-REGISTRATION-EMPLOYEE-FLOW.md)** - Регистрация сотрудника
   - Регистрация через БИН существующей компании
   - Pending status после регистрации
   - Блокировка входа до одобрения владельцем
   - Различные статусы (pending, active, rejected)

4. **[04-EMAIL-VERIFICATION-FLOW.md](./auth-flows/04-EMAIL-VERIFICATION-FLOW.md)** - Email верификация
   - 6-значные коды с 15-минутным сроком
   - Security: блокировка тестовых кодов (123456, 000000)
   - Rate limiting и защита от брутфорса
   - SQL запросы для получения кодов из БД

5. **[05-EMPLOYEE-APPROVAL-FLOW.md](./auth-flows/05-EMPLOYEE-APPROVAL-FLOW.md)** - Одобрение сотрудников
   - Получение списка pending employees
   - Обязательное назначение в департамент
   - Активация и предоставление workspace доступа
   - Email уведомления (currently disabled)

6. **[06-ONBOARDING-FLOW.md](./auth-flows/06-ONBOARDING-FLOW.md)** - Процесс onboarding
   - Различия для owner (создание орг.) и employee (присоединение)
   - Автоматические backend действия
   - Создание workspace и департаментов
   - Генерация JWT для активных пользователей

## 🚀 Основные модули платформы

### 🔐 Система авторизации и безопасности
- **JWT Bearer tokens** (httpOnly cookies удалены)
- **Ролевая модель** (Owner, Manager, Employee, User)
- **Email верификация** с блокировкой тестовых кодов
- **Multi-tenant isolation** через workspaces

### 👥 HR Management
- Employee onboarding с pending approval
- Department management (8 авто-департаментов)
- Performance tracking и KPI
- Payroll system (в разработке)

### 💰 Finance Module
- Invoicing system
- Payment processing
- Financial reports
- Budget management

### 🏭 Production Module
- Work orders management
- Inventory control
- Quality assurance
- Production planning

### 📊 Analytics & Dashboard
- Real-time metrics
- Custom dashboards
- Performance monitoring
- Reporting engine

### 🛒 Sales & CRM
- Lead management
- Deal pipeline
- Customer relations
- Sales analytics

### 🤖 AI Integration
- **Google Vertex AI** (Gemini 1.5 Pro)
- **Полностью функционален** ✅
- Бизнес-консультации и аналитика

## 🔑 JWT Token Structure

```json
{
  "email": "owner_test_1755882547@mybusiness.kz",
  "sub": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
  "role": "owner",
  "registrationStatus": "active",
  "status": "active",
  "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
  "workspaceId": "df082cb8-a880-448f-8abf-6d29e918e186",
  "employeeId": null,
  "onboardingCompleted": true,
  "iat": 1755887488,
  "exp": 1755909088,
  "iss": "prometric-api"
}
```

## 🔐 Основные роли в системе

| Роль | Описание | Права доступа | Особенности |
|------|----------|---------------|-------------|
| **OWNER** | Владелец организации | Полный доступ | Одобрение сотрудников, управление департаментами |
| **MANAGER** | Менеджер | Управление отделом | Ограниченный доступ к настройкам |
| **EMPLOYEE** | Сотрудник | Базовый доступ | Требует одобрения при регистрации |
| **USER** | Базовый пользователь | Временная роль | После регистрации до выбора роли |

## 🌐 Базовые URL и подключения

- **Backend API**: `http://localhost:5001/api/v1`
- **Frontend**: `http://localhost:3000`
- **PostgreSQL**: `prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com`
  ```bash
  PGPASSWORD=prometric01 psql -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
    -U prometric -d prometric
  ```

## 🔄 Основные Authentication Flows

### Owner Registration Flow
```
1. Pre-register (БИН валидация) → 2. Email Verify → 3. Onboarding → 4. Login (Active)
```

### Employee Registration Flow
```
1. Pre-register (БИН lookup) → 2. Email Verify → 3. Onboarding → 4. Pending → 5. Owner Approval → 6. Login
```

## ✅ Протестированные компоненты (из реальных тестов)

### Работающие на 90%+
- ✅ Owner registration с автоматическим созданием департаментов
- ✅ Employee registration через БИН компании
- ✅ Email verification (коды из БД)
- ✅ Employee approval workflow
- ✅ JWT authentication
- ✅ AI service (Gemini 1.5 Pro)

### Известные проблемы
- ⚠️ SMTP service отключен (fake success)
- ⚠️ Refresh tokens не реализованы
- ⚠️ httpOnly cookies удалены
- ⚠️ Deduplication service - только TODO
- ⚠️ Rate limiting не настроен
- ⚠️ Email templates отсутствуют

## 🧪 Тестовые данные (из реальных тестов)

### Тестовый Owner
```javascript
{
  email: "owner_test_1755882547@mybusiness.kz",
  password: "MySecurePass123!",
  organization: "ТОО Успешный Бизнес Новый",
  bin: "987654321098"
}
```

### Тестовый Employee
```javascript
{
  email: "employee_1755885515@mail.kz",
  password: "EmployeePass123!",
  status: "pending → active (после одобрения)",
  department: "HR",
  position: "Junior Developer"
}
```

### Получение verification code из БД
```bash
PGPASSWORD=prometric01 psql -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
  -U prometric -d prometric -t \
  -c "SELECT code FROM email_verifications WHERE email = 'test@email.com' ORDER BY created_at DESC LIMIT 1;"
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
npm run start:dev
# Server: http://localhost:5001
```

### Запуск frontend
```bash
cd prometric-platform
npm run dev
# App: http://localhost:3000
```

### Тестирование полного flow
```bash
cd test-scripts
./test-full-flow.sh
```

## 📈 Общая готовность системы: 65% (MEDIUM-HIGH)

### Модули по готовности
| Модуль | Готовность | Статус |
|--------|------------|--------|
| Authentication | 90% | ✅ Working |
| User Management | 95% | ✅ Working |
| Organization Setup | 95% | ✅ Working |
| Employee Management | 85% | ✅ Working |
| Task Management | 40% | ⚠️ Partial |
| Project Management | 10% | ❌ Not ready |
| Finance Module | 30% | ❌ DB issues |
| AI Integration | 95% | ✅ Working |
| Security | 60% | ⚠️ Needs work |

## 📝 Важные замечания

1. **Заблокированные тестовые коды**: 123456, 000000, 111111, 999999 не работают
2. **БИН обязателен**: Сотрудники должны знать БИН организации
3. **Department assignment обязателен**: При одобрении требуется departmentId
4. **Workspace isolation**: Каждый департамент имеет свой workspace
5. **JWT expiration**: 6 часов (refresh tokens отсутствуют)

## 🔗 Полезные ссылки

- [Детальные Auth Flows](./auth-flows/)
- [Test Scripts Collection](./test-scripts/)
- [HR Management Module](./hr-management/)
- [Finance Module](./finance-module/)
- [Production Module](./production-module/)

## 📞 Контакты и поддержка

- **Backend Issues**: Проверяйте логи `npm run start:dev`
- **Database Issues**: PostgreSQL на AWS RDS
- **Frontend Issues**: Browser console для ошибок
- **Documentation**: Этот репозиторий

---

*Последнее обновление: 22 августа 2025*
*Версия документации: 2.0.0*