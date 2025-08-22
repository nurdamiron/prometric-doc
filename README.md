# 📚 Prometric Platform Documentation

## 🎯 Описание
Полная техническая документация для Prometric ERP Platform, включающая детальное описание всех auth flows, API endpoints, и бизнес-процессов.

## 📋 Содержание

### 🔐 Authentication Flows (`/auth-flows`)
Детальная документация всех процессов авторизации и регистрации:

1. **[01-LOGIN-FLOW.md](./auth-flows/01-LOGIN-FLOW.md)** - Процесс входа в систему
   - JWT token структура
   - Различия для разных ролей (owner, employee, manager)
   - Security features и известные проблемы

2. **[02-REGISTRATION-OWNER-FLOW.md](./auth-flows/02-REGISTRATION-OWNER-FLOW.md)** - Регистрация владельца бизнеса
   - Pre-registration с БИН валидацией
   - Email верификация
   - Автоматическое создание 8 департаментов
   - Onboarding completion

3. **[03-REGISTRATION-EMPLOYEE-FLOW.md](./auth-flows/03-REGISTRATION-EMPLOYEE-FLOW.md)** - Регистрация сотрудника
   - Регистрация через БИН компании
   - Pending status после регистрации
   - Требование одобрения владельца

4. **[04-EMAIL-VERIFICATION-FLOW.md](./auth-flows/04-EMAIL-VERIFICATION-FLOW.md)** - Процесс верификации email
   - 6-значные коды верификации
   - Security: блокировка тестовых кодов
   - Rate limiting и защита от брутфорса

5. **[05-EMPLOYEE-APPROVAL-FLOW.md](./auth-flows/05-EMPLOYEE-APPROVAL-FLOW.md)** - Одобрение сотрудников
   - Получение списка pending employees
   - Назначение в департамент
   - Активация и предоставление доступа

6. **[06-ONBOARDING-FLOW.md](./auth-flows/06-ONBOARDING-FLOW.md)** - Процесс onboarding
   - Различия для owner и employee
   - Автоматические действия backend
   - Создание организации и workspace

## 🚀 Ключевые особенности

### ✅ Протестированные компоненты
- Authentication system (JWT Bearer tokens)
- User registration (owner & employee)
- Email verification 
- Employee approval workflow
- Department management
- Workspace isolation
- Role-based access control (RBAC)

### ⚠️ Известные проблемы
- SMTP service отключен (возвращает fake success)
- Refresh tokens не реализованы
- httpOnly cookies удалены из JWT implementation
- Deduplication service содержит только TODO placeholders
- Rate limiting не настроен

### 🔒 Security Features
- Блокировка тестовых кодов верификации (123456, 000000, etc.)
- JWT token expiration: 6 часов
- Password requirements (min 8 chars, uppercase, number, special)
- Multi-tenant workspace isolation

## 📊 Архитектура

### Backend
- **Framework:** NestJS
- **Database:** PostgreSQL с TypeORM
- **Authentication:** JWT Bearer tokens
- **Architecture:** Multi-tenant с workspace isolation

### Frontend
- **Framework:** Next.js 14.2.16
- **Styling:** Tailwind CSS
- **Internationalization:** next-intl

### AI Service
- **Provider:** Google Vertex AI
- **Model:** Gemini 1.5 Pro
- **Status:** Полностью функционален

## 🔄 Типичные User Flows

### Owner Registration Flow
```
1. Pre-register → 2. Verify Email → 3. Complete Onboarding → 4. Login
```

### Employee Registration Flow
```
1. Pre-register (с БИН) → 2. Verify Email → 3. Complete Onboarding → 4. Pending → 5. Owner Approval → 6. Login
```

## 📝 Примеры запросов

### Login Request
```bash
curl -X POST http://localhost:5001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "owner@company.kz",
    "password": "SecurePass123!"
  }'
```

### Get Verification Code (для тестирования)
```bash
PGPASSWORD=prometric01 psql -h prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com \
  -U prometric -d prometric -t \
  -c "SELECT code FROM email_verifications WHERE email = 'test@email.com' ORDER BY created_at DESC LIMIT 1;"
```

## 🛠️ Тестовые данные

### Тестовый Owner
- Email: owner_test_1755882547@mybusiness.kz
- Password: MySecurePass123!
- Организация: ТОО "Успешный Бизнес Новый"
- БИН: 987654321098

### Тестовый Employee
- Email: employee_1755885515@mail.kz
- Password: EmployeePass123!
- Статус: Требует одобрения

## 📞 Контакты

Для вопросов и предложений по документации обращайтесь к команде разработки Prometric Platform.

---

*Последнее обновление: 22 августа 2025*