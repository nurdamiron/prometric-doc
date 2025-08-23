# ✅ АКТУАЛЬНЫЕ AUTH ENDPOINTS (ПРОВЕРЕНО 23.08.2025)

## 📋 ТОЛЬКО ЭТИ ENDPOINTS СУЩЕСТВУЮТ И РАБОТАЮТ

### 🔐 Основные Auth endpoints
```
POST /api/v1/auth/login                                  # Вход в систему ✅
POST /api/v1/auth/logout                                 # Выход из системы ✅
POST /api/v1/auth/refresh                                # НЕ РАБОТАЕТ (refresh token отключен)
GET  /api/v1/auth/profile                                # Получение профиля ✅
```

### 📝 Registration endpoints
```
POST /api/v1/auth/registration/pre-register              # Предварительная регистрация ✅
POST /api/v1/auth/registration/verify-email              # Верификация email ✅ (но всегда возвращает success: false)
POST /api/v1/auth/registration/onboarding/complete       # Завершение onboarding ✅ (С РОЛЬЮ!)
POST /api/v1/auth/registration/resend-verification       # НЕ ТЕСТИРОВАЛСЯ
```

### 🏢 Employee Management
```
GET  /api/v1/workspaces/:id/employee-management/pending-employees    # Список pending сотрудников ✅
POST /api/v1/workspaces/:id/employee-management/employees/:id/approve # Одобрение employee ✅
POST /api/v1/workspaces/:id/employee-management/employees/:id/reject  # Отклонение employee (НЕ ТЕСТИРОВАЛСЯ)
```

### 👥 Departments  
```
GET  /api/v1/workspaces/:id/departments                  # Список департаментов ✅
```

## ❌ НЕ СУЩЕСТВУЮЩИЕ ENDPOINTS (УДАЛЕНЫ)

```
❌ POST /api/v1/auth/select-role                         # НЕТ! Роль передается в onboarding/complete
❌ GET  /api/v1/auth/token-from-cookie                   # НЕТ! Используем Bearer токены
❌ POST /api/v1/auth/register                            # НЕТ! Используем pre-register
```

## ⚠️ КРИТИЧЕСКИ ВАЖНЫЕ ПАРАМЕТРЫ И ИЗВЕСТНЫЕ БАГИ

### Для OWNER при onboarding/complete:
```json
{
  "email": "email",              // ⚠️ ОБЯЗАТЕЛЬНО!
  "selectedRole": "owner",       // ⚠️ ОБЯЗАТЕЛЬНО!
  "companyInfo": {
    "companyName": "Название",    // ⚠️ ОБЯЗАТЕЛЬНО!
    "bin": "123456789012",        // ⚠️ ОБЯЗАТЕЛЬНО! Ровно 12 цифр!
    "companyType": "ТОО",          // ⚠️ ОБЯЗАТЕЛЬНО!
    "industry": "IT"               // ⚠️ ОБЯЗАТЕЛЬНО!
  }
}
```

### Для EMPLOYEE при onboarding/complete:
```json
{
  "email": "email",                     // ⚠️ ОБЯЗАТЕЛЬНО!
  "selectedRole": "employee",           // ⚠️ ОБЯЗАТЕЛЬНО!
  "employeeCompanyBin": "123456789012"  // ⚠️ ОБЯЗАТЕЛЬНО! БИН компании для присоединения
}
```

### 🐛 ИЗВЕСТНЫЕ БАГИ:
1. **workspaceId возвращается как null** в ответе onboarding/complete для owner
2. **verify-email всегда возвращает success: false** даже при успешной верификации
3. **Refresh token полностью отключен** - только access token на 6 часов
4. **Email отправка не работает** - нужно получать коды из БД для тестирования

## 🔑 ПРАВИЛЬНАЯ ПОСЛЕДОВАТЕЛЬНОСТЬ

### Owner Registration:
1. `POST /api/v1/auth/registration/pre-register` - создание пользователя
2. `POST /api/v1/auth/registration/verify-email` - верификация email (игнорируйте success: false)
3. `POST /api/v1/auth/registration/onboarding/complete` - с `selectedRole: "owner"` и `companyInfo`

### Employee Registration:
1. `POST /api/v1/auth/registration/pre-register` - создание пользователя
2. `POST /api/v1/auth/registration/verify-email` - верификация email (игнорируйте success: false)
3. `POST /api/v1/auth/registration/onboarding/complete` - с `selectedRole: "employee"` и `employeeCompanyBin`
4. Ожидание одобрения owner'ом (статус будет pending)
5. `POST /api/v1/workspaces/:id/employee-management/employees/:id/approve` - owner одобряет

## 📌 ЗАМЕТКИ

1. **НЕТ /select-role** - роль передается в параметре `selectedRole` при вызове `/onboarding/complete`
2. **БИН обязателен** - для owner при создании, для employee при присоединении
3. **Bearer токены** - не используем httpOnly cookies
4. **Статус pending** - employee может логиниться, но с ограничениями до одобрения