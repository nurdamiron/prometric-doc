# ✅ АКТУАЛЬНЫЕ AUTH ENDPOINTS

## 📋 ТОЛЬКО ЭТИ ENDPOINTS СУЩЕСТВУЮТ

### 🔐 Основные Auth endpoints
```
POST /api/v1/auth/login                                  # Вход в систему
POST /api/v1/auth/logout                                 # Выход из системы
POST /api/v1/auth/refresh                                # Обновление токена
GET  /api/v1/auth/profile                                # Получение профиля
```


### 📝 Registration endpoints
```
POST /api/v1/auth/registration/pre-register              # Предварительная регистрация
POST /api/v1/auth/registration/verify-email              # Верификация email
POST /api/v1/auth/registration/onboarding/complete       # Завершение onboarding (С РОЛЬЮ!)
POST /api/v1/auth/registration/resend-verification       # Повторная отправка кода
```

### 🏢 Company Management
```
POST /api/v1/companies/validate-bin                      # Валидация БИН
GET  /api/v1/company/pending-registrations               # Список ожидающих одобрения
POST /api/v1/company/approve-registration                # Одобрение employee
```

### 👥 Employees & Departments  
```
GET  /api/v1/workspaces/:id/employees                    # Список сотрудников
GET  /api/v1/workspaces/:id/departments                  # Список департаментов
POST /api/v1/workspaces/:id/employees/:id/assign         # Назначение в департамент
```

## ❌ НЕ СУЩЕСТВУЮЩИЕ ENDPOINTS (УДАЛЕНЫ)

```
❌ POST /api/v1/auth/select-role                         # НЕТ! Роль передается в onboarding/complete
❌ GET  /api/v1/auth/token-from-cookie                   # НЕТ! Используем Bearer токены
❌ POST /api/v1/auth/register                            # НЕТ! Используем pre-register
```

## ⚠️ КРИТИЧЕСКИ ВАЖНЫЕ ПАРАМЕТРЫ

### Для OWNER при onboarding/complete:
```json
{
  "selectedRole": "owner",      // ⚠️ ОБЯЗАТЕЛЬНО!
  "companyBin": "123456789012", // ⚠️ ОБЯЗАТЕЛЬНО! 12 цифр, уникальный
  "userId": "uuid",              // ⚠️ ОБЯЗАТЕЛЬНО!
  "email": "email",              // ⚠️ ОБЯЗАТЕЛЬНО!
  "companyName": "Название",
  "companyType": "ТОО",
  "industry": "IT"
}
```

### Для EMPLOYEE при onboarding/complete:
```json
{
  "selectedRole": "employee",          // ⚠️ ОБЯЗАТЕЛЬНО!
  "employeeCompanyBin": "123456789012", // ⚠️ ОБЯЗАТЕЛЬНО! БИН компании
  "userId": "uuid",                      // ⚠️ ОБЯЗАТЕЛЬНО!
  "email": "email",                      // ⚠️ ОБЯЗАТЕЛЬНО!
  "position": "Developer",
  "message": "Прошу принять"
}
```

## 🔑 ПРАВИЛЬНАЯ ПОСЛЕДОВАТЕЛЬНОСТЬ

### Owner Registration:
1. `POST /auth/registration/pre-register` - создание пользователя
2. `POST /auth/registration/verify-email` - верификация email
3. `POST /auth/registration/onboarding/complete` - создание организации с `selectedRole: "owner"`

### Employee Registration:
1. `POST /auth/registration/pre-register` - с `organizationBin`
2. `POST /auth/registration/verify-email` - верификация email  
3. `POST /auth/registration/onboarding/complete` - с `selectedRole: "employee"`
4. Ожидание одобрения owner'ом
5. `POST /company/approve-registration` - owner одобряет

## 📌 ЗАМЕТКИ

1. **НЕТ /select-role** - роль передается в параметре `selectedRole` при вызове `/onboarding/complete`
2. **БИН обязателен** - для owner при создании, для employee при присоединении
3. **Bearer токены** - не используем httpOnly cookies
4. **Статус pending** - employee может логиниться, но с ограничениями до одобрения