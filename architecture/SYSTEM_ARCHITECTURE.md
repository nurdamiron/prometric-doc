# Архитектура Prometric AI System

## 🏗️ Общая Архитектура

```
┌─────────────────────────────────────────────────────────┐
│                     Frontend (React)                      │
│                   prometric-platform                      │
└────────────────────────┬────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────┐
│                  API Gateway / Nginx                      │
└──────────┬──────────────────────────┬────────────────────┘
           │                          │
           ▼                          ▼
┌──────────────────────┐    ┌────────────────────────────┐
│   Prometric Backend  │    │   Prometric AI Service     │
│     (NestJS)         │◄───┤      (Node.js)             │
│   Port: 5001         │    │      Port: 8080            │
└──────────┬───────────┘    └────────────┬───────────────┘
           │                              │
           ▼                              ▼
┌──────────────────────┐    ┌────────────────────────────┐
│   PostgreSQL DB      │    │     Vertex AI API          │
│   (AWS RDS)          │    │    (Google Cloud)          │
└──────────────────────┘    └────────────────────────────┘
```

## 🧩 Компоненты Системы

### 1. Frontend (prometric-platform)
- **Технологии:** React, Next.js, TypeScript
- **Порт:** 3000 (dev), 3001 (prod)
- **Основные модули:**
  - Dashboard
  - Sales (Deals, Clients, Products)
  - Marketing (Campaigns, Leads)
  - Finance (Invoices, Payments)
  - Production (Orders, Planning)
  - HR (Employees, Performance)
  - AI Assistant Interface

### 2. Backend API (prometric-backend)
- **Технологии:** NestJS, TypeScript, TypeORM
- **Порт:** 5001
- **База данных:** PostgreSQL (AWS RDS)
- **Основные модули:**
  - Auth Module (JWT)
  - Workspaces Module
  - Organizations Module
  - Users/Employees Module
  - Sales Module
  - Finance Module
  - Production Module
  - Tasks Module
  - Documents Module

### 3. AI Service (prometric-ai-service)
- **Технологии:** Node.js, Express, JavaScript
- **Порт:** 8080
- **AI Provider:** Google Vertex AI (Gemini)
- **Основные компоненты:**
  - AI Command Center
  - Intent Detection Engine
  - Entity Extraction Engine
  - Dependency Resolution Engine
  - Execution Orchestrator
  - Backend Integration Handlers
  - Workflow Automation Engine

## 🔄 Request Flow

### Типичный поток запроса CREATE_CUSTOMER:

1. **User Input** (Frontend)
   ```
   Пользователь: "создай клиента Инновации КЗ с email info@innovation.kz"
   ```

2. **Frontend → AI Service**
   ```javascript
   POST http://localhost:8080/api/ai/command
   {
     "input": "создай клиента Инновации КЗ с email info@innovation.kz",
     "workspaceId": "...",
     "organizationId": "...",
     "userId": "..."
   }
   ```

3. **AI Service Processing**
   - Intent Detection → `CREATE_CUSTOMER`
   - Entity Extraction → `{name: "Инновации КЗ", email: "info@innovation.kz"}`
   - Dependency Resolution → Check organization, workspace
   - Execution Planning → Prepare customer data

4. **AI Service → Backend**
   ```javascript
   POST http://localhost:5001/api/v1/workspaces/{id}/customers
   {
     "name": "Инновации КЗ",
     "type": "COMPANY",
     "companyName": "Инновации КЗ",
     "email": "info@innovation.kz",
     // ...
   }
   ```

5. **Backend Processing**
   - Validate data
   - Check permissions
   - Create DB record
   - Return created entity

6. **Response Chain**
   Backend → AI Service → Frontend → User

## 🗂️ Структура Проекта

```
/prometric/
├── prometric-platform/       # Frontend приложение
│   ├── src/
│   │   ├── components/      # React компоненты
│   │   ├── pages/          # Next.js страницы
│   │   ├── hooks/          # Custom hooks
│   │   ├── lib/            # Утилиты и API клиенты
│   │   └── styles/         # CSS/SCSS стили
│   └── public/             # Статические файлы
│
├── prometric-backend/       # Backend API
│   ├── src/
│   │   ├── modules/        # NestJS модули
│   │   ├── entities/       # TypeORM entities
│   │   ├── migrations/     # База данных миграции
│   │   └── common/         # Общие утилиты
│   └── test/              # Тесты
│
└── prometric-ai-service/   # AI сервис
    ├── core/
    │   ├── engines/        # AI движки
    │   ├── services/       # Бизнес-логика
    │   └── utils/         # Утилиты
    ├── handlers/          # Backend интеграция
    ├── middleware/        # Express middleware
    └── routes/           # API роуты
```

## 🔐 Безопасность

### Аутентификация и Авторизация
1. **JWT Tokens** - для всех API запросов
2. **Workspace Isolation** - изоляция данных по workspace
3. **Role-Based Access Control (RBAC)**:
   - Owner - полный доступ
   - Manager - управление командой
   - Employee - ограниченный доступ

### Защита данных
- HTTPS для всех соединений
- Шифрование sensitive данных
- Input sanitization против XSS/SQL injection
- Rate limiting для защиты от DDoS

## 📊 Производительность

### Оптимизации:
1. **Кэширование**
   - Redis для сессий и частых запросов
   - In-memory cache для AI intent detection
   - Browser cache для статических ресурсов

2. **База данных**
   - Индексы на часто используемых полях
   - Connection pooling
   - Query optimization

3. **AI Service**
   - Batch processing для множественных запросов
   - Async/await для неблокирующих операций
   - Rate limiting (10 req/burst, 60 req/min)

## 🚀 Deployment

### Production Environment:
- **Frontend:** Railway/Vercel
- **Backend:** Railway
- **Database:** AWS RDS (PostgreSQL)
- **AI Service:** Railway
- **Redis:** Railway Redis addon

### Environment Variables:
```env
# Backend
DATABASE_URL=postgresql://...
JWT_SECRET=...
PORT=5001

# AI Service
BACKEND_URL=http://localhost:5001
GOOGLE_APPLICATION_CREDENTIALS=./vertex-ai-key.json
PORT=8080

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:5001
NEXT_PUBLIC_AI_SERVICE_URL=http://localhost:8080
```

## 📈 Мониторинг

### Метрики:
- Request/Response times
- Error rates
- AI intent detection accuracy
- Database query performance
- User activity analytics

### Логирование:
- Winston для структурированного логирования
- Уровни: error, warn, info, debug
- Централизованное хранение логов

## 🔄 CI/CD Pipeline

1. **Development** → Feature branches
2. **Testing** → Automated tests (Jest, Cypress)
3. **Staging** → Pre-production environment
4. **Production** → Railway deployment

## 🎯 Roadmap

### Ближайшие планы:
1. ✅ Базовые CRUD операции через AI
2. ✅ Интеграция с Vertex AI
3. 🔄 Поддержка всех модулей системы
4. 📅 Batch операции
5. 📊 Advanced аналитика

### Долгосрочные цели:
1. 🤖 ML модели для предсказаний
2. 🔊 Voice команды
3. 📱 Мобильное приложение
4. 🌍 Мультиязычность
5. 🔗 Интеграции с внешними системами