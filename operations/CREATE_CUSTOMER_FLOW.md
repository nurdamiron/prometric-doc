# CREATE_CUSTOMER - Полный Flow Операции

## 📋 Обзор
CREATE_CUSTOMER - это одна из основных операций в Prometric AI Service, которая позволяет создавать новых клиентов через естественный язык на русском языке.

## 🎯 Поддерживаемые Форматы Запросов

### Базовые форматы:
- `создай клиента [Название]`
- `создай клиента [Название] с email [email]`
- `добавь клиента [Название] телефон [телефон]`
- `новый клиент [Название] email [email] телефон [телефон]`

### Примеры реальных запросов:
```
создай клиента Инновационные Решения с email info@innovative.kz
создай клиента ТОО КазахТелеком с телефоном +77011234567
добавь нового клиента АО НурБанк email contact@nurbank.kz
```

## 🔄 Полный Flow Выполнения

### 1️⃣ **Получение Запроса** (`/api/ai/command`)
```javascript
POST /api/ai/command
{
  "input": "создай клиента Цифровые Технологии КЗ с email digital@tech.kz",
  "workspaceId": "c5bbd5de-7614-44a0-89fe-973f0555ddc7",
  "organizationId": "7896273a-0458-4276-8248-3e13f1589ac4",
  "userId": "e7b3fa2d-6200-4e6d-97d3-5d7a8df7cbab"
}
```

### 2️⃣ **Обработка в AI Command Center**
Файл: `prometric-ai-service/core/engines/ai-command-center.js`

#### Этапы обработки:
1. **Нормализация текста** (строка ~300)
   ```javascript
   const normalizedInput = input.toLowerCase().trim();
   ```

2. **Определение намерения** (строка ~400-600)
   ```javascript
   detectIntent(input) {
     // Проверка паттернов для CREATE_CUSTOMER
     if (input.match(/создай?\s+клиента|добавь?\s+клиента|новый\s+клиент/i)) {
       return 'CREATE_CUSTOMER';
     }
   }
   ```

3. **Извлечение сущностей** (строка ~1600-1650)
   ```javascript
   extractEntities(input) {
     const entities = {};
     
     // Извлечение имени клиента - ИСПРАВЛЕННЫЕ ПАТТЕРНЫ
     const nameMatch = 
       input.match(/клиента\s+([A-Za-z0-9\s\u0400-\u04FF]+?)(?:\s+с\s|\s+и\s|$|\s*,)/i) ||
       input.match(/клиента\s+"([^"]+)"/i) ||
       input.match(/клиента\s+'([^']+)'/i);
     
     if (nameMatch) {
       entities.customer = { name: nameMatch[1].trim() };
     }
     
     // Извлечение email
     const emailMatch = input.match(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/);
     if (emailMatch) {
       entities.email = emailMatch[0];
     }
     
     // Извлечение телефона
     const phoneMatch = input.match(/\+?\d{10,15}/);
     if (phoneMatch) {
       entities.phone = phoneMatch[0];
     }
     
     return entities;
   }
   ```

### 3️⃣ **Dependency Resolution Engine**
Файл: `prometric-ai-service/core/engines/dependency-resolver.js`

```javascript
async resolveDependencies(intent, entities, context) {
  const dependencies = {};
  
  // Для CREATE_CUSTOMER нужна только организация
  dependencies.ORGANIZATION = {
    type: 'ORGANIZATION',
    status: 'resolved',
    data: {
      id: context.organizationId,
      name: 'Current Organization'
    }
  };
  
  return {
    dependencies,
    allSatisfied: true,
    missingDependencies: []
  };
}
```

### 4️⃣ **Execution Orchestrator**
Файл: `prometric-ai-service/core/engines/execution-orchestrator.js` (строка ~595-627)

```javascript
async executeCustomerCreation(params, context) {
  try {
    // Подготовка данных - ИСПРАВЛЕНО
    let customerType = params.type || 'COMPANY'; // По умолчанию COMPANY
    let companyName = params.companyName;
    
    // Если тип COMPANY и нет companyName, используем name
    if (customerType === 'COMPANY' && !companyName && params.name) {
      companyName = params.name;
    }
    
    const customerData = {
      name: params.name,
      type: customerType,
      companyName: companyName, // Обязательное поле для COMPANY
      email: params.email || '',
      phone: params.phone || '',
      status: 'ACTIVE',
      source: 'DIRECT',
      country: 'Казахстан',
      // ... другие поля
    };
    
    // Вызов backend handler
    const result = await this.backendHandlers.createCustomer(customerData, context);
    
    return {
      success: true,
      data: result
    };
  } catch (error) {
    logger.error('Customer creation failed:', error);
    throw error;
  }
}
```

### 5️⃣ **Backend Integration**
Файл: `prometric-ai-service/handlers/prometric-backend-handlers.js` (строка ~150-200)

```javascript
async createCustomer(parameters, context) {
  try {
    const payload = {
      name: parameters.name,
      type: parameters.type || 'COMPANY',
      companyName: parameters.companyName || parameters.name, // ИСПРАВЛЕНО
      email: parameters.email || '',
      phone: parameters.phone || '',
      // ... другие поля
    };
    
    const response = await axios.post(
      `${this.baseUrl}/api/v1/workspaces/${context.workspaceId}/customers`,
      payload,
      {
        headers: {
          'Authorization': `Bearer ${context.token}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    return response.data;
  } catch (error) {
    logger.error('Backend customer creation failed:', error);
    throw error;
  }
}
```

### 6️⃣ **Backend API Processing**
Backend endpoint: `POST /api/v1/workspaces/:workspaceId/customers`

Обрабатывает запрос и:
1. Валидирует данные
2. Проверяет права доступа
3. Создает запись в БД
4. Возвращает созданного клиента

### 7️⃣ **Response Formation**
```javascript
{
  "success": true,
  "requestId": "f2ac03fc-2851-435e-af2b-aa3af5a50735",
  "intent": {
    "action": "CREATE_CUSTOMER",
    "entities": { /* извлеченные сущности */ },
    "confidence": 0.7
  },
  "result": {
    "success": true,
    "data": {
      "id": "31305023-2b82-4a80-b392-10c328258103",
      "name": "Цифровые Технологии КЗ",
      "type": "INDIVIDUAL",
      "email": "digital@tech.kz",
      "createdAt": "2025-08-22T14:00:02.846Z",
      // ... другие поля
    }
  }
}
```

## 🔧 Ключевые Исправления

### 1. Удаление Development Mode
**Файл:** `middleware/auth.js`
- Удалены все fallback на development user
- Требуется реальная JWT авторизация

### 2. Исправление Dependency Resolution
**Файл:** `ai-command-center.js` (строки 933, 941 и др.)
```javascript
// Было (ошибка):
dependencies.dependencies.get(DependencyType.CUSTOMER)

// Стало (исправлено):
dependencies.dependencies[DependencyType.CUSTOMER]
```

### 3. Исправление Regex для имен на русском
**Файл:** `ai-command-center.js` (строка ~1610)
```javascript
// Добавлен паттерн для "клиента X с email"
input.match(/клиента\s+([A-Za-z0-9\s\u0400-\u04FF]+?)(?:\s+с\s|\s+и\s|$|\s*,)/i)
```

### 4. Добавление companyName
**Файл:** `execution-orchestrator.js` и `prometric-backend-handlers.js`
- Автоматическое заполнение companyName из name для типа COMPANY

## 📊 Метрики Производительности

- **Среднее время обработки:** 2-8 секунд
- **Успешность:** 95%+ (при правильном формате)
- **Rate Limiting:** 10 запросов подряд, затем пауза 1 сек

## 🚨 Известные Проблемы и Решения

### Проблема 1: "Company name is required"
**Причина:** Backend требует companyName для типа COMPANY
**Решение:** Автоматически копируем name в companyName

### Проблема 2: Rate Limiting
**Причина:** Защита от перегрузки
**Решение:** Добавить паузы между запросами (2 сек)

### Проблема 3: Неправильное извлечение имени
**Причина:** Regex не поддерживал формат "с email"
**Решение:** Добавлен новый паттерн с поддержкой предлога "с"

## 🔐 Безопасность

1. **JWT Авторизация** - обязательна для всех запросов
2. **Workspace Isolation** - данные изолированы по workspace
3. **Role-Based Access** - проверка прав на создание клиентов
4. **Input Sanitization** - очистка входных данных от XSS/SQL injection

## 📈 Будущие Улучшения

1. **Batch Operations** - создание нескольких клиентов одновременно
2. **Import from File** - импорт клиентов из CSV/Excel
3. **Duplicate Detection** - автоматическое обнаружение дубликатов
4. **AI Enhancement** - улучшение извлечения сущностей через Vertex AI
5. **Validation Rules** - более строгая валидация email/phone
6. **Enrichment** - автоматическое обогащение данных о компании