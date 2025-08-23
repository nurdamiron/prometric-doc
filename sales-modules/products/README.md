# 📦 Products Module - Полная документация

## 📋 Содержание
1. [Обзор модуля](#обзор-модуля)
2. [Entity структура](#entity-структура)
3. [Типы продуктов](#типы-продуктов)
4. [API Endpoints](#api-endpoints)
5. [DTO структуры](#dto-структуры)
6. [Бизнес-логика](#бизнес-логика)
7. [Интеграции](#интеграции)
8. [Валидация](#валидация)
9. [Кеширование](#кеширование)
10. [Примеры использования](#примеры-использования)

## 🎯 Обзор модуля

Products Module - центральный модуль управления продуктами, материалами и услугами в системе Prometric ERP. Поддерживает полный жизненный цикл управления номенклатурой от создания до архивирования.

### Ключевые возможности:
- ✅ Управление различными типами продуктов (товары, материалы, услуги, производимые изделия)
- ✅ Многоуровневая категоризация
- ✅ Управление складскими остатками
- ✅ НДС и налоговые расчеты (12% стандарт для Казахстана)
- ✅ Интеграция с производством и закупками
- ✅ Bulk операции для массового импорта/экспорта
- ✅ Wizard для упрощенного создания продуктов
- ✅ Полная история изменений

## 🗄️ Entity структура

### Product Entity (`src/products/entities/product.entity.ts`)

```typescript
@Entity('products')
@Index(['organizationId', 'workspaceId'])
@Index(['code', 'organizationId'], { unique: true })
@Index(['status'])
@Index(['productType'])
@Index(['categoryId'])
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string; // Наименование продукта

  @Column({ unique: true })
  code: string; // Уникальный код/артикул

  @Column({ type: 'text', nullable: true })
  description: string; // Описание

  @Column({ default: 'шт' })
  unit: string; // Единица измерения

  @Column({ type: 'decimal', precision: 15, scale: 2, default: 0 })
  price: number; // Цена продажи

  @Column({ type: 'decimal', precision: 15, scale: 2, default: 0 })
  cost: number; // Себестоимость

  @Column({ type: 'enum', enum: ProductType, default: ProductType.PRODUCT })
  productType: ProductType;

  @Column({ type: 'enum', enum: ProductStatus, default: ProductStatus.ACTIVE })
  status: ProductStatus;

  // НДС и налоги
  @Column({ type: 'decimal', precision: 5, scale: 2, default: 12 })
  vatRate: number; // Ставка НДС (12% стандарт)

  @Column({ default: true })
  vatIncluded: boolean; // НДС включен в цену

  @Column({ default: false })
  vatExempt: boolean; // Освобожден от НДС

  // Физические характеристики
  @Column({ type: 'decimal', precision: 10, scale: 3, nullable: true })
  weight: number; // Вес в кг

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  length: number; // Длина в см

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  width: number; // Ширина в см

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  height: number; // Высота в см

  // Поставщики
  @Column({ nullable: true })
  primarySupplierId: string;

  @Column({ nullable: true })
  supplierCode: string; // Код поставщика

  @Column({ type: 'decimal', precision: 15, scale: 2, nullable: true })
  purchasePrice: number; // Закупочная цена

  @Column({ type: 'int', nullable: true })
  leadTimeDays: number; // Срок поставки в днях

  @Column({ type: 'decimal', precision: 15, scale: 3, nullable: true })
  minOrderQuantity: number; // Минимальный заказ

  // Производство
  @Column({ type: 'decimal', precision: 15, scale: 2, nullable: true })
  materialCost: number; // Стоимость материалов

  @Column({ type: 'decimal', precision: 15, scale: 2, nullable: true })
  laborCost: number; // Стоимость работы

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 20 })
  overheadPercent: number; // Накладные расходы %

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 30 })
  marginPercent: number; // Наценка %

  // Складские параметры
  @Column({ type: 'decimal', precision: 15, scale: 3, nullable: true })
  minStockLevel: number; // Минимальный остаток

  @Column({ type: 'decimal', precision: 15, scale: 3, nullable: true })
  maxStockLevel: number; // Максимальный остаток

  @Column({ type: 'int', nullable: true })
  expiryDays: number; // Срок годности в днях

  @Column({ default: false })
  batchTracking: boolean; // Партионный учет

  // Связи
  @ManyToOne(() => Category, { nullable: true })
  @JoinColumn({ name: 'categoryId' })
  category: Category;

  @Column({ nullable: true })
  categoryId: string;

  @ManyToOne(() => Organization)
  @JoinColumn({ name: 'organizationId' })
  organization: Organization;

  @Column()
  organizationId: string;

  @ManyToOne(() => Workspace)
  @JoinColumn({ name: 'workspaceId' })
  workspace: Workspace;

  @Column()
  workspaceId: string;

  // Timestamps
  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ nullable: true })
  createdBy: string;

  @Column({ nullable: true })
  updatedBy: string;
}
```

## 🎨 Типы продуктов

### ProductType Enum

```typescript
export enum ProductType {
  PRODUCT = 'PRODUCT',           // Обычный товар для перепродажи
  MATERIAL = 'MATERIAL',         // Сырье и материалы
  SERVICE = 'SERVICE',           // Услуги
  DIGITAL = 'DIGITAL',          // Цифровые товары
  BUNDLE = 'BUNDLE',            // Наборы/комплекты
  MANUFACTURED = 'MANUFACTURED'  // Производимые изделия
}
```

### ProductStatus Enum

```typescript
export enum ProductStatus {
  ACTIVE = 'ACTIVE',           // Активен для продаж
  INACTIVE = 'INACTIVE',       // Временно неактивен
  DRAFT = 'DRAFT',            // Черновик
  DISCONTINUED = 'DISCONTINUED' // Снят с производства
}
```

### Специфика по типам:

#### 🛍️ PRODUCT (Товары для перепродажи)
- **Обязательные поля:** name, code, unit, price, purchasePrice
- **Использование:** Товары, закупаемые у поставщиков для перепродажи
- **Интеграции:** Закупки, Склад, Продажи

#### 🏭 MATERIAL (Материалы и сырье)
- **Обязательные поля:** name, code, unit, price, weight или dimensions
- **Использование:** Сырье для производства
- **Интеграции:** Производство, BOM (Bill of Materials), Закупки

#### 🛠️ SERVICE (Услуги)
- **Обязательные поля:** name, code, unit, price
- **Использование:** Услуги компании
- **Особенности:** Не требуют складского учета

#### 🏗️ MANUFACTURED (Производимые изделия)
- **Обязательные поля:** materialCost, laborCost
- **Использование:** Товары собственного производства
- **Расчеты:** 
  - `totalCost = materialCost + laborCost + (materialCost + laborCost) * overheadPercent / 100`
  - `price = totalCost * (1 + marginPercent / 100)`
- **Интеграции:** Production Orders, BOM, Work Orders

#### 📦 BUNDLE (Наборы)
- **Обязательные поля:** description, price
- **Использование:** Комплекты из нескольких товаров
- **Особенности:** Связь с BundleItems

#### 💾 DIGITAL (Цифровые товары)
- **Обязательные поля:** price, description
- **Использование:** Лицензии, подписки, цифровой контент
- **Особенности:** Не требуют физического склада

## 📡 API Endpoints

### Основные CRUD операции

#### GET /workspaces/:workspaceId/products
Получить список продуктов с фильтрацией и пагинацией

**Query параметры:**
- `search` - поиск по названию/коду
- `status` - фильтр по статусу
- `productType` - фильтр по типу
- `categoryId` - фильтр по категории
- `minPrice` / `maxPrice` - фильтр по цене
- `page` - страница (default: 1)
- `limit` - элементов на странице (default: 20)
- `sortBy` - поле сортировки
- `sortOrder` - ASC/DESC

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Продукт 1",
      "code": "PRD001",
      "price": 15000,
      "cost": 10000,
      "status": "ACTIVE",
      "productType": "PRODUCT",
      "vatRate": 12,
      "vatIncluded": true,
      "category": {
        "id": "uuid",
        "name": "Категория"
      }
    }
  ],
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 20,
    "totalPages": 5
  }
}
```

#### GET /workspaces/:workspaceId/products/:id
Получить детальную информацию о продукте

#### POST /workspaces/:workspaceId/products
Создать новый продукт

**Request Body:**
```json
{
  "name": "Новый продукт",
  "code": "NEW001",
  "description": "Описание продукта",
  "unit": "шт",
  "price": 25000,
  "cost": 15000,
  "productType": "PRODUCT",
  "status": "ACTIVE",
  "vatRate": 12,
  "vatIncluded": true,
  "categoryId": "uuid",
  "minStockLevel": 10,
  "maxStockLevel": 100
}
```

#### PUT /workspaces/:workspaceId/products/:id
Обновить продукт

#### DELETE /workspaces/:workspaceId/products/:id
Удалить продукт (soft delete)

### Специальные endpoints

#### POST /workspaces/:workspaceId/products/bulk
Массовое создание продуктов

**Request Body:**
```json
{
  "products": [
    { /* product data */ },
    { /* product data */ }
  ],
  "skipValidation": false
}
```

#### DELETE /workspaces/:workspaceId/products/bulk
Массовое удаление продуктов

**Request Body:**
```json
{
  "productIds": ["uuid1", "uuid2", "uuid3"]
}
```

#### POST /workspaces/:workspaceId/products/import
Импорт из Excel/CSV файла

**Form Data:**
- `file` - файл Excel/CSV
- `updateExisting` - обновлять существующие (boolean)
- `skipErrors` - пропускать ошибки (boolean)

#### GET /workspaces/:workspaceId/products/export
Экспорт в Excel

**Query параметры:**
- Все параметры фильтрации как в GET /products
- `format` - excel/csv

### Product Wizard

#### POST /workspaces/:workspaceId/products/wizard
Создание продукта через визард

**Request Body:**
```json
{
  "step": "basic",
  "data": {
    "productType": "MANUFACTURED",
    "name": "Изделие",
    "code": "MAN001",
    "baseInfo": { /* ... */ },
    "pricing": { /* ... */ },
    "inventory": { /* ... */ },
    "manufacturing": {
      "bomItems": [
        {
          "materialId": "uuid",
          "quantity": 2,
          "unit": "шт"
        }
      ],
      "operations": [
        {
          "name": "Сборка",
          "duration": 120,
          "cost": 5000
        }
      ]
    }
  }
}
```

### Categories

#### GET /workspaces/:workspaceId/products/categories
Получить дерево категорий

#### POST /workspaces/:workspaceId/products/categories
Создать категорию

#### PUT /workspaces/:workspaceId/products/categories/:id
Обновить категорию

#### DELETE /workspaces/:workspaceId/products/categories/:id
Удалить категорию

### Inventory

#### GET /workspaces/:workspaceId/products/:id/inventory
Получить складские остатки продукта

#### POST /workspaces/:workspaceId/products/:id/inventory/adjust
Корректировка остатков

**Request Body:**
```json
{
  "warehouseId": "uuid",
  "adjustment": 10,
  "reason": "Инвентаризация",
  "notes": "Примечания"
}
```

## 📝 DTO структуры

### CreateProductDto

```typescript
export class CreateProductDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  code: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsString()
  @IsOptional()
  unit?: string = 'шт';

  @IsNumber()
  @IsOptional()
  price?: number;

  @IsNumber()
  @IsOptional()
  cost?: number;

  @IsEnum(ProductType)
  @IsOptional()
  productType?: ProductType = ProductType.PRODUCT;

  @IsEnum(ProductStatus)
  @IsOptional()
  status?: ProductStatus = ProductStatus.ACTIVE;

  @IsNumber()
  @IsOptional()
  vatRate?: number = 12;

  @IsBoolean()
  @IsOptional()
  vatIncluded?: boolean = true;

  @IsBoolean()
  @IsOptional()
  vatExempt?: boolean = false;

  @IsString()
  @IsOptional()
  categoryId?: string;

  // Физические характеристики
  @IsNumber()
  @IsOptional()
  weight?: number;

  @IsNumber()
  @IsOptional()
  length?: number;

  @IsNumber()
  @IsOptional()
  width?: number;

  @IsNumber()
  @IsOptional()
  height?: number;

  // Поставщики
  @IsString()
  @IsOptional()
  primarySupplierId?: string;

  @IsString()
  @IsOptional()
  supplierCode?: string;

  @IsNumber()
  @IsOptional()
  purchasePrice?: number;

  @IsNumber()
  @IsOptional()
  leadTimeDays?: number;

  @IsNumber()
  @IsOptional()
  minOrderQuantity?: number;

  // Производство
  @IsNumber()
  @IsOptional()
  materialCost?: number;

  @IsNumber()
  @IsOptional()
  laborCost?: number;

  @IsNumber()
  @IsOptional()
  overheadPercent?: number = 20;

  @IsNumber()
  @IsOptional()
  marginPercent?: number = 30;

  // Склад
  @IsNumber()
  @IsOptional()
  minStockLevel?: number;

  @IsNumber()
  @IsOptional()
  maxStockLevel?: number;

  @IsNumber()
  @IsOptional()
  expiryDays?: number;

  @IsBoolean()
  @IsOptional()
  batchTracking?: boolean = false;
}
```

### UpdateProductDto

```typescript
export class UpdateProductDto extends PartialType(CreateProductDto) {}
```

### BulkCreateProductsDto

```typescript
export class BulkCreateProductsDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateProductDto)
  products: CreateProductDto[];

  @IsBoolean()
  @IsOptional()
  skipValidation?: boolean = false;
}
```

### ProductWizardDto

```typescript
export class ProductWizardDto {
  @IsEnum(['basic', 'pricing', 'inventory', 'manufacturing', 'complete'])
  step: string;

  @IsObject()
  data: {
    productType?: ProductType;
    baseInfo?: {
      name: string;
      code: string;
      description?: string;
      categoryId?: string;
    };
    pricing?: {
      price: number;
      cost?: number;
      vatRate?: number;
      vatIncluded?: boolean;
    };
    inventory?: {
      unit: string;
      minStockLevel?: number;
      maxStockLevel?: number;
      batchTracking?: boolean;
    };
    manufacturing?: {
      bomItems?: Array<{
        materialId: string;
        quantity: number;
        unit: string;
      }>;
      operations?: Array<{
        name: string;
        duration: number;
        cost: number;
      }>;
    };
  };
}
```

## 💼 Бизнес-логика

### Расчет цен для MANUFACTURED продуктов

```typescript
calculateManufacturedPrice(product: Product): number {
  const baseCost = product.materialCost + product.laborCost;
  const overheadCost = baseCost * (product.overheadPercent / 100);
  const totalCost = baseCost + overheadCost;
  const price = totalCost * (1 + product.marginPercent / 100);
  
  // Учет НДС
  if (!product.vatIncluded && !product.vatExempt) {
    return price * (1 + product.vatRate / 100);
  }
  
  return price;
}
```

### Расчет НДС

```typescript
calculateVAT(product: Product): {
  priceWithoutVAT: number;
  vatAmount: number;
  priceWithVAT: number;
} {
  if (product.vatExempt) {
    return {
      priceWithoutVAT: product.price,
      vatAmount: 0,
      priceWithVAT: product.price
    };
  }

  const vatRate = product.vatRate / 100;
  
  if (product.vatIncluded) {
    const priceWithoutVAT = product.price / (1 + vatRate);
    const vatAmount = product.price - priceWithoutVAT;
    return {
      priceWithoutVAT,
      vatAmount,
      priceWithVAT: product.price
    };
  } else {
    const vatAmount = product.price * vatRate;
    return {
      priceWithoutVAT: product.price,
      vatAmount,
      priceWithVAT: product.price + vatAmount
    };
  }
}
```

### Валидация по типам продуктов

```typescript
@ValidatorConstraint({ async: false })
export class ProductTypeValidatorConstraint implements ValidatorConstraintInterface {
  validate(value: any, args: ValidationArguments) {
    const object = args.object as any;
    const productType = object.productType;

    switch (productType) {
      case ProductType.SERVICE:
        // Для услуг обязательны: unit, price
        return !!(object.unit && object.price);
        
      case ProductType.MATERIAL:
        // Для материалов обязательны: unit, price, weight или dimensions
        return !!(object.unit && object.price && 
          (object.weight || object.length || object.width || object.height));
          
      case ProductType.DIGITAL:
        // Для цифровых продуктов обязательны: price, description
        return !!(object.price && object.description);
        
      case ProductType.MANUFACTURED:
        // Для производимых продуктов обязательны: materialCost, laborCost
        return !!(object.materialCost !== undefined && object.laborCost !== undefined);
        
      case ProductType.BUNDLE:
        // Для наборов обязательны: description, price
        return !!(object.description && object.price);
        
      default:
        return true;
    }
  }
}
```

## 🔗 Интеграции

### Связь с другими модулями

#### 1. Deals Module
- Продукты добавляются в сделки через `DealProduct` entity
- Поддержка скидок и специальных цен
- Автоматический расчет маржи

#### 2. Orders Module
- Продукты в заказах через `OrderItem` interface
- Проверка доступности на складе
- Резервирование товаров

#### 3. Production Module
- MANUFACTURED продукты создают Production Orders
- BOM (Bill of Materials) для состава изделий
- Расчет себестоимости производства

#### 4. Procurement Module
- Автоматическое создание заявок на закупку
- Отслеживание поставщиков и цен
- Управление минимальными остатками

#### 5. Warehouse Module
- Складской учет по местам хранения
- Партионный учет для отслеживаемых товаров
- Инвентаризация и корректировки

## 🗃️ Кеширование

### Redis Cache Strategy

```typescript
@Injectable()
export class ProductsService {
  // Кеширование списка продуктов
  @Cacheable({
    key: (args) => `products:list:${args[0]}:${args[1]}:${JSON.stringify(args[2])}`,
    ttl: 300 // 5 минут
  })
  async findAll(organizationId: string, workspaceId: string, filters: any) {
    // ...
  }

  // Кеширование отдельного продукта
  @Cacheable({
    key: (args) => `products:single:${args[0]}`,
    ttl: 600 // 10 минут
  })
  async findOne(id: string) {
    // ...
  }

  // Очистка кеша при изменении
  @CacheEvict({
    key: (args) => [
      `products:single:${args[0]}`,
      `products:list:*`
    ]
  })
  async update(id: string, updateProductDto: UpdateProductDto) {
    // ...
  }
}
```

## 📊 Примеры использования

### Создание обычного товара

```typescript
// POST /workspaces/:workspaceId/products
{
  "name": "Ноутбук Dell Latitude 5520",
  "code": "DELL-5520",
  "description": "Бизнес-ноутбук с процессором Intel i7",
  "unit": "шт",
  "price": 450000,
  "cost": 380000,
  "productType": "PRODUCT",
  "status": "ACTIVE",
  "vatRate": 12,
  "vatIncluded": true,
  "categoryId": "electronics-category-id",
  "weight": 2.5,
  "primarySupplierId": "dell-supplier-id",
  "purchasePrice": 380000,
  "leadTimeDays": 14,
  "minOrderQuantity": 1,
  "minStockLevel": 5,
  "maxStockLevel": 20
}
```

### Создание услуги

```typescript
// POST /workspaces/:workspaceId/products
{
  "name": "Консультация по внедрению ERP",
  "code": "SERV-CONSULT-001",
  "description": "Консультационные услуги по внедрению ERP системы",
  "unit": "час",
  "price": 50000,
  "productType": "SERVICE",
  "status": "ACTIVE",
  "vatRate": 12,
  "vatIncluded": true,
  "categoryId": "services-category-id"
}
```

### Создание производимого изделия

```typescript
// POST /workspaces/:workspaceId/products/wizard
{
  "step": "complete",
  "data": {
    "productType": "MANUFACTURED",
    "baseInfo": {
      "name": "Стол офисный",
      "code": "FURN-DESK-001",
      "description": "Офисный стол 140x70 см",
      "categoryId": "furniture-category-id"
    },
    "pricing": {
      "materialCost": 25000,
      "laborCost": 15000,
      "overheadPercent": 20,
      "marginPercent": 40,
      "vatRate": 12,
      "vatIncluded": true
    },
    "inventory": {
      "unit": "шт",
      "minStockLevel": 2,
      "maxStockLevel": 10
    },
    "manufacturing": {
      "bomItems": [
        {
          "materialId": "wood-material-id",
          "quantity": 2,
          "unit": "м²"
        },
        {
          "materialId": "screws-material-id",
          "quantity": 20,
          "unit": "шт"
        }
      ],
      "operations": [
        {
          "name": "Распил",
          "duration": 30,
          "cost": 3000
        },
        {
          "name": "Сборка",
          "duration": 60,
          "cost": 5000
        },
        {
          "name": "Покраска",
          "duration": 120,
          "cost": 7000
        }
      ]
    }
  }
}
```

### Массовый импорт из Excel

```typescript
// POST /workspaces/:workspaceId/products/import
// Form-data:
// - file: products.xlsx
// - updateExisting: true
// - skipErrors: false

// Excel структура:
// | Код | Наименование | Тип | Ед.изм | Цена | Себестоимость | НДС % | Категория |
// | PRD001 | Товар 1 | PRODUCT | шт | 10000 | 7000 | 12 | Категория 1 |
// | MAT001 | Материал 1 | MATERIAL | кг | 5000 | 3500 | 12 | Материалы |
```

### Получение продуктов с фильтрацией

```typescript
// GET /workspaces/:workspaceId/products?productType=MANUFACTURED&status=ACTIVE&minPrice=10000&maxPrice=100000&page=1&limit=20&sortBy=price&sortOrder=ASC

// Response:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Стол офисный",
      "code": "FURN-DESK-001",
      "price": 61600, // (25000 + 15000) * 1.2 * 1.4
      "materialCost": 25000,
      "laborCost": 15000,
      "overheadPercent": 20,
      "marginPercent": 40,
      "productType": "MANUFACTURED",
      "status": "ACTIVE",
      "vatRate": 12,
      "vatIncluded": true,
      "category": {
        "id": "furniture-category-id",
        "name": "Мебель"
      },
      "createdAt": "2025-01-15T10:00:00Z",
      "updatedAt": "2025-01-15T10:00:00Z"
    }
  ],
  "meta": {
    "total": 15,
    "page": 1,
    "limit": 20,
    "totalPages": 1,
    "filters": {
      "productType": "MANUFACTURED",
      "status": "ACTIVE",
      "minPrice": 10000,
      "maxPrice": 100000
    }
  }
}
```

## 🔒 Безопасность и права доступа

### Роли и разрешения

```typescript
enum ProductPermissions {
  VIEW_PRODUCTS = 'products.view',
  CREATE_PRODUCT = 'products.create',
  UPDATE_PRODUCT = 'products.update',
  DELETE_PRODUCT = 'products.delete',
  IMPORT_PRODUCTS = 'products.import',
  EXPORT_PRODUCTS = 'products.export',
  MANAGE_CATEGORIES = 'products.categories.manage',
  ADJUST_INVENTORY = 'products.inventory.adjust'
}

// Применение в контроллере
@UseGuards(JwtAuthGuard, WorkspaceGuard, PermissionGuard)
@RequirePermissions(ProductPermissions.CREATE_PRODUCT)
@Post()
async create(@Body() createProductDto: CreateProductDto) {
  // ...
}
```

## 📈 Метрики и аналитика

### Доступные метрики

- Общее количество продуктов по типам
- Топ продаваемых продуктов
- Продукты с низкими остатками
- Средняя маржинальность по категориям
- Оборачиваемость товаров
- ABC-анализ номенклатуры

### Endpoint для метрик

```typescript
// GET /workspaces/:workspaceId/products/metrics

{
  "totalProducts": 1250,
  "byType": {
    "PRODUCT": 800,
    "MATERIAL": 200,
    "SERVICE": 100,
    "MANUFACTURED": 150
  },
  "byStatus": {
    "ACTIVE": 1100,
    "INACTIVE": 100,
    "DISCONTINUED": 50
  },
  "lowStock": 25,
  "averageMargin": 35.5,
  "topCategories": [
    {
      "id": "uuid",
      "name": "Электроника",
      "count": 300,
      "revenue": 150000000
    }
  ]
}
```

## 🔄 Синхронизация и интеграции

### События модуля

```typescript
// Emitted events
- 'product.created' - при создании продукта
- 'product.updated' - при обновлении
- 'product.deleted' - при удалении
- 'product.status.changed' - при изменении статуса
- 'product.stock.low' - при достижении минимального остатка
- 'product.imported' - при массовом импорте

// Listened events
- 'order.created' - для резервирования товаров
- 'production.completed' - для обновления остатков
- 'purchase.received' - для оприходования товаров
```

## 🚨 Обработка ошибок

### Типичные ошибки и их обработка

```typescript
// Дублирование кода продукта
throw new ConflictException('Product with this code already exists');

// Недостаточно остатков
throw new BadRequestException('Insufficient stock for product');

// Нельзя удалить продукт с активными заказами
throw new BadRequestException('Cannot delete product with active orders');

// Неверный тип продукта для операции
throw new BadRequestException('Operation not allowed for this product type');
```

## 📝 Лучшие практики

1. **Всегда используйте уникальные коды** для продуктов
2. **Настройте категории** перед массовым импортом
3. **Используйте batch операции** для массовых изменений
4. **Настройте минимальные остатки** для автоматических закупок
5. **Регулярно архивируйте** неиспользуемые продукты
6. **Используйте партионный учет** для товаров с ограниченным сроком годности
7. **Проверяйте НДС настройки** для правильного налогообложения

---

© 2025 Prometric ERP - Products Module Documentation