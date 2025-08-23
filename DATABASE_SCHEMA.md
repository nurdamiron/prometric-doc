# 🗄️ Prometric ERP - Database Schema Documentation

## 📊 Database Overview

**Database Type**: PostgreSQL 14  
**Hosting**: AWS RDS  
**Connection**: SSL Required  
**Character Set**: UTF-8  
**Timezone**: UTC  

---

## 🏗️ Core Database Principles

### Multi-Tenancy Architecture
- **Organization Level**: Top-level tenant isolation
- **Workspace Level**: Sub-tenant within organization
- **Row-Level Security**: All queries filtered by `organizationId` and `workspaceId`
- **UUID Primary Keys**: All tables use UUID v4 for primary keys

### Audit & Tracking
- All tables include: `createdAt`, `updatedAt`, `deletedAt` (soft deletes)
- Most tables include: `createdBy`, `updatedBy` (user tracking)
- Critical tables have: `version` field for optimistic locking

---

## 📋 Database Tables by Module

## 🔐 Authentication & Users

### `users` Table
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    firstName VARCHAR(100),
    lastName VARCHAR(100),
    phone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'employee', -- owner, manager, employee
    status VARCHAR(50) DEFAULT 'pending', -- active, pending, inactive
    registrationStatus VARCHAR(50) DEFAULT 'pending',
    emailVerified BOOLEAN DEFAULT FALSE,
    isVerified BOOLEAN DEFAULT FALSE,
    isActive BOOLEAN DEFAULT TRUE,
    onboardingCompleted BOOLEAN DEFAULT FALSE,
    lastLoginAt TIMESTAMP,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    CONSTRAINT check_role CHECK (role IN ('owner', 'manager', 'employee', 'investor'))
);
```

### `refresh_tokens` Table
```sql
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    userId UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    deviceInfo JSONB,
    ipAddress VARCHAR(45),
    userAgent TEXT,
    expiresAt TIMESTAMP NOT NULL,
    revokedAt TIMESTAMP,
    revokedReason VARCHAR(255),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_refresh_tokens_user (userId),
    INDEX idx_refresh_tokens_token (token)
);
```

### `email_verifications` Table
```sql
CREATE TABLE email_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    userId UUID REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    code VARCHAR(6) NOT NULL,
    token VARCHAR(255) UNIQUE,
    type VARCHAR(50), -- registration, password_reset
    expiresAt TIMESTAMP NOT NULL,
    verifiedAt TIMESTAMP,
    attempts INTEGER DEFAULT 0,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email_verifications_email (email),
    INDEX idx_email_verifications_token (token)
);
```

---

## 🏢 Organizations & Workspaces

### `organizations` Table
```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    bin VARCHAR(12) UNIQUE NOT NULL,
    type VARCHAR(50) DEFAULT 'COMPANY', -- COMPANY, INDIVIDUAL
    industry VARCHAR(100),
    size VARCHAR(50), -- small, medium, large, enterprise
    description TEXT,
    website VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(20),
    address JSONB,
    settings JSONB,
    logo VARCHAR(500),
    isActive BOOLEAN DEFAULT TRUE,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_organizations_bin (bin),
    INDEX idx_organizations_name (name)
);
```

### `workspaces` Table
```sql
CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) DEFAULT 'main', -- main, branch, department
    description TEXT,
    settings JSONB,
    isActive BOOLEAN DEFAULT TRUE,
    isDefault BOOLEAN DEFAULT FALSE,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_workspaces_org (organizationId),
    UNIQUE KEY unique_default_workspace (organizationId, isDefault)
);
```

### `workspace_users` Table
```sql
CREATE TABLE workspace_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    userId UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member', -- admin, manager, member
    permissions JSONB,
    isActive BOOLEAN DEFAULT TRUE,
    joinedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_workspace_user (workspaceId, userId),
    INDEX idx_workspace_users_workspace (workspaceId),
    INDEX idx_workspace_users_user (userId)
);
```

### `departments` Table
```sql
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    parentId UUID REFERENCES departments(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    headEmployeeId UUID,
    settings JSONB,
    isActive BOOLEAN DEFAULT TRUE,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_departments_org (organizationId),
    INDEX idx_departments_workspace (workspaceId),
    INDEX idx_departments_parent (parentId)
);
```

### `employees` Table
```sql
CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    userId UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID REFERENCES workspaces(id),
    departmentId UUID REFERENCES departments(id),
    employeeCode VARCHAR(50),
    position VARCHAR(255),
    organizationRole VARCHAR(50), -- owner, manager, employee
    hireDate DATE,
    salary DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'KZT',
    status VARCHAR(50) DEFAULT 'active', -- active, pending, inactive, terminated
    personalInfo JSONB,
    documents JSONB,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_employees_user (userId),
    INDEX idx_employees_org (organizationId),
    INDEX idx_employees_workspace (workspaceId),
    INDEX idx_employees_department (departmentId),
    UNIQUE KEY unique_user_org (userId, organizationId)
);
```

---

## 👥 CRM Module

### `customers` Table
```sql
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) DEFAULT 'COMPANY', -- COMPANY, INDIVIDUAL
    bin VARCHAR(12),
    email VARCHAR(255),
    phone VARCHAR(20),
    website VARCHAR(255),
    industry VARCHAR(100),
    size VARCHAR(50),
    rating INTEGER DEFAULT 0, -- 0-5 stars
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, blacklisted
    tags TEXT[],
    address JSONB,
    billingAddress JSONB,
    shippingAddress JSONB,
    contacts JSONB[], -- Array of contact persons
    notes TEXT,
    creditLimit DECIMAL(15,2),
    balance DECIMAL(15,2) DEFAULT 0,
    totalPurchases DECIMAL(15,2) DEFAULT 0,
    lastContactDate TIMESTAMP,
    assignedTo UUID REFERENCES users(id),
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_customers_org (organizationId),
    INDEX idx_customers_workspace (workspaceId),
    INDEX idx_customers_name (name),
    INDEX idx_customers_bin (bin),
    INDEX idx_customers_assigned (assignedTo)
);
```

### `customer_contacts` Table
```sql
CREATE TABLE customer_contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customerId UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    firstName VARCHAR(100),
    lastName VARCHAR(100),
    position VARCHAR(100),
    email VARCHAR(255),
    phone VARCHAR(20),
    mobile VARCHAR(20),
    isPrimary BOOLEAN DEFAULT FALSE,
    notes TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_customer_contacts_customer (customerId)
);
```

---

## 💼 Deals Module

### `deals` Table
```sql
CREATE TABLE deals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    customerId UUID NOT NULL REFERENCES customers(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    value DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'KZT',
    stage VARCHAR(50) DEFAULT 'NEW', -- NEW, QUALIFIED, PROPOSAL, NEGOTIATION, WON, LOST
    probability INTEGER DEFAULT 0, -- 0-100%
    expectedCloseDate DATE,
    actualCloseDate DATE,
    wonAt TIMESTAMP,
    lostAt TIMESTAMP,
    lostReason VARCHAR(255),
    competitorInfo JSONB,
    source VARCHAR(100), -- website, referral, cold_call, exhibition, etc
    assignedTo UUID REFERENCES users(id),
    tags TEXT[],
    notes TEXT,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_deals_org (organizationId),
    INDEX idx_deals_workspace (workspaceId),
    INDEX idx_deals_customer (customerId),
    INDEX idx_deals_stage (stage),
    INDEX idx_deals_assigned (assignedTo)
);
```

### `deal_products` Table
```sql
CREATE TABLE deal_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dealId UUID NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
    productId UUID NOT NULL REFERENCES products(id),
    quantity DECIMAL(15,3) NOT NULL,
    unitPrice DECIMAL(15,2) NOT NULL,
    discount DECIMAL(5,2) DEFAULT 0, -- percentage
    tax DECIMAL(5,2) DEFAULT 12, -- percentage
    totalPrice DECIMAL(15,2) NOT NULL,
    notes TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_deal_products_deal (dealId),
    INDEX idx_deal_products_product (productId)
);
```

### `deal_activities` Table
```sql
CREATE TABLE deal_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dealId UUID NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- call, email, meeting, note, task
    subject VARCHAR(255),
    description TEXT,
    outcome VARCHAR(100),
    scheduledAt TIMESTAMP,
    completedAt TIMESTAMP,
    duration INTEGER, -- minutes
    assignedTo UUID REFERENCES users(id),
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_deal_activities_deal (dealId),
    INDEX idx_deal_activities_type (type),
    INDEX idx_deal_activities_assigned (assignedTo)
);
```

---

## 📦 Products Module

### `products` Table
```sql
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    categoryId UUID REFERENCES product_categories(id),
    code VARCHAR(100) UNIQUE NOT NULL,
    barcode VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) DEFAULT 'PRODUCT', -- PRODUCT, SERVICE, MATERIAL
    unit VARCHAR(50) DEFAULT 'шт', -- шт, кг, л, м, м2, м3
    price DECIMAL(15,2) DEFAULT 0,
    cost DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'KZT',
    taxRate DECIMAL(5,2) DEFAULT 12,
    minStock DECIMAL(15,3) DEFAULT 0,
    maxStock DECIMAL(15,3),
    currentStock DECIMAL(15,3) DEFAULT 0,
    reservedStock DECIMAL(15,3) DEFAULT 0,
    availableStock DECIMAL(15,3) GENERATED ALWAYS AS (currentStock - reservedStock) STORED,
    weight DECIMAL(10,3), -- kg
    dimensions JSONB, -- {length, width, height}
    images TEXT[],
    specifications JSONB,
    status VARCHAR(50) DEFAULT 'ACTIVE', -- ACTIVE, INACTIVE, DISCONTINUED
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_products_org (organizationId),
    INDEX idx_products_workspace (workspaceId),
    INDEX idx_products_category (categoryId),
    INDEX idx_products_code (code),
    INDEX idx_products_barcode (barcode),
    INDEX idx_products_name (name)
);
```

### `product_categories` Table
```sql
CREATE TABLE product_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    parentId UUID REFERENCES product_categories(id) ON DELETE SET NULL,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    image VARCHAR(500),
    sortOrder INTEGER DEFAULT 0,
    isActive BOOLEAN DEFAULT TRUE,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_product_categories_org (organizationId),
    INDEX idx_product_categories_parent (parentId)
);
```

---

## 📋 Orders Module

### `orders` Table
```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    orderNumber VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(50) DEFAULT 'SALES', -- SALES, PURCHASE, TRANSFER
    customerId UUID REFERENCES customers(id),
    dealId UUID REFERENCES deals(id),
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, CONFIRMED, PROCESSING, SHIPPED, DELIVERED, CANCELLED
    orderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expectedDeliveryDate DATE,
    actualDeliveryDate DATE,
    shippingAddress JSONB,
    billingAddress JSONB,
    subtotal DECIMAL(15,2) DEFAULT 0,
    taxAmount DECIMAL(15,2) DEFAULT 0,
    discountAmount DECIMAL(15,2) DEFAULT 0,
    shippingAmount DECIMAL(15,2) DEFAULT 0,
    totalAmount DECIMAL(15,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'KZT',
    paymentStatus VARCHAR(50) DEFAULT 'PENDING', -- PENDING, PARTIAL, PAID, REFUNDED
    paymentMethod VARCHAR(50), -- cash, card, transfer, kaspi
    notes TEXT,
    assignedTo UUID REFERENCES users(id),
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_orders_org (organizationId),
    INDEX idx_orders_workspace (workspaceId),
    INDEX idx_orders_number (orderNumber),
    INDEX idx_orders_customer (customerId),
    INDEX idx_orders_deal (dealId),
    INDEX idx_orders_status (status)
);
```

### `order_items` Table
```sql
CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    orderId UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    productId UUID NOT NULL REFERENCES products(id),
    quantity DECIMAL(15,3) NOT NULL,
    unitPrice DECIMAL(15,2) NOT NULL,
    discount DECIMAL(5,2) DEFAULT 0,
    tax DECIMAL(5,2) DEFAULT 12,
    totalPrice DECIMAL(15,2) NOT NULL,
    notes TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order_items_order (orderId),
    INDEX idx_order_items_product (productId)
);
```

---

## 🏭 Production Module

### `production_orders` Table
```sql
CREATE TABLE production_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    orderNumber VARCHAR(50) UNIQUE NOT NULL,
    orderId UUID REFERENCES orders(id),
    productId UUID NOT NULL REFERENCES products(id),
    quantity DECIMAL(15,3) NOT NULL,
    completedQuantity DECIMAL(15,3) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'PLANNED', -- PLANNED, IN_PROGRESS, COMPLETED, CANCELLED
    priority VARCHAR(20) DEFAULT 'NORMAL', -- LOW, NORMAL, HIGH, URGENT
    plannedStartDate TIMESTAMP,
    plannedEndDate TIMESTAMP,
    actualStartDate TIMESTAMP,
    actualEndDate TIMESTAMP,
    assignedTo UUID REFERENCES users(id),
    notes TEXT,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_production_orders_org (organizationId),
    INDEX idx_production_orders_workspace (workspaceId),
    INDEX idx_production_orders_order (orderId),
    INDEX idx_production_orders_product (productId),
    INDEX idx_production_orders_status (status)
);
```

### `work_orders` Table
```sql
CREATE TABLE work_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    productionOrderId UUID NOT NULL REFERENCES production_orders(id) ON DELETE CASCADE,
    workOrderNumber VARCHAR(50) UNIQUE NOT NULL,
    operation VARCHAR(255) NOT NULL,
    workCenterId UUID,
    quantity DECIMAL(15,3) NOT NULL,
    completedQuantity DECIMAL(15,3) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, IN_PROGRESS, COMPLETED, CANCELLED
    assignedTo UUID REFERENCES users(id),
    startTime TIMESTAMP,
    endTime TIMESTAMP,
    duration INTEGER, -- minutes
    notes TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_work_orders_production (productionOrderId),
    INDEX idx_work_orders_status (status),
    INDEX idx_work_orders_assigned (assignedTo)
);
```

### `production_bom` Table (Bill of Materials)
```sql
CREATE TABLE production_bom (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    productId UUID NOT NULL REFERENCES products(id),
    componentId UUID NOT NULL REFERENCES products(id),
    quantity DECIMAL(15,6) NOT NULL,
    unit VARCHAR(50),
    notes TEXT,
    isActive BOOLEAN DEFAULT TRUE,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_bom_org (organizationId),
    INDEX idx_bom_product (productId),
    INDEX idx_bom_component (componentId),
    UNIQUE KEY unique_bom_component (productId, componentId)
);
```

---

## 💰 Finance Module

### `invoices` Table
```sql
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    invoiceNumber VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(50) DEFAULT 'SALES', -- SALES, PURCHASE
    customerId UUID REFERENCES customers(id),
    orderId UUID REFERENCES orders(id),
    dealId UUID REFERENCES deals(id),
    status VARCHAR(50) DEFAULT 'DRAFT', -- DRAFT, SENT, PAID, PARTIAL, OVERDUE, CANCELLED
    issueDate DATE NOT NULL,
    dueDate DATE NOT NULL,
    subtotal DECIMAL(15,2) DEFAULT 0,
    taxAmount DECIMAL(15,2) DEFAULT 0,
    discountAmount DECIMAL(15,2) DEFAULT 0,
    totalAmount DECIMAL(15,2) DEFAULT 0,
    paidAmount DECIMAL(15,2) DEFAULT 0,
    balanceDue DECIMAL(15,2) GENERATED ALWAYS AS (totalAmount - paidAmount) STORED,
    currency VARCHAR(3) DEFAULT 'KZT',
    notes TEXT,
    termsAndConditions TEXT,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_invoices_org (organizationId),
    INDEX idx_invoices_workspace (workspaceId),
    INDEX idx_invoices_number (invoiceNumber),
    INDEX idx_invoices_customer (customerId),
    INDEX idx_invoices_order (orderId),
    INDEX idx_invoices_status (status)
);
```

### `invoice_items` Table
```sql
CREATE TABLE invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoiceId UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    productId UUID REFERENCES products(id),
    description TEXT NOT NULL,
    quantity DECIMAL(15,3) NOT NULL,
    unitPrice DECIMAL(15,2) NOT NULL,
    discount DECIMAL(5,2) DEFAULT 0,
    tax DECIMAL(5,2) DEFAULT 12,
    totalPrice DECIMAL(15,2) NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_invoice_items_invoice (invoiceId),
    INDEX idx_invoice_items_product (productId)
);
```

### `payments` Table
```sql
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    paymentNumber VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(50) DEFAULT 'INCOMING', -- INCOMING, OUTGOING
    invoiceId UUID REFERENCES invoices(id),
    customerId UUID REFERENCES customers(id),
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KZT',
    paymentMethod VARCHAR(50) NOT NULL, -- cash, card, transfer, kaspi
    paymentDate DATE NOT NULL,
    referenceNumber VARCHAR(100),
    status VARCHAR(50) DEFAULT 'COMPLETED', -- PENDING, COMPLETED, FAILED, REFUNDED
    notes TEXT,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_payments_org (organizationId),
    INDEX idx_payments_workspace (workspaceId),
    INDEX idx_payments_invoice (invoiceId),
    INDEX idx_payments_customer (customerId),
    INDEX idx_payments_date (paymentDate)
);
```

### `expenses` Table
```sql
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    expenseNumber VARCHAR(50) UNIQUE NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    amount DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KZT',
    expenseDate DATE NOT NULL,
    paymentMethod VARCHAR(50),
    vendorId UUID REFERENCES customers(id),
    employeeId UUID REFERENCES employees(id),
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED, PAID
    approvedBy UUID REFERENCES users(id),
    approvedAt TIMESTAMP,
    receipt VARCHAR(500), -- file path
    notes TEXT,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_expenses_org (organizationId),
    INDEX idx_expenses_workspace (workspaceId),
    INDEX idx_expenses_category (category),
    INDEX idx_expenses_employee (employeeId),
    INDEX idx_expenses_status (status)
);
```

---

## 👨‍💼 HR Module

### `attendance` Table
```sql
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    employeeId UUID NOT NULL REFERENCES employees(id),
    date DATE NOT NULL,
    checkInTime TIME,
    checkOutTime TIME,
    totalHours DECIMAL(5,2),
    overtimeHours DECIMAL(5,2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'PRESENT', -- PRESENT, ABSENT, LATE, HALF_DAY, HOLIDAY, WEEKEND
    notes TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_attendance_org (organizationId),
    INDEX idx_attendance_workspace (workspaceId),
    INDEX idx_attendance_employee (employeeId),
    INDEX idx_attendance_date (date),
    UNIQUE KEY unique_attendance (employeeId, date)
);
```

### `leaves` Table
```sql
CREATE TABLE leaves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    employeeId UUID NOT NULL REFERENCES employees(id),
    type VARCHAR(50) NOT NULL, -- annual, sick, maternity, unpaid, other
    startDate DATE NOT NULL,
    endDate DATE NOT NULL,
    totalDays INTEGER NOT NULL,
    reason TEXT,
    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED, CANCELLED
    approvedBy UUID REFERENCES users(id),
    approvedAt TIMESTAMP,
    rejectionReason TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_leaves_org (organizationId),
    INDEX idx_leaves_workspace (workspaceId),
    INDEX idx_leaves_employee (employeeId),
    INDEX idx_leaves_status (status)
);
```

### `payroll` Table
```sql
CREATE TABLE payroll (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    employeeId UUID NOT NULL REFERENCES employees(id),
    payrollNumber VARCHAR(50) UNIQUE NOT NULL,
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    basicSalary DECIMAL(15,2) NOT NULL,
    allowances DECIMAL(15,2) DEFAULT 0,
    deductions DECIMAL(15,2) DEFAULT 0,
    taxAmount DECIMAL(15,2) DEFAULT 0,
    netSalary DECIMAL(15,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KZT',
    status VARCHAR(50) DEFAULT 'DRAFT', -- DRAFT, APPROVED, PAID
    paymentDate DATE,
    paymentMethod VARCHAR(50),
    bankAccount VARCHAR(100),
    notes TEXT,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_payroll_org (organizationId),
    INDEX idx_payroll_workspace (workspaceId),
    INDEX idx_payroll_employee (employeeId),
    INDEX idx_payroll_period (year, month),
    UNIQUE KEY unique_payroll_period (employeeId, year, month)
);
```

---

## 📊 Tasks Module

### `tasks` Table
```sql
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    projectId UUID REFERENCES projects(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) DEFAULT 'TASK', -- TASK, BUG, FEATURE, IMPROVEMENT
    priority VARCHAR(20) DEFAULT 'NORMAL', -- LOW, NORMAL, HIGH, URGENT
    status VARCHAR(50) DEFAULT 'TODO', -- TODO, IN_PROGRESS, IN_REVIEW, DONE, CANCELLED
    assignedTo UUID REFERENCES users(id),
    assignedBy UUID REFERENCES users(id),
    dueDate TIMESTAMP,
    startDate TIMESTAMP,
    completedAt TIMESTAMP,
    estimatedHours DECIMAL(5,2),
    actualHours DECIMAL(5,2),
    tags TEXT[],
    attachments TEXT[],
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_tasks_org (organizationId),
    INDEX idx_tasks_workspace (workspaceId),
    INDEX idx_tasks_project (projectId),
    INDEX idx_tasks_assigned (assignedTo),
    INDEX idx_tasks_status (status)
);
```

### `task_comments` Table
```sql
CREATE TABLE task_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    taskId UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    userId UUID NOT NULL REFERENCES users(id),
    comment TEXT NOT NULL,
    attachments TEXT[],
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_task_comments_task (taskId),
    INDEX idx_task_comments_user (userId)
);
```

---

## 📅 Calendar Module

### `calendar_events` Table
```sql
CREATE TABLE calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) DEFAULT 'EVENT', -- EVENT, MEETING, REMINDER, TASK
    location VARCHAR(255),
    startTime TIMESTAMP NOT NULL,
    endTime TIMESTAMP NOT NULL,
    allDay BOOLEAN DEFAULT FALSE,
    recurrence VARCHAR(50), -- NONE, DAILY, WEEKLY, MONTHLY, YEARLY
    recurrenceEnd DATE,
    attendees UUID[], -- Array of user IDs
    reminders JSONB, -- Array of reminder settings
    color VARCHAR(7), -- Hex color
    status VARCHAR(50) DEFAULT 'CONFIRMED', -- CONFIRMED, TENTATIVE, CANCELLED
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_calendar_events_org (organizationId),
    INDEX idx_calendar_events_workspace (workspaceId),
    INDEX idx_calendar_events_start (startTime),
    INDEX idx_calendar_events_type (type)
);
```

---

## 📄 Documents Module

### `documents` Table
```sql
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- contract, invoice, report, presentation, etc
    category VARCHAR(100),
    fileUrl VARCHAR(500) NOT NULL,
    fileSize BIGINT,
    mimeType VARCHAR(100),
    entityType VARCHAR(50), -- deal, order, customer, employee, etc
    entityId UUID,
    version INTEGER DEFAULT 1,
    tags TEXT[],
    metadata JSONB,
    isPublic BOOLEAN DEFAULT FALSE,
    sharedWith UUID[], -- Array of user IDs
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deletedAt TIMESTAMP,
    INDEX idx_documents_org (organizationId),
    INDEX idx_documents_workspace (workspaceId),
    INDEX idx_documents_entity (entityType, entityId),
    INDEX idx_documents_type (type)
);
```

---

## 🚚 Warehouse Module

### `warehouses` Table
```sql
CREATE TABLE warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE,
    type VARCHAR(50) DEFAULT 'MAIN', -- MAIN, BRANCH, VIRTUAL
    address JSONB,
    managerId UUID REFERENCES users(id),
    capacity DECIMAL(15,2),
    currentUtilization DECIMAL(5,2), -- percentage
    isActive BOOLEAN DEFAULT TRUE,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_warehouses_org (organizationId),
    INDEX idx_warehouses_workspace (workspaceId)
);
```

### `inventory` Table
```sql
CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    warehouseId UUID NOT NULL REFERENCES warehouses(id),
    productId UUID NOT NULL REFERENCES products(id),
    quantity DECIMAL(15,3) NOT NULL DEFAULT 0,
    reservedQuantity DECIMAL(15,3) DEFAULT 0,
    availableQuantity DECIMAL(15,3) GENERATED ALWAYS AS (quantity - reservedQuantity) STORED,
    location VARCHAR(100), -- rack/shelf location
    batchNumber VARCHAR(100),
    expiryDate DATE,
    lastCountDate DATE,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_inventory_org (organizationId),
    INDEX idx_inventory_workspace (workspaceId),
    INDEX idx_inventory_warehouse (warehouseId),
    INDEX idx_inventory_product (productId),
    UNIQUE KEY unique_warehouse_product (warehouseId, productId, batchNumber)
);
```

### `stock_movements` Table
```sql
CREATE TABLE stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    warehouseId UUID NOT NULL REFERENCES warehouses(id),
    productId UUID NOT NULL REFERENCES products(id),
    type VARCHAR(50) NOT NULL, -- IN, OUT, TRANSFER, ADJUSTMENT
    quantity DECIMAL(15,3) NOT NULL,
    referenceType VARCHAR(50), -- order, production, transfer, adjustment
    referenceId UUID,
    fromWarehouseId UUID REFERENCES warehouses(id),
    toWarehouseId UUID REFERENCES warehouses(id),
    reason TEXT,
    createdBy UUID REFERENCES users(id),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_stock_movements_org (organizationId),
    INDEX idx_stock_movements_workspace (workspaceId),
    INDEX idx_stock_movements_warehouse (warehouseId),
    INDEX idx_stock_movements_product (productId),
    INDEX idx_stock_movements_type (type),
    INDEX idx_stock_movements_reference (referenceType, referenceId)
);
```

---

## 📈 Analytics & Metrics

### `metrics` Table
```sql
CREATE TABLE metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    workspaceId UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL, -- revenue, orders, customers, etc
    period VARCHAR(20) NOT NULL, -- daily, weekly, monthly, yearly
    value DECIMAL(15,2) NOT NULL,
    previousValue DECIMAL(15,2),
    change DECIMAL(5,2), -- percentage change
    target DECIMAL(15,2),
    date DATE NOT NULL,
    metadata JSONB,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_metrics_org (organizationId),
    INDEX idx_metrics_workspace (workspaceId),
    INDEX idx_metrics_type (type),
    INDEX idx_metrics_period (period),
    INDEX idx_metrics_date (date)
);
```

### `kpi_definitions` Table
```sql
CREATE TABLE kpi_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    formula TEXT,
    unit VARCHAR(50),
    targetValue DECIMAL(15,2),
    frequency VARCHAR(50), -- daily, weekly, monthly, quarterly, yearly
    category VARCHAR(100),
    isActive BOOLEAN DEFAULT TRUE,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_kpi_definitions_org (organizationId)
);
```

---

## 🔔 Notifications

### `notifications` Table
```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    userId UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- info, warning, error, success
    category VARCHAR(50), -- order, deal, task, system, etc
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSONB,
    isRead BOOLEAN DEFAULT FALSE,
    readAt TIMESTAMP,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notifications_user (userId),
    INDEX idx_notifications_read (isRead),
    INDEX idx_notifications_created (createdAt)
);
```

---

## 🔍 Audit & Logging

### `audit_logs` Table
```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizationId UUID REFERENCES organizations(id),
    userId UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity VARCHAR(100) NOT NULL,
    entityId UUID,
    oldValue JSONB,
    newValue JSONB,
    ipAddress VARCHAR(45),
    userAgent TEXT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_logs_org (organizationId),
    INDEX idx_audit_logs_user (userId),
    INDEX idx_audit_logs_entity (entity, entityId),
    INDEX idx_audit_logs_action (action),
    INDEX idx_audit_logs_created (createdAt)
);
```

---

## 🔑 Database Indexes Strategy

### Performance Indexes
1. **Primary Keys**: All tables use UUID with B-tree index
2. **Foreign Keys**: Automatic indexes on all foreign key columns
3. **Search Fields**: Indexes on frequently searched columns (name, email, code, etc.)
4. **Date Ranges**: Indexes on date columns for range queries
5. **Status Fields**: Indexes on enum/status columns for filtering
6. **Composite Indexes**: Multi-column indexes for complex queries

### Example Composite Indexes
```sql
-- For multi-tenant queries
CREATE INDEX idx_deals_org_workspace_status ON deals(organizationId, workspaceId, status);

-- For date range queries
CREATE INDEX idx_orders_org_date_range ON orders(organizationId, orderDate, status);

-- For search queries
CREATE INDEX idx_customers_search ON customers(organizationId, name, email, bin);
```

---

## 🔄 Database Migrations

### Migration Naming Convention
```
YYYYMMDDHHMMSS_description.sql
Example: 20250823143000_create_users_table.sql
```

### Migration Structure
```sql
-- Up Migration
BEGIN;
CREATE TABLE ...
COMMIT;

-- Down Migration
BEGIN;
DROP TABLE IF EXISTS ...
COMMIT;
```

---

## 🛡️ Security Considerations

1. **Row-Level Security**: All queries filtered by organizationId and workspaceId
2. **Soft Deletes**: deletedAt column for data recovery
3. **Audit Trail**: All changes logged in audit_logs table
4. **Encryption**: Sensitive data encrypted at rest (passwords, tokens)
5. **UUID Usage**: Prevents ID enumeration attacks
6. **Index Security**: Careful index creation to prevent timing attacks

---

## 📊 Database Statistics

- **Total Tables**: 75+
- **Total Indexes**: 250+
- **Average Table Size**: 15-20 columns
- **Largest Tables**: orders, invoices, stock_movements, audit_logs
- **Most Referenced**: users, organizations, workspaces, products

---

## 🔧 Maintenance Procedures

### Regular Tasks
1. **VACUUM**: Weekly for heavily updated tables
2. **ANALYZE**: Daily for statistics update
3. **REINDEX**: Monthly for fragmented indexes
4. **Backup**: Daily automated backups to S3
5. **Archive**: Monthly archival of old audit logs

### Performance Monitoring
```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check index usage
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

---

© 2025 Prometric ERP. All rights reserved.