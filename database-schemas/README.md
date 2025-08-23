# 🗄️ Database Schemas - Complete Entity Relationship Design

## 📌 Overview

Prometric ERP uses PostgreSQL as the primary database with a multi-tenant architecture based on organizationId + workspaceId isolation. This document provides complete schema definitions, relationships, indexes, and constraints.

## 🏗️ Database Architecture

```yaml
Database: prometric
Host: prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com
Port: 5432
Engine: PostgreSQL 14+
Encoding: UTF8
Timezone: Asia/Almaty
```

## 🔐 Core Authentication Tables

### users
User accounts (multi-tenant isolation)

```sql
CREATE TABLE users (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email                 VARCHAR(255) UNIQUE NOT NULL,
  password_hash         VARCHAR(255) NOT NULL,
  first_name           VARCHAR(100) NOT NULL DEFAULT '',
  last_name            VARCHAR(100) NOT NULL DEFAULT '',
  phone                VARCHAR(20),
  organization_role    VARCHAR(20) NOT NULL DEFAULT 'employee' 
    CHECK (organization_role IN ('owner', 'admin', 'manager', 'employee')),
  status               VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'active', 'inactive', 'suspended')),
  registration_status  VARCHAR(20) NOT NULL DEFAULT 'email_pending'
    CHECK (registration_status IN ('email_pending', 'email_verified', 'onboarding_pending', 'completed')),
  last_login_at        TIMESTAMP,
  last_ip              INET,
  user_agent          TEXT,
  session_id          VARCHAR(255),
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP
);

-- Indexes
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_status ON users (status);
CREATE INDEX idx_users_org_role ON users (organization_role);
CREATE INDEX idx_users_created_at ON users (created_at);
```

### organizations
Organization entities (companies)

```sql
CREATE TABLE organizations (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  VARCHAR(255) NOT NULL,
  bin                   VARCHAR(12) UNIQUE NOT NULL, -- Kazakhstan BIN
  legal_name           VARCHAR(255),
  address              TEXT,
  phone                VARCHAR(20),
  email                VARCHAR(255),
  website              VARCHAR(255),
  industry             VARCHAR(100),
  employee_count       INTEGER DEFAULT 0,
  annual_revenue       DECIMAL(15,2) DEFAULT 0,
  tax_id               VARCHAR(50),
  registration_number  VARCHAR(50),
  status               VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'suspended')),
  settings             JSONB DEFAULT '{}'::jsonb,
  metadata             JSONB DEFAULT '{}'::jsonb,
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at           TIMESTAMP
);

-- Indexes
CREATE UNIQUE INDEX idx_organizations_bin ON organizations (bin) WHERE deleted_at IS NULL;
CREATE INDEX idx_organizations_status ON organizations (status);
CREATE INDEX idx_organizations_industry ON organizations (industry);
CREATE INDEX idx_organizations_settings ON organizations USING GIN (settings);
```

### workspaces
Workspace isolation within organizations

```sql
CREATE TABLE workspaces (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  name                  VARCHAR(255) NOT NULL,
  description           TEXT,
  type                  VARCHAR(50) NOT NULL DEFAULT 'main'
    CHECK (type IN ('main', 'division', 'project', 'branch')),
  status               VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive', 'archived')),
  settings             JSONB DEFAULT '{}'::jsonb,
  created_by           UUID REFERENCES users(id),
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at           TIMESTAMP
);

-- Indexes
CREATE INDEX idx_workspaces_org_id ON workspaces (organization_id);
CREATE INDEX idx_workspaces_status ON workspaces (status);
CREATE INDEX idx_workspaces_type ON workspaces (type);
```

### employees
Employee records linking users to organizations

```sql
CREATE TABLE employees (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              UUID NOT NULL REFERENCES users(id),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  department_id        UUID REFERENCES departments(id),
  employee_number      VARCHAR(50) UNIQUE,
  position             VARCHAR(255),
  hire_date           DATE,
  termination_date    DATE,
  salary              DECIMAL(12,2),
  currency            VARCHAR(3) NOT NULL DEFAULT 'KZT',
  status              VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'active', 'inactive', 'terminated')),
  permissions         TEXT[] DEFAULT '{}',
  settings            JSONB DEFAULT '{}'::jsonb,
  documents           JSONB DEFAULT '{}'::jsonb, -- IIN, passport, contracts
  emergency_contact   JSONB DEFAULT '{}'::jsonb,
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP,
  
  CONSTRAINT uk_employee_user_org UNIQUE (user_id, organization_id)
);

-- Indexes
CREATE INDEX idx_employees_user_id ON employees (user_id);
CREATE INDEX idx_employees_org_id ON employees (organization_id);
CREATE INDEX idx_employees_workspace_id ON employees (workspace_id);
CREATE INDEX idx_employees_department_id ON employees (department_id);
CREATE INDEX idx_employees_status ON employees (status);
CREATE INDEX idx_employees_employee_number ON employees (employee_number);
```

## 🏢 Organizational Structure Tables

### departments
Department hierarchy

```sql
CREATE TABLE departments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  name                 VARCHAR(255) NOT NULL,
  code                 VARCHAR(50),
  description          TEXT,
  parent_id           UUID REFERENCES departments(id),
  head_id             UUID REFERENCES employees(id),
  budget              DECIMAL(15,2) DEFAULT 0,
  cost_center         VARCHAR(50),
  is_active           BOOLEAN NOT NULL DEFAULT true,
  settings            JSONB DEFAULT '{}'::jsonb,
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP,
  
  CONSTRAINT uk_department_code_org UNIQUE (code, organization_id)
);

-- Indexes
CREATE INDEX idx_departments_org_id ON departments (organization_id);
CREATE INDEX idx_departments_workspace_id ON departments (workspace_id);
CREATE INDEX idx_departments_parent_id ON departments (parent_id);
CREATE INDEX idx_departments_head_id ON departments (head_id);
CREATE INDEX idx_departments_is_active ON departments (is_active);
```

## 📦 Products & Inventory Tables

### products
Product catalog

```sql
CREATE TABLE products (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  code                 VARCHAR(100) NOT NULL,
  name                 VARCHAR(500) NOT NULL,
  description          TEXT,
  type                 VARCHAR(20) NOT NULL DEFAULT 'PRODUCT'
    CHECK (type IN ('PRODUCT', 'MATERIAL', 'SERVICE', 'MANUFACTURED', 'BUNDLE', 'DIGITAL')),
  category_id          UUID REFERENCES product_categories(id),
  unit                 VARCHAR(20) NOT NULL DEFAULT 'шт',
  status               VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'INACTIVE', 'DISCONTINUED')),
  
  -- Pricing
  price                DECIMAL(12,2) NOT NULL DEFAULT 0,
  cost                 DECIMAL(12,2) NOT NULL DEFAULT 0,
  currency             VARCHAR(3) NOT NULL DEFAULT 'KZT',
  markup_percent       DECIMAL(5,2) DEFAULT 0,
  
  -- Tax
  vat_rate            DECIMAL(5,2) NOT NULL DEFAULT 12.00,
  vat_included        BOOLEAN NOT NULL DEFAULT true,
  vat_exempt          BOOLEAN NOT NULL DEFAULT false,
  
  -- Inventory
  track_inventory     BOOLEAN NOT NULL DEFAULT true,
  stock_level         INTEGER NOT NULL DEFAULT 0,
  reserved_quantity   INTEGER NOT NULL DEFAULT 0,
  available_quantity  INTEGER GENERATED ALWAYS AS (stock_level - reserved_quantity) STORED,
  min_stock_level     INTEGER NOT NULL DEFAULT 0,
  max_stock_level     INTEGER NOT NULL DEFAULT 100,
  reorder_point       INTEGER NOT NULL DEFAULT 10,
  reorder_quantity    INTEGER NOT NULL DEFAULT 50,
  
  -- Physical attributes
  weight              DECIMAL(8,3),
  dimensions          JSONB, -- {length, width, height, unit}
  color               VARCHAR(50),
  barcode             VARCHAR(100),
  sku                 VARCHAR(100),
  
  -- Manufacturing
  lead_time_days      INTEGER DEFAULT 0,
  production_time     INTEGER DEFAULT 0, -- minutes
  requires_production BOOLEAN DEFAULT false,
  
  -- Digital attributes
  images              JSONB DEFAULT '[]'::jsonb,
  specifications      JSONB DEFAULT '{}'::jsonb,
  custom_fields       JSONB DEFAULT '{}'::jsonb,
  tags                TEXT[] DEFAULT '{}',
  
  -- Audit
  created_by          UUID REFERENCES employees(id),
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP,
  
  CONSTRAINT uk_product_code_org UNIQUE (code, organization_id)
);

-- Indexes
CREATE INDEX idx_products_org_id ON products (organization_id);
CREATE INDEX idx_products_workspace_id ON products (workspace_id);
CREATE INDEX idx_products_code ON products (code);
CREATE INDEX idx_products_type ON products (type);
CREATE INDEX idx_products_category_id ON products (category_id);
CREATE INDEX idx_products_status ON products (status);
CREATE INDEX idx_products_barcode ON products (barcode);
CREATE INDEX idx_products_sku ON products (sku);
CREATE INDEX idx_products_stock_level ON products (stock_level);
CREATE INDEX idx_products_tags ON products USING GIN (tags);
CREATE INDEX idx_products_specs ON products USING GIN (specifications);
```

### product_categories
Product categorization

```sql
CREATE TABLE product_categories (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  name                 VARCHAR(255) NOT NULL,
  code                 VARCHAR(50),
  description          TEXT,
  parent_id           UUID REFERENCES product_categories(id),
  sort_order          INTEGER DEFAULT 0,
  is_active           BOOLEAN NOT NULL DEFAULT true,
  metadata            JSONB DEFAULT '{}'::jsonb,
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP
);

-- Indexes
CREATE INDEX idx_product_categories_org_id ON product_categories (organization_id);
CREATE INDEX idx_product_categories_workspace_id ON product_categories (workspace_id);
CREATE INDEX idx_product_categories_parent_id ON product_categories (parent_id);
```

## 👤 Customers & CRM Tables

### customers
Customer records

```sql
CREATE TABLE customers (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  customer_number      VARCHAR(50) UNIQUE,
  
  -- Basic info
  name                 VARCHAR(500) NOT NULL,
  type                 VARCHAR(20) NOT NULL DEFAULT 'COMPANY'
    CHECK (type IN ('COMPANY', 'INDIVIDUAL')),
  status               VARCHAR(20) NOT NULL DEFAULT 'LEAD'
    CHECK (status IN ('LEAD', 'PROSPECT', 'ACTIVE', 'INACTIVE', 'CHURNED')),
  
  -- Contact details
  email                VARCHAR(255),
  phone                VARCHAR(20),
  website              VARCHAR(255),
  
  -- Company details
  company_name         VARCHAR(500),
  legal_name          VARCHAR(500),
  industry            VARCHAR(100),
  employee_count      INTEGER,
  annual_revenue      DECIMAL(15,2),
  
  -- Kazakhstan specific
  bin                 VARCHAR(12), -- Company BIN
  iin                 VARCHAR(12), -- Individual IIN
  kbe_code           VARCHAR(10), -- Kazakhstan Bank Code
  
  -- Business metrics
  credit_limit        DECIMAL(15,2) DEFAULT 0,
  balance             DECIMAL(15,2) DEFAULT 0,
  currency            VARCHAR(3) NOT NULL DEFAULT 'KZT',
  payment_terms       VARCHAR(20) DEFAULT 'NET_30'
    CHECK (payment_terms IN ('PREPAYMENT', 'NET_15', 'NET_30', 'NET_45', 'NET_60')),
  payment_behavior    VARCHAR(20) DEFAULT 'unknown'
    CHECK (payment_behavior IN ('excellent', 'good', 'fair', 'poor', 'unknown')),
  
  -- CRM fields
  source              VARCHAR(50), -- lead source
  segment             VARCHAR(50),
  tier                VARCHAR(20) DEFAULT 'standard'
    CHECK (tier IN ('standard', 'silver', 'gold', 'platinum')),
  assigned_to         UUID REFERENCES employees(id),
  rating              DECIMAL(3,2) DEFAULT 0 CHECK (rating >= 0 AND rating <= 10),
  
  -- Calculated fields
  lifetime_value      DECIMAL(15,2) DEFAULT 0,
  last_order_date     DATE,
  last_contact_date   DATE,
  order_count         INTEGER DEFAULT 0,
  deal_count          INTEGER DEFAULT 0,
  
  -- Custom data
  tags                TEXT[] DEFAULT '{}',
  custom_fields       JSONB DEFAULT '{}'::jsonb,
  preferences         JSONB DEFAULT '{}'::jsonb,
  notes               TEXT,
  
  -- Audit
  created_by          UUID REFERENCES employees(id),
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP
);

-- Indexes
CREATE INDEX idx_customers_org_id ON customers (organization_id);
CREATE INDEX idx_customers_workspace_id ON customers (workspace_id);
CREATE INDEX idx_customers_type ON customers (type);
CREATE INDEX idx_customers_status ON customers (status);
CREATE INDEX idx_customers_email ON customers (email);
CREATE INDEX idx_customers_bin ON customers (bin);
CREATE INDEX idx_customers_iin ON customers (iin);
CREATE INDEX idx_customers_assigned_to ON customers (assigned_to);
CREATE INDEX idx_customers_tags ON customers USING GIN (tags);
CREATE INDEX idx_customers_tier ON customers (tier);
CREATE INDEX idx_customers_last_order_date ON customers (last_order_date);
```

### customer_contacts
Customer contact persons

```sql
CREATE TABLE customer_contacts (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id          UUID NOT NULL REFERENCES customers(id),
  first_name           VARCHAR(100) NOT NULL,
  last_name            VARCHAR(100) NOT NULL,
  position             VARCHAR(255),
  email                VARCHAR(255),
  phone                VARCHAR(20),
  mobile               VARCHAR(20),
  is_primary           BOOLEAN NOT NULL DEFAULT false,
  is_decision_maker    BOOLEAN NOT NULL DEFAULT false,
  department           VARCHAR(100),
  notes                TEXT,
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at           TIMESTAMP
);

-- Indexes
CREATE INDEX idx_customer_contacts_customer_id ON customer_contacts (customer_id);
CREATE INDEX idx_customer_contacts_is_primary ON customer_contacts (is_primary);
CREATE INDEX idx_customer_contacts_email ON customer_contacts (email);
```

### customer_addresses
Customer addresses

```sql
CREATE TABLE customer_addresses (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id          UUID NOT NULL REFERENCES customers(id),
  type                 VARCHAR(20) NOT NULL
    CHECK (type IN ('billing', 'shipping', 'legal', 'office')),
  address_line_1       VARCHAR(500) NOT NULL,
  address_line_2       VARCHAR(500),
  city                 VARCHAR(100) NOT NULL,
  state_region         VARCHAR(100),
  postal_code          VARCHAR(20),
  country              VARCHAR(2) NOT NULL DEFAULT 'KZ',
  is_primary           BOOLEAN NOT NULL DEFAULT false,
  is_default_billing   BOOLEAN NOT NULL DEFAULT false,
  is_default_shipping  BOOLEAN NOT NULL DEFAULT false,
  coordinates          POINT, -- PostGIS extension
  notes                TEXT,
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at           TIMESTAMP
);

-- Indexes
CREATE INDEX idx_customer_addresses_customer_id ON customer_addresses (customer_id);
CREATE INDEX idx_customer_addresses_type ON customer_addresses (type);
CREATE INDEX idx_customer_addresses_country ON customer_addresses (country);
CREATE INDEX idx_customer_addresses_postal_code ON customer_addresses (postal_code);
```

## 💼 Sales & Deals Tables

### deals
Sales opportunities

```sql
CREATE TABLE deals (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  deal_number          VARCHAR(50) UNIQUE,
  
  -- Basic deal info
  title                VARCHAR(500) NOT NULL,
  description          TEXT,
  customer_id          UUID NOT NULL REFERENCES customers(id),
  value                DECIMAL(15,2) NOT NULL DEFAULT 0,
  currency             VARCHAR(3) NOT NULL DEFAULT 'KZT',
  
  -- Stage & probability
  stage                VARCHAR(20) NOT NULL DEFAULT 'LEAD'
    CHECK (stage IN ('LEAD', 'QUALIFIED', 'PROPOSAL', 'NEGOTIATION', 'CLOSING', 'WON', 'LOST')),
  probability          INTEGER NOT NULL DEFAULT 0 CHECK (probability >= 0 AND probability <= 100),
  
  -- Dates
  expected_close_date  DATE,
  actual_close_date    DATE,
  won_at              TIMESTAMP,
  lost_at             TIMESTAMP,
  
  -- Assignment & source
  assigned_to          UUID REFERENCES employees(id),
  source               VARCHAR(50), -- lead source
  campaign_id          UUID, -- marketing campaign
  
  -- Competition
  competitors          TEXT[] DEFAULT '{}',
  competitive_info     JSONB DEFAULT '{}'::jsonb,
  
  -- Win/Loss analysis
  won_reason           TEXT,
  lost_reason          VARCHAR(100),
  lost_to_competitor   VARCHAR(255),
  competitor_info      JSONB DEFAULT '{}'::jsonb,
  
  -- Financial projections
  recurring_revenue    DECIMAL(15,2) DEFAULT 0,
  one_time_revenue     DECIMAL(15,2) DEFAULT 0,
  projected_margin     DECIMAL(15,2) DEFAULT 0,
  
  -- Custom data
  tags                 TEXT[] DEFAULT '{}',
  custom_fields        JSONB DEFAULT '{}'::jsonb,
  notes                TEXT,
  
  -- AI predictions
  ai_score            DECIMAL(5,2),
  ai_predicted_probability INTEGER,
  ai_recommended_actions JSONB,
  ai_risk_factors     JSONB,
  
  -- Audit
  created_by          UUID REFERENCES employees(id),
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP
);

-- Indexes
CREATE INDEX idx_deals_org_id ON deals (organization_id);
CREATE INDEX idx_deals_workspace_id ON deals (workspace_id);
CREATE INDEX idx_deals_customer_id ON deals (customer_id);
CREATE INDEX idx_deals_stage ON deals (stage);
CREATE INDEX idx_deals_assigned_to ON deals (assigned_to);
CREATE INDEX idx_deals_expected_close_date ON deals (expected_close_date);
CREATE INDEX idx_deals_actual_close_date ON deals (actual_close_date);
CREATE INDEX idx_deals_value ON deals (value);
CREATE INDEX idx_deals_tags ON deals USING GIN (tags);
CREATE INDEX idx_deals_won_at ON deals (won_at);
CREATE INDEX idx_deals_lost_at ON deals (lost_at);
```

### deal_products
Products associated with deals

```sql
CREATE TABLE deal_products (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id              UUID NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  product_id           UUID NOT NULL REFERENCES products(id),
  quantity             DECIMAL(10,3) NOT NULL DEFAULT 1,
  unit_price           DECIMAL(12,2) NOT NULL DEFAULT 0,
  discount_percent     DECIMAL(5,2) NOT NULL DEFAULT 0,
  discount_amount      DECIMAL(12,2) NOT NULL DEFAULT 0,
  tax_percent          DECIMAL(5,2) NOT NULL DEFAULT 12,
  tax_amount           DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_price          DECIMAL(12,2) GENERATED ALWAYS AS (
    (unit_price * quantity - discount_amount) + tax_amount
  ) STORED,
  notes                TEXT,
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_deal_products_deal_id ON deal_products (deal_id);
CREATE INDEX idx_deal_products_product_id ON deal_products (product_id);
```

### deal_activities
Activity tracking for deals

```sql
CREATE TABLE deal_activities (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id              UUID NOT NULL REFERENCES deals(id) ON DELETE CASCADE,
  type                 VARCHAR(50) NOT NULL
    CHECK (type IN ('call', 'email', 'meeting', 'demo', 'proposal', 'follow_up', 'note')),
  subject              VARCHAR(500) NOT NULL,
  description          TEXT,
  activity_date        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  duration_minutes     INTEGER,
  outcome              VARCHAR(50)
    CHECK (outcome IN ('positive', 'neutral', 'negative', 'no_response')),
  next_action          TEXT,
  next_action_date     TIMESTAMP,
  participants         UUID[] DEFAULT '{}', -- employee IDs
  attachments          JSONB DEFAULT '[]'::jsonb,
  created_by           UUID NOT NULL REFERENCES employees(id),
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_deal_activities_deal_id ON deal_activities (deal_id);
CREATE INDEX idx_deal_activities_type ON deal_activities (type);
CREATE INDEX idx_deal_activities_activity_date ON deal_activities (activity_date);
CREATE INDEX idx_deal_activities_created_by ON deal_activities (created_by);
```

## 📦 Orders & Fulfillment Tables

### orders
Unified order system

```sql
CREATE TABLE orders (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  order_number         VARCHAR(50) UNIQUE,
  
  -- Order classification
  type                 VARCHAR(20) NOT NULL DEFAULT 'SALES'
    CHECK (type IN ('SALES', 'PURCHASE', 'TRANSFER', 'RETURN', 'ADJUSTMENT')),
  category             VARCHAR(50),
  
  -- Relations
  customer_id          UUID REFERENCES customers(id),
  supplier_id          UUID REFERENCES suppliers(id),
  deal_id             UUID REFERENCES deals(id),
  parent_order_id     UUID REFERENCES orders(id),
  
  -- Status & workflow
  status               VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')),
  priority             VARCHAR(10) NOT NULL DEFAULT 'normal'
    CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  
  -- Financial details
  subtotal             DECIMAL(15,2) NOT NULL DEFAULT 0,
  tax_amount           DECIMAL(15,2) NOT NULL DEFAULT 0,
  discount_amount      DECIMAL(15,2) NOT NULL DEFAULT 0,
  shipping_cost        DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_amount         DECIMAL(15,2) GENERATED ALWAYS AS (
    subtotal + tax_amount + shipping_cost - discount_amount
  ) STORED,
  currency             VARCHAR(3) NOT NULL DEFAULT 'KZT',
  
  -- Payment
  payment_status       VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (payment_status IN ('pending', 'partial', 'paid', 'overdue', 'cancelled')),
  payment_terms        VARCHAR(20) DEFAULT 'NET_30',
  paid_amount          DECIMAL(15,2) NOT NULL DEFAULT 0,
  
  -- Dates
  order_date           DATE NOT NULL DEFAULT CURRENT_DATE,
  required_date        DATE,
  promised_date        DATE,
  shipped_date         DATE,
  delivered_date       DATE,
  
  -- Shipping
  shipping_method      VARCHAR(100),
  tracking_number      VARCHAR(100),
  carrier              VARCHAR(100),
  shipping_address     JSONB,
  billing_address      JSONB,
  
  -- Additional info
  notes                TEXT,
  internal_notes       TEXT,
  tags                 TEXT[] DEFAULT '{}',
  custom_fields        JSONB DEFAULT '{}'::jsonb,
  
  -- Audit
  created_by           UUID NOT NULL REFERENCES employees(id),
  approved_by          UUID REFERENCES employees(id),
  approved_at          TIMESTAMP,
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at           TIMESTAMP
);

-- Indexes
CREATE INDEX idx_orders_org_id ON orders (organization_id);
CREATE INDEX idx_orders_workspace_id ON orders (workspace_id);
CREATE INDEX idx_orders_type ON orders (type);
CREATE INDEX idx_orders_status ON orders (status);
CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_orders_deal_id ON orders (deal_id);
CREATE INDEX idx_orders_order_date ON orders (order_date);
CREATE INDEX idx_orders_required_date ON orders (required_date);
CREATE INDEX idx_orders_total_amount ON orders (total_amount);
CREATE INDEX idx_orders_tracking_number ON orders (tracking_number);
```

### order_items
Line items for orders

```sql
CREATE TABLE order_items (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id             UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id           UUID NOT NULL REFERENCES products(id),
  
  -- Product details (snapshot)
  product_code         VARCHAR(100) NOT NULL,
  product_name         VARCHAR(500) NOT NULL,
  description          TEXT,
  
  -- Quantities
  quantity_ordered     DECIMAL(10,3) NOT NULL DEFAULT 1,
  quantity_shipped     DECIMAL(10,3) NOT NULL DEFAULT 0,
  quantity_delivered   DECIMAL(10,3) NOT NULL DEFAULT 0,
  quantity_returned    DECIMAL(10,3) NOT NULL DEFAULT 0,
  
  -- Pricing
  unit_price           DECIMAL(12,2) NOT NULL DEFAULT 0,
  unit_cost           DECIMAL(12,2) NOT NULL DEFAULT 0,
  discount_percent     DECIMAL(5,2) NOT NULL DEFAULT 0,
  discount_amount      DECIMAL(12,2) NOT NULL DEFAULT 0,
  tax_percent          DECIMAL(5,2) NOT NULL DEFAULT 12,
  tax_amount           DECIMAL(12,2) NOT NULL DEFAULT 0,
  line_total           DECIMAL(12,2) GENERATED ALWAYS AS (
    (unit_price * quantity_ordered - discount_amount) + tax_amount
  ) STORED,
  
  -- Manufacturing
  requires_production  BOOLEAN NOT NULL DEFAULT false,
  production_notes     TEXT,
  
  -- Quality & specifications
  specifications       JSONB DEFAULT '{}'::jsonb,
  quality_requirements JSONB DEFAULT '{}'::jsonb,
  
  -- Custom data
  custom_fields        JSONB DEFAULT '{}'::jsonb,
  notes                TEXT,
  
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_order_items_order_id ON order_items (order_id);
CREATE INDEX idx_order_items_product_id ON order_items (product_id);
CREATE INDEX idx_order_items_product_code ON order_items (product_code);
```

## 🏭 Production Tables

### production_orders
Manufacturing work orders

```sql
CREATE TABLE production_orders (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  production_number    VARCHAR(50) UNIQUE,
  
  -- Relations
  order_id            UUID REFERENCES orders(id),
  product_id          UUID NOT NULL REFERENCES products(id),
  bom_id             UUID REFERENCES bills_of_materials(id),
  
  -- Production details
  quantity_to_produce  INTEGER NOT NULL,
  quantity_produced    INTEGER NOT NULL DEFAULT 0,
  quantity_completed   INTEGER NOT NULL DEFAULT 0,
  quantity_scrapped    INTEGER NOT NULL DEFAULT 0,
  
  -- Status & priority
  status               VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'scheduled', 'in_progress', 'completed', 'cancelled', 'on_hold')),
  priority             VARCHAR(10) NOT NULL DEFAULT 'normal'
    CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  
  -- Scheduling
  planned_start_date   TIMESTAMP,
  planned_end_date     TIMESTAMP,
  actual_start_date    TIMESTAMP,
  actual_end_date      TIMESTAMP,
  due_date            TIMESTAMP,
  
  -- Resources
  production_line      VARCHAR(100),
  work_center         VARCHAR(100),
  shift               VARCHAR(20),
  assigned_team       UUID[], -- employee IDs
  
  -- Costs
  estimated_cost       DECIMAL(12,2) DEFAULT 0,
  actual_cost         DECIMAL(12,2) DEFAULT 0,
  material_cost       DECIMAL(12,2) DEFAULT 0,
  labor_cost          DECIMAL(12,2) DEFAULT 0,
  overhead_cost       DECIMAL(12,2) DEFAULT 0,
  
  -- Quality
  quality_standard     VARCHAR(50),
  qc_required         BOOLEAN NOT NULL DEFAULT true,
  qc_passed           BOOLEAN,
  qc_notes           TEXT,
  
  -- Additional info
  notes               TEXT,
  instructions        TEXT,
  custom_fields       JSONB DEFAULT '{}'::jsonb,
  
  -- Audit
  created_by          UUID NOT NULL REFERENCES employees(id),
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP
);

-- Indexes
CREATE INDEX idx_production_orders_org_id ON production_orders (organization_id);
CREATE INDEX idx_production_orders_workspace_id ON production_orders (workspace_id);
CREATE INDEX idx_production_orders_order_id ON production_orders (order_id);
CREATE INDEX idx_production_orders_product_id ON production_orders (product_id);
CREATE INDEX idx_production_orders_status ON production_orders (status);
CREATE INDEX idx_production_orders_priority ON production_orders (priority);
CREATE INDEX idx_production_orders_due_date ON production_orders (due_date);
```

### bills_of_materials
Product recipes and BOMs

```sql
CREATE TABLE bills_of_materials (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  
  -- Product relation
  product_id           UUID NOT NULL REFERENCES products(id),
  version              VARCHAR(20) NOT NULL DEFAULT '1.0',
  name                 VARCHAR(255) NOT NULL,
  description          TEXT,
  
  -- BOM details
  quantity             DECIMAL(10,3) NOT NULL DEFAULT 1, -- quantity this BOM produces
  unit                 VARCHAR(20) NOT NULL DEFAULT 'шт',
  
  -- Status
  status               VARCHAR(20) NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'inactive', 'archived')),
  is_default           BOOLEAN NOT NULL DEFAULT false,
  
  -- Manufacturing details
  lead_time_days       INTEGER DEFAULT 0,
  setup_time_minutes   INTEGER DEFAULT 0,
  production_time_minutes INTEGER DEFAULT 0,
  
  -- Costs (calculated)
  material_cost        DECIMAL(12,2) DEFAULT 0,
  labor_cost          DECIMAL(12,2) DEFAULT 0,
  overhead_cost       DECIMAL(12,2) DEFAULT 0,
  total_cost          DECIMAL(12,2) GENERATED ALWAYS AS (
    material_cost + labor_cost + overhead_cost
  ) STORED,
  
  -- Metadata
  valid_from          DATE DEFAULT CURRENT_DATE,
  valid_to            DATE,
  created_by          UUID REFERENCES employees(id),
  approved_by         UUID REFERENCES employees(id),
  approved_at         TIMESTAMP,
  
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP,
  
  CONSTRAINT uk_bom_product_version UNIQUE (product_id, version)
);

-- Indexes
CREATE INDEX idx_bom_org_id ON bills_of_materials (organization_id);
CREATE INDEX idx_bom_workspace_id ON bills_of_materials (workspace_id);
CREATE INDEX idx_bom_product_id ON bills_of_materials (product_id);
CREATE INDEX idx_bom_status ON bills_of_materials (status);
CREATE INDEX idx_bom_is_default ON bills_of_materials (is_default);
```

### bom_components
BOM component details

```sql
CREATE TABLE bom_components (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bom_id               UUID NOT NULL REFERENCES bills_of_materials(id) ON DELETE CASCADE,
  component_id         UUID NOT NULL REFERENCES products(id),
  
  -- Component details
  sequence_number      INTEGER NOT NULL DEFAULT 1,
  quantity_per_unit    DECIMAL(10,3) NOT NULL DEFAULT 1,
  unit                 VARCHAR(20) NOT NULL DEFAULT 'шт',
  scrap_factor        DECIMAL(5,3) NOT NULL DEFAULT 0, -- waste percentage
  
  -- Substitutes
  substitute_component_id UUID REFERENCES products(id),
  substitution_ratio   DECIMAL(5,3) DEFAULT 1,
  
  -- Operations
  operation_sequence   INTEGER,
  operation_notes      TEXT,
  
  -- Costing
  unit_cost           DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_cost          DECIMAL(12,2) GENERATED ALWAYS AS (
    unit_cost * quantity_per_unit * (1 + scrap_factor)
  ) STORED,
  
  -- Specifications
  specifications       JSONB DEFAULT '{}'::jsonb,
  notes               TEXT,
  
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_bom_components_bom_id ON bom_components (bom_id);
CREATE INDEX idx_bom_components_component_id ON bom_components (component_id);
CREATE INDEX idx_bom_components_sequence ON bom_components (bom_id, sequence_number);
```

## 💰 Finance Tables

### invoices
Invoice management

```sql
CREATE TABLE invoices (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  invoice_number       VARCHAR(50) UNIQUE NOT NULL,
  
  -- Relations
  customer_id          UUID REFERENCES customers(id),
  order_id            UUID REFERENCES orders(id),
  deal_id             UUID REFERENCES deals(id),
  
  -- Invoice details
  type                 VARCHAR(20) NOT NULL DEFAULT 'STANDARD'
    CHECK (type IN ('STANDARD', 'PROFORMA', 'CREDIT_NOTE', 'DEBIT_NOTE', 'RECURRING')),
  status               VARCHAR(20) NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'sent', 'viewed', 'partial', 'paid', 'overdue', 'cancelled')),
  
  -- Amounts
  subtotal             DECIMAL(15,2) NOT NULL DEFAULT 0,
  tax_amount           DECIMAL(15,2) NOT NULL DEFAULT 0,
  discount_amount      DECIMAL(15,2) NOT NULL DEFAULT 0,
  total_amount         DECIMAL(15,2) GENERATED ALWAYS AS (
    subtotal + tax_amount - discount_amount
  ) STORED,
  paid_amount          DECIMAL(15,2) NOT NULL DEFAULT 0,
  currency             VARCHAR(3) NOT NULL DEFAULT 'KZT',
  
  -- Dates
  issue_date           DATE NOT NULL DEFAULT CURRENT_DATE,
  due_date             DATE NOT NULL,
  sent_date           DATE,
  paid_date           DATE,
  
  -- Payment terms
  payment_terms        VARCHAR(20) DEFAULT 'NET_30',
  payment_method       VARCHAR(50),
  
  -- References
  po_number           VARCHAR(100), -- Purchase Order number
  reference_number    VARCHAR(100),
  contract_number     VARCHAR(100),
  
  -- Additional info
  notes               TEXT,
  internal_notes      TEXT,
  terms_conditions    TEXT,
  
  -- ESF (Kazakhstan e-invoice)
  esf_number          VARCHAR(50),
  esf_status          VARCHAR(20),
  esf_date           TIMESTAMP,
  
  -- Custom data
  custom_fields       JSONB DEFAULT '{}'::jsonb,
  
  -- Audit
  created_by          UUID NOT NULL REFERENCES employees(id),
  sent_by             UUID REFERENCES employees(id),
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP
);

-- Indexes
CREATE INDEX idx_invoices_org_id ON invoices (organization_id);
CREATE INDEX idx_invoices_workspace_id ON invoices (workspace_id);
CREATE INDEX idx_invoices_customer_id ON invoices (customer_id);
CREATE INDEX idx_invoices_order_id ON invoices (order_id);
CREATE INDEX idx_invoices_status ON invoices (status);
CREATE INDEX idx_invoices_issue_date ON invoices (issue_date);
CREATE INDEX idx_invoices_due_date ON invoices (due_date);
CREATE INDEX idx_invoices_total_amount ON invoices (total_amount);
CREATE UNIQUE INDEX idx_invoices_number ON invoices (invoice_number) WHERE deleted_at IS NULL;
```

### invoice_items
Invoice line items

```sql
CREATE TABLE invoice_items (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id           UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  product_id           UUID REFERENCES products(id),
  
  -- Item details
  description          TEXT NOT NULL,
  quantity             DECIMAL(10,3) NOT NULL DEFAULT 1,
  unit                 VARCHAR(20) NOT NULL DEFAULT 'шт',
  unit_price           DECIMAL(12,2) NOT NULL DEFAULT 0,
  
  -- Discounts
  discount_percent     DECIMAL(5,2) NOT NULL DEFAULT 0,
  discount_amount      DECIMAL(12,2) NOT NULL DEFAULT 0,
  
  -- Tax
  tax_percent          DECIMAL(5,2) NOT NULL DEFAULT 12,
  tax_amount           DECIMAL(12,2) NOT NULL DEFAULT 0,
  
  -- Totals
  line_total           DECIMAL(12,2) GENERATED ALWAYS AS (
    (unit_price * quantity - discount_amount) + tax_amount
  ) STORED,
  
  -- Additional info
  notes               TEXT,
  custom_fields       JSONB DEFAULT '{}'::jsonb,
  
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_invoice_items_invoice_id ON invoice_items (invoice_id);
CREATE INDEX idx_invoice_items_product_id ON invoice_items (product_id);
```

### payments
Payment records

```sql
CREATE TABLE payments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  payment_number       VARCHAR(50) UNIQUE,
  
  -- Relations
  customer_id          UUID REFERENCES customers(id),
  invoice_id          UUID REFERENCES invoices(id),
  order_id            UUID REFERENCES orders(id),
  
  -- Payment details
  amount               DECIMAL(15,2) NOT NULL,
  currency             VARCHAR(3) NOT NULL DEFAULT 'KZT',
  payment_date         DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- Payment method
  payment_method       VARCHAR(50) NOT NULL
    CHECK (payment_method IN ('CASH', 'BANK_TRANSFER', 'CARD', 'CHECK', 'OTHER')),
  payment_gateway      VARCHAR(50),
  transaction_id       VARCHAR(255),
  reference_number     VARCHAR(100),
  
  -- Bank details
  bank_name           VARCHAR(255),
  account_number      VARCHAR(50),
  routing_number      VARCHAR(50),
  
  -- Status
  status              VARCHAR(20) NOT NULL DEFAULT 'completed'
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded')),
  
  -- Exchange rate (if multi-currency)
  exchange_rate       DECIMAL(10,6) DEFAULT 1,
  base_amount         DECIMAL(15,2),
  
  -- Additional info
  notes               TEXT,
  internal_notes      TEXT,
  
  -- Audit
  processed_by        UUID REFERENCES employees(id),
  created_by          UUID REFERENCES employees(id),
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP
);

-- Indexes
CREATE INDEX idx_payments_org_id ON payments (organization_id);
CREATE INDEX idx_payments_workspace_id ON payments (workspace_id);
CREATE INDEX idx_payments_customer_id ON payments (customer_id);
CREATE INDEX idx_payments_invoice_id ON payments (invoice_id);
CREATE INDEX idx_payments_payment_date ON payments (payment_date);
CREATE INDEX idx_payments_amount ON payments (amount);
CREATE INDEX idx_payments_status ON payments (status);
CREATE INDEX idx_payments_method ON payments (payment_method);
```

## 👥 HR & Payroll Tables

### tasks
Task management

```sql
CREATE TABLE tasks (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  
  -- Task details
  title                VARCHAR(500) NOT NULL,
  description          TEXT,
  type                 VARCHAR(50) NOT NULL DEFAULT 'general',
  category             VARCHAR(50),
  priority             VARCHAR(10) NOT NULL DEFAULT 'medium'
    CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
  
  -- Status & workflow
  status               VARCHAR(20) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'in_progress', 'on_hold', 'completed', 'cancelled')),
  progress_percent     INTEGER DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
  
  -- Assignment
  assigned_to          UUID REFERENCES employees(id),
  assigned_by          UUID REFERENCES employees(id),
  department_id        UUID REFERENCES departments(id),
  project_id          UUID REFERENCES projects(id),
  
  -- Relations
  customer_id          UUID REFERENCES customers(id),
  deal_id             UUID REFERENCES deals(id),
  order_id            UUID REFERENCES orders(id),
  related_entity_type  VARCHAR(50),
  related_entity_id    UUID,
  parent_task_id      UUID REFERENCES tasks(id),
  
  -- Time tracking
  estimated_hours      DECIMAL(6,2) DEFAULT 0,
  actual_hours         DECIMAL(6,2) DEFAULT 0,
  billable_hours       DECIMAL(6,2) DEFAULT 0,
  hourly_rate         DECIMAL(8,2) DEFAULT 0,
  
  -- Dates
  start_date          DATE,
  due_date            DATE,
  completed_date      DATE,
  
  -- Additional info
  tags                TEXT[] DEFAULT '{}',
  attachments         JSONB DEFAULT '[]'::jsonb,
  custom_fields       JSONB DEFAULT '{}'::jsonb,
  notes               TEXT,
  
  -- Audit
  created_by          UUID NOT NULL REFERENCES employees(id),
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP
);

-- Indexes
CREATE INDEX idx_tasks_org_id ON tasks (organization_id);
CREATE INDEX idx_tasks_workspace_id ON tasks (workspace_id);
CREATE INDEX idx_tasks_assigned_to ON tasks (assigned_to);
CREATE INDEX idx_tasks_status ON tasks (status);
CREATE INDEX idx_tasks_priority ON tasks (priority);
CREATE INDEX idx_tasks_due_date ON tasks (due_date);
CREATE INDEX idx_tasks_department_id ON tasks (department_id);
CREATE INDEX idx_tasks_customer_id ON tasks (customer_id);
CREATE INDEX idx_tasks_tags ON tasks USING GIN (tags);
```

### time_entries
Time tracking

```sql
CREATE TABLE time_entries (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID NOT NULL REFERENCES organizations(id),
  workspace_id         UUID NOT NULL REFERENCES workspaces(id),
  employee_id          UUID NOT NULL REFERENCES employees(id),
  
  -- Time details
  entry_date           DATE NOT NULL,
  start_time          TIME,
  end_time            TIME,
  duration_hours       DECIMAL(6,2) NOT NULL CHECK (duration_hours >= 0),
  break_hours         DECIMAL(6,2) DEFAULT 0,
  
  -- Relations
  task_id             UUID REFERENCES tasks(id),
  project_id          UUID REFERENCES projects(id),
  customer_id         UUID REFERENCES customers(id),
  
  -- Billing
  is_billable         BOOLEAN NOT NULL DEFAULT true,
  hourly_rate         DECIMAL(8,2) DEFAULT 0,
  billable_amount     DECIMAL(10,2) GENERATED ALWAYS AS (
    CASE WHEN is_billable THEN duration_hours * hourly_rate ELSE 0 END
  ) STORED,
  
  -- Status
  status              VARCHAR(20) NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'submitted', 'approved', 'rejected', 'billed')),
  
  -- Description
  description         TEXT,
  notes               TEXT,
  
  -- Approval
  approved_by         UUID REFERENCES employees(id),
  approved_at         TIMESTAMP,
  rejection_reason    TEXT,
  
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  deleted_at          TIMESTAMP
);

-- Indexes
CREATE INDEX idx_time_entries_org_id ON time_entries (organization_id);
CREATE INDEX idx_time_entries_workspace_id ON time_entries (workspace_id);
CREATE INDEX idx_time_entries_employee_id ON time_entries (employee_id);
CREATE INDEX idx_time_entries_entry_date ON time_entries (entry_date);
CREATE INDEX idx_time_entries_task_id ON time_entries (task_id);
CREATE INDEX idx_time_entries_status ON time_entries (status);
```

## 📊 Analytics & Audit Tables

### audit_logs
System audit trail

```sql
CREATE TABLE audit_logs (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID REFERENCES organizations(id),
  workspace_id         UUID REFERENCES workspaces(id),
  
  -- Action details
  entity_type          VARCHAR(100) NOT NULL,
  entity_id           UUID NOT NULL,
  action              VARCHAR(50) NOT NULL
    CHECK (action IN ('CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT', 'EXPORT', 'IMPORT')),
  
  -- User details
  user_id             UUID REFERENCES users(id),
  user_email          VARCHAR(255),
  session_id          VARCHAR(255),
  
  -- Context
  ip_address          INET,
  user_agent          TEXT,
  request_path        VARCHAR(500),
  http_method         VARCHAR(10),
  
  -- Changes
  old_values          JSONB,
  new_values          JSONB,
  changes             JSONB,
  
  -- Additional metadata
  source              VARCHAR(50) DEFAULT 'web', -- web, api, system, etc
  reason              TEXT,
  metadata            JSONB DEFAULT '{}'::jsonb,
  
  -- Timing
  timestamp           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  duration_ms         INTEGER
);

-- Indexes (Partitioned by month for performance)
CREATE INDEX idx_audit_logs_timestamp ON audit_logs (timestamp);
CREATE INDEX idx_audit_logs_entity ON audit_logs (entity_type, entity_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs (user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs (action);
CREATE INDEX idx_audit_logs_org_workspace ON audit_logs (organization_id, workspace_id);

-- Partition by month
CREATE TABLE audit_logs_y2025m01 PARTITION OF audit_logs 
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

### system_logs
Application logs

```sql
CREATE TABLE system_logs (
  id                    BIGSERIAL PRIMARY KEY,
  level                VARCHAR(10) NOT NULL
    CHECK (level IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')),
  message              TEXT NOT NULL,
  logger_name          VARCHAR(255),
  
  -- Context
  organization_id       UUID,
  workspace_id         UUID,
  user_id             UUID,
  session_id          VARCHAR(255),
  request_id          VARCHAR(255),
  
  -- Error details
  error_code          VARCHAR(50),
  stack_trace         TEXT,
  
  -- Metadata
  metadata            JSONB DEFAULT '{}'::jsonb,
  tags                TEXT[] DEFAULT '{}',
  
  -- Timing
  timestamp           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  duration_ms         INTEGER
);

-- Indexes
CREATE INDEX idx_system_logs_timestamp ON system_logs (timestamp);
CREATE INDEX idx_system_logs_level ON system_logs (level);
CREATE INDEX idx_system_logs_logger ON system_logs (logger_name);
CREATE INDEX idx_system_logs_user_id ON system_logs (user_id);
CREATE INDEX idx_system_logs_error_code ON system_logs (error_code);
```

## 📋 Configuration Tables

### email_verifications
Email verification codes

```sql
CREATE TABLE email_verifications (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email                 VARCHAR(255) NOT NULL,
  code                  VARCHAR(10) NOT NULL,
  user_id              UUID REFERENCES users(id),
  type                 VARCHAR(20) NOT NULL DEFAULT 'registration'
    CHECK (type IN ('registration', 'password_reset', 'email_change')),
  
  -- Status
  is_used              BOOLEAN NOT NULL DEFAULT false,
  used_at              TIMESTAMP,
  
  -- Expiry
  expires_at           TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP + INTERVAL '24 hours'),
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_email_verifications_email ON email_verifications (email);
CREATE INDEX idx_email_verifications_code ON email_verifications (code);
CREATE INDEX idx_email_verifications_user_id ON email_verifications (user_id);
CREATE INDEX idx_email_verifications_expires_at ON email_verifications (expires_at);
```

### app_settings
Application configuration

```sql
CREATE TABLE app_settings (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id       UUID REFERENCES organizations(id),
  workspace_id         UUID REFERENCES workspaces(id),
  
  -- Setting identification
  key                  VARCHAR(255) NOT NULL,
  category             VARCHAR(100) NOT NULL DEFAULT 'general',
  
  -- Value
  value                JSONB NOT NULL,
  data_type           VARCHAR(20) NOT NULL DEFAULT 'string'
    CHECK (data_type IN ('string', 'number', 'boolean', 'object', 'array')),
  
  -- Metadata
  description          TEXT,
  is_secret           BOOLEAN NOT NULL DEFAULT false,
  is_readonly         BOOLEAN NOT NULL DEFAULT false,
  validation_rules    JSONB,
  
  -- Audit
  created_by          UUID REFERENCES users(id),
  updated_by          UUID REFERENCES users(id),
  created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  CONSTRAINT uk_settings_key_scope UNIQUE (key, organization_id, workspace_id)
);

-- Indexes
CREATE INDEX idx_app_settings_org_workspace ON app_settings (organization_id, workspace_id);
CREATE INDEX idx_app_settings_category ON app_settings (category);
CREATE INDEX idx_app_settings_key ON app_settings (key);
```

## 🔍 Views for Common Queries

### Customer Summary View

```sql
CREATE VIEW customer_summary AS
SELECT 
  c.id,
  c.name,
  c.type,
  c.status,
  c.email,
  c.phone,
  c.lifetime_value,
  c.credit_limit,
  c.balance,
  c.last_order_date,
  COUNT(DISTINCT d.id) as deal_count,
  COUNT(DISTINCT o.id) as order_count,
  COALESCE(SUM(o.total_amount), 0) as total_orders_value,
  COALESCE(AVG(o.total_amount), 0) as avg_order_value,
  c.created_at,
  c.updated_at
FROM customers c
LEFT JOIN deals d ON c.id = d.customer_id AND d.deleted_at IS NULL
LEFT JOIN orders o ON c.id = o.customer_id AND o.deleted_at IS NULL
WHERE c.deleted_at IS NULL
GROUP BY c.id, c.name, c.type, c.status, c.email, c.phone, 
         c.lifetime_value, c.credit_limit, c.balance, c.last_order_date,
         c.created_at, c.updated_at;
```

### Sales Pipeline View

```sql
CREATE VIEW sales_pipeline AS
SELECT 
  d.stage,
  COUNT(*) as deal_count,
  SUM(d.value) as total_value,
  AVG(d.value) as avg_deal_value,
  AVG(d.probability) as avg_probability,
  SUM(d.value * d.probability / 100) as weighted_value,
  COUNT(CASE WHEN d.expected_close_date <= CURRENT_DATE + INTERVAL '30 days' 
        THEN 1 END) as closing_this_month
FROM deals d
WHERE d.deleted_at IS NULL
  AND d.stage NOT IN ('WON', 'LOST')
GROUP BY d.stage
ORDER BY 
  CASE d.stage
    WHEN 'LEAD' THEN 1
    WHEN 'QUALIFIED' THEN 2
    WHEN 'PROPOSAL' THEN 3
    WHEN 'NEGOTIATION' THEN 4
    WHEN 'CLOSING' THEN 5
  END;
```

### Inventory Status View

```sql
CREATE VIEW inventory_status AS
SELECT 
  p.id,
  p.code,
  p.name,
  p.type,
  p.status,
  p.stock_level,
  p.reserved_quantity,
  p.available_quantity,
  p.min_stock_level,
  p.reorder_point,
  CASE 
    WHEN p.stock_level <= 0 THEN 'OUT_OF_STOCK'
    WHEN p.stock_level <= p.min_stock_level THEN 'LOW_STOCK'
    WHEN p.stock_level <= p.reorder_point THEN 'REORDER_NEEDED'
    ELSE 'IN_STOCK'
  END as inventory_status,
  p.price,
  p.cost,
  (p.price - p.cost) as margin,
  CASE WHEN p.cost > 0 THEN ((p.price - p.cost) / p.cost * 100) ELSE 0 END as margin_percent,
  p.stock_level * p.cost as inventory_value
FROM products p
WHERE p.deleted_at IS NULL
  AND p.track_inventory = true;
```

## 🔐 Security Policies

### Row Level Security (RLS)

```sql
-- Enable RLS on all tenant tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Organization-level isolation
CREATE POLICY organization_isolation ON customers
FOR ALL USING (organization_id = current_setting('app.current_organization_id')::uuid);

CREATE POLICY organization_isolation ON products  
FOR ALL USING (organization_id = current_setting('app.current_organization_id')::uuid);

-- Workspace-level isolation  
CREATE POLICY workspace_isolation ON deals
FOR ALL USING (
  organization_id = current_setting('app.current_organization_id')::uuid 
  AND workspace_id = current_setting('app.current_workspace_id')::uuid
);
```

### Data Encryption

```sql
-- Enable pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Encrypted sensitive fields
ALTER TABLE users ADD COLUMN encrypted_ssn BYTEA;

-- Functions for encryption/decryption
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(data TEXT)
RETURNS BYTEA AS $$
BEGIN
  RETURN pgp_sym_encrypt(data, current_setting('app.encryption_key'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrypt_sensitive_data(data BYTEA)
RETURNS TEXT AS $$
BEGIN
  RETURN pgp_sym_decrypt(data, current_setting('app.encryption_key'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## 🚀 Performance Optimizations

### Composite Indexes

```sql
-- Multi-tenant composite indexes
CREATE INDEX idx_customers_org_workspace_status 
ON customers (organization_id, workspace_id, status);

CREATE INDEX idx_deals_org_workspace_stage 
ON deals (organization_id, workspace_id, stage);

CREATE INDEX idx_orders_org_workspace_status_date 
ON orders (organization_id, workspace_id, status, order_date);

-- Performance indexes for common queries
CREATE INDEX idx_deals_close_date_stage 
ON deals (expected_close_date, stage) 
WHERE stage NOT IN ('WON', 'LOST');

CREATE INDEX idx_orders_customer_date 
ON orders (customer_id, order_date DESC);

CREATE INDEX idx_products_stock_status 
ON products (stock_level, status) 
WHERE track_inventory = true;
```

### Materialized Views

```sql
-- Daily sales summary
CREATE MATERIALIZED VIEW daily_sales_summary AS
SELECT 
  DATE(order_date) as sale_date,
  COUNT(*) as order_count,
  SUM(total_amount) as total_revenue,
  AVG(total_amount) as avg_order_value,
  COUNT(DISTINCT customer_id) as unique_customers
FROM orders
WHERE status IN ('delivered', 'completed')
  AND deleted_at IS NULL
GROUP BY DATE(order_date)
ORDER BY sale_date DESC;

-- Refresh schedule
CREATE INDEX idx_daily_sales_date ON daily_sales_summary (sale_date);
```

## 📊 Data Integrity Constraints

### Business Rules Enforcement

```sql
-- Ensure deal probability matches stage
CREATE OR REPLACE FUNCTION validate_deal_probability()
RETURNS TRIGGER AS $$
BEGIN
  -- Stage-based probability validation
  IF NEW.stage = 'LEAD' AND NEW.probability > 20 THEN
    NEW.probability = 20;
  ELSIF NEW.stage = 'QUALIFIED' AND NEW.probability > 40 THEN
    NEW.probability = 40;
  ELSIF NEW.stage = 'PROPOSAL' AND NEW.probability > 60 THEN
    NEW.probability = 60;
  ELSIF NEW.stage = 'NEGOTIATION' AND NEW.probability > 80 THEN
    NEW.probability = 80;
  ELSIF NEW.stage = 'WON' THEN
    NEW.probability = 100;
  ELSIF NEW.stage = 'LOST' THEN
    NEW.probability = 0;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validate_deal_probability
  BEFORE INSERT OR UPDATE ON deals
  FOR EACH ROW EXECUTE FUNCTION validate_deal_probability();
```

### Referential Integrity

```sql
-- Prevent deletion of products in use
CREATE OR REPLACE FUNCTION prevent_product_deletion()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM deal_products WHERE product_id = OLD.id
    UNION ALL
    SELECT 1 FROM order_items WHERE product_id = OLD.id
    UNION ALL
    SELECT 1 FROM invoice_items WHERE product_id = OLD.id
  ) THEN
    RAISE EXCEPTION 'Cannot delete product that is referenced in deals, orders, or invoices';
  END IF;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_product_deletion_trigger
  BEFORE DELETE ON products
  FOR EACH ROW EXECUTE FUNCTION prevent_product_deletion();
```

---

© 2025 Prometric ERP. Database Schema Documentation.