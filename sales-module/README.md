# 🛒 Sales & CRM Module Documentation

## 📖 Обзор модуля продаж и CRM

Модуль продаж и CRM обеспечивает полный цикл взаимодействия с клиентами: от привлечения лидов до закрытия сделок и послепродажного обслуживания. Система построена на современных принципах управления взаимоотношениями с клиентами и автоматизации продаж.

## 📁 Структура модуля

### 🎯 Lead Management (Управление лидами)
- Захват лидов из разных источников
- Квалификация и скоринг потенциальных клиентов
- Автоматическое распределение лидов по менеджерам
- Отслеживание активности и взаимодействий
- Интеграция с маркетинговыми каналами

### 📈 Deal Pipeline (Воронка продаж)
- Настраиваемые этапы воронки продаж
- Визуальное управление сделками (Kanban)
- Прогнозирование продаж и конверсий
- Автоматизация переходов между этапами
- Аналитика эффективности воронки

### 👥 Customer Relations (Управление клиентами)
- Единая база клиентов и контактов
- История взаимодействий и активности
- Сегментация клиентской базы
- Программы лояльности и retention
- 360-градусный профиль клиента

### 📊 Sales Analytics (Аналитика продаж)
- KPI и метрики продаж в реальном времени
- Анализ конверсий по воронке
- Производительность команды продаж
- Прогнозы и планирование
- ABC-анализ клиентов

## 🔗 Связи с другими модулями

- **Finance**: Автоматическое создание счетов из закрытых сделок
- **Production**: Передача заказов в производство
- **HR Management**: Управление командой продаж и мотивацией
- **Analytics**: Интеграция метрик продаж в общую аналитику

## 📋 API Endpoints

Основные endpoints для работы с модулем продаж:

```
GET    /api/v1/workspaces/{id}/sales/leads
POST   /api/v1/workspaces/{id}/sales/leads
PUT    /api/v1/workspaces/{id}/sales/leads/{leadId}
DELETE /api/v1/workspaces/{id}/sales/leads/{leadId}

GET    /api/v1/workspaces/{id}/sales/deals
POST   /api/v1/workspaces/{id}/sales/deals
PUT    /api/v1/workspaces/{id}/sales/deals/{dealId}
PATCH  /api/v1/workspaces/{id}/sales/deals/{dealId}/stage

GET    /api/v1/workspaces/{id}/sales/customers
POST   /api/v1/workspaces/{id}/sales/customers
PUT    /api/v1/workspaces/{id}/sales/customers/{customerId}

GET    /api/v1/workspaces/{id}/sales/pipeline
GET    /api/v1/workspaces/{id}/sales/analytics/conversion-rates
GET    /api/v1/workspaces/{id}/sales/analytics/sales-forecast
```

## 🎯 Воронка продаж и этапы

### Стандартные этапы Deal Pipeline
```typescript
enum DealStage {
  LEAD = 'lead',                    // Лид
  QUALIFIED = 'qualified',          // Квалифицирован
  PROPOSAL = 'proposal',            // Коммерческое предложение
  NEGOTIATION = 'negotiation',      // Переговоры
  CONTRACT = 'contract',            // Договор
  WON = 'won',                     // Сделка закрыта (успешно)
  LOST = 'lost'                    // Сделка закрыта (неуспешно)
}
```

### Конверсии и вероятности
```typescript
const stageConversions = {
  LEAD: { probability: 10, nextStage: 'QUALIFIED' },
  QUALIFIED: { probability: 25, nextStage: 'PROPOSAL' },
  PROPOSAL: { probability: 50, nextStage: 'NEGOTIATION' },
  NEGOTIATION: { probability: 75, nextStage: 'CONTRACT' },
  CONTRACT: { probability: 90, nextStage: 'WON' },
  WON: { probability: 100, nextStage: null },
  LOST: { probability: 0, nextStage: null }
};
```

## 👤 Типы клиентов и сегментация

### Customer Types
- **B2B** - бизнес клиенты
- **B2C** - частные клиенты  
- **PARTNER** - партнеры
- **SUPPLIER** - поставщики

### Customer Segments
- **VIP** - VIP клиенты (высокая стоимость)
- **REGULAR** - обычные клиенты
- **POTENTIAL** - потенциальные клиенты
- **INACTIVE** - неактивные клиенты
- **CHURNED** - ушедшие клиенты

### Lead Sources
```typescript
enum LeadSource {
  WEBSITE = 'website',              // Веб-сайт
  SOCIAL_MEDIA = 'social_media',    // Социальные сети
  EMAIL_CAMPAIGN = 'email_campaign', // Email рассылка
  REFERRAL = 'referral',            // Реферальная программа
  COLD_CALL = 'cold_call',          // Холодные звонки
  EXHIBITION = 'exhibition',        // Выставки
  PARTNERSHIP = 'partnership',      // Партнерские каналы
  DIRECT = 'direct'                 // Прямое обращение
}
```

## 📊 Ключевые метрики продаж

### Sales KPIs Dashboard
```typescript
const salesMetrics = [
  {
    id: 'monthly_revenue',
    name: 'Выручка за месяц',
    type: MetricType.CURRENCY,
    target: 1000000,
    currency: 'KZT'
  },
  {
    id: 'conversion_rate',
    name: 'Конверсия Lead → Deal',
    type: MetricType.PERCENTAGE,
    target: 15,
    critical: true
  },
  {
    id: 'average_deal_size',
    name: 'Средний чек',
    type: MetricType.CURRENCY,
    currency: 'KZT'
  },
  {
    id: 'sales_cycle_length',
    name: 'Длина цикла продаж',
    type: MetricType.TIME,
    unit: 'дней',
    target: 30
  }
];
```

### Performance Tracking
- **Revenue** - общая выручка
- **Deal Win Rate** - процент успешных сделок
- **Average Deal Size** - средний размер сделки
- **Sales Cycle Length** - длительность цикла продаж
- **Pipeline Velocity** - скорость движения по воронке
- **Customer Acquisition Cost (CAC)** - стоимость привлечения клиента
- **Customer Lifetime Value (CLV)** - пожизненная стоимость клиента

## 🤖 Автоматизация продаж

### Workflow Automation
```typescript
interface SalesWorkflow {
  trigger: 'lead_created' | 'deal_stage_changed' | 'customer_inactive';
  conditions: WorkflowCondition[];
  actions: WorkflowAction[];
}

// Пример: Автоматическое создание задач
const autoTaskCreation: SalesWorkflow = {
  trigger: 'deal_stage_changed',
  conditions: [
    { field: 'stage', operator: 'equals', value: 'PROPOSAL' }
  ],
  actions: [
    {
      type: 'create_task',
      assigneeId: 'deal.ownerId',
      title: 'Подготовить коммерческое предложение',
      dueDate: '+3 days'
    }
  ]
};
```

### Email Sequences
- Автоматические последующие письма
- Персонализированные шаблоны
- A/B тестирование email кампаний
- Отслеживание открытий и кликов

## 🏷️ Ценообразование и предложения

### Price Management
```typescript
interface PriceList {
  id: string;
  name: string;
  currency: string;
  validFrom: Date;
  validTo: Date;
  items: PriceItem[];
}

interface PriceItem {
  productId: string;
  basePrice: number;
  discountRules: DiscountRule[];
  minimumPrice: number;
}
```

### Discount Rules
- Скидки по объему
- Сезонные скидки
- Скидки для VIP клиентов
- Промокоды и купоны

## 📱 Мобильные возможности

### Mobile CRM Features
- Работа с лидами в оффлайне
- Геолокация для планирования встреч
- Быстрое добавление контактов
- Push уведомления о важных событиях
- Синхронизация с календарем

## 📈 Отчетность и аналитика

### Sales Reports
- Воронка продаж (Funnel Report)
- Прогноз продаж (Sales Forecast)
- Активность команды (Activity Report)
- Анализ потерянных сделок (Lost Deals Analysis)
- Отчет по источникам лидов

### Dashboard Views
```typescript
const salesDashboardViews = [
  'sales_overview',      // Общий обзор продаж
  'team_performance',    // Производительность команды
  'pipeline_health',     // Здоровье воронки
  'customer_insights',   // Инсайты по клиентам
  'forecasting'         // Прогнозирование
];
```

## 🔄 Интеграции и API

### CRM Integrations
- **Bitrix24** - синхронизация данных
- **amoCRM** - миграция данных
- **Salesforce** - импорт/экспорт
- **HubSpot** - интеграция с маркетингом

### Communication Channels
- **Email** - Gmail, Outlook интеграция
- **Phone** - VoIP системы
- **Messenger** - WhatsApp Business, Telegram
- **Video** - Zoom, Google Meet

## 🎨 Пользовательский интерфейс

### Kanban Board для Deal Pipeline
```typescript
<DealPipelineKanban
  stages={pipelineStages}
  deals={deals}
  onDealMove={handleDealStageChange}
  onDealClick={openDealModal}
  groupBy="stage"
  sortBy="priority"
/>
```

### Lead Capture Forms
- Встраиваемые формы для сайта
- Лендинг страницы для кампаний
- Чат-боты для квалификации
- Интеграция с социальными сетями

## 🧪 Тестирование

Тесты модуля продаж находятся в `test-scripts/sales-testing/`

```bash
# Тестирование управления лидами
./test-scripts/sales-testing/test-lead-management.sh

# Тестирование воронки продаж
./test-scripts/sales-testing/test-deal-pipeline.sh

# Тестирование CRM функций
./test-scripts/sales-testing/test-customer-relations.sh

# Тестирование аналитики продаж
./test-scripts/sales-testing/test-sales-analytics.sh
```

## 🔒 Безопасность и доступ

### Role-based Access Control
- **Sales Manager** - полный доступ к команде
- **Sales Rep** - доступ к своим лидам и сделкам
- **Sales Admin** - настройка системы продаж
- **Viewer** - только просмотр отчетов

### Data Privacy
- Соответствие GDPR требованиям
- Маскирование персональных данных
- Право на удаление данных клиента
- Аудит доступа к данным

## ⚡ Производительность

- Ленивая загрузка больших списков сделок
- Кэширование часто используемых фильтров
- Оптимизация запросов к базе данных
- Real-time обновления через WebSocket

---

*Модуль продаж - двигатель роста бизнеса*