# 🚀 ONBOARDING FLOW - Детальная документация

## 📋 Общее описание
Onboarding flow - это завершающий этап регистрации после верификации email. Различается для owner и employee ролей.

⚠️ **ВАЖНО**: Не существует отдельного endpoint `/select-role`. Роль передается через обязательный параметр `selectedRole` в этом же запросе!

## 🎯 Endpoint
```
POST /api/v1/auth/registration/onboarding/complete
```

## 📊 Различия по ролям

### Owner Onboarding
- Создает новую организацию
- Автоматически создает 8 департаментов
- Получает главный workspace компании
- Сразу активен и может войти

### Employee Onboarding
- Присоединяется к существующей организации
- Получает статус "pending"
- Требует одобрения владельца
- Не может войти до одобрения

## 🔄 OWNER ONBOARDING

### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/registration/onboarding/complete
Content-Type: application/json
Authorization: Bearer {token_from_verify_email}

{
  "email": "owner_test_1755882547@mybusiness.kz",
  "userId": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
  "selectedRole": "owner",  // ⚠️ ОБЯЗАТЕЛЬНО!
  "companyName": "ТОО Успешный Бизнес Новый",
  "companyBin": "987654321098",  // ОБЯЗАТЕЛЬНО 12 цифр!
  "companyType": "ТОО",
  "industry": "IT",
  "companyAddress": "г. Алматы, ул. Абая 150",
  "companyPhone": "+77273456789",
  "employeeCount": "10-50",
  "website": "https://mybusiness.kz"
}
```

### 📥 RESPONSE SUCCESS (200 OK)
```json
{
  "success": true,
  "message": "Onboarding completed successfully",
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": "e918d6de-9d72-4dc6-b223-96cf13a73bfc",
  "email": "owner_test_1755882547@mybusiness.kz",
  "firstName": "Асылбек",
  "lastName": "Нурланов",
  "fullName": "Асылбек Нурланов",
  "role": "owner",
  "status": "active",
  "registrationStatus": "active",
  "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
  "workspaceId": "df082cb8-a880-448f-8abf-6d29e918e186",
  "employeeId": null,
  "position": "CEO",
  "department": "Руководство",
  "departmentId": "leadership-dept-id",
  "phoneNumber": "+77012345678",
  "avatar": null,
  "onboardingCompleted": true,
  "hasCompany": true,
  "isFirstLogin": true,
  "emailVerified": true,
  "isActive": true,
  "organizationInfo": {
    "id": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
    "name": "ТОО Успешный Бизнес Новый",
    "bin": "987654321098",
    "type": "ТОО",
    "industry": "IT",
    "address": "г. Алматы, ул. Абая 150",
    "phone": "+77273456789",
    "employeeCount": "10-50",
    "website": "https://mybusiness.kz",
    "createdAt": "2025-08-22T18:22:36.000Z",
    "createdDepartments": [
      {
        "id": "dept-1",
        "name": "Руководство",
        "workspaceId": "ws-leadership"
      },
      {
        "id": "dept-2",
        "name": "Продажи",
        "workspaceId": "ws-sales"
      },
      {
        "id": "dept-3",
        "name": "Логистика",
        "workspaceId": "ws-logistics"
      },
      {
        "id": "dept-4",
        "name": "Маркетинг",
        "workspaceId": "ws-marketing"
      },
      {
        "id": "dept-5",
        "name": "Финансы",
        "workspaceId": "ws-finance"
      },
      {
        "id": "dept-6",
        "name": "Производство",
        "workspaceId": "ws-production"
      },
      {
        "id": "dept-7",
        "name": "Закупки",
        "workspaceId": "ws-procurement"
      },
      {
        "id": "dept-8",
        "name": "HR",
        "workspaceId": "ws-hr"
      }
    ]
  },
  "permissions": {
    "canManageEmployees": true,
    "canManageDepartments": true,
    "canViewFinances": true,
    "canEditCompanyInfo": true,
    "canApproveEmployees": true,
    "canDeleteData": true,
    "isAdmin": true
  }
}
```

### 📥 RESPONSE ERROR - БИН уже зарегистрирован (409 Conflict)
```json
{
  "success": false,
  "error": {
    "code": "BIN_ALREADY_EXISTS",
    "type": "ConflictError",
    "message": "Организация с таким БИН уже зарегистрирована",
    "details": {
      "bin": "987654321098",
      "existingOrganization": "ТОО Другая Компания"
    }
  }
}
```

## 🔄 EMPLOYEE ONBOARDING

### 📤 REQUEST
```http
POST http://localhost:5001/api/v1/auth/registration/onboarding/complete
Content-Type: application/json

{
  "email": "employee_1755885515@mail.kz",
  "userId": "7d103ddc-2f02-46df-90ae-f769d5950c20",
  "selectedRole": "employee",
  "companyName": "ТОО Успешный Бизнес Новый",
  "bin": "987654321098",
  "companyType": "ТОО",
  "industry": "IT",
  "requestedDepartment": "HR",
  "requestedPosition": "Junior Developer",
  "experience": "3 года",
  "skills": ["JavaScript", "React", "Node.js"],
  "requestMessage": "Хочу присоединиться к вашей команде"
}
```

### 📥 RESPONSE SUCCESS - Pending Status (200 OK)
```json
{
  "success": true,
  "message": "Employee onboarding completed. Waiting for admin approval.",
  "accessToken": null,
  "userId": "7d103ddc-2f02-46df-90ae-f769d5950c20",
  "email": "employee_1755885515@mail.kz",
  "firstName": "Айгуль",
  "lastName": "Смагулова",
  "fullName": "Айгуль Смагулова",
  "role": "employee",
  "status": "pending",
  "registrationStatus": "pending",
  "organizationId": "c3446549-cb87-4f38-9ba6-d5bebbf8380a",
  "organizationName": "ТОО Успешный Бизнес Новый",
  "workspaceId": null,
  "employeeId": "60f9366c-aa3f-4e6a-9ce8-8370f2e3daba",
  "position": null,
  "department": null,
  "departmentId": null,
  "phoneNumber": "+77017654321",
  "avatar": null,
  "onboardingCompleted": false,
  "hasCompany": true,
  "isFirstLogin": true,
  "emailVerified": true,
  "isActive": false,
  "requiresApproval": true,
  "approvalStatus": "pending",
  "requestedDepartment": "HR",
  "requestedPosition": "Junior Developer",
  "pendingInfo": {
    "submittedAt": "2025-08-22T18:34:16.000Z",
    "experience": "3 года",
    "skills": ["JavaScript", "React", "Node.js"],
    "requestMessage": "Хочу присоединиться к вашей команде",
    "estimatedReviewTime": "24-48 часов"
  },
  "nextSteps": [
    "Ваша заявка отправлена на рассмотрение",
    "Администратор организации получил уведомление",
    "Вы получите email после рассмотрения заявки",
    "После одобрения сможете войти в систему"
  ]
}
```

## 🔐 Проверки при onboarding

### Общие проверки
1. **Email верифицирован**
   ```json
   {
     "error": "EMAIL_NOT_VERIFIED",
     "message": "Email must be verified before completing onboarding"
   }
   ```

2. **User существует**
   ```json
   {
     "error": "USER_NOT_FOUND",
     "message": "User not found. Please register first"
   }
   ```

3. **Onboarding не завершен ранее**
   ```json
   {
     "error": "ONBOARDING_ALREADY_COMPLETED",
     "message": "Onboarding has already been completed"
   }
   ```

### Проверки для Owner
1. **БИН уникален**
2. **Название компании уникально**
3. **Все обязательные поля заполнены**

### Проверки для Employee
1. **БИН существует в системе**
2. **Организация активна**
3. **Организация принимает новых сотрудников**

## 🏗️ Автоматические действия

### При Owner Onboarding
```javascript
// Псевдокод backend процесса
async function completeOwnerOnboarding(data) {
  // 1. Создаем организацию
  const organization = await createOrganization({
    name: data.companyName,
    bin: data.bin,
    type: data.companyType,
    industry: data.industry
  });
  
  // 2. Создаем главный workspace
  const mainWorkspace = await createWorkspace({
    organizationId: organization.id,
    name: 'Main Workspace',
    type: 'company'
  });
  
  // 3. Создаем департаменты
  const departments = [
    'Руководство', 'Продажи', 'Логистика', 
    'Маркетинг', 'Финансы', 'Производство', 
    'Закупки', 'HR'
  ];
  
  for (const deptName of departments) {
    const deptWorkspace = await createWorkspace({
      organizationId: organization.id,
      name: `${deptName} Workspace`,
      type: 'department'
    });
    
    await createDepartment({
      name: deptName,
      organizationId: organization.id,
      workspaceId: deptWorkspace.id
    });
  }
  
  // 4. Обновляем user статус
  await updateUser(data.userId, {
    status: 'active',
    registrationStatus: 'active',
    organizationId: organization.id,
    workspaceId: mainWorkspace.id,
    onboardingCompleted: true
  });
  
  // 5. Генерируем JWT token
  const token = generateJWT({
    userId: data.userId,
    role: 'owner',
    organizationId: organization.id,
    workspaceId: mainWorkspace.id
  });
  
  return { token, organization, workspaces };
}
```

### При Employee Onboarding
```javascript
// Псевдокод backend процесса
async function completeEmployeeOnboarding(data) {
  // 1. Находим организацию по БИН
  const organization = await findOrganizationByBin(data.bin);
  
  if (!organization) {
    throw new Error('Organization not found');
  }
  
  // 2. Создаем employee запись
  const employee = await createEmployee({
    userId: data.userId,
    organizationId: organization.id,
    status: 'pending',
    requestedDepartment: data.requestedDepartment,
    requestedPosition: data.requestedPosition
  });
  
  // 3. Обновляем user статус
  await updateUser(data.userId, {
    status: 'pending',
    registrationStatus: 'pending',
    organizationId: organization.id,
    employeeId: employee.id,
    onboardingCompleted: false
  });
  
  // 4. Отправляем уведомление владельцу
  await notifyOwner(organization.ownerId, {
    type: 'NEW_EMPLOYEE_REQUEST',
    employeeId: employee.id,
    employeeName: `${data.firstName} ${data.lastName}`,
    requestedDepartment: data.requestedDepartment
  });
  
  // 5. НЕ генерируем токен (pending status)
  return { 
    employee, 
    requiresApproval: true,
    message: 'Waiting for approval'
  };
}
```

## 📝 Примеры использования

### JavaScript/TypeScript - Универсальный onboarding handler
```typescript
class OnboardingService {
  async completeOnboarding(userData: any) {
    const endpoint = 'http://localhost:5001/api/v1/auth/registration/onboarding/complete';
    
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(userData)
      });
      
      const data = await response.json();
      
      if (!data.success) {
        throw new Error(data.error.message);
      }
      
      // Обработка в зависимости от роли
      if (userData.selectedRole === 'owner') {
        return this.handleOwnerOnboarding(data);
      } else {
        return this.handleEmployeeOnboarding(data);
      }
      
    } catch (error) {
      console.error('Onboarding failed:', error);
      throw error;
    }
  }
  
  private handleOwnerOnboarding(data: any) {
    // Сохраняем токен и данные
    localStorage.setItem('accessToken', data.accessToken);
    localStorage.setItem('organizationId', data.organizationId);
    localStorage.setItem('workspaceId', data.workspaceId);
    localStorage.setItem('role', 'owner');
    localStorage.setItem('onboardingCompleted', 'true');
    
    // Показываем созданные департаменты
    console.log('Created departments:', data.organizationInfo.createdDepartments);
    
    // Redirect на dashboard
    window.location.href = '/dashboard';
    
    return {
      success: true,
      type: 'owner',
      canLogin: true
    };
  }
  
  private handleEmployeeOnboarding(data: any) {
    // Сохраняем базовую информацию
    localStorage.setItem('userId', data.userId);
    localStorage.setItem('email', data.email);
    localStorage.setItem('role', 'employee');
    localStorage.setItem('status', 'pending');
    localStorage.setItem('requiresApproval', 'true');
    
    // Показываем информацию о следующих шагах
    alert(data.nextSteps.join('\n'));
    
    // Redirect на страницу ожидания
    window.location.href = '/auth/pending-approval';
    
    return {
      success: true,
      type: 'employee',
      canLogin: false,
      requiresApproval: true
    };
  }
}
```

### Bash Script - Тестирование onboarding
```bash
#!/bin/bash

# Функция для owner onboarding
owner_onboarding() {
  local email=$1
  local userId=$2
  
  RESPONSE=$(curl -s -X POST http://localhost:5001/api/v1/auth/registration/onboarding/complete \
    -H "Content-Type: application/json" \
    -d "{
      \"email\": \"$email\",
      \"userId\": \"$userId\",
      \"selectedRole\": \"owner\",
      \"companyName\": \"Test Company\",
      \"bin\": \"123456789012\",
      \"companyType\": \"ТОО\",
      \"industry\": \"IT\"
    }")
  
  SUCCESS=$(echo $RESPONSE | jq -r '.success')
  
  if [[ "$SUCCESS" == "true" ]]; then
    TOKEN=$(echo $RESPONSE | jq -r '.accessToken')
    ORG_ID=$(echo $RESPONSE | jq -r '.organizationId')
    WS_ID=$(echo $RESPONSE | jq -r '.workspaceId')
    
    echo "✅ Owner onboarding successful!"
    echo "Token: ${TOKEN:0:40}..."
    echo "Organization: $ORG_ID"
    echo "Workspace: $WS_ID"
    
    # Показать созданные департаменты
    echo "Created departments:"
    echo $RESPONSE | jq -r '.organizationInfo.createdDepartments[].name'
  else
    ERROR=$(echo $RESPONSE | jq -r '.error.message')
    echo "❌ Onboarding failed: $ERROR"
  fi
}

# Функция для employee onboarding
employee_onboarding() {
  local email=$1
  local userId=$2
  local bin=$3
  
  RESPONSE=$(curl -s -X POST http://localhost:5001/api/v1/auth/registration/onboarding/complete \
    -H "Content-Type: application/json" \
    -d "{
      \"email\": \"$email\",
      \"userId\": \"$userId\",
      \"selectedRole\": \"employee\",
      \"companyName\": \"Existing Company\",
      \"bin\": \"$bin\",
      \"companyType\": \"ТОО\",
      \"industry\": \"IT\",
      \"requestedDepartment\": \"HR\",
      \"requestedPosition\": \"Developer\"
    }")
  
  SUCCESS=$(echo $RESPONSE | jq -r '.success')
  
  if [[ "$SUCCESS" == "true" ]]; then
    STATUS=$(echo $RESPONSE | jq -r '.status')
    REQUIRES_APPROVAL=$(echo $RESPONSE | jq -r '.requiresApproval')
    
    echo "✅ Employee onboarding successful!"
    echo "Status: $STATUS"
    echo "Requires approval: $REQUIRES_APPROVAL"
    
    if [[ "$REQUIRES_APPROVAL" == "true" ]]; then
      echo "⏳ Waiting for admin approval..."
      echo "Next steps:"
      echo $RESPONSE | jq -r '.nextSteps[]'
    fi
  else
    ERROR=$(echo $RESPONSE | jq -r '.error.message')
    echo "❌ Onboarding failed: $ERROR"
  fi
}

# Использование
echo "Testing Owner Onboarding:"
owner_onboarding "owner@test.com" "owner-user-id"

echo ""
echo "Testing Employee Onboarding:"
employee_onboarding "employee@test.com" "employee-user-id" "987654321098"
```

## ✅ Проверенные сценарии

1. ✅ Owner onboarding с созданием организации
2. ✅ Автоматическое создание 8 департаментов
3. ✅ Employee onboarding с pending status
4. ✅ Проверка email верификации
5. ✅ Проверка уникальности БИН
6. ✅ Блокировка повторного onboarding
7. ✅ Генерация JWT для owner
8. ✅ Отсутствие токена для pending employee

## 🚨 Известные проблемы

1. **Deduplication Service**
   - Содержит только TODO placeholders
   - Не работает проверка дубликатов компаний

2. **Email уведомления**
   - SMTP service отключен
   - Владелец не получает уведомления о новых сотрудниках

3. **Workspace Creation**
   - Иногда workspace не создается для департаментов
   - Требуется ручное создание

## 🔗 Связанные endpoints

- `/api/v1/auth/registration/pre-register` - Начало регистрации
- `/api/v1/auth/registration/verify-email` - Верификация email
- `/api/v1/auth/login` - Вход после onboarding
- `/api/v1/workspaces/{id}/departments` - Управление департаментами
- `/api/v1/workspaces/{id}/employee-management/pending-employees` - Pending сотрудники