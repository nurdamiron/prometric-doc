# 📡 Prometric ERP - Complete API Documentation

## 🎯 API Reference - All Endpoints

This documentation contains all API endpoints available in the Prometric ERP system, organized by modules and functionality. Based on actual controller analysis from the codebase.

> **Base URL**: `http://localhost:5001/api/v1`  
> **Authentication**: Bearer Token (JWT)  
> **Content-Type**: application/json

---

## 🔐 Authentication Module

### Core Authentication
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/auth/health` | Health check endpoint | No |
| POST | `/auth/login` | User login with email/password | No |
| POST | `/auth/refresh` | Refresh access token | No |
| POST | `/auth/logout` | User logout | Yes |
| GET | `/auth/verify` | Verify user token | Yes |
| GET | `/auth/me` | Get current user information | Yes |
| GET | `/auth/profile` | Get user profile (deprecated, use /me) | Yes |
| POST | `/auth/verify-token` | Verify token with email check | Yes |

### Registration & Validation
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/check-email` | Check if email exists | No |
| POST | `/auth/check-bin` | Universal BIN validation | No |
| POST | `/auth/check-bin-employee` | Check BIN for employee (deprecated) | No |
| POST | `/auth/validate-invite-code` | Validate employee invite code | No |
| GET | `/auth/registration-status` | Get registration status by email | No |
| GET | `/auth/approval-status/:userId` | Get approval status by userId | No |
| GET | `/auth/registration-status/:userId` | Get detailed registration status | No |
| POST | `/auth/onboarding/complete` | Complete onboarding process | No |

### Password Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/forgot-password` | Request password reset | No |
| POST | `/auth/reset-password` | Reset password with token | No |

### Registration Flow
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/auth/registration/owner` | Register new business owner | No |
| POST | `/auth/registration/employee` | Register new employee | No |
| POST | `/auth/registration/verify-email` | Verify email with code | No |
| POST | `/auth/registration/resend-verification` | Resend verification email | No |
| POST | `/auth/registration/onboarding/complete` | Complete onboarding | No |

---

## 🏢 Organizations Module

### Organization Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/organizations` | Get all organizations | Yes |
| GET | `/organizations/:id` | Get organization by ID | Yes |
| POST | `/organizations` | Create new organization | Yes |
| PUT | `/organizations/:id` | Update organization | Yes |
| DELETE | `/organizations/:id` | Delete organization | Yes |
| GET | `/organizations/my` | Get current user's organization | Yes |
| GET | `/organizations/:id/stats` | Get organization statistics | Yes |

### Workspace Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces` | Get all workspaces | Yes |
| GET | `/workspaces/:id` | Get workspace by ID | Yes |
| POST | `/workspaces` | Create new workspace | Yes |
| PUT | `/workspaces/:id` | Update workspace | Yes |
| DELETE | `/workspaces/:id` | Delete workspace | Yes |
| GET | `/workspaces/:id/employees` | Get workspace employees | Yes |
| POST | `/workspaces/:id/switch` | Switch to workspace | Yes |

### Department Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/departments` | Get all departments | Yes |
| GET | `/workspaces/:workspaceId/departments/:id` | Get department by ID | Yes |
| POST | `/workspaces/:workspaceId/departments` | Create department | Yes |
| PUT | `/workspaces/:workspaceId/departments/:id` | Update department | Yes |
| DELETE | `/workspaces/:workspaceId/departments/:id` | Delete department | Yes |
| POST | `/workspaces/:workspaceId/departments/:id/assign-employees` | Assign employees | Yes |
| GET | `/workspaces/:workspaceId/departments/:id/employees` | Get department employees | Yes |

### Employee Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/employees` | Get all employees | Yes |
| GET | `/workspaces/:workspaceId/employees/:id` | Get employee by ID | Yes |
| POST | `/workspaces/:workspaceId/employees` | Create employee | Yes |
| PUT | `/workspaces/:workspaceId/employees/:id` | Update employee | Yes |
| DELETE | `/workspaces/:workspaceId/employees/:id` | Delete employee | Yes |
| POST | `/workspaces/:workspaceId/employees/:id/approve` | Approve employee | Yes |
| POST | `/workspaces/:workspaceId/employees/:id/reject` | Reject employee | Yes |
| GET | `/workspaces/:workspaceId/employees/pending` | Get pending employees | Yes |

---

## 👥 Customers Module (CRM)

### Customer Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/customers` | Get all customers | Yes |
| GET | `/workspaces/:workspaceId/customers/:id` | Get customer by ID | Yes |
| POST | `/workspaces/:workspaceId/customers` | Create customer | Yes |
| PUT | `/workspaces/:workspaceId/customers/:id` | Update customer | Yes |
| DELETE | `/workspaces/:workspaceId/customers/:id` | Delete customer | Yes |
| GET | `/workspaces/:workspaceId/customers/search` | Search customers | Yes |
| POST | `/workspaces/:workspaceId/customers/import` | Import customers | Yes |
| GET | `/workspaces/:workspaceId/customers/export` | Export customers | Yes |

### Customer Contacts
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/customers/:customerId/contacts` | Get contacts | Yes |
| POST | `/workspaces/:workspaceId/customers/:customerId/contacts` | Add contact | Yes |
| PUT | `/workspaces/:workspaceId/customers/:customerId/contacts/:id` | Update contact | Yes |
| DELETE | `/workspaces/:workspaceId/customers/:customerId/contacts/:id` | Delete contact | Yes |

### Customer Analytics
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/customers/:id/analytics` | Get customer analytics | Yes |
| GET | `/workspaces/:workspaceId/customers/:id/history` | Get customer history | Yes |
| GET | `/workspaces/:workspaceId/customers/:id/deals` | Get customer deals | Yes |
| GET | `/workspaces/:workspaceId/customers/:id/orders` | Get customer orders | Yes |

---

## 💼 Deals Module

### Deal Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/deals` | Get all deals | Yes |
| GET | `/workspaces/:workspaceId/deals/:id` | Get deal by ID | Yes |
| POST | `/workspaces/:workspaceId/deals` | Create deal | Yes |
| PUT | `/workspaces/:workspaceId/deals/:id` | Update deal | Yes |
| DELETE | `/workspaces/:workspaceId/deals/:id` | Delete deal | Yes |
| POST | `/workspaces/:workspaceId/deals/:id/stage` | Change deal stage | Yes |
| POST | `/workspaces/:workspaceId/deals/:id/close-won` | Close deal as won | Yes |
| POST | `/workspaces/:workspaceId/deals/:id/close-lost` | Close deal as lost | Yes |

### Deal Products
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/deals/:dealId/products` | Get deal products | Yes |
| POST | `/workspaces/:workspaceId/deals/:dealId/products` | Add products to deal | Yes |
| PUT | `/workspaces/:workspaceId/deals/:dealId/products/:id` | Update deal product | Yes |
| DELETE | `/workspaces/:workspaceId/deals/:dealId/products/:id` | Remove product | Yes |

### Deal Pipeline
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/pipelines` | Get all pipelines | Yes |
| GET | `/workspaces/:workspaceId/pipelines/:id` | Get pipeline by ID | Yes |
| POST | `/workspaces/:workspaceId/pipelines` | Create pipeline | Yes |
| PUT | `/workspaces/:workspaceId/pipelines/:id` | Update pipeline | Yes |
| DELETE | `/workspaces/:workspaceId/pipelines/:id` | Delete pipeline | Yes |
| GET | `/workspaces/:workspaceId/pipelines/:id/stages` | Get pipeline stages | Yes |
| POST | `/workspaces/:workspaceId/pipelines/:id/stages` | Add pipeline stage | Yes |

### Deal Analytics
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/deals/metrics` | Get deals metrics | Yes |
| GET | `/workspaces/:workspaceId/deals/funnel` | Get sales funnel | Yes |
| GET | `/workspaces/:workspaceId/deals/forecast` | Get sales forecast | Yes |
| GET | `/workspaces/:workspaceId/deals/conversion-rates` | Get conversion rates | Yes |

---

## 📦 Products Module

### Product Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/products` | Get all products | Yes |
| GET | `/workspaces/:workspaceId/products/:id` | Get product by ID | Yes |
| POST | `/workspaces/:workspaceId/products` | Create product | Yes |
| PUT | `/workspaces/:workspaceId/products/:id` | Update product | Yes |
| DELETE | `/workspaces/:workspaceId/products/:id` | Delete product | Yes |
| GET | `/workspaces/:workspaceId/products/search` | Search products | Yes |
| POST | `/workspaces/:workspaceId/products/import` | Import products | Yes |
| GET | `/workspaces/:workspaceId/products/export` | Export products | Yes |

### Product Categories
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/product-categories` | Get categories | Yes |
| GET | `/workspaces/:workspaceId/product-categories/:id` | Get category | Yes |
| POST | `/workspaces/:workspaceId/product-categories` | Create category | Yes |
| PUT | `/workspaces/:workspaceId/product-categories/:id` | Update category | Yes |
| DELETE | `/workspaces/:workspaceId/product-categories/:id` | Delete category | Yes |

### Product Inventory
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/products/:id/inventory` | Get inventory | Yes |
| POST | `/workspaces/:workspaceId/products/:id/inventory` | Update inventory | Yes |
| GET | `/workspaces/:workspaceId/products/:id/stock-movements` | Get stock movements | Yes |
| POST | `/workspaces/:workspaceId/products/:id/adjust-stock` | Adjust stock | Yes |

---

## 📋 Orders Module

### Order Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/orders` | Get all orders | Yes |
| GET | `/workspaces/:workspaceId/orders/:id` | Get order by ID | Yes |
| POST | `/workspaces/:workspaceId/orders` | Create order | Yes |
| PUT | `/workspaces/:workspaceId/orders/:id` | Update order | Yes |
| DELETE | `/workspaces/:workspaceId/orders/:id` | Delete order | Yes |
| POST | `/workspaces/:workspaceId/orders/:id/confirm` | Confirm order | Yes |
| POST | `/workspaces/:workspaceId/orders/:id/cancel` | Cancel order | Yes |
| POST | `/workspaces/:workspaceId/orders/:id/complete` | Complete order | Yes |

### Order Items
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/orders/:orderId/items` | Get order items | Yes |
| POST | `/workspaces/:workspaceId/orders/:orderId/items` | Add order item | Yes |
| PUT | `/workspaces/:workspaceId/orders/:orderId/items/:id` | Update item | Yes |
| DELETE | `/workspaces/:workspaceId/orders/:orderId/items/:id` | Delete item | Yes |

### Order Fulfillment
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/orders/:id/fulfillment` | Get fulfillment status | Yes |
| POST | `/workspaces/:workspaceId/orders/:id/fulfill` | Start fulfillment | Yes |
| POST | `/workspaces/:workspaceId/orders/:id/ship` | Mark as shipped | Yes |
| POST | `/workspaces/:workspaceId/orders/:id/deliver` | Mark as delivered | Yes |

---

## 🏭 Production Module

### Production Orders
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/production/production-orders` | Get all | Yes |
| GET | `/workspaces/:workspaceId/operations/production/production-orders/:id` | Get by ID | Yes |
| POST | `/workspaces/:workspaceId/operations/production/production-orders` | Create | Yes |
| PUT | `/workspaces/:workspaceId/operations/production/production-orders/:id` | Update | Yes |
| DELETE | `/workspaces/:workspaceId/operations/production/production-orders/:id` | Delete | Yes |
| POST | `/workspaces/:workspaceId/operations/production/production-orders/:id/start` | Start | Yes |
| POST | `/workspaces/:workspaceId/operations/production/production-orders/:id/complete` | Complete | Yes |

### Work Orders
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/production/work-orders` | Get all | Yes |
| GET | `/workspaces/:workspaceId/operations/production/work-orders/:id` | Get by ID | Yes |
| POST | `/workspaces/:workspaceId/operations/production/work-orders` | Create | Yes |
| PUT | `/workspaces/:workspaceId/operations/production/work-orders/:id` | Update | Yes |
| POST | `/workspaces/:workspaceId/operations/production/work-orders/:id/assign` | Assign | Yes |
| POST | `/workspaces/:workspaceId/operations/production/work-orders/:id/complete` | Complete | Yes |

### Bill of Materials (BOM)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/production/boms` | Get all BOMs | Yes |
| GET | `/workspaces/:workspaceId/operations/production/boms/:id` | Get BOM | Yes |
| POST | `/workspaces/:workspaceId/operations/production/boms` | Create BOM | Yes |
| PUT | `/workspaces/:workspaceId/operations/production/boms/:id` | Update BOM | Yes |
| DELETE | `/workspaces/:workspaceId/operations/production/boms/:id` | Delete BOM | Yes |

### Quality Control
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/quality/inspections` | Get inspections | Yes |
| GET | `/workspaces/:workspaceId/operations/quality/inspections/:id` | Get inspection | Yes |
| POST | `/workspaces/:workspaceId/operations/quality/inspections` | Create inspection | Yes |
| PUT | `/workspaces/:workspaceId/operations/quality/inspections/:id` | Update inspection | Yes |
| POST | `/workspaces/:workspaceId/operations/quality/inspections/:id/pass` | Pass inspection | Yes |
| POST | `/workspaces/:workspaceId/operations/quality/inspections/:id/fail` | Fail inspection | Yes |

---

## 💰 Finance Module

### Invoices
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/finance/invoices` | Get all invoices | Yes |
| GET | `/workspaces/:workspaceId/finance/invoices/:id` | Get invoice | Yes |
| POST | `/workspaces/:workspaceId/finance/invoices` | Create invoice | Yes |
| PUT | `/workspaces/:workspaceId/finance/invoices/:id` | Update invoice | Yes |
| DELETE | `/workspaces/:workspaceId/finance/invoices/:id` | Delete invoice | Yes |
| POST | `/workspaces/:workspaceId/finance/invoices/:id/send` | Send invoice | Yes |
| POST | `/workspaces/:workspaceId/finance/invoices/:id/mark-paid` | Mark as paid | Yes |
| GET | `/workspaces/:workspaceId/finance/invoices/:id/pdf` | Download PDF | Yes |

### Payments
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/finance/payments` | Get all payments | Yes |
| GET | `/workspaces/:workspaceId/finance/payments/:id` | Get payment | Yes |
| POST | `/workspaces/:workspaceId/finance/payments` | Record payment | Yes |
| PUT | `/workspaces/:workspaceId/finance/payments/:id` | Update payment | Yes |
| DELETE | `/workspaces/:workspaceId/finance/payments/:id` | Delete payment | Yes |
| POST | `/workspaces/:workspaceId/finance/payments/:id/refund` | Refund payment | Yes |

### Expenses
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/finance/expenses` | Get all expenses | Yes |
| GET | `/workspaces/:workspaceId/finance/expenses/:id` | Get expense | Yes |
| POST | `/workspaces/:workspaceId/finance/expenses` | Create expense | Yes |
| PUT | `/workspaces/:workspaceId/finance/expenses/:id` | Update expense | Yes |
| DELETE | `/workspaces/:workspaceId/finance/expenses/:id` | Delete expense | Yes |
| POST | `/workspaces/:workspaceId/finance/expenses/:id/approve` | Approve expense | Yes |
| POST | `/workspaces/:workspaceId/finance/expenses/:id/reject` | Reject expense | Yes |

### Financial Reports
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/finance/reports/profit-loss` | P&L statement | Yes |
| GET | `/workspaces/:workspaceId/finance/reports/balance-sheet` | Balance sheet | Yes |
| GET | `/workspaces/:workspaceId/finance/reports/cash-flow` | Cash flow | Yes |
| GET | `/workspaces/:workspaceId/finance/reports/accounts-receivable` | AR report | Yes |
| GET | `/workspaces/:workspaceId/finance/reports/accounts-payable` | AP report | Yes |

---

## 👨‍💼 HR Module

### Employee Records
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/hr/employees` | Get all employees | Yes |
| GET | `/workspaces/:workspaceId/hr/employees/:id` | Get employee | Yes |
| POST | `/workspaces/:workspaceId/hr/employees` | Create employee | Yes |
| PUT | `/workspaces/:workspaceId/hr/employees/:id` | Update employee | Yes |
| DELETE | `/workspaces/:workspaceId/hr/employees/:id` | Delete employee | Yes |
| GET | `/workspaces/:workspaceId/hr/employees/:id/documents` | Get documents | Yes |
| POST | `/workspaces/:workspaceId/hr/employees/:id/documents` | Upload document | Yes |

### Attendance
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/hr/attendance` | Get attendance records | Yes |
| POST | `/workspaces/:workspaceId/hr/attendance/check-in` | Check in | Yes |
| POST | `/workspaces/:workspaceId/hr/attendance/check-out` | Check out | Yes |
| GET | `/workspaces/:workspaceId/hr/attendance/report` | Attendance report | Yes |
| POST | `/workspaces/:workspaceId/hr/attendance/bulk-import` | Import attendance | Yes |

### Leave Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/hr/leaves` | Get leave requests | Yes |
| GET | `/workspaces/:workspaceId/hr/leaves/:id` | Get leave request | Yes |
| POST | `/workspaces/:workspaceId/hr/leaves` | Create leave request | Yes |
| PUT | `/workspaces/:workspaceId/hr/leaves/:id` | Update leave request | Yes |
| POST | `/workspaces/:workspaceId/hr/leaves/:id/approve` | Approve leave | Yes |
| POST | `/workspaces/:workspaceId/hr/leaves/:id/reject` | Reject leave | Yes |
| GET | `/workspaces/:workspaceId/hr/leaves/balance/:employeeId` | Get leave balance | Yes |

### Payroll
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/hr/payroll` | Get payroll records | Yes |
| GET | `/workspaces/:workspaceId/hr/payroll/:id` | Get payroll | Yes |
| POST | `/workspaces/:workspaceId/hr/payroll/calculate` | Calculate payroll | Yes |
| POST | `/workspaces/:workspaceId/hr/payroll/process` | Process payroll | Yes |
| GET | `/workspaces/:workspaceId/hr/payroll/payslips/:employeeId` | Get payslips | Yes |
| POST | `/workspaces/:workspaceId/hr/payroll/payslips/generate` | Generate payslips | Yes |

---

## 📊 Tasks Module

### Task Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/tasks` | Get all tasks | Yes |
| GET | `/workspaces/:workspaceId/tasks/:id` | Get task by ID | Yes |
| POST | `/workspaces/:workspaceId/tasks` | Create task | Yes |
| PUT | `/workspaces/:workspaceId/tasks/:id` | Update task | Yes |
| DELETE | `/workspaces/:workspaceId/tasks/:id` | Delete task | Yes |
| POST | `/workspaces/:workspaceId/tasks/:id/assign` | Assign task | Yes |
| POST | `/workspaces/:workspaceId/tasks/:id/complete` | Complete task | Yes |
| POST | `/workspaces/:workspaceId/tasks/:id/reopen` | Reopen task | Yes |

### Task Comments
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/tasks/:taskId/comments` | Get comments | Yes |
| POST | `/workspaces/:workspaceId/tasks/:taskId/comments` | Add comment | Yes |
| PUT | `/workspaces/:workspaceId/tasks/:taskId/comments/:id` | Update comment | Yes |
| DELETE | `/workspaces/:workspaceId/tasks/:taskId/comments/:id` | Delete comment | Yes |

### Task Templates
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/task-templates` | Get templates | Yes |
| GET | `/workspaces/:workspaceId/task-templates/:id` | Get template | Yes |
| POST | `/workspaces/:workspaceId/task-templates` | Create template | Yes |
| PUT | `/workspaces/:workspaceId/task-templates/:id` | Update template | Yes |
| DELETE | `/workspaces/:workspaceId/task-templates/:id` | Delete template | Yes |
| POST | `/workspaces/:workspaceId/task-templates/:id/apply` | Apply template | Yes |

---

## 📅 Calendar Module

### Calendar Events
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/calendar/events` | Get all events | Yes |
| GET | `/workspaces/:workspaceId/calendar/events/:id` | Get event | Yes |
| POST | `/workspaces/:workspaceId/calendar/events` | Create event | Yes |
| PUT | `/workspaces/:workspaceId/calendar/events/:id` | Update event | Yes |
| DELETE | `/workspaces/:workspaceId/calendar/events/:id` | Delete event | Yes |
| GET | `/workspaces/:workspaceId/calendar/events/upcoming` | Get upcoming | Yes |
| POST | `/workspaces/:workspaceId/calendar/events/:id/remind` | Set reminder | Yes |

### Meeting Rooms
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/calendar/rooms` | Get all rooms | Yes |
| GET | `/workspaces/:workspaceId/calendar/rooms/:id` | Get room | Yes |
| POST | `/workspaces/:workspaceId/calendar/rooms` | Create room | Yes |
| PUT | `/workspaces/:workspaceId/calendar/rooms/:id` | Update room | Yes |
| DELETE | `/workspaces/:workspaceId/calendar/rooms/:id` | Delete room | Yes |
| GET | `/workspaces/:workspaceId/calendar/rooms/:id/availability` | Check availability | Yes |
| POST | `/workspaces/:workspaceId/calendar/rooms/:id/book` | Book room | Yes |

---

## 📄 Documents Module

### Document Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/documents` | Get all documents | Yes |
| GET | `/workspaces/:workspaceId/documents/:id` | Get document | Yes |
| POST | `/workspaces/:workspaceId/documents` | Upload document | Yes |
| PUT | `/workspaces/:workspaceId/documents/:id` | Update document | Yes |
| DELETE | `/workspaces/:workspaceId/documents/:id` | Delete document | Yes |
| GET | `/workspaces/:workspaceId/documents/:id/download` | Download document | Yes |
| POST | `/workspaces/:workspaceId/documents/:id/share` | Share document | Yes |
| GET | `/workspaces/:workspaceId/documents/:id/versions` | Get versions | Yes |

### Document Templates
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/document-templates` | Get templates | Yes |
| GET | `/workspaces/:workspaceId/document-templates/:id` | Get template | Yes |
| POST | `/workspaces/:workspaceId/document-templates` | Create template | Yes |
| PUT | `/workspaces/:workspaceId/document-templates/:id` | Update template | Yes |
| DELETE | `/workspaces/:workspaceId/document-templates/:id` | Delete template | Yes |
| POST | `/workspaces/:workspaceId/document-templates/:id/generate` | Generate from template | Yes |

---

## 🚚 Warehouse Module

### Warehouse Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/warehouse/warehouses` | Get all | Yes |
| GET | `/workspaces/:workspaceId/operations/warehouse/warehouses/:id` | Get by ID | Yes |
| POST | `/workspaces/:workspaceId/operations/warehouse/warehouses` | Create | Yes |
| PUT | `/workspaces/:workspaceId/operations/warehouse/warehouses/:id` | Update | Yes |
| DELETE | `/workspaces/:workspaceId/operations/warehouse/warehouses/:id` | Delete | Yes |

### Inventory Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/warehouse/inventory` | Get inventory | Yes |
| GET | `/workspaces/:workspaceId/operations/warehouse/inventory/:productId` | Get product inventory | Yes |
| POST | `/workspaces/:workspaceId/operations/warehouse/inventory/adjust` | Adjust inventory | Yes |
| GET | `/workspaces/:workspaceId/operations/warehouse/inventory/movements` | Get movements | Yes |
| POST | `/workspaces/:workspaceId/operations/warehouse/inventory/transfer` | Transfer stock | Yes |

### Goods Receipt
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/warehouse/goods-receipts` | Get all | Yes |
| GET | `/workspaces/:workspaceId/operations/warehouse/goods-receipts/:id` | Get by ID | Yes |
| POST | `/workspaces/:workspaceId/operations/warehouse/goods-receipts` | Create | Yes |
| PUT | `/workspaces/:workspaceId/operations/warehouse/goods-receipts/:id` | Update | Yes |
| POST | `/workspaces/:workspaceId/operations/warehouse/goods-receipts/:id/confirm` | Confirm | Yes |

### Picking Orders
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/warehouse/picking-orders` | Get all | Yes |
| GET | `/workspaces/:workspaceId/operations/warehouse/picking-orders/:id` | Get by ID | Yes |
| POST | `/workspaces/:workspaceId/operations/warehouse/picking-orders` | Create | Yes |
| PUT | `/workspaces/:workspaceId/operations/warehouse/picking-orders/:id` | Update | Yes |
| POST | `/workspaces/:workspaceId/operations/warehouse/picking-orders/:id/start` | Start | Yes |
| POST | `/workspaces/:workspaceId/operations/warehouse/picking-orders/:id/complete` | Complete | Yes |

---

## 🚛 Logistics Module

### Delivery Orders
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/logistics/delivery-orders` | Get all | Yes |
| GET | `/workspaces/:workspaceId/operations/logistics/delivery-orders/:id` | Get by ID | Yes |
| POST | `/workspaces/:workspaceId/operations/logistics/delivery-orders` | Create | Yes |
| PUT | `/workspaces/:workspaceId/operations/logistics/delivery-orders/:id` | Update | Yes |
| POST | `/workspaces/:workspaceId/operations/logistics/delivery-orders/:id/assign-driver` | Assign driver | Yes |
| POST | `/workspaces/:workspaceId/operations/logistics/delivery-orders/:id/start` | Start delivery | Yes |
| POST | `/workspaces/:workspaceId/operations/logistics/delivery-orders/:id/complete` | Complete | Yes |

### Route Planning
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/operations/logistics/routes` | Get all routes | Yes |
| GET | `/workspaces/:workspaceId/operations/logistics/routes/:id` | Get route | Yes |
| POST | `/workspaces/:workspaceId/operations/logistics/routes` | Create route | Yes |
| PUT | `/workspaces/:workspaceId/operations/logistics/routes/:id` | Update route | Yes |
| POST | `/workspaces/:workspaceId/operations/logistics/routes/optimize` | Optimize routes | Yes |

---

## 📈 Analytics & Reports

### Dashboard Analytics
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/analytics/dashboard` | Dashboard metrics | Yes |
| GET | `/workspaces/:workspaceId/analytics/kpis` | Key KPIs | Yes |
| GET | `/workspaces/:workspaceId/analytics/trends` | Trend analysis | Yes |
| GET | `/workspaces/:workspaceId/analytics/performance` | Performance metrics | Yes |

### Sales Analytics
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/analytics/sales/revenue` | Revenue analytics | Yes |
| GET | `/workspaces/:workspaceId/analytics/sales/conversion` | Conversion rates | Yes |
| GET | `/workspaces/:workspaceId/analytics/sales/forecast` | Sales forecast | Yes |
| GET | `/workspaces/:workspaceId/analytics/sales/by-product` | Sales by product | Yes |
| GET | `/workspaces/:workspaceId/analytics/sales/by-customer` | Sales by customer | Yes |

### Financial Analytics
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/analytics/finance/revenue` | Revenue analysis | Yes |
| GET | `/workspaces/:workspaceId/analytics/finance/expenses` | Expense analysis | Yes |
| GET | `/workspaces/:workspaceId/analytics/finance/profit-margin` | Profit margins | Yes |
| GET | `/workspaces/:workspaceId/analytics/finance/cash-flow` | Cash flow analysis | Yes |

### Custom Reports
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/reports` | Get all reports | Yes |
| GET | `/workspaces/:workspaceId/reports/:id` | Get report | Yes |
| POST | `/workspaces/:workspaceId/reports` | Create report | Yes |
| PUT | `/workspaces/:workspaceId/reports/:id` | Update report | Yes |
| DELETE | `/workspaces/:workspaceId/reports/:id` | Delete report | Yes |
| POST | `/workspaces/:workspaceId/reports/:id/generate` | Generate report | Yes |
| GET | `/workspaces/:workspaceId/reports/:id/export` | Export report | Yes |

---

## 🔔 Notifications

### Notification Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/notifications` | Get all notifications | Yes |
| GET | `/notifications/:id` | Get notification | Yes |
| POST | `/notifications/mark-read` | Mark as read | Yes |
| POST | `/notifications/mark-all-read` | Mark all as read | Yes |
| DELETE | `/notifications/:id` | Delete notification | Yes |
| GET | `/notifications/preferences` | Get preferences | Yes |
| PUT | `/notifications/preferences` | Update preferences | Yes |

---

## 🤖 AI Integration

### AI Chat
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/ai/chat` | Send message to AI | Yes |
| GET | `/ai/chat/history` | Get chat history | Yes |
| DELETE | `/ai/chat/history` | Clear chat history | Yes |

### AI Analytics
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/ai/analyze/sales` | Analyze sales data | Yes |
| POST | `/ai/analyze/customers` | Analyze customers | Yes |
| POST | `/ai/predict/revenue` | Predict revenue | Yes |
| POST | `/ai/suggest/products` | Product suggestions | Yes |

### AI Actions
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/ai/actions/create-invoice` | Create invoice via AI | Yes |
| POST | `/ai/actions/create-deal` | Create deal via AI | Yes |
| POST | `/ai/actions/generate-report` | Generate report via AI | Yes |

---

## 📊 Metrics Module

### Metric Definitions
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/metrics` | Get all metrics | Yes |
| GET | `/workspaces/:workspaceId/metrics/:id` | Get metric | Yes |
| POST | `/workspaces/:workspaceId/metrics` | Create metric | Yes |
| PUT | `/workspaces/:workspaceId/metrics/:id` | Update metric | Yes |
| DELETE | `/workspaces/:workspaceId/metrics/:id` | Delete metric | Yes |

### Metric Values
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/workspaces/:workspaceId/metrics/:metricId/values` | Get values | Yes |
| POST | `/workspaces/:workspaceId/metrics/:metricId/values` | Record value | Yes |
| GET | `/workspaces/:workspaceId/metrics/:metricId/history` | Get history | Yes |

---

## 🔧 System Administration

### User Management
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/admin/users` | Get all users | Yes (Admin) |
| GET | `/admin/users/:id` | Get user | Yes (Admin) |
| PUT | `/admin/users/:id` | Update user | Yes (Admin) |
| DELETE | `/admin/users/:id` | Delete user | Yes (Admin) |
| POST | `/admin/users/:id/reset-password` | Reset password | Yes (Admin) |
| POST | `/admin/users/:id/activate` | Activate user | Yes (Admin) |
| POST | `/admin/users/:id/deactivate` | Deactivate user | Yes (Admin) |

### System Settings
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/admin/settings` | Get all settings | Yes (Admin) |
| GET | `/admin/settings/:key` | Get setting | Yes (Admin) |
| PUT | `/admin/settings/:key` | Update setting | Yes (Admin) |
| POST | `/admin/settings/reset` | Reset to defaults | Yes (Admin) |

### Audit Logs
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/admin/audit-logs` | Get audit logs | Yes (Admin) |
| GET | `/admin/audit-logs/:id` | Get audit log | Yes (Admin) |
| GET | `/admin/audit-logs/export` | Export logs | Yes (Admin) |

---

## 🔄 WebSocket Events

### Connection
```javascript
// Connect to WebSocket
const socket = io('http://localhost:5001', {
  auth: {
    token: 'your-jwt-token'
  }
});
```

### Available Events

#### Subscribe Events (Client → Server)
| Event | Description | Payload |
|-------|-------------|---------|
| `subscribe:workspace` | Subscribe to workspace updates | `{ workspaceId: string }` |
| `subscribe:deals` | Subscribe to deal updates | `{ workspaceId: string }` |
| `subscribe:orders` | Subscribe to order updates | `{ workspaceId: string }` |
| `subscribe:tasks` | Subscribe to task updates | `{ workspaceId: string }` |
| `subscribe:notifications` | Subscribe to notifications | `{ userId: string }` |

#### Listen Events (Server → Client)
| Event | Description | Payload |
|-------|-------------|---------|
| `deal:created` | New deal created | Deal object |
| `deal:updated` | Deal updated | Deal object |
| `deal:stage-changed` | Deal stage changed | `{ dealId, oldStage, newStage }` |
| `order:created` | New order created | Order object |
| `order:status-changed` | Order status changed | `{ orderId, oldStatus, newStatus }` |
| `task:assigned` | Task assigned | Task object |
| `task:completed` | Task completed | Task object |
| `notification:new` | New notification | Notification object |

---

## 🔒 Authentication

### Bearer Token Authentication
All protected endpoints require Bearer token in Authorization header:

```http
Authorization: Bearer <your-jwt-token>
```

### Token Structure
```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "role": "owner|manager|employee",
  "organizationId": "uuid",
  "workspaceId": "uuid",
  "employeeId": "uuid",
  "iat": 1234567890,
  "exp": 1234567890
}
```

### Token Expiration
- Access Token: 24 hours
- Refresh Token: 30 days (if rememberMe enabled)

---

## 📝 Response Formats

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data
  },
  "message": "Operation successful"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description",
    "details": {
      // Additional error details
    }
  }
}
```

### Pagination Response
```json
{
  "success": true,
  "data": {
    "items": [],
    "total": 100,
    "page": 1,
    "pageSize": 20,
    "totalPages": 5
  }
}
```

---

## 🌍 Localization

All API responses support localization. Pass `Accept-Language` header:

```http
Accept-Language: en | ru | kz
```

---

## 📋 Rate Limiting

Different endpoints have different rate limits:

| Endpoint Type | Limit | Window |
|---------------|-------|--------|
| Authentication | 100 requests | 15 minutes |
| Read operations | 1000 requests | 1 minute |
| Write operations | 100 requests | 1 minute |
| File uploads | 10 requests | 1 minute |
| Reports | 10 requests | 5 minutes |

---

## 🔍 Search & Filtering

Most list endpoints support search and filtering:

### Query Parameters
- `search`: Search term
- `filter[field]`: Filter by field value
- `sort`: Sort field (prefix with `-` for descending)
- `page`: Page number (default: 1)
- `pageSize`: Items per page (default: 20, max: 100)
- `dateFrom`: Start date filter
- `dateTo`: End date filter

### Example
```
GET /api/v1/workspaces/:workspaceId/deals?search=software&filter[status]=open&sort=-createdAt&page=1&pageSize=20
```

---

## 📄 File Uploads

File upload endpoints accept `multipart/form-data`:

```javascript
const formData = new FormData();
formData.append('file', fileBlob);
formData.append('type', 'document');
formData.append('description', 'Invoice document');

fetch('/api/v1/workspaces/:workspaceId/documents', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer <token>'
  },
  body: formData
});
```

### Supported File Types
- Documents: PDF, DOCX, XLSX, TXT
- Images: JPG, PNG, GIF, SVG
- Archives: ZIP, RAR, 7Z

### File Size Limits
- Documents: 10 MB
- Images: 5 MB
- Archives: 50 MB

---

## 🚀 API Versioning

Current API version: **v1**

All endpoints are prefixed with `/api/v1/`

Future versions will be available at `/api/v2/`, `/api/v3/`, etc.

---

## 📚 Additional Resources

- [Technical Architecture](./TECHNICAL_ARCHITECTURE.md)
- [Database Schema](./DATABASE_SCHEMA.md)
- [WebSocket Documentation](./WEBSOCKET_EVENTS.md)
- [Error Codes Reference](./ERROR_CODES.md)
- [Integration Guide](./INTEGRATION_GUIDE.md)

---

© 2025 Prometric ERP. All rights reserved.