# 📖 PROMETRIC ERP - РЕАЛЬНОЕ РУКОВОДСТВО ПОЛЬЗОВАТЕЛЯ

## 🎯 О системе

Prometric ERP - комплексная система управления предприятием, разработанная для автоматизации бизнес-процессов казахстанских компаний. Система построена на современном стеке технологий и обеспечивает полную цифровизацию операций.

---

## 📋 СОДЕРЖАНИЕ

1. [Архитектура системы](#архитектура-системы)
2. [Модули системы](#модули-системы)
3. [Процесс аутентификации](#процесс-аутентификации)
4. [Работа с модулями](#работа-с-модулями)
5. [API Reference](#api-reference)

---

## 🏗️ АРХИТЕКТУРА СИСТЕМЫ

### Технологический стек:
- **Backend:** NestJS 10.x, TypeScript 5.x
- **Database:** PostgreSQL 14 (AWS RDS)
- **Cache:** Redis 
- **Real-time:** WebSockets
- **Queue:** Bull (Redis-based)
- **AI Service:** Vertex AI (Google Cloud)
- **Frontend:** Next.js 14, React 18

### Микросервисная архитектура:
```
prometric-backend/     - Основной API сервер (порт 5001)
prometric-platform/    - Frontend приложение (порт 3000)
prometric-ai-service/  - AI сервис (порт 8080)
```

---

## 🔐 ПРОЦЕСС АУТЕНТИФИКАЦИИ

### 1. Регистрация владельца компании

#### Шаг 1: Проверка email
```http
POST /api/v1/auth/check-email
{
  "email": "owner@company.kz"
}
```

#### Шаг 2: Проверка БИН компании
```http
POST /api/v1/auth/check-bin
{
  "bin": "123456789012"
}
```

#### Шаг 3: Регистрация
```http
POST /api/v1/users/register-owner
{
  "email": "owner@company.kz",
  "password": "SecurePassword123",
  "firstName": "Имя",
  "lastName": "Фамилия",
  "bin": "123456789012",
  "companyName": "ТОО Компания"
}
```

#### Шаг 4: Верификация email
```http
POST /api/v1/users/verify-email
{
  "email": "owner@company.kz",
  "code": "123456"
}
```

### 2. Регистрация сотрудника

#### Шаг 1: Проверка БИН для сотрудника
```http
POST /api/v1/auth/check-bin-employee
{
  "bin": "123456789012"
}
```

#### Шаг 2: Регистрация сотрудника
```http
POST /api/v1/users/register-employee
{
  "email": "employee@company.kz",
  "password": "Password123",
  "firstName": "Имя",
  "lastName": "Фамилия",
  "organizationId": "uuid",
  "position": "Менеджер"
}
```

#### Шаг 3: Ожидание одобрения
Сотрудник должен быть одобрен владельцем через:
```http
POST /api/v1/organizations/:orgId/employees/:empId/approve
```

### 3. Вход в систему

```http
POST /api/v1/auth/login
{
  "email": "user@company.kz",
  "password": "Password123"
}

Response:
{
  "success": true,
  "accessToken": "jwt-token",
  "refreshToken": "refresh-token",
  "userId": "uuid",
  "workspaceId": "uuid",
  "organizationId": "uuid",
  "organizationRole": "owner|admin|employee"
}
```

---

## 📦 РЕАЛЬНЫЕ МОДУЛИ СИСТЕМЫ

### 1. **ORGANIZATIONS (Организации)**

**Endpoints:**
- `GET /api/v1/organizations` - Список организаций
- `POST /api/v1/organizations` - Создать организацию
- `GET /api/v1/organizations/:id` - Детали организации
- `PUT /api/v1/organizations/:id` - Обновить организацию

**Функции:**
- Управление данными компании
- Структура подразделений (departments)
- Управление сотрудниками
- Роли и права доступа

### 2. **WORKSPACES (Рабочие пространства)**

**Endpoints:**
- `GET /api/v1/workspaces` - Список workspace
- `POST /api/v1/workspaces` - Создать workspace
- `GET /api/v1/workspaces/:id` - Детали workspace
- `PUT /api/v1/workspaces/:id` - Обновить workspace

**Функции:**
- Изоляция данных между компаниями
- Персональные и корпоративные workspace
- Управление доступом

### 3. **CUSTOMERS (Клиенты/CRM)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/customers` - Список клиентов
- `POST /api/v1/workspaces/:wsId/customers` - Создать клиента
- `GET /api/v1/workspaces/:wsId/customers/:id` - Детали клиента
- `PUT /api/v1/workspaces/:wsId/customers/:id` - Обновить клиента
- `DELETE /api/v1/workspaces/:wsId/customers/:id` - Удалить клиента

**Функции:**
- База клиентов (B2B и B2C)
- История взаимодействий
- Контактные лица
- Сегментация и теги
- Интеграция с deals

### 4. **DEALS (Сделки)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/deals` - Список сделок
- `POST /api/v1/workspaces/:wsId/deals` - Создать сделку
- `GET /api/v1/workspaces/:wsId/deals/:id` - Детали сделки
- `PUT /api/v1/workspaces/:wsId/deals/:id` - Обновить сделку
- `POST /api/v1/workspaces/:wsId/deals/:id/stage` - Изменить этап

**Этапы сделки:**
- `NEW` - Новая
- `QUALIFIED` - Квалифицирована
- `PROPOSAL` - Предложение
- `NEGOTIATION` - Переговоры
- `WON` - Выиграна
- `LOST` - Проиграна

**События:**
- При переходе в WON -> автоматическое создание Order
- При переходе в LOST -> анализ причин

### 5. **PRODUCTS (Продукты)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/products` - Список продуктов
- `POST /api/v1/workspaces/:wsId/products` - Создать продукт
- `GET /api/v1/workspaces/:wsId/products/:id` - Детали продукта
- `PUT /api/v1/workspaces/:wsId/products/:id` - Обновить продукт
- `DELETE /api/v1/workspaces/:wsId/products/:id` - Удалить продукт

**Функции:**
- Каталог товаров и услуг
- Управление ценами
- Складской учет
- Категории продуктов
- BOM (Bill of Materials)

### 6. **ORDERS (Заказы)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/orders` - Список заказов
- `POST /api/v1/workspaces/:wsId/orders` - Создать заказ
- `GET /api/v1/workspaces/:wsId/orders/:id` - Детали заказа
- `PUT /api/v1/workspaces/:wsId/orders/:id` - Обновить заказ
- `POST /api/v1/workspaces/:wsId/orders/:id/status` - Изменить статус

**Статусы заказа:**
- `pending` - Ожидает
- `processing` - В обработке
- `completed` - Выполнен
- `cancelled` - Отменен

### 7. **PRODUCTION (Производство)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/production/orders` - Производственные заказы
- `POST /api/v1/workspaces/:wsId/production/orders` - Создать произв. заказ
- `GET /api/v1/workspaces/:wsId/production/quality` - Контроль качества
- `POST /api/v1/workspaces/:wsId/production/planning` - Планирование

**Функции:**
- Производственные заказы
- Планирование производства
- Контроль качества
- Управление мощностями
- Интеграция со складом

### 8. **FINANCE (Финансы)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/finance/invoices` - Счета
- `POST /api/v1/workspaces/:wsId/finance/invoices` - Создать счет
- `GET /api/v1/workspaces/:wsId/finance/payments` - Платежи
- `POST /api/v1/workspaces/:wsId/finance/payments` - Создать платеж

**Функции:**
- Выставление счетов
- Учет платежей
- Взаиморасчеты
- Финансовая отчетность
- Бюджетирование

### 9. **HR (Управление персоналом)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/employees` - Список сотрудников
- `POST /api/v1/workspaces/:wsId/employees` - Добавить сотрудника
- `GET /api/v1/workspaces/:wsId/departments` - Департаменты
- `POST /api/v1/workspaces/:wsId/departments` - Создать департамент

**Функции:**
- Управление сотрудниками
- Организационная структура
- Учет рабочего времени
- Расчет зарплаты
- KPI и оценка

### 10. **TASKS (Задачи)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/tasks` - Список задач
- `POST /api/v1/workspaces/:wsId/tasks` - Создать задачу
- `GET /api/v1/workspaces/:wsId/tasks/:id` - Детали задачи
- `PUT /api/v1/workspaces/:wsId/tasks/:id` - Обновить задачу
- `POST /api/v1/workspaces/:wsId/tasks/:id/comments` - Добавить комментарий

**Функции:**
- Управление задачами
- Приоритеты и дедлайны
- Назначение исполнителей
- Комментарии и вложения
- Интеграция с проектами

### 11. **DOCUMENTS (Документы)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/documents` - Список документов
- `POST /api/v1/workspaces/:wsId/documents` - Загрузить документ
- `GET /api/v1/workspaces/:wsId/documents/:id` - Скачать документ
- `DELETE /api/v1/workspaces/:wsId/documents/:id` - Удалить документ

**Функции:**
- Хранилище документов
- Версионирование
- Права доступа
- Шаблоны документов
- AI обработка (OCR)

### 12. **CALENDAR (Календарь)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/calendar/events` - События
- `POST /api/v1/workspaces/:wsId/calendar/events` - Создать событие
- `GET /api/v1/workspaces/:wsId/calendar/events/:id` - Детали события
- `PUT /api/v1/workspaces/:wsId/calendar/events/:id` - Обновить событие

**Функции:**
- Календарь событий
- Встречи и митинги
- Напоминания
- Интеграция с задачами

### 13. **NOTIFICATIONS (Уведомления)**

**Endpoints:**
- `GET /api/v1/notifications` - Список уведомлений
- `POST /api/v1/notifications/mark-read` - Отметить как прочитанное
- `GET /api/v1/notifications/settings` - Настройки уведомлений
- `PUT /api/v1/notifications/settings` - Обновить настройки

**Функции:**
- Push уведомления
- Email уведомления
- In-app уведомления
- WebSocket real-time

### 14. **ANALYTICS (Аналитика)**

**Endpoints:**
- `GET /api/v1/workspaces/:wsId/analytics/dashboard` - Дашборд
- `GET /api/v1/workspaces/:wsId/analytics/sales` - Аналитика продаж
- `GET /api/v1/workspaces/:wsId/analytics/finance` - Финансовая аналитика
- `GET /api/v1/workspaces/:wsId/analytics/hr` - HR аналитика

**Функции:**
- Ключевые метрики
- Графики и диаграммы
- Отчеты
- Экспорт данных

### 15. **AI INTEGRATION**

**Endpoints:**
- `POST /api/v1/ai/chat` - AI чат
- `POST /api/v1/ai/analyze-document` - Анализ документов
- `POST /api/v1/ai/generate-report` - Генерация отчетов
- `POST /api/v1/ai/predict` - Предиктивная аналитика

**AI Service (порт 8080):**
- `/api/chat` - AI ассистент
- `/api/analyze` - Анализ данных
- `/api/ocr` - Распознавание документов

---

## 🔄 EVENT-DRIVEN АРХИТЕКТУРА

### Основные события системы:

#### Deal Events:
- `deal.created` - Создана новая сделка
- `deal.updated` - Обновлена сделка
- `deal.won` - Сделка выиграна → создает Order
- `deal.lost` - Сделка проиграна

#### Order Events:
- `order.created` - Создан заказ → создает Production Order
- `order.updated` - Обновлен заказ
- `order.completed` - Заказ выполнен
- `order.cancelled` - Заказ отменен

#### Production Events:
- `production.order.created` - Создан производственный заказ
- `production.completed` - Производство завершено
- `quality.check.passed` - Пройден контроль качества

#### Finance Events:
- `invoice.created` - Создан счет
- `payment.received` - Получен платеж
- `invoice.paid` - Счет оплачен

### Orchestrators (Оркестраторы):

1. **DealWonOrchestrator**
   - Слушает: `deal.won`
   - Действия:
     - Создает Order
     - Создает Invoice
     - Отправляет уведомления
     - Обновляет статистику

2. **OrderFulfillmentOrchestrator**
   - Слушает: `order.created`
   - Действия:
     - Создает Production Order
     - Резервирует материалы
     - Планирует производство

---

## 🔐 РОЛИ И ПРАВА ДОСТУПА

### Системные роли:

1. **OWNER (Владелец)**
   - Полный доступ ко всем модулям
   - Управление организацией
   - Утверждение сотрудников
   - Финансовые операции

2. **ADMIN (Администратор)**
   - Управление системой
   - Настройка модулей
   - Управление пользователями
   - Отчеты и аналитика

3. **MANAGER (Менеджер)**
   - Работа с клиентами
   - Управление сделками
   - Создание заказов
   - Просмотр отчетов

4. **EMPLOYEE (Сотрудник)**
   - Выполнение задач
   - Просмотр данных
   - Базовые операции

5. **ACCOUNTANT (Бухгалтер)**
   - Финансовый модуль
   - Счета и платежи
   - Финансовая отчетность

---

## 🛠️ НАСТРОЙКА И КОНФИГУРАЦИЯ

### Переменные окружения:

```env
# Database
DATABASE_HOST=prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_USERNAME=prometric
DATABASE_PASSWORD=prometric01
DATABASE_NAME=prometric

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRATION=24h

# AI Service
AI_SERVICE_URL=http://localhost:8080
GOOGLE_APPLICATION_CREDENTIALS=./google-vertex.json

# Frontend
FRONTEND_URL=http://localhost:3000
BACKEND_URL=http://localhost:5001
```

---

## 📱 FRONTEND ПРИЛОЖЕНИЕ

### Основные страницы:

1. **Аутентификация:**
   - `/login` - Вход
   - `/register/owner` - Регистрация владельца
   - `/register/employee` - Регистрация сотрудника
   - `/verify-email` - Верификация email
   - `/onboarding` - Первичная настройка

2. **Dashboard:**
   - `/dashboard` - Главная панель
   - `/dashboard/analytics` - Аналитика
   - `/dashboard/metrics` - Метрики

3. **Модули:**
   - `/customers` - Клиенты
   - `/deals` - Сделки
   - `/products` - Продукты
   - `/orders` - Заказы
   - `/production` - Производство
   - `/finance` - Финансы
   - `/hr` - Персонал
   - `/tasks` - Задачи
   - `/documents` - Документы
   - `/calendar` - Календарь

4. **Настройки:**
   - `/settings/profile` - Профиль
   - `/settings/organization` - Организация
   - `/settings/workspace` - Workspace
   - `/settings/integrations` - Интеграции

---

## 🔧 ИНТЕГРАЦИИ

### Доступные интеграции:

1. **Email:**
   - SMTP сервер для отправки писем
   - Шаблоны писем

2. **SMS:**
   - SMS уведомления (в разработке)

3. **Платежные системы:**
   - Kaspi (планируется)
   - Halyk Bank (планируется)

4. **Государственные сервисы:**
   - ЭСФ (планируется)
   - Egov.kz (планируется)

---

## 📊 ТЕСТОВЫЕ ДАННЫЕ

### Тестовые учетные записи:
```
Email: nurdaulet@expanse.kz
Password: Nurda2003
Workspace ID: c5bbd5de-7614-44a0-89fe-973f0555ddc7
Organization ID: 7896273a-0458-4276-8248-3e13f1589ac4
```

---

## 🚀 ЗАПУСК СИСТЕМЫ

### Backend:
```bash
cd prometric-backend
npm install
npm run start:dev  # Порт 5001
```

### Frontend:
```bash
cd prometric-platform
npm install
npm run dev  # Порт 3000
```

### AI Service:
```bash
cd prometric-ai-service
npm install
node server.js  # Порт 8080
```

---

## 📝 ЗАКЛЮЧЕНИЕ

Prometric ERP - это полнофункциональная ERP система, включающая:
- ✅ Управление клиентами (CRM)
- ✅ Управление сделками и продажами
- ✅ Производственное планирование
- ✅ Финансовый учет
- ✅ Управление персоналом
- ✅ Документооборот
- ✅ AI интеграция
- ✅ Real-time уведомления
- ✅ Аналитика и отчетность

Система активно развивается и регулярно обновляется.

---

*© 2025 Prometric ERP. Версия документации: 1.0.0*
*Последнее обновление: 2025-08-23*