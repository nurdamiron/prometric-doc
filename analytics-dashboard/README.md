# 📊 Analytics & Dashboard Module Documentation

## 📖 Обзор модуля аналитики и дашбордов

Система аналитики и дашбордов обеспечивает real-time мониторинг бизнес-процессов, сбор метрик, оптимизацию производительности и создание настраиваемых отчетов для всех уровней управления.

## 📁 Структура модуля

### 📈 Metrics System (Система метрик и KPI)
- **MetricsOrchestrator** - централизованное управление метриками
- **Real-time data collection** - сбор данных в реальном времени
- **Custom KPI configuration** - настраиваемые ключевые показатели
- **Multi-module metrics** - метрики из всех модулей системы

### 🔄 Real-time Monitoring (Мониторинг в реальном времени)
- **WebSocket connections** - live-обновления данных
- **Event-driven architecture** - архитектура на событиях
- **Performance alerts** - уведомления о производительности
- **System health monitoring** - мониторинг состояния системы

### ⚡ Performance Cache (Оптимизация производительности)
- **React Query caching** - кэширование данных на клиенте
- **Intelligent invalidation** - умная инвалидация кэша
- **Component memoization** - мемоизация компонентов
- **Bundle optimization** - оптимизация бандлов

### 📄 Reporting Engine (Движок отчетности)
- **Custom report builder** - конструктор отчетов
- **Export functionality** - экспорт в различные форматы
- **Scheduled reports** - автоматическая генерация отчетов
- **Data visualization** - визуализация данных

## 🎯 Ключевые компоненты

### MetricsOrchestrator
Центральный компонент для управления всеми метриками:

```typescript
<MetricsOrchestrator
  userId={user?.id || ''}
  workspaceId={workspaceId}
  maxVisible={4}
  showSettings={true}
  className="metrics-panel"
/>
```

### useMetrics Hook
Хук для загрузки и управления метриками:

```typescript
const {
  metrics,
  loading,
  error,
  loadMetrics,
  refreshMetric
} = useMetrics({
  module: MetricModule.HR,
  userId,
  workspaceId
});
```

## 📊 Типы метрик

- **COUNT** - количественные показатели
- **PERCENTAGE** - процентные значения  
- **TIME** - временные метрики
- **RATING** - рейтинговые оценки
- **CURRENCY** - денежные показатели

## 🔗 Связи с другими модулями

- **HR**: Метрики сотрудников, производительность команды
- **Finance**: Финансовые показатели, бюджет, ROI
- **Production**: Производственные метрики, качество
- **Sales**: Конверсии, воронка продаж, доходы

## 📋 API Endpoints

```
GET    /api/v1/workspaces/{id}/metrics
GET    /api/v1/workspaces/{id}/metrics/{metricId}/data
POST   /api/v1/workspaces/{id}/metrics/refresh
GET    /api/v1/workspaces/{id}/analytics/dashboard
POST   /api/v1/workspaces/{id}/reports/generate
```

## 🚨 Недавние исправления

### Проблема с пустыми метриками
**Проблема**: Метрики отображались как пустые карточки  
**Причина**: Dashboard использовал MetricsOrchestrator вместо исправленной логики  
**Решение**: Добавлено отладочное логирование в MetricsOrchestrator и useMetrics  

### Оптимизация производительности
- Мемоизация тяжелых вычислений в Dashboard (982 строки → оптимизировано)
- Исправление циклических зависимостей в useEffect
- Замена emergency timeout на elegant loading states

## 🧪 Тестирование

Тесты для analytics модуля находятся в `test-scripts/performance-tests/`.

---

*Этот модуль активно развивается и оптимизируется*