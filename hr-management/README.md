# 👥 HR Management Module Documentation

## 📖 Обзор модуля управления персоналом

Модуль HR Management обеспечивает полный цикл управления человеческими ресурсами в организации: от найма сотрудников до отслеживания их производительности и расчета заработной платы.

## 📁 Структура модуля

### 🎯 Employee Onboarding (Процесс найма и адаптации)
- Управление вакансиями и кандидатами
- Процесс собеседований
- Документооборот при найме
- Адаптационные программы

### 💰 Payroll System (Система расчета зарплат)
- Расчет заработной платы
- Управление бонусами и премиями
- Налоговые расчеты
- Интеграция с банковскими системами

### 📊 Performance Tracking (Отслеживание эффективности)
- Система KPI и целей
- Регулярные оценки производительности
- 360-градусная обратная связь
- Планы развития сотрудников

### 🏢 Department Structure (Организационная структура)
- Иерархия отделов и должностей
- Управление подчиненностью
- Роли и полномочия
- Организационные изменения

## 🔗 Связи с другими модулями

- **Authentication**: Управление ролями и доступом
- **Finance**: Интеграция с бюджетом и фонд оплаты труда
- **Analytics**: Метрики и отчеты по персоналу
- **Sales**: Распределение клиентов по менеджерам

## 📋 API Endpoints

Основные endpoints для работы с HR модулем:

```
GET    /api/v1/workspaces/{id}/employees
POST   /api/v1/workspaces/{id}/employees
PUT    /api/v1/workspaces/{id}/employees/{employeeId}
DELETE /api/v1/workspaces/{id}/employees/{employeeId}

GET    /api/v1/workspaces/{id}/departments
POST   /api/v1/workspaces/{id}/departments
PUT    /api/v1/workspaces/{id}/departments/{deptId}

GET    /api/v1/workspaces/{id}/payroll
POST   /api/v1/workspaces/{id}/payroll/calculate
```

## 🧪 Тестирование

Каждый компонент HR модуля имеет соответствующие тесты в папке `test-scripts/hr-testing/`.

---

*Документация находится в разработке и будет дополняться*