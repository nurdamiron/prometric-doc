# ✅ EMPLOYEE APPROVAL FLOW - Детальная документация

## 📋 Общее описание
Employee approval flow - это процесс одобрения или отклонения заявок сотрудников владельцем организации. После одобрения сотрудник получает доступ к системе и назначается в департамент.

## 🎯 Основные endpoints
1. `GET /api/v1/workspaces/{workspaceId}/employee-management/pending-employees` - Получение списка pending
2. `GET /api/v1/workspaces/{workspaceId}/departments` - Получение департаментов
3. `POST /api/v1/workspaces/{workspaceId}/employee-management/employees/{employeeId}/approve` - Одобрение
4. `POST /api/v1/workspaces/{workspaceId}/employee-management/employees/{employeeId}/reject` - Отклонение

## 📊 Детальный процесс одобрения

### ШАГ 1: Авторизация владельца

#### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/login
Content-Type: application/json

{
  "email": "owner_test_1755882547@mybusiness.kz",
  "password": "MySecurePass123!"
}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
  "role": "owner",
  "workspaceId": "df082cb8-a880-448f-8abf-6d29e918e186",
  "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a"
}
```

### ШАГ 2: Получение списка pending employees

#### 📤 REQUEST (Owner Only)
```http
GET http://localhost:5001/api/v1/workspaces/df082cb8-a880-448f-8abf-6d29e918e186/employee-management/pending-employees
Authorization: Bearer {OWNER_TOKEN}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "id": "60f9366c-aa3f-4e6a-9ce8-8370f2e3daba",
      "userId": "7d103ddc-2f02-46df-90ae-f769d5950c20",
      "name": "Айгуль Смагулова",
      "email": "employee_1755885515@mail.kz",
      "phone": "+77017654321",
      "registrationStatus": "pending",
      "registeredAt": "2025-08-22T18:33:45.000Z",
      "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
      "requestedRole": "employee",
      "position": null,
      "department": null,
      "additionalInfo": {
        "requestMessage": "Хочу присоединиться к команде",
        "experience": "3 года в IT"
      }
    }
  ],
  "pagination": {
    "total": 1,
    "page": 1,
    "limit": 10,
    "hasMore": false
  }
}
```

#### 📥 RESPONSE ERROR - Не владелец (403 Forbidden)
```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "type": "AuthorizationError",
    "message": "Only organization owner can view pending employees"
  }
}
```

### ШАГ 3: Получение списка департаментов

#### 📤 REQUEST
```http
GET http://localhost:5001/api/v1/workspaces/df082cb8-a880-448f-8abf-6d29e918e186/departments
Authorization: Bearer {OWNER_TOKEN}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
[
  {
    "id": "fb13e095-f1a5-4ad8-82a1-6b420204f5d6",
    "name": "HR",
    "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
    "workspaceId": "0e7ce9b4-1149-4fb4-ba08-f18a86f47dc2",
    "isActive": true,
    "description": "Управление персоналом",
    "managerId": null,
    "employeeCount": 0,
    "createdAt": "2025-08-22T18:22:36.000Z"
  },
  {
    "id": "a3f8c123-b456-4789-9012-def345678901",
    "name": "Продажи",
    "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
    "workspaceId": "sales-workspace-id",
    "isActive": true,
    "description": "Отдел продаж",
    "managerId": null,
    "employeeCount": 5,
    "createdAt": "2025-08-22T18:22:36.000Z"
  },
  {
    "id": "b2e7d234-c567-4890-1234-abc456789012",
    "name": "Финансы",
    "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
    "workspaceId": "finance-workspace-id",
    "isActive": true,
    "description": "Финансовый отдел",
    "managerId": null,
    "employeeCount": 3,
    "createdAt": "2025-08-22T18:22:36.000Z"
  }
]
```

### ШАГ 4: Одобрение сотрудника

#### 📤 REQUEST (Owner Only)
```http
POST http://localhost:5001/api/v1/workspaces/df082cb8-a880-448f-8abf-6d29e918e186/employee-management/employees/60f9366c-aa3f-4e6a-9ce8-8370f2e3daba/approve
Authorization: Bearer {OWNER_TOKEN}
Content-Type: application/json

{
  "approved": true,
  "departmentId": "fb13e095-f1a5-4ad8-82a1-6b420204f5d6",
  "position": "Junior Developer",
  "organizationRole": "EMPLOYEE",
  "accessLevel": "basic",
  "permissions": {
    "canViewReports": false,
    "canManageTeam": false,
    "canApproveExpenses": false
  }
}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "message": "Employee approved and activated successfully",
  "data": {
    "employeeId": "60f9366c-aa3f-4e6a-9ce8-8370f2e3daba",
    "userId": "7d103ddc-2f02-46df-90ae-f769d5950c20",
    "name": "Айгуль Смагулова",
    "email": "employee_1755885515@mail.kz",
    "status": "active",
    "registrationStatus": "active",
    "department": "HR",
    "departmentId": "fb13e095-f1a5-4ad8-82a1-6b420204f5d6",
    "position": "Junior Developer",
    "organizationRole": "EMPLOYEE",
    "workspaceId": "0e7ce9b4-1149-4fb4-ba08-f18a86f47dc2",
    "activatedAt": "2025-08-22T18:40:00.000Z",
    "approvedBy": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
    "notificationSent": true
  }
}
```

#### 📥 RESPONSE ERROR - Отсутствует departmentId (400 Bad Request)
```json
{
  "success": false,
  "error": {
    "code": "DEPARTMENT_REQUIRED",
    "type": "ValidationError",
    "message": "Department ID is required for employee approval",
    "details": {
      "field": "departmentId",
      "requirement": "Must be a valid department ID"
    }
  }
}
```

#### 📥 RESPONSE ERROR - Сотрудник не найден (404 Not Found)
```json
{
  "success": false,
  "error": {
    "code": "EMPLOYEE_NOT_FOUND",
    "type": "NotFoundError",
    "message": "Employee not found or not in pending status"
  }
}
```

### ШАГ 5: Отклонение сотрудника (альтернатива)

#### 📤 REQUEST (Owner Only)
```http
POST http://localhost:5001/api/v1/workspaces/df082cb8-a880-448f-8abf-6d29e918e186/employee-management/employees/60f9366c-aa3f-4e6a-9ce8-8370f2e3daba/reject
Authorization: Bearer {OWNER_TOKEN}
Content-Type: application/json

{
  "reason": "Не соответствует требованиям позиции",
  "canReapply": true,
  "reapplyAfterDays": 90
}
```

#### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "message": "Employee application rejected",
  "data": {
    "employeeId": "60f9366c-aa3f-4e6a-9ce8-8370f2e3daba",
    "status": "rejected",
    "rejectionReason": "Не соответствует требованиям позиции",
    "canReapply": true,
    "reapplyAfter": "2025-11-20T00:00:00.000Z",
    "rejectedBy": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
    "rejectedAt": "2025-08-22T18:40:00.000Z",
    "notificationSent": true
  }
}
```

## 🔄 Изменения статуса сотрудника

### До одобрения
```json
{
  "status": "pending",
  "registrationStatus": "pending",
  "isActive": false,
  "workspaceId": null,
  "departmentId": null,
  "position": null,
  "canLogin": false
}
```

### После одобрения
```json
{
  "status": "active",
  "registrationStatus": "active",
  "isActive": true,
  "workspaceId": "0e7ce9b4-1149-4fb4-ba08-f18a86f47dc2",
  "departmentId": "fb13e095-f1a5-4ad8-82a1-6b420204f5d6",
  "department": "HR",
  "position": "Junior Developer",
  "organizationRole": "EMPLOYEE",
  "canLogin": true
}
```

### После отклонения
```json
{
  "status": "rejected",
  "registrationStatus": "rejected",
  "isActive": false,
  "rejectionReason": "Не соответствует требованиям позиции",
  "canReapply": true,
  "reapplyAfter": "2025-11-20T00:00:00.000Z",
  "canLogin": false
}
```

## 🔔 Уведомления

### Email уведомление сотруднику при одобрении
```
Subject: Ваша заявка одобрена!

Здравствуйте, Айгуль!

Ваша заявка на присоединение к организации "ТОО Успешный Бизнес Новый" была одобрена.

Детали:
- Департамент: HR
- Позиция: Junior Developer
- Доступ к системе: Активен

Вы можете войти в систему используя свой email и пароль.

С уважением,
Команда Prometric
```

### Email уведомление при отклонении
```
Subject: Статус вашей заявки

Здравствуйте, Айгуль!

К сожалению, ваша заявка была отклонена.

Причина: Не соответствует требованиям позиции

Вы можете подать заявку повторно через 90 дней.

С уважением,
Команда Prometric
```

## 📝 Примеры использования в коде

### JavaScript/TypeScript - Полный процесс одобрения
```typescript
class EmployeeApprovalService {
  constructor(private apiBase: string, private ownerToken: string) {}
  
  async getPendingEmployees(workspaceId: string) {
    const response = await fetch(
      `${this.apiBase}/workspaces/${workspaceId}/employee-management/pending-employees`,
      {
        headers: {
          'Authorization': `Bearer ${this.ownerToken}`
        }
      }
    );
    return response.json();
  }
  
  async getDepartments(workspaceId: string) {
    const response = await fetch(
      `${this.apiBase}/workspaces/${workspaceId}/departments`,
      {
        headers: {
          'Authorization': `Bearer ${this.ownerToken}`
        }
      }
    );
    return response.json();
  }
  
  async approveEmployee(
    workspaceId: string,
    employeeId: string,
    departmentId: string,
    position: string
  ) {
    const response = await fetch(
      `${this.apiBase}/workspaces/${workspaceId}/employee-management/employees/${employeeId}/approve`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.ownerToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          approved: true,
          departmentId,
          position,
          organizationRole: 'EMPLOYEE'
        })
      }
    );
    
    const data = await response.json();
    
    if (!data.success) {
      throw new Error(data.error.message);
    }
    
    return data;
  }
  
  async rejectEmployee(
    workspaceId: string,
    employeeId: string,
    reason: string
  ) {
    const response = await fetch(
      `${this.apiBase}/workspaces/${workspaceId}/employee-management/employees/${employeeId}/reject`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.ownerToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          reason,
          canReapply: true,
          reapplyAfterDays: 90
        })
      }
    );
    
    return response.json();
  }
  
  // Полный workflow
  async processEmployeeApprovals(workspaceId: string) {
    try {
      // 1. Получаем pending employees
      const pendingData = await this.getPendingEmployees(workspaceId);
      
      if (pendingData.data.length === 0) {
        console.log('Нет pending employees');
        return;
      }
      
      // 2. Получаем департаменты
      const departments = await this.getDepartments(workspaceId);
      
      // 3. Обрабатываем каждого сотрудника
      for (const employee of pendingData.data) {
        console.log(`Обработка: ${employee.name} (${employee.email})`);
        
        // Выбираем департамент (например, HR)
        const hrDept = departments.find(d => d.name === 'HR');
        
        if (hrDept) {
          // Одобряем сотрудника
          const result = await this.approveEmployee(
            workspaceId,
            employee.id,
            hrDept.id,
            'Junior Developer'
          );
          
          console.log(`✅ Одобрен: ${employee.name}`);
          console.log(`   Департамент: ${hrDept.name}`);
          console.log(`   Workspace: ${result.data.workspaceId}`);
        }
      }
      
    } catch (error) {
      console.error('Ошибка обработки:', error);
    }
  }
}

// Использование
const approvalService = new EmployeeApprovalService(
  'http://localhost:5001/api/v1',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
);

approvalService.processEmployeeApprovals('df082cb8-a880-448f-8abf-6d29e918e186');
```

### Bash Script - Автоматическое одобрение
```bash
#!/bin/bash

API_BASE="http://localhost:5001/api/v1"
OWNER_EMAIL="owner_test_1755882547@mybusiness.kz"
OWNER_PASSWORD="MySecurePass123!"

# Login as owner
LOGIN_RESPONSE=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$OWNER_EMAIL\",\"password\":\"$OWNER_PASSWORD\"}")

OWNER_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.accessToken')
WORKSPACE_ID=$(echo $LOGIN_RESPONSE | jq -r '.workspaceId')

echo "Owner logged in. Workspace: $WORKSPACE_ID"

# Get pending employees
PENDING=$(curl -s -X GET "$API_BASE/workspaces/$WORKSPACE_ID/employee-management/pending-employees" \
  -H "Authorization: Bearer $OWNER_TOKEN")

PENDING_COUNT=$(echo $PENDING | jq '.data | length')
echo "Found $PENDING_COUNT pending employees"

if [ "$PENDING_COUNT" -gt 0 ]; then
  # Get departments
  DEPARTMENTS=$(curl -s -X GET "$API_BASE/workspaces/$WORKSPACE_ID/departments" \
    -H "Authorization: Bearer $OWNER_TOKEN")
  
  # Get first department ID
  DEPT_ID=$(echo $DEPARTMENTS | jq -r '.[0].id')
  DEPT_NAME=$(echo $DEPARTMENTS | jq -r '.[0].name')
  
  echo "Using department: $DEPT_NAME ($DEPT_ID)"
  
  # Process each pending employee
  echo $PENDING | jq -r '.data[] | @json' | while read employee; do
    EMPLOYEE_ID=$(echo $employee | jq -r '.id')
    EMPLOYEE_NAME=$(echo $employee | jq -r '.name')
    
    echo "Approving: $EMPLOYEE_NAME"
    
    # Approve employee
    APPROVAL_RESPONSE=$(curl -s -X POST \
      "$API_BASE/workspaces/$WORKSPACE_ID/employee-management/employees/$EMPLOYEE_ID/approve" \
      -H "Authorization: Bearer $OWNER_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"approved\": true,
        \"departmentId\": \"$DEPT_ID\",
        \"position\": \"Junior Developer\",
        \"organizationRole\": \"EMPLOYEE\"
      }")
    
    SUCCESS=$(echo $APPROVAL_RESPONSE | jq -r '.success')
    
    if [ "$SUCCESS" = "true" ]; then
      echo "✅ Approved successfully"
    else
      ERROR=$(echo $APPROVAL_RESPONSE | jq -r '.error.message')
      echo "❌ Failed: $ERROR"
    fi
  done
fi
```

## ✅ Проверенные сценарии

1. ✅ Получение списка pending employees владельцем
2. ✅ Блокировка доступа для не-владельцев
3. ✅ Получение списка департаментов
4. ✅ Успешное одобрение с назначением в департамент
5. ✅ Ошибка при отсутствии departmentId
6. ✅ Изменение статуса на active после одобрения
7. ✅ Назначение workspace от департамента
8. ✅ Возможность входа после одобрения

## 🚨 Известные проблемы

1. **Email уведомления не работают**
   - SMTP service отключен
   - Уведомления возвращают fake success

2. **Нет массового одобрения**
   - Каждый сотрудник одобряется отдельно
   - Нет bulk approval endpoint

3. **Отсутствует история изменений**
   - Нет audit log для approval/rejection
   - Не сохраняется кто и когда одобрил

## 🔗 Связанные endpoints

- `/api/v1/auth/registration/pre-register` - Регистрация сотрудника
- `/api/v1/auth/login` - Вход после одобрения
- `/api/v1/workspaces/{id}/employee-management/employees` - Список всех сотрудников
- `/api/v1/workspaces/{id}/departments/{id}/assign-employee` - Переназначение в другой департамент