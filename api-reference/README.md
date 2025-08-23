# 📚 API Reference - Complete Endpoint Documentation

## 🌐 Base Configuration

### API Base URLs

```yaml
Development: http://localhost:5001/api/v1
Staging: https://api-staging.prometric.kz/api/v1
Production: https://api.prometric.kz/api/v1
AI Service: http://localhost:8080/api/v1
```

### Authentication

All API requests require JWT Bearer token authentication:

```http
Authorization: Bearer <jwt_token>
```

### Request Headers

```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <jwt_token>
X-Workspace-Id: <workspace_uuid>
X-Organization-Id: <organization_uuid>
Accept-Language: kk-KZ | ru-RU | en-US
```

### Response Format

```typescript
// Success Response
{
  "success": true,
  "data": T,
  "meta": {
    "timestamp": "2025-01-15T10:00:00Z",
    "version": "1.0.0"
  }
}

// Error Response
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": {},
    "timestamp": "2025-01-15T10:00:00Z"
  }
}

// Paginated Response
{
  "success": true,
  "data": {
    "items": T[],
    "total": number,
    "page": number,
    "limit": number,
    "totalPages": number
  }
}
```

## 🔐 Authentication API

### POST /auth/register
Register new organization owner

```typescript
// Request
{
  "email": "owner@company.kz",
  "password": "SecurePassword123!",
  "firstName": "Нұрдәулет",
  "lastName": "Ахматов",
  "phone": "+77001234567",
  "organizationName": "Tech Solutions KZ",
  "organizationBin": "123456789012"
}

// Response
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "owner@company.kz",
      "status": "pending"
    },
    "message": "Verification email sent"
  }
}
```

### POST /auth/login
User login

```typescript
// Request
{
  "email": "user@company.kz",
  "password": "password123"
}

// Response
{
  "success": true,
  "data": {
    "accessToken": "jwt_token",
    "refreshToken": "refresh_token",
    "user": {
      "id": "uuid",
      "email": "user@company.kz",
      "firstName": "Нұрдәулет",
      "lastName": "Ахматов",
      "organizationRole": "owner",
      "organizationId": "uuid",
      "workspaceId": "uuid"
    }
  }
}
```

### POST /auth/refresh
Refresh access token

```typescript
// Request
{
  "refreshToken": "refresh_token"
}

// Response
{
  "success": true,
  "data": {
    "accessToken": "new_jwt_token",
    "refreshToken": "new_refresh_token"
  }
}
```

### POST /auth/verify-email
Verify email with code

```typescript
// Request
{
  "email": "user@company.kz",
  "code": "123456"
}

// Response
{
  "success": true,
  "data": {
    "message": "Email verified successfully"
  }
}
```

### POST /auth/forgot-password
Request password reset

```typescript
// Request
{
  "email": "user@company.kz"
}

// Response
{
  "success": true,
  "data": {
    "message": "Reset code sent to email"
  }
}
```

### POST /auth/reset-password
Reset password with code

```typescript
// Request
{
  "email": "user@company.kz",
  "code": "123456",
  "newPassword": "NewSecurePassword123!"
}

// Response
{
  "success": true,
  "data": {
    "message": "Password reset successfully"
  }
}
```

## 👥 Users & Employees API

### GET /employees
Get all employees in workspace

```typescript
// Query Parameters
{
  page?: number;
  limit?: number;
  search?: string;
  departmentId?: string;
  status?: 'active' | 'inactive' | 'pending';
  role?: string;
}

// Response
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "userId": "uuid",
        "email": "employee@company.kz",
        "firstName": "Асхат",
        "lastName": "Жумабаев",
        "position": "Senior Developer",
        "departmentId": "uuid",
        "departmentName": "IT Department",
        "organizationRole": "employee",
        "status": "active",
        "phone": "+77001234567",
        "salary": 500000,
        "hireDate": "2024-01-15",
        "permissions": ["DEALS_VIEW", "DEALS_CREATE"]
      }
    ],
    "total": 45,
    "page": 1,
    "limit": 20
  }
}
```

### POST /employees
Create new employee

```typescript
// Request
{
  "email": "newemployee@company.kz",
  "password": "TempPassword123!",
  "firstName": "Айгерим",
  "lastName": "Сатпаева",
  "position": "Sales Manager",
  "departmentId": "uuid",
  "organizationRole": "employee",
  "phone": "+77001234568",
  "iin": "901231234567",
  "salary": 350000,
  "hireDate": "2025-01-15",
  "permissions": ["DEALS_VIEW", "DEALS_CREATE", "DEALS_UPDATE"]
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "newemployee@company.kz",
    "status": "pending",
    "message": "Employee created, awaiting approval"
  }
}
```

### GET /employees/:id
Get employee details

```typescript
// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "userId": "uuid",
    "email": "employee@company.kz",
    "firstName": "Айгерим",
    "lastName": "Сатпаева",
    "position": "Sales Manager",
    "department": {
      "id": "uuid",
      "name": "Sales Department",
      "headId": "uuid"
    },
    "organizationRole": "employee",
    "status": "active",
    "contacts": {
      "phone": "+77001234568",
      "emergencyContact": "+77009876543"
    },
    "documents": {
      "iin": "901231234567",
      "passport": "N12345678"
    },
    "employment": {
      "hireDate": "2025-01-15",
      "contractType": "permanent",
      "salary": 350000,
      "currency": "KZT"
    },
    "permissions": ["DEALS_VIEW", "DEALS_CREATE", "DEALS_UPDATE"],
    "metrics": {
      "tasksCompleted": 45,
      "dealsWon": 12,
      "performanceScore": 8.5
    }
  }
}
```

### PUT /employees/:id
Update employee

```typescript
// Request
{
  "position": "Senior Sales Manager",
  "salary": 450000,
  "departmentId": "new_dept_uuid",
  "permissions": ["DEALS_VIEW", "DEALS_CREATE", "DEALS_UPDATE", "DEALS_DELETE"]
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "message": "Employee updated successfully"
  }
}
```

### POST /employees/:id/approve
Approve pending employee

```typescript
// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "active",
    "message": "Employee approved and activated"
  }
}
```

## 🏢 Departments API

### GET /departments
Get all departments

```typescript
// Response
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Sales Department",
      "code": "SALES",
      "headId": "uuid",
      "headName": "Айгерим Сатпаева",
      "employeeCount": 12,
      "budget": 5000000,
      "isActive": true,
      "parentId": null,
      "children": []
    }
  ]
}
```

### POST /departments
Create department

```typescript
// Request
{
  "name": "Marketing Department",
  "code": "MKT",
  "headId": "uuid",
  "budget": 3000000,
  "parentId": null
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "Marketing Department",
    "code": "MKT"
  }
}
```

## 📦 Products API

### GET /products
Get all products

```typescript
// Query Parameters
{
  page?: number;
  limit?: number;
  search?: string;
  type?: 'PRODUCT' | 'MATERIAL' | 'SERVICE' | 'MANUFACTURED' | 'BUNDLE' | 'DIGITAL';
  status?: 'ACTIVE' | 'INACTIVE' | 'DISCONTINUED';
  category?: string;
  minPrice?: number;
  maxPrice?: number;
}

// Response
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "code": "PRD-001",
        "name": "Laptop Dell XPS 15",
        "type": "PRODUCT",
        "category": "Electronics",
        "description": "High-performance laptop",
        "unit": "шт",
        "status": "ACTIVE",
        "price": 650000,
        "cost": 500000,
        "currency": "KZT",
        "vatRate": 12,
        "vatIncluded": true,
        "barcode": "1234567890123",
        "inventory": {
          "inStock": 15,
          "reserved": 3,
          "available": 12,
          "minStock": 5,
          "maxStock": 50
        },
        "images": [
          {
            "url": "https://storage.prometric.kz/products/xps15-1.jpg",
            "isPrimary": true
          }
        ],
        "specifications": {
          "processor": "Intel Core i7",
          "ram": "16GB",
          "storage": "512GB SSD"
        },
        "createdAt": "2024-12-01T10:00:00Z",
        "updatedAt": "2025-01-15T10:00:00Z"
      }
    ],
    "total": 250,
    "page": 1,
    "limit": 20
  }
}
```

### POST /products
Create product

```typescript
// Request
{
  "code": "PRD-002",
  "name": "Wireless Mouse Logitech",
  "type": "PRODUCT",
  "category": "Accessories",
  "description": "Ergonomic wireless mouse",
  "unit": "шт",
  "price": 15000,
  "cost": 10000,
  "vatRate": 12,
  "vatIncluded": true,
  "barcode": "9876543210987",
  "minStock": 10,
  "maxStock": 100,
  "specifications": {
    "connectivity": "Bluetooth 5.0",
    "battery": "AA x2",
    "range": "10m"
  }
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "code": "PRD-002",
    "name": "Wireless Mouse Logitech",
    "status": "ACTIVE"
  }
}
```

### GET /products/:id
Get product details

```typescript
// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "code": "PRD-001",
    "name": "Laptop Dell XPS 15",
    "type": "PRODUCT",
    "fullDetails": true,
    "bom": [
      {
        "componentId": "uuid",
        "componentName": "Charger",
        "quantity": 1,
        "unit": "шт"
      }
    ],
    "suppliers": [
      {
        "supplierId": "uuid",
        "supplierName": "Tech Supplies KZ",
        "leadTime": 7,
        "minOrderQuantity": 5
      }
    ],
    "priceHistory": [
      {
        "date": "2025-01-01",
        "price": 650000,
        "cost": 500000
      }
    ],
    "stockMovements": [
      {
        "date": "2025-01-15",
        "type": "IN",
        "quantity": 10,
        "reference": "PO-001"
      }
    ]
  }
}
```

### PUT /products/:id
Update product

```typescript
// Request
{
  "price": 700000,
  "status": "ACTIVE",
  "minStock": 8,
  "specifications": {
    "processor": "Intel Core i9",
    "ram": "32GB",
    "storage": "1TB SSD"
  }
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "message": "Product updated successfully"
  }
}
```

### POST /products/batch
Batch create products

```typescript
// Request
{
  "products": [
    {
      "code": "PRD-003",
      "name": "Keyboard Mechanical",
      "type": "PRODUCT",
      "price": 35000
    },
    {
      "code": "PRD-004",
      "name": "Monitor 27 inch",
      "type": "PRODUCT",
      "price": 150000
    }
  ]
}

// Response
{
  "success": true,
  "data": {
    "created": 2,
    "failed": 0,
    "products": [
      { "id": "uuid1", "code": "PRD-003" },
      { "id": "uuid2", "code": "PRD-004" }
    ]
  }
}
```

## 👤 Customers API

### GET /customers
Get all customers

```typescript
// Query Parameters
{
  page?: number;
  limit?: number;
  search?: string;
  type?: 'COMPANY' | 'INDIVIDUAL';
  status?: 'LEAD' | 'PROSPECT' | 'ACTIVE' | 'INACTIVE' | 'CHURNED';
  segment?: string;
  minRevenue?: number;
  maxRevenue?: number;
}

// Response
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "name": "ТОО Tech Solutions",
        "type": "COMPANY",
        "status": "ACTIVE",
        "email": "info@techsolutions.kz",
        "phone": "+77001234567",
        "bin": "123456789012",
        "segment": "Enterprise",
        "rating": 4.5,
        "creditLimit": 5000000,
        "balance": -250000,
        "lifetimeValue": 15000000,
        "contacts": [
          {
            "id": "uuid",
            "firstName": "Арман",
            "lastName": "Есенов",
            "position": "CEO",
            "email": "arman@techsolutions.kz",
            "phone": "+77001234568",
            "isPrimary": true
          }
        ],
        "addresses": [
          {
            "type": "legal",
            "addressLine1": "ул. Абая 150",
            "city": "Алматы",
            "postalCode": "050000",
            "country": "KZ"
          }
        ],
        "metrics": {
          "totalOrders": 45,
          "totalRevenue": 15000000,
          "averageOrderValue": 333333,
          "lastOrderDate": "2025-01-10",
          "paymentBehavior": "on-time"
        }
      }
    ],
    "total": 1250,
    "page": 1,
    "limit": 20
  }
}
```

### POST /customers
Create customer

```typescript
// Request
{
  "name": "ИП Жумабаев А.С.",
  "type": "INDIVIDUAL",
  "email": "zhumabaev@email.kz",
  "phone": "+77009876543",
  "iin": "901231234567",
  "status": "LEAD",
  "source": "website",
  "segment": "SMB",
  "creditLimit": 1000000,
  "paymentTerms": "NET_30",
  "contacts": [
    {
      "firstName": "Асхат",
      "lastName": "Жумабаев",
      "position": "Owner",
      "email": "ashat@email.kz",
      "phone": "+77009876543",
      "isPrimary": true
    }
  ],
  "addresses": [
    {
      "type": "billing",
      "addressLine1": "пр. Достык 100",
      "city": "Нур-Султан",
      "postalCode": "010000",
      "country": "KZ"
    }
  ]
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "ИП Жумабаев А.С.",
    "status": "LEAD",
    "customerNumber": "CUS-2025-0001"
  }
}
```

### GET /customers/:id
Get customer details

```typescript
// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "ТОО Tech Solutions",
    "type": "COMPANY",
    "status": "ACTIVE",
    "fullDetails": true,
    "deals": [
      {
        "id": "uuid",
        "title": "Enterprise Software License",
        "value": 5000000,
        "stage": "WON",
        "closedAt": "2024-12-15"
      }
    ],
    "orders": [
      {
        "id": "uuid",
        "orderNumber": "ORD-2025-0001",
        "totalAmount": 1500000,
        "status": "delivered",
        "deliveredAt": "2025-01-10"
      }
    ],
    "invoices": [
      {
        "id": "uuid",
        "invoiceNumber": "INV-2025-0001",
        "amount": 1680000,
        "status": "paid",
        "paidAt": "2025-01-15"
      }
    ],
    "activities": [
      {
        "type": "email",
        "subject": "Contract renewal discussion",
        "date": "2025-01-14",
        "userId": "uuid"
      }
    ]
  }
}
```

### PUT /customers/:id
Update customer

```typescript
// Request
{
  "status": "ACTIVE",
  "segment": "Enterprise",
  "creditLimit": 10000000,
  "rating": 5
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "message": "Customer updated successfully"
  }
}
```

### POST /customers/:id/convert
Convert lead to customer

```typescript
// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "ACTIVE",
    "message": "Lead converted to active customer"
  }
}
```

## 💼 Deals API

### GET /deals
Get all deals

```typescript
// Query Parameters
{
  page?: number;
  limit?: number;
  search?: string;
  stage?: 'LEAD' | 'QUALIFIED' | 'PROPOSAL' | 'NEGOTIATION' | 'CLOSING' | 'WON' | 'LOST';
  customerId?: string;
  assignedTo?: string;
  minValue?: number;
  maxValue?: number;
  dateFrom?: string;
  dateTo?: string;
}

// Response
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "dealNumber": "DL-2025-0001",
        "title": "ERP System Implementation",
        "description": "Full ERP implementation for manufacturing",
        "customerId": "uuid",
        "customerName": "ТОО Tech Solutions",
        "value": 25000000,
        "currency": "KZT",
        "stage": "NEGOTIATION",
        "probability": 75,
        "expectedCloseDate": "2025-02-15",
        "assignedTo": "uuid",
        "assignedToName": "Айгерим Сатпаева",
        "source": "referral",
        "products": [
          {
            "productId": "uuid",
            "productName": "ERP License",
            "quantity": 50,
            "unitPrice": 400000,
            "discount": 10,
            "tax": 12,
            "totalPrice": 20160000
          }
        ],
        "competitors": ["Competitor A", "Competitor B"],
        "tags": ["enterprise", "high-priority"],
        "metrics": {
          "daysInPipeline": 45,
          "activitiesCount": 23,
          "lastActivityDate": "2025-01-14"
        }
      }
    ],
    "total": 87,
    "page": 1,
    "limit": 20
  }
}
```

### POST /deals
Create deal

```typescript
// Request
{
  "title": "Cloud Migration Project",
  "description": "Migrate on-premise infrastructure to cloud",
  "customerId": "uuid",
  "value": 15000000,
  "stage": "QUALIFIED",
  "probability": 60,
  "expectedCloseDate": "2025-03-01",
  "assignedTo": "uuid",
  "source": "website",
  "products": [
    {
      "productId": "uuid",
      "quantity": 1,
      "unitPrice": 15000000,
      "discount": 0,
      "tax": 12
    }
  ],
  "competitors": ["AWS", "Azure"],
  "tags": ["cloud", "migration", "priority"]
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "dealNumber": "DL-2025-0002",
    "title": "Cloud Migration Project",
    "stage": "QUALIFIED"
  }
}
```

### GET /deals/:id
Get deal details

```typescript
// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "dealNumber": "DL-2025-0001",
    "title": "ERP System Implementation",
    "fullDetails": true,
    "customer": {
      "id": "uuid",
      "name": "ТОО Tech Solutions",
      "type": "COMPANY",
      "email": "info@techsolutions.kz"
    },
    "products": [
      {
        "productId": "uuid",
        "product": {
          "name": "ERP License",
          "code": "ERP-001"
        },
        "quantity": 50,
        "unitPrice": 400000,
        "discount": 10,
        "tax": 12,
        "totalPrice": 20160000
      }
    ],
    "activities": [
      {
        "id": "uuid",
        "type": "meeting",
        "subject": "Requirements gathering",
        "date": "2025-01-10",
        "duration": 120,
        "notes": "Discussed implementation timeline",
        "participants": ["uuid1", "uuid2"]
      }
    ],
    "documents": [
      {
        "id": "uuid",
        "name": "Proposal_v2.pdf",
        "type": "proposal",
        "url": "https://storage.prometric.kz/deals/proposal.pdf",
        "uploadedAt": "2025-01-12"
      }
    ],
    "timeline": [
      {
        "stage": "LEAD",
        "enteredAt": "2024-12-01",
        "exitedAt": "2024-12-05"
      },
      {
        "stage": "QUALIFIED",
        "enteredAt": "2024-12-05",
        "exitedAt": "2024-12-20"
      },
      {
        "stage": "PROPOSAL",
        "enteredAt": "2024-12-20",
        "exitedAt": "2025-01-10"
      },
      {
        "stage": "NEGOTIATION",
        "enteredAt": "2025-01-10",
        "exitedAt": null
      }
    ]
  }
}
```

### PUT /deals/:id
Update deal

```typescript
// Request
{
  "stage": "CLOSING",
  "probability": 90,
  "value": 23000000,
  "expectedCloseDate": "2025-02-01"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "message": "Deal updated successfully"
  }
}
```

### POST /deals/:id/win
Mark deal as won

```typescript
// Request
{
  "actualCloseDate": "2025-01-15",
  "finalAmount": 22500000,
  "notes": "Closed with 10% discount"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "stage": "WON",
    "wonAt": "2025-01-15T10:00:00Z",
    "message": "Deal marked as won, order created automatically"
  }
}
```

### POST /deals/:id/lose
Mark deal as lost

```typescript
// Request
{
  "lostReason": "price",
  "competitorWon": "Competitor A",
  "notes": "Client chose cheaper alternative"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "stage": "LOST",
    "lostAt": "2025-01-15T10:00:00Z"
  }
}
```

### POST /deals/:id/activities
Add activity to deal

```typescript
// Request
{
  "type": "call",
  "subject": "Follow-up call",
  "date": "2025-01-15T14:00:00Z",
  "duration": 30,
  "notes": "Discussed pricing options",
  "outcome": "positive"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "message": "Activity added to deal"
  }
}
```

## 📦 Orders API

### GET /orders
Get all orders

```typescript
// Query Parameters
{
  page?: number;
  limit?: number;
  search?: string;
  status?: 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  customerId?: string;
  dealId?: string;
  dateFrom?: string;
  dateTo?: string;
}

// Response
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "orderNumber": "ORD-2025-0001",
        "type": "SALES",
        "customerId": "uuid",
        "customerName": "ТОО Tech Solutions",
        "dealId": "uuid",
        "dealNumber": "DL-2025-0001",
        "status": "processing",
        "totalAmount": 22500000,
        "currency": "KZT",
        "items": [
          {
            "productId": "uuid",
            "productName": "ERP License",
            "quantity": 50,
            "unitPrice": 400000,
            "discount": 10,
            "tax": 12,
            "totalPrice": 20160000
          }
        ],
        "shippingAddress": {
          "addressLine1": "ул. Абая 150",
          "city": "Алматы",
          "postalCode": "050000",
          "country": "KZ"
        },
        "deliveryDate": "2025-02-01",
        "paymentStatus": "partial",
        "paidAmount": 10000000,
        "createdAt": "2025-01-15T10:00:00Z"
      }
    ],
    "total": 234,
    "page": 1,
    "limit": 20
  }
}
```

### POST /orders
Create order

```typescript
// Request
{
  "type": "SALES",
  "customerId": "uuid",
  "dealId": "uuid",
  "items": [
    {
      "productId": "uuid",
      "quantity": 10,
      "unitPrice": 650000,
      "discount": 5,
      "tax": 12
    }
  ],
  "shippingAddress": {
    "addressLine1": "пр. Достык 100",
    "city": "Нур-Султан",
    "postalCode": "010000",
    "country": "KZ"
  },
  "deliveryDate": "2025-02-15",
  "paymentTerms": "NET_30",
  "notes": "Urgent delivery required"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "orderNumber": "ORD-2025-0002",
    "status": "pending",
    "totalAmount": 6916000
  }
}
```

### GET /orders/:id
Get order details

```typescript
// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "orderNumber": "ORD-2025-0001",
    "fullDetails": true,
    "statusHistory": [
      {
        "status": "pending",
        "date": "2025-01-15T10:00:00Z",
        "userId": "uuid"
      },
      {
        "status": "confirmed",
        "date": "2025-01-15T11:00:00Z",
        "userId": "uuid"
      },
      {
        "status": "processing",
        "date": "2025-01-15T12:00:00Z",
        "userId": "uuid"
      }
    ],
    "productionOrders": [
      {
        "id": "uuid",
        "productId": "uuid",
        "quantity": 50,
        "status": "in_progress",
        "completedQuantity": 30
      }
    ],
    "shipments": [
      {
        "id": "uuid",
        "trackingNumber": "KZ123456789",
        "carrier": "Kazpost",
        "status": "in_transit",
        "estimatedDelivery": "2025-02-01"
      }
    ],
    "invoices": [
      {
        "id": "uuid",
        "invoiceNumber": "INV-2025-0001",
        "amount": 22500000,
        "status": "partial",
        "paidAmount": 10000000
      }
    ],
    "documents": [
      {
        "type": "contract",
        "name": "Sales_Contract.pdf",
        "url": "https://storage.prometric.kz/orders/contract.pdf"
      }
    ]
  }
}
```

### PUT /orders/:id
Update order

```typescript
// Request
{
  "status": "confirmed",
  "deliveryDate": "2025-02-10",
  "notes": "Delivery date changed per customer request"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "message": "Order updated successfully"
  }
}
```

### POST /orders/:id/cancel
Cancel order

```typescript
// Request
{
  "reason": "Customer requested cancellation",
  "refundAmount": 10000000
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "cancelled",
    "message": "Order cancelled successfully"
  }
}
```

### POST /orders/:id/ship
Mark order as shipped

```typescript
// Request
{
  "trackingNumber": "KZ987654321",
  "carrier": "DHL",
  "estimatedDelivery": "2025-02-05"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "shipped",
    "shipmentId": "uuid"
  }
}
```

## 🏭 Production API

### GET /production/orders
Get production orders

```typescript
// Query Parameters
{
  page?: number;
  limit?: number;
  status?: 'pending' | 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
  priority?: 'low' | 'medium' | 'high' | 'urgent';
  productId?: string;
  orderId?: string;
}

// Response
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "productionNumber": "PRD-2025-0001",
        "orderId": "uuid",
        "orderNumber": "ORD-2025-0001",
        "productId": "uuid",
        "productName": "Custom Server Cabinet",
        "quantity": 10,
        "completedQuantity": 6,
        "status": "in_progress",
        "priority": "high",
        "startDate": "2025-01-10",
        "dueDate": "2025-01-25",
        "estimatedCompletion": "2025-01-24",
        "workOrders": [
          {
            "id": "uuid",
            "operation": "Cutting",
            "status": "completed",
            "completedQuantity": 10
          },
          {
            "id": "uuid",
            "operation": "Welding",
            "status": "in_progress",
            "completedQuantity": 6
          }
        ]
      }
    ],
    "total": 45,
    "page": 1,
    "limit": 20
  }
}
```

### POST /production/orders
Create production order

```typescript
// Request
{
  "orderId": "uuid",
  "productId": "uuid",
  "quantity": 20,
  "priority": "high",
  "dueDate": "2025-02-01",
  "notes": "Rush order for important client"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "productionNumber": "PRD-2025-0002",
    "status": "pending"
  }
}
```

### GET /production/bom/:productId
Get bill of materials

```typescript
// Response
{
  "success": true,
  "data": {
    "productId": "uuid",
    "productName": "Server Cabinet",
    "components": [
      {
        "materialId": "uuid",
        "materialName": "Steel Sheet 2mm",
        "quantity": 5,
        "unit": "м²",
        "cost": 15000
      },
      {
        "materialId": "uuid",
        "materialName": "Door Lock",
        "quantity": 1,
        "unit": "шт",
        "cost": 25000
      }
    ],
    "operations": [
      {
        "name": "Cutting",
        "duration": 120,
        "requiredSkills": ["metal-cutting"],
        "equipment": ["laser-cutter"]
      },
      {
        "name": "Welding",
        "duration": 180,
        "requiredSkills": ["welding"],
        "equipment": ["welding-machine"]
      }
    ],
    "totalCost": 100000,
    "totalTime": 300
  }
}
```

## 💰 Finance API

### GET /finance/invoices
Get all invoices

```typescript
// Query Parameters
{
  page?: number;
  limit?: number;
  status?: 'draft' | 'sent' | 'partial' | 'paid' | 'overdue' | 'cancelled';
  customerId?: string;
  orderId?: string;
  dateFrom?: string;
  dateTo?: string;
}

// Response
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "invoiceNumber": "INV-2025-0001",
        "customerId": "uuid",
        "customerName": "ТОО Tech Solutions",
        "orderId": "uuid",
        "orderNumber": "ORD-2025-0001",
        "status": "partial",
        "amount": 22500000,
        "paidAmount": 10000000,
        "currency": "KZT",
        "issueDate": "2025-01-15",
        "dueDate": "2025-02-15",
        "items": [
          {
            "description": "ERP License x50",
            "quantity": 50,
            "unitPrice": 400000,
            "tax": 12,
            "amount": 22400000
          }
        ],
        "payments": [
          {
            "id": "uuid",
            "amount": 10000000,
            "date": "2025-01-20",
            "method": "bank_transfer"
          }
        ]
      }
    ],
    "total": 567,
    "page": 1,
    "limit": 20
  }
}
```

### POST /finance/invoices
Create invoice

```typescript
// Request
{
  "customerId": "uuid",
  "orderId": "uuid",
  "items": [
    {
      "description": "Consulting Services",
      "quantity": 40,
      "unitPrice": 50000,
      "tax": 12
    }
  ],
  "dueDate": "2025-02-28",
  "notes": "Payment terms: NET 30"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "invoiceNumber": "INV-2025-0002",
    "amount": 2240000,
    "status": "draft"
  }
}
```

### POST /finance/payments
Record payment

```typescript
// Request
{
  "invoiceId": "uuid",
  "amount": 5000000,
  "method": "bank_transfer",
  "reference": "TRX123456",
  "date": "2025-01-25"
}

// Response
{
  "success": true,
  "data": {
    "id": "uuid",
    "paymentNumber": "PAY-2025-0001",
    "message": "Payment recorded successfully"
  }
}
```

## 📊 Analytics API

### GET /analytics/sales/dashboard
Sales dashboard metrics

```typescript
// Query Parameters
{
  period?: 'day' | 'week' | 'month' | 'quarter' | 'year';
  startDate?: string;
  endDate?: string;
}

// Response
{
  "success": true,
  "data": {
    "revenue": {
      "total": 125000000,
      "growth": 15.5,
      "target": 150000000,
      "achievement": 83.3
    },
    "deals": {
      "total": 87,
      "won": 23,
      "lost": 12,
      "inPipeline": 52,
      "winRate": 65.7,
      "averageValue": 5400000,
      "averageCycleTime": 45
    },
    "customers": {
      "total": 1250,
      "new": 45,
      "active": 890,
      "churnRate": 2.3
    },
    "products": {
      "topSelling": [
        {
          "id": "uuid",
          "name": "ERP License",
          "revenue": 45000000,
          "quantity": 112
        }
      ],
      "lowStock": [
        {
          "id": "uuid",
          "name": "Laptop Dell XPS",
          "current": 3,
          "minimum": 5
        }
      ]
    },
    "pipeline": {
      "LEAD": { "count": 15, "value": 45000000 },
      "QUALIFIED": { "count": 20, "value": 80000000 },
      "PROPOSAL": { "count": 10, "value": 55000000 },
      "NEGOTIATION": { "count": 5, "value": 35000000 },
      "CLOSING": { "count": 2, "value": 15000000 }
    }
  }
}
```

### GET /analytics/sales/forecast
Sales forecast

```typescript
// Query Parameters
{
  period?: 'month' | 'quarter' | 'year';
  horizon?: number; // months ahead
}

// Response
{
  "success": true,
  "data": {
    "forecast": [
      {
        "month": "2025-02",
        "predicted": 45000000,
        "minimum": 40000000,
        "maximum": 50000000,
        "confidence": 0.85
      },
      {
        "month": "2025-03",
        "predicted": 52000000,
        "minimum": 47000000,
        "maximum": 57000000,
        "confidence": 0.80
      }
    ],
    "factors": {
      "seasonality": 1.15,
      "trend": "growing",
      "risks": ["competitor_activity", "economic_slowdown"]
    }
  }
}
```

## 🤖 AI Service API

### POST /ai/chat
AI chat interaction

```typescript
// Request
{
  "message": "Какие сделки близки к закрытию в этом месяце?",
  "context": {
    "module": "sales",
    "intent": "query"
  }
}

// Response
{
  "success": true,
  "data": {
    "response": "У вас есть 3 сделки в стадии CLOSING с общей суммой 35 млн тенге:\n1. ERP Implementation - 20 млн, вероятность 90%\n2. Cloud Migration - 10 млн, вероятность 85%\n3. Security Audit - 5 млн, вероятность 95%",
    "actions": [
      {
        "type": "view_deals",
        "params": { "stage": "CLOSING" }
      }
    ],
    "suggestions": [
      "Показать детали по каждой сделке",
      "Создать задачи для закрытия"
    ]
  }
}
```

### POST /ai/predict
AI predictions

```typescript
// Request
{
  "type": "deal_success",
  "entityId": "uuid",
  "context": {
    "includeHistory": true
  }
}

// Response
{
  "success": true,
  "data": {
    "prediction": {
      "probability": 0.75,
      "confidence": 0.85,
      "factors": {
        "positive": [
          "Strong customer engagement",
          "Budget approved",
          "Decision maker involved"
        ],
        "negative": [
          "Long sales cycle",
          "Multiple competitors"
        ]
      }
    },
    "recommendations": [
      {
        "action": "schedule_demo",
        "priority": "high",
        "reason": "Increase engagement"
      },
      {
        "action": "offer_discount",
        "priority": "medium",
        "reason": "Counter competition"
      }
    ]
  }
}
```

### POST /ai/analyze
AI analysis

```typescript
// Request
{
  "type": "customer_churn",
  "customerId": "uuid",
  "period": "last_6_months"
}

// Response
{
  "success": true,
  "data": {
    "churnRisk": 0.35,
    "riskLevel": "medium",
    "indicators": {
      "decreasedOrders": true,
      "latePayments": false,
      "supportTickets": true,
      "lastOrderDays": 45
    },
    "recommendations": [
      {
        "action": "personal_outreach",
        "urgency": "high",
        "expectedImpact": 0.25
      },
      {
        "action": "loyalty_discount",
        "urgency": "medium",
        "expectedImpact": 0.15
      }
    ]
  }
}
```

## 🔍 Search API

### POST /search
Global search

```typescript
// Request
{
  "query": "Dell laptop",
  "types": ["products", "customers", "deals", "orders"],
  "limit": 10
}

// Response
{
  "success": true,
  "data": {
    "results": [
      {
        "type": "product",
        "id": "uuid",
        "title": "Laptop Dell XPS 15",
        "description": "High-performance laptop",
        "score": 0.95
      },
      {
        "type": "deal",
        "id": "uuid",
        "title": "Dell Equipment Purchase",
        "description": "50 laptops for office",
        "score": 0.85
      }
    ],
    "total": 2,
    "suggestions": [
      "Dell monitors",
      "Dell accessories"
    ]
  }
}
```

## 📄 Reports API

### GET /reports/generate
Generate report

```typescript
// Query Parameters
{
  type: 'sales' | 'inventory' | 'finance' | 'hr';
  format: 'pdf' | 'excel' | 'csv';
  period: string;
  filters?: object;
}

// Response
{
  "success": true,
  "data": {
    "reportId": "uuid",
    "status": "processing",
    "estimatedTime": 30,
    "message": "Report generation started"
  }
}
```

### GET /reports/:id/download
Download report

```typescript
// Response
// Binary file download or
{
  "success": true,
  "data": {
    "url": "https://storage.prometric.kz/reports/report-uuid.pdf",
    "expiresAt": "2025-01-15T12:00:00Z"
  }
}
```

## 🔔 Notifications API

### GET /notifications
Get user notifications

```typescript
// Query Parameters
{
  unread?: boolean;
  type?: string;
  limit?: number;
}

// Response
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "type": "deal_won",
        "title": "Deal Won!",
        "message": "ERP Implementation deal closed successfully",
        "data": {
          "dealId": "uuid",
          "amount": 20000000
        },
        "read": false,
        "createdAt": "2025-01-15T10:00:00Z"
      }
    ],
    "unreadCount": 5,
    "total": 45
  }
}
```

### PUT /notifications/:id/read
Mark notification as read

```typescript
// Response
{
  "success": true,
  "data": {
    "message": "Notification marked as read"
  }
}
```

## 🔧 System API

### GET /health
Health check

```typescript
// Response
{
  "success": true,
  "data": {
    "status": "healthy",
    "version": "1.0.0",
    "uptime": 864000,
    "services": {
      "database": "connected",
      "redis": "connected",
      "elasticsearch": "connected",
      "ai": "connected"
    }
  }
}
```

### GET /config
Get system configuration

```typescript
// Response
{
  "success": true,
  "data": {
    "features": {
      "ai": true,
      "elasticsearch": true,
      "multiLanguage": true
    },
    "locales": ["kk-KZ", "ru-RU", "en-US"],
    "currency": "KZT",
    "vatRate": 12,
    "dateFormat": "DD.MM.YYYY",
    "timeZone": "Asia/Almaty"
  }
}
```

## 📊 WebSocket Events

### Connection

```javascript
const socket = io('wss://api.prometric.kz', {
  auth: {
    token: 'jwt_token'
  }
});

socket.on('connect', () => {
  console.log('Connected to WebSocket');
});
```

### Real-time Events

```javascript
// Deal updates
socket.on('deal.updated', (data) => {
  console.log('Deal updated:', data);
});

// Order status changes
socket.on('order.status.changed', (data) => {
  console.log('Order status changed:', data);
});

// New notifications
socket.on('notification.new', (data) => {
  console.log('New notification:', data);
});

// Chat messages
socket.on('chat.message', (data) => {
  console.log('New chat message:', data);
});
```

## 🚦 Rate Limiting

```yaml
Default Limits:
  - Anonymous: 10 requests/minute
  - Authenticated: 100 requests/minute
  - Premium: 1000 requests/minute

Headers:
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 95
  X-RateLimit-Reset: 1642329600
```

## 🔑 Error Codes

```typescript
const ErrorCodes = {
  // Authentication
  AUTH_INVALID_CREDENTIALS: 'Invalid email or password',
  AUTH_TOKEN_EXPIRED: 'Token has expired',
  AUTH_UNAUTHORIZED: 'Unauthorized access',
  
  // Validation
  VALIDATION_FAILED: 'Validation failed',
  INVALID_UUID: 'Invalid UUID format',
  REQUIRED_FIELD: 'Required field missing',
  
  // Business Logic
  INSUFFICIENT_BALANCE: 'Insufficient balance',
  CREDIT_LIMIT_EXCEEDED: 'Credit limit exceeded',
  STOCK_UNAVAILABLE: 'Stock not available',
  
  // System
  INTERNAL_ERROR: 'Internal server error',
  DATABASE_ERROR: 'Database operation failed',
  SERVICE_UNAVAILABLE: 'Service temporarily unavailable'
};
```

## 📝 API Versioning

```http
# Version in URL
GET /api/v1/products
GET /api/v2/products

# Version in Header
GET /api/products
API-Version: 1.0
```

## 🔄 Pagination

```typescript
// Request
GET /api/v1/products?page=2&limit=20&sort=name&order=asc

// Response
{
  "data": {
    "items": [...],
    "pagination": {
      "page": 2,
      "limit": 20,
      "total": 250,
      "totalPages": 13,
      "hasNext": true,
      "hasPrev": true
    }
  }
}
```

## 🔍 Filtering & Sorting

```typescript
// Complex filtering
GET /api/v1/deals?
  stage=NEGOTIATION,CLOSING&
  value[gte]=1000000&
  value[lte]=10000000&
  customer.type=COMPANY&
  assignedTo=uuid&
  createdAt[gte]=2025-01-01&
  sort=-value,createdAt

// Response includes filtered and sorted results
```

## 🌍 Internationalization

```typescript
// Request with locale
GET /api/v1/products
Accept-Language: kk-KZ

// Response with localized content
{
  "data": {
    "name": "Ноутбук Dell XPS 15",
    "description": "Жоғары өнімді ноутбук",
    "category": "Электроника"
  }
}
```

---

© 2025 Prometric ERP. API Reference Documentation.