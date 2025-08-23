# 📦 Orders Module - Полная техническая документация

## 📌 Обзор модуля

Orders Module - центральный компонент управления заказами в Prometric ERP. Обеспечивает полный цикл обработки заказов от создания до доставки, включая автоматическую интеграцию с производством, складом и логистикой.

## 🏗️ Архитектура модуля

### Основные компоненты

```typescript
OrdersModule
├── Controllers
│   ├── OrdersController (основные операции)
│   └── OrderStatusController (управление статусами)
├── Services
│   ├── OrdersService (бизнес-логика)
│   ├── OrderOrchestrationService (оркестрация)
│   ├── OrderValidationService (валидация)
│   └── OrderFulfillmentService (выполнение)
├── Entities
│   ├── Order (унифицированная сущность)
│   ├── CustomerOrder (заказы продаж)
│   ├── ProductionOrder (производственные заказы)
│   └── DeliveryOrder (заказы доставки)
├── Orchestrators
│   ├── OrderFulfillmentOrchestrator
│   └── DealWonOrchestrator
├── DTOs
│   ├── CreateOrderDto
│   ├── UpdateOrderDto
│   └── OrderQueryDto
└── Interfaces
    └── IOrder (унифицированный интерфейс)
```

## 📊 Entity: Order (Унифицированная)

### Основная сущность

```typescript
@Entity('orders')
@Index(['organizationId', 'workspaceId'])
@Index(['orderNumber'], { unique: true })
@Index(['status'])
@Index(['customerId'])
@Index(['dealId'])
@Index(['createdAt'])
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  organizationId: string;

  @Column()
  workspaceId: string;

  @Column({ unique: true })
  orderNumber: string;

  @Column({ type: 'enum', enum: OrderType, default: OrderType.SALES })
  type: OrderType;

  @Column({ type: 'enum', enum: OrderStatus, default: OrderStatus.PENDING })
  status: OrderStatus;

  @Column({ nullable: true })
  dealId: string;

  @ManyToOne(() => Deal, deal => deal.orders, { 
    nullable: true, 
    lazy: true 
  })
  @JoinColumn({ name: 'dealId' })
  deal: Promise<Deal>;

  @Column()
  customerId: string;

  @ManyToOne(() => Customer, customer => customer.orders, { 
    lazy: true 
  })
  @JoinColumn({ name: 'customerId' })
  customer: Promise<Customer>;

  @Column({ type: 'jsonb' })
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      try {
        return JSON.parse(value);
      } catch {
        return [];
      }
    }
    return value || [];
  })
  items: OrderItem[];

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  subtotal: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  taxAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  discountAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  shippingCost: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  totalAmount: number;

  @Column({ default: 'KZT' })
  currency: string;

  @Column({ type: 'jsonb', nullable: true })
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      try {
        return JSON.parse(value);
      } catch {
        return null;
      }
    }
    return value;
  })
  deliveryAddress: {
    street: string;
    building?: string;
    apartment?: string;
    city: string;
    region?: string;
    postalCode: string;
    country: string;
    contactName?: string;
    contactPhone?: string;
    deliveryInstructions?: string;
  };

  @Column({ type: 'timestamp', nullable: true })
  requestedDeliveryDate: Date;

  @Column({ type: 'timestamp', nullable: true })
  actualDeliveryDate: Date;

  @Column({ nullable: true })
  paymentMethod: string; // 'cash' | 'card' | 'transfer' | 'kaspi'

  @Column({ nullable: true })
  paymentStatus: string; // 'pending' | 'partial' | 'paid' | 'refunded'

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  paidAmount: number;

  @Column({ type: 'timestamp', nullable: true })
  paidAt: Date;

  @Column({ nullable: true })
  invoiceId: string;

  @Column({ nullable: true })
  productionOrderId: string;

  @Column({ nullable: true })
  deliveryOrderId: string;

  @Column({ nullable: true })
  warehouseId: string;

  @Column({ type: 'enum', enum: OrderPriority, default: OrderPriority.NORMAL })
  priority: OrderPriority;

  @Column({ type: 'enum', enum: FulfillmentStatus, default: FulfillmentStatus.PENDING })
  fulfillmentStatus: FulfillmentStatus;

  @Column({ type: 'jsonb', nullable: true })
  fulfillmentDetails: {
    method: 'pickup' | 'delivery' | 'shipping';
    carrier?: string;
    trackingNumber?: string;
    estimatedDays?: number;
    actualDays?: number;
  };

  @Column({ type: 'text', nullable: true })
  notes: string;

  @Column({ type: 'text', nullable: true })
  internalNotes: string;

  @Column({ type: 'jsonb', nullable: true })
  customFields: Record<string, any>;

  @Column({ type: 'jsonb', nullable: true })
  tags: string[];

  @Column({ type: 'jsonb', nullable: true })
  statusHistory: {
    status: OrderStatus;
    changedAt: Date;
    changedBy: string;
    reason?: string;
  }[];

  @Column({ type: 'boolean', default: false })
  isUrgent: boolean;

  @Column({ type: 'boolean', default: false })
  requiresApproval: boolean;

  @Column({ nullable: true })
  approvedBy: string;

  @Column({ type: 'timestamp', nullable: true })
  approvedAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  cancelledAt: Date;

  @Column({ nullable: true })
  cancelledBy: string;

  @Column({ nullable: true })
  cancelReason: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ nullable: true })
  createdBy: string;

  @Column({ nullable: true })
  updatedBy: string;

  // Вычисляемые методы
  @BeforeInsert()
  generateOrderNumber() {
    if (!this.orderNumber) {
      const prefix = this.type === OrderType.SALES ? 'SO' : 'PO';
      this.orderNumber = `${prefix}-${Date.now()}`;
    }
  }

  @BeforeInsert()
  @BeforeUpdate()
  calculateTotals() {
    this.subtotal = this.items.reduce((sum, item) => sum + (item.quantity * item.unitPrice), 0);
    this.taxAmount = this.items.reduce((sum, item) => {
      const itemSubtotal = item.quantity * item.unitPrice;
      return sum + (itemSubtotal * (item.tax || 0) / 100);
    }, 0);
    this.totalAmount = this.subtotal + this.taxAmount - this.discountAmount + this.shippingCost;
  }

  @BeforeUpdate()
  updateStatusHistory() {
    if (this.status) {
      this.statusHistory = [
        ...(this.statusHistory || []),
        {
          status: this.status,
          changedAt: new Date(),
          changedBy: this.updatedBy
        }
      ];
    }
  }
}
```

### Interfaces & Types

```typescript
export interface OrderItem {
  id?: string;
  productId: string;
  productName: string;
  productCode?: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  discount?: number;
  discountType?: 'fixed' | 'percentage';
  tax?: number; // процент НДС
  totalPrice: number;
  cost?: number; // себестоимость
  specifications?: Record<string, any>;
  notes?: string;
}

export enum OrderType {
  SALES = 'SALES',                   // Заказ продаж
  PURCHASE = 'PURCHASE',             // Заказ закупки
  TRANSFER = 'TRANSFER',             // Перемещение между складами
  PRODUCTION = 'PRODUCTION',         // Производственный заказ
  SERVICE = 'SERVICE'                // Сервисный заказ
}

export enum OrderStatus {
  DRAFT = 'DRAFT',                   // Черновик
  PENDING = 'PENDING',               // Ожидает обработки
  CONFIRMED = 'CONFIRMED',           // Подтвержден
  PROCESSING = 'PROCESSING',         // В обработке
  READY = 'READY',                   // Готов к отгрузке
  SHIPPED = 'SHIPPED',               // Отгружен
  DELIVERED = 'DELIVERED',           // Доставлен
  COMPLETED = 'COMPLETED',           // Завершен
  CANCELLED = 'CANCELLED',           // Отменен
  ON_HOLD = 'ON_HOLD'               // На удержании
}

export enum OrderPriority {
  LOW = 'LOW',
  NORMAL = 'NORMAL',
  HIGH = 'HIGH',
  URGENT = 'URGENT',
  CRITICAL = 'CRITICAL'
}

export enum FulfillmentStatus {
  PENDING = 'PENDING',               // Ожидает
  IN_PROGRESS = 'IN_PROGRESS',       // В процессе
  PARTIALLY = 'PARTIALLY',           // Частично выполнен
  FULFILLED = 'FULFILLED',           // Выполнен
  FAILED = 'FAILED'                  // Не выполнен
}
```

## 📊 Entity: CustomerOrder (Sales Orders)

```typescript
@Entity('customer_orders')
@Index(['workspaceId'])
@Index(['orderNumber'], { unique: true })
export class CustomerOrder {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  workspaceId: string;

  @Column()
  organizationId: string;

  @Column({ unique: true })
  orderNumber: string;

  @Column({ type: 'enum', enum: CustomerOrderStatus, default: CustomerOrderStatus.PENDING })
  status: CustomerOrderStatus;

  @Column()
  customerId: string;

  @Column({ nullable: true })
  dealId: string;

  @Column({ nullable: true })
  salesRepId: string; // Менеджер по продажам

  @Column({ type: 'jsonb' })
  items: OrderItem[];

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  totalAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  taxAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  discountAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  shippingCost: number;

  @Column({ type: 'jsonb', nullable: true })
  shippingAddress: any;

  @Column({ type: 'jsonb', nullable: true })
  billingAddress: any;

  @Column({ nullable: true })
  paymentTerms: string; // 'immediate' | 'net30' | 'net60'

  @Column({ type: 'timestamp', nullable: true })
  orderDate: Date;

  @Column({ type: 'timestamp', nullable: true })
  shipDate: Date;

  @Column({ type: 'timestamp', nullable: true })
  deliveryDate: Date;

  @Column({ nullable: true })
  poNumber: string; // Purchase Order номер клиента

  @Column({ type: 'text', nullable: true })
  specialInstructions: string;

  @Column({ type: 'boolean', default: false })
  isRecurring: boolean;

  @Column({ nullable: true })
  recurringSchedule: string; // 'weekly' | 'monthly' | 'quarterly'

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ nullable: true })
  createdBy: string;

  @Column({ nullable: true })
  updatedBy: string;
}

export enum CustomerOrderStatus {
  PENDING = 'pending',
  CONFIRMED = 'confirmed',
  IN_FULFILLMENT = 'in_fulfillment',
  PARTIALLY_SHIPPED = 'partially_shipped',
  SHIPPED = 'shipped',
  DELIVERED = 'delivered',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  REFUNDED = 'refunded'
}
```

## 📊 Entity: ProductionOrder

```typescript
@Entity('production_orders')
@Index(['workspaceId'])
@Index(['orderNumber'], { unique: true })
export class ProductionOrder {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  workspaceId: string;

  @Column()
  organizationId: string;

  @Column({ unique: true })
  orderNumber: string;

  @Column({ type: 'enum', enum: ProductionOrderStatus, default: ProductionOrderStatus.DRAFT })
  status: ProductionOrderStatus;

  @Column({ type: 'enum', enum: OrderSource, default: OrderSource.MANUAL })
  source: OrderSource;

  @Column({ nullable: true })
  dealId: string;

  @Column({ nullable: true })
  salesOrderId: string;

  @Column({ nullable: true })
  customerId: string;

  @Column({ nullable: true })
  customerName: string;

  @Column()
  productId: string;

  @Column()
  productName: string;

  @Column({ type: 'float' })
  quantity: number;

  @Column()
  unitOfMeasure: string;

  @Column({ type: 'timestamp' })
  requestedDate: Date;

  @Column({ type: 'timestamp' })
  dueDate: Date;

  @Column({ type: 'timestamp', nullable: true })
  scheduledStart: Date;

  @Column({ type: 'timestamp', nullable: true })
  scheduledEnd: Date;

  @Column({ type: 'timestamp', nullable: true })
  actualStart: Date;

  @Column({ type: 'timestamp', nullable: true })
  actualEnd: Date;

  @Column({ type: 'enum', enum: OrderPriority, default: OrderPriority.NORMAL })
  priority: OrderPriority;

  @Column({ type: 'float', default: 0 })
  progress: number; // 0-100%

  @Column({ type: 'float', default: 0 })
  completedQuantity: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  estimatedCost: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  actualCost: number;

  @Column({ type: 'jsonb', nullable: true })
  billOfMaterials: {
    materialId: string;
    materialName: string;
    quantity: number;
    unit: string;
    unitCost: number;
  }[];

  @Column({ type: 'jsonb', nullable: true })
  workCenters: {
    workCenterId: string;
    workCenterName: string;
    plannedHours: number;
    actualHours: number;
  }[];

  @Column({ type: 'jsonb', nullable: true })
  qualityChecks: {
    checkpointId: string;
    checkpointName: string;
    status: 'pending' | 'passed' | 'failed';
    checkedAt?: Date;
    checkedBy?: string;
    notes?: string;
  }[];

  @Column({ type: 'text', nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ nullable: true })
  createdBy: string;

  @Column({ nullable: true })
  updatedBy: string;
}

export enum ProductionOrderStatus {
  DRAFT = 'draft',
  PLANNED = 'planned',
  IN_PROGRESS = 'in_progress',
  QUALITY_CHECK = 'quality_check',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  FAILED = 'failed'
}

export enum OrderSource {
  SALES_ORDER = 'sales_order',
  INVENTORY = 'inventory',
  FORECAST = 'forecast',
  DEAL = 'deal',
  MANUAL = 'manual'
}
```

## 📋 DTOs

### CreateOrderDto

```typescript
export class CreateOrderDto {
  @IsEnum(OrderType)
  @IsOptional()
  type?: OrderType;

  @IsUUID()
  customerId: string;

  @IsUUID()
  @IsOptional()
  dealId?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];

  @IsObject()
  @IsOptional()
  deliveryAddress?: {
    street: string;
    building?: string;
    apartment?: string;
    city: string;
    region?: string;
    postalCode: string;
    country: string;
    contactName?: string;
    contactPhone?: string;
    deliveryInstructions?: string;
  };

  @IsDateString()
  @IsOptional()
  requestedDeliveryDate?: string;

  @IsString()
  @IsOptional()
  paymentMethod?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  discountAmount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  shippingCost?: number;

  @IsEnum(OrderPriority)
  @IsOptional()
  priority?: OrderPriority;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsObject()
  @IsOptional()
  customFields?: Record<string, any>;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];

  @IsBoolean()
  @IsOptional()
  isUrgent?: boolean;

  @IsBoolean()
  @IsOptional()
  requiresApproval?: boolean;
}

export class CreateOrderItemDto {
  @IsUUID()
  productId: string;

  @IsString()
  productName: string;

  @IsString()
  @IsOptional()
  productCode?: string;

  @IsNumber()
  @Min(0.01)
  quantity: number;

  @IsString()
  unit: string;

  @IsNumber()
  @Min(0)
  unitPrice: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  discount?: number;

  @IsString()
  @IsIn(['fixed', 'percentage'])
  @IsOptional()
  discountType?: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  tax?: number;

  @IsObject()
  @IsOptional()
  specifications?: Record<string, any>;

  @IsString()
  @IsOptional()
  notes?: string;
}
```

### UpdateOrderDto

```typescript
export class UpdateOrderDto extends PartialType(CreateOrderDto) {
  @IsEnum(OrderStatus)
  @IsOptional()
  status?: OrderStatus;

  @IsString()
  @IsOptional()
  paymentStatus?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  paidAmount?: number;

  @IsDateString()
  @IsOptional()
  paidAt?: string;

  @IsDateString()
  @IsOptional()
  actualDeliveryDate?: string;

  @IsString()
  @IsOptional()
  internalNotes?: string;
}
```

### OrderQueryDto

```typescript
export class OrderQueryDto extends PaginationDto {
  @IsEnum(OrderType)
  @IsOptional()
  type?: OrderType;

  @IsEnum(OrderStatus)
  @IsOptional()
  status?: OrderStatus;

  @IsArray()
  @IsEnum(OrderStatus, { each: true })
  @IsOptional()
  statuses?: OrderStatus[];

  @IsUUID()
  @IsOptional()
  customerId?: string;

  @IsUUID()
  @IsOptional()
  dealId?: string;

  @IsString()
  @IsOptional()
  orderNumber?: string;

  @IsString()
  @IsOptional()
  search?: string; // поиск по orderNumber, customer name

  @IsEnum(OrderPriority)
  @IsOptional()
  priority?: OrderPriority;

  @IsEnum(FulfillmentStatus)
  @IsOptional()
  fulfillmentStatus?: FulfillmentStatus;

  @IsString()
  @IsOptional()
  paymentStatus?: string;

  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => value === 'true')
  isUrgent?: boolean;

  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => value === 'true')
  requiresApproval?: boolean;

  @IsDateString()
  @IsOptional()
  createdFrom?: string;

  @IsDateString()
  @IsOptional()
  createdTo?: string;

  @IsDateString()
  @IsOptional()
  deliveryDateFrom?: string;

  @IsDateString()
  @IsOptional()
  deliveryDateTo?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Transform(({ value }) => Number(value))
  minAmount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Transform(({ value }) => Number(value))
  maxAmount?: number;

  @IsString()
  @IsOptional()
  @IsIn(['createdAt', 'updatedAt', 'orderNumber', 'totalAmount', 'status', 'priority'])
  sortBy?: string;

  @IsString()
  @IsOptional()
  @IsIn(['ASC', 'DESC'])
  sortOrder?: 'ASC' | 'DESC';
}
```

## 🔌 API Endpoints

### Основные endpoints

```typescript
@Controller('api/v1/workspaces/:workspaceId/orders')
@UseGuards(JwtAuthGuard, WorkspaceGuard)
export class OrdersController {
  
  // Получить список заказов
  @Get()
  @RequirePermissions(Permission.ORDERS_VIEW)
  async findAll(
    @Param('workspaceId') workspaceId: string,
    @Query() query: OrderQueryDto
  ): Promise<PaginatedResponse<Order>>

  // Получить заказ по ID
  @Get(':id')
  @RequirePermissions(Permission.ORDERS_VIEW)
  async findOne(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string
  ): Promise<Order>

  // Создать заказ
  @Post()
  @RequirePermissions(Permission.ORDERS_CREATE)
  async create(
    @Param('workspaceId') workspaceId: string,
    @Body() dto: CreateOrderDto,
    @CurrentUser() user: User
  ): Promise<Order>

  // Обновить заказ
  @Put(':id')
  @RequirePermissions(Permission.ORDERS_UPDATE)
  async update(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string,
    @Body() dto: UpdateOrderDto,
    @CurrentUser() user: User
  ): Promise<Order>

  // Удалить заказ
  @Delete(':id')
  @RequirePermissions(Permission.ORDERS_DELETE)
  async remove(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string
  ): Promise<void>

  // Изменить статус заказа
  @Patch(':id/status')
  @RequirePermissions(Permission.ORDERS_UPDATE)
  async changeStatus(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string,
    @Body() dto: ChangeStatusDto,
    @CurrentUser() user: User
  ): Promise<Order>

  // Утвердить заказ
  @Post(':id/approve')
  @RequirePermissions(Permission.ORDERS_APPROVE)
  async approve(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string,
    @CurrentUser() user: User
  ): Promise<Order>

  // Отменить заказ
  @Post(':id/cancel')
  @RequirePermissions(Permission.ORDERS_UPDATE)
  async cancel(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string,
    @Body() dto: CancelOrderDto,
    @CurrentUser() user: User
  ): Promise<Order>

  // Клонировать заказ
  @Post(':id/clone')
  @RequirePermissions(Permission.ORDERS_CREATE)
  async clone(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string,
    @Body() dto: CloneOrderDto
  ): Promise<Order>
}
```

### Fulfillment endpoints

```typescript
// Начать выполнение заказа
@Post(':id/fulfill')
async startFulfillment(
  @Param('id') id: string,
  @Body() dto: StartFulfillmentDto
): Promise<Order>

// Обновить статус выполнения
@Patch(':id/fulfillment')
async updateFulfillment(
  @Param('id') id: string,
  @Body() dto: UpdateFulfillmentDto
): Promise<Order>

// Отметить как отгруженный
@Post(':id/ship')
async markAsShipped(
  @Param('id') id: string,
  @Body() dto: ShipOrderDto
): Promise<Order>

// Отметить как доставленный
@Post(':id/deliver')
async markAsDelivered(
  @Param('id') id: string,
  @Body() dto: DeliverOrderDto
): Promise<Order>

// Получить статус отслеживания
@Get(':id/tracking')
async getTrackingInfo(
  @Param('id') id: string
): Promise<TrackingInfo>
```

### Payment endpoints

```typescript
// Зарегистрировать платеж
@Post(':id/payments')
async recordPayment(
  @Param('id') id: string,
  @Body() dto: RecordPaymentDto
): Promise<Payment>

// Получить историю платежей
@Get(':id/payments')
async getPayments(
  @Param('id') id: string
): Promise<Payment[]>

// Вернуть платеж
@Post(':id/refund')
async refund(
  @Param('id') id: string,
  @Body() dto: RefundDto
): Promise<Refund>
```

### Analytics endpoints

```typescript
// Статистика заказов
@Get('statistics')
async getStatistics(
  @Param('workspaceId') workspaceId: string,
  @Query() query: StatisticsQueryDto
): Promise<OrderStatistics>

// Отчет по выполнению
@Get('fulfillment-report')
async getFulfillmentReport(
  @Param('workspaceId') workspaceId: string,
  @Query() query: ReportQueryDto
): Promise<FulfillmentReport>

// Анализ доходности
@Get('profitability')
async getProfitabilityAnalysis(
  @Param('workspaceId') workspaceId: string,
  @Query() query: ProfitabilityQueryDto
): Promise<ProfitabilityAnalysis>
```

## 💼 Service Layer

### OrdersService

```typescript
@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
    private orderOrchestrationService: OrderOrchestrationService,
    private inventoryService: InventoryService,
    private eventEmitter: EventEmitter2,
    private notificationService: NotificationService
  ) {}

  async create(dto: CreateOrderDto, userId: string): Promise<Order> {
    const queryRunner = this.connection.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Валидация наличия товаров
      await this.validateInventory(dto.items);

      // Создаем заказ
      const order = this.orderRepository.create({
        ...dto,
        type: dto.type || OrderType.SALES,
        status: OrderStatus.PENDING,
        fulfillmentStatus: FulfillmentStatus.PENDING,
        statusHistory: [{
          status: OrderStatus.PENDING,
          changedAt: new Date(),
          changedBy: userId
        }],
        createdBy: userId,
        updatedBy: userId
      });

      // Генерируем номер и считаем суммы
      order.generateOrderNumber();
      order.calculateTotals();

      const savedOrder = await queryRunner.manager.save(order);

      // Резервируем товары на складе
      for (const item of dto.items) {
        await this.inventoryService.reserve({
          productId: item.productId,
          quantity: item.quantity,
          orderId: savedOrder.id,
          warehouseId: savedOrder.warehouseId
        });
      }

      await queryRunner.commitTransaction();

      // Эмитируем событие создания заказа
      this.eventEmitter.emit('order.created', {
        orderId: savedOrder.id,
        customerId: savedOrder.customerId,
        dealId: savedOrder.dealId,
        items: savedOrder.items,
        totalAmount: savedOrder.totalAmount,
        workspaceId: savedOrder.workspaceId,
        organizationId: savedOrder.organizationId,
        createdBy: userId
      });

      // Уведомление если требуется утверждение
      if (savedOrder.requiresApproval) {
        await this.notificationService.notifyApprovers({
          orderId: savedOrder.id,
          orderNumber: savedOrder.orderNumber,
          totalAmount: savedOrder.totalAmount,
          customerId: savedOrder.customerId
        });
      }

      return savedOrder;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  async changeStatus(
    orderId: string,
    newStatus: OrderStatus,
    userId: string,
    reason?: string
  ): Promise<Order> {
    const order = await this.orderRepository.findOne({
      where: { id: orderId }
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    const previousStatus = order.status;

    // Валидация перехода статусов
    this.validateStatusTransition(previousStatus, newStatus);

    // Обновляем статус
    order.status = newStatus;
    order.updatedBy = userId;
    order.updateStatusHistory();

    // Специальная обработка для разных статусов
    switch (newStatus) {
      case OrderStatus.CONFIRMED:
        await this.handleOrderConfirmed(order);
        break;
      
      case OrderStatus.PROCESSING:
        await this.handleOrderProcessing(order);
        break;
      
      case OrderStatus.SHIPPED:
        await this.handleOrderShipped(order);
        break;
      
      case OrderStatus.DELIVERED:
        await this.handleOrderDelivered(order);
        break;
      
      case OrderStatus.CANCELLED:
        await this.handleOrderCancelled(order, reason);
        break;
    }

    const updatedOrder = await this.orderRepository.save(order);

    // Эмитируем событие изменения статуса
    this.eventEmitter.emit('order.status.changed', {
      orderId: order.id,
      previousStatus,
      newStatus,
      changedBy: userId,
      reason
    });

    return updatedOrder;
  }

  private async handleOrderConfirmed(order: Order): Promise<void> {
    // Подтверждаем резервирование на складе
    await this.inventoryService.confirmReservation(order.id);

    // Создаем задачи для выполнения
    this.eventEmitter.emit('tasks.create', {
      type: 'ORDER_FULFILLMENT',
      orderId: order.id,
      assignedTo: order.warehouseId,
      priority: order.priority
    });
  }

  private async handleOrderProcessing(order: Order): Promise<void> {
    // Начинаем процесс сборки
    order.fulfillmentStatus = FulfillmentStatus.IN_PROGRESS;

    // Создаем PickingList для склада
    this.eventEmitter.emit('warehouse.picking.create', {
      orderId: order.id,
      items: order.items,
      warehouseId: order.warehouseId,
      priority: order.priority
    });
  }

  private async handleOrderShipped(order: Order): Promise<void> {
    // Списываем товары со склада
    for (const item of order.items) {
      await this.inventoryService.deduct({
        productId: item.productId,
        quantity: item.quantity,
        warehouseId: order.warehouseId,
        reason: 'ORDER_SHIPPED',
        referenceId: order.id
      });
    }

    // Отправляем уведомление клиенту
    this.eventEmitter.emit('notification.customer', {
      customerId: order.customerId,
      type: 'ORDER_SHIPPED',
      data: {
        orderNumber: order.orderNumber,
        trackingNumber: order.fulfillmentDetails?.trackingNumber
      }
    });
  }

  private async handleOrderDelivered(order: Order): Promise<void> {
    order.actualDeliveryDate = new Date();
    order.fulfillmentStatus = FulfillmentStatus.FULFILLED;
    order.status = OrderStatus.COMPLETED;

    // Обновляем метрики клиента
    this.eventEmitter.emit('customer.purchase.completed', {
      customerId: order.customerId,
      orderAmount: order.totalAmount,
      orderDate: order.createdAt
    });

    // Запрашиваем отзыв
    this.eventEmitter.emit('feedback.request', {
      customerId: order.customerId,
      orderId: order.id,
      orderNumber: order.orderNumber
    });
  }

  private async handleOrderCancelled(order: Order, reason?: string): Promise<void> {
    order.cancelledAt = new Date();
    order.cancelledBy = order.updatedBy;
    order.cancelReason = reason;

    // Отменяем резервирование на складе
    await this.inventoryService.cancelReservation(order.id);

    // Возвращаем платежи если были
    if (order.paidAmount > 0) {
      this.eventEmitter.emit('payment.refund', {
        orderId: order.id,
        amount: order.paidAmount,
        reason: 'ORDER_CANCELLED'
      });
    }
  }

  private validateStatusTransition(from: OrderStatus, to: OrderStatus): void {
    const validTransitions: Record<OrderStatus, OrderStatus[]> = {
      [OrderStatus.DRAFT]: [OrderStatus.PENDING, OrderStatus.CANCELLED],
      [OrderStatus.PENDING]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED, OrderStatus.ON_HOLD],
      [OrderStatus.CONFIRMED]: [OrderStatus.PROCESSING, OrderStatus.CANCELLED],
      [OrderStatus.PROCESSING]: [OrderStatus.READY, OrderStatus.CANCELLED, OrderStatus.ON_HOLD],
      [OrderStatus.READY]: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
      [OrderStatus.SHIPPED]: [OrderStatus.DELIVERED, OrderStatus.CANCELLED],
      [OrderStatus.DELIVERED]: [OrderStatus.COMPLETED],
      [OrderStatus.COMPLETED]: [],
      [OrderStatus.CANCELLED]: [],
      [OrderStatus.ON_HOLD]: [OrderStatus.PENDING, OrderStatus.PROCESSING, OrderStatus.CANCELLED]
    };

    const allowedTransitions = validTransitions[from] || [];
    
    if (!allowedTransitions.includes(to)) {
      throw new BadRequestException(
        `Invalid status transition from ${from} to ${to}`
      );
    }
  }

  private async validateInventory(items: OrderItem[]): Promise<void> {
    for (const item of items) {
      const available = await this.inventoryService.checkAvailability(
        item.productId,
        item.quantity
      );

      if (!available) {
        throw new BadRequestException(
          `Insufficient inventory for product ${item.productName}`
        );
      }
    }
  }
}
```

## 🎯 Order Fulfillment Orchestrator

```typescript
@Injectable()
export class OrderFulfillmentOrchestrator {
  private readonly logger = new Logger(OrderFulfillmentOrchestrator.name);

  constructor(
    private dataSource: DataSource,
    private ordersService: OrdersService,
    private productionOrderService: ProductionOrderService,
    private deliveryOrdersService: DeliveryOrdersService,
    private inventoryService: InventoryService,
    private eventEmitter: EventEmitter2
  ) {}

  @OnEvent('order.created')
  async handleOrderCreated(event: any) {
    this.logger.log(`Processing order: ${event.orderId}`);
    
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const order = await this.ordersService.findOne(event.orderId);

      // Проверяем доступность товаров
      const inventoryCheck = await this.checkInventoryAvailability(
        order.items,
        order.workspaceId
      );

      if (inventoryCheck.allAvailable) {
        // Создаем PickingOrder для сборки со склада
        await this.createPickingOrder(order, queryRunner);
      } else {
        // Создаем ProductionOrder для производства
        const productionOrder = await this.createProductionOrder(
          order,
          inventoryCheck.unavailableItems,
          queryRunner
        );

        // Эмитируем событие для производства
        this.eventEmitter.emit('production.order.created', {
          productionOrderId: productionOrder.id,
          orderId: order.id,
          items: inventoryCheck.unavailableItems
        });
      }

      // Создаем DeliveryOrder для доставки
      const deliveryOrder = await this.createDeliveryOrder(order, queryRunner);

      // Обновляем статус заказа
      order.status = OrderStatus.PROCESSING;
      order.productionOrderId = productionOrder?.id;
      order.deliveryOrderId = deliveryOrder.id;
      
      await queryRunner.manager.save(order);
      await queryRunner.commitTransaction();

      // Эмитируем событие начала выполнения
      this.eventEmitter.emit('order.fulfillment.started', {
        orderId: order.id,
        hasProduction: !inventoryCheck.allAvailable,
        deliveryOrderId: deliveryOrder.id
      });

    } catch (error) {
      await queryRunner.rollbackTransaction();
      this.logger.error(`Failed to process order: ${error.message}`);
      
      this.eventEmitter.emit('order.fulfillment.failed', {
        orderId: event.orderId,
        error: error.message
      });
      
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  private async checkInventoryAvailability(
    items: OrderItem[],
    workspaceId: string
  ): Promise<{ allAvailable: boolean; unavailableItems: OrderItem[] }> {
    const unavailableItems = [];

    for (const item of items) {
      const inventoryItems = await this.inventoryService.getProductInventory(
        item.productId
      );

      const totalAvailable = inventoryItems.reduce(
        (sum, inv) => sum + (inv.quantity || 0),
        0
      );

      if (totalAvailable < item.quantity) {
        unavailableItems.push(item);
      }
    }

    return {
      allAvailable: unavailableItems.length === 0,
      unavailableItems
    };
  }

  private async createProductionOrder(
    order: Order,
    itemsToProduce: OrderItem[],
    queryRunner: any
  ): Promise<ProductionOrder> {
    const productionOrderData = {
      orderNumber: `PO-${Date.now()}`,
      source: OrderSource.SALES_ORDER,
      salesOrderId: order.id,
      dealId: order.dealId,
      customerId: order.customerId,
      status: ProductionOrderStatus.PLANNED,
      priority: order.priority,
      items: itemsToProduce,
      dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      organizationId: order.organizationId,
      workspaceId: order.workspaceId,
      createdBy: order.createdBy
    };

    const productionOrder = queryRunner.manager.create(
      ProductionOrder,
      productionOrderData
    );
    
    return queryRunner.manager.save(productionOrder);
  }

  private async createDeliveryOrder(
    order: Order,
    queryRunner: any
  ): Promise<DeliveryOrder> {
    const deliveryOrderData = {
      deliveryOrderNumber: `DO-${Date.now()}`,
      sourceOrderId: order.id,
      sourceOrderType: 'sales_order',
      customerId: order.customerId,
      deliveryAddress: order.deliveryAddress,
      scheduledDate: order.requestedDeliveryDate || 
        new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
      items: order.items,
      priority: order.priority,
      organizationId: order.organizationId,
      workspaceId: order.workspaceId,
      createdBy: order.createdBy
    };

    const deliveryOrder = queryRunner.manager.create(
      DeliveryOrder,
      deliveryOrderData
    );
    
    return queryRunner.manager.save(deliveryOrder);
  }

  @OnEvent('production.order.completed')
  async handleProductionCompleted(event: any) {
    // Обновляем статус основного заказа
    const order = await this.ordersService.findOne(event.salesOrderId);
    
    if (order) {
      await this.ordersService.changeStatus(
        order.id,
        OrderStatus.READY,
        'system',
        'Production completed'
      );

      // Инициируем доставку
      this.eventEmitter.emit('delivery.initiate', {
        orderId: order.id,
        deliveryOrderId: order.deliveryOrderId
      });
    }
  }

  @OnEvent('delivery.completed')
  async handleDeliveryCompleted(event: any) {
    // Завершаем заказ
    const order = await this.ordersService.findOne(event.orderId);
    
    if (order) {
      await this.ordersService.changeStatus(
        order.id,
        OrderStatus.DELIVERED,
        'system',
        'Delivery completed'
      );
    }
  }
}
```

## 🎯 Events

### Эмитируемые события

```typescript
// Создание заказа
'order.created': {
  orderId: string;
  customerId: string;
  dealId?: string;
  items: OrderItem[];
  totalAmount: number;
  workspaceId: string;
  organizationId: string;
  createdBy: string;
}

// Изменение статуса
'order.status.changed': {
  orderId: string;
  previousStatus: OrderStatus;
  newStatus: OrderStatus;
  changedBy: string;
  reason?: string;
}

// Начало выполнения
'order.fulfillment.started': {
  orderId: string;
  hasProduction: boolean;
  deliveryOrderId: string;
}

// Завершение выполнения
'order.fulfillment.completed': {
  orderId: string;
  completedAt: Date;
}

// Отмена заказа
'order.cancelled': {
  orderId: string;
  cancelledBy: string;
  reason: string;
}

// Отгрузка заказа
'order.shipped': {
  orderId: string;
  trackingNumber?: string;
  carrier?: string;
}

// Доставка заказа
'order.delivered': {
  orderId: string;
  deliveredAt: Date;
  signature?: string;
}

// Платеж получен
'order.payment.received': {
  orderId: string;
  amount: number;
  paymentMethod: string;
}

// Возврат платежа
'order.refunded': {
  orderId: string;
  refundAmount: number;
  reason: string;
}
```

### Обрабатываемые события

```typescript
@OnEvent('deal.won')
async handleDealWon(event: DealWonEvent) {
  // Создаем заказ из выигранной сделки
}

@OnEvent('inventory.low')
async handleLowInventory(event: InventoryLowEvent) {
  // Приостанавливаем заказы с этим товаром
}

@OnEvent('production.order.completed')
async handleProductionCompleted(event: ProductionCompletedEvent) {
  // Обновляем статус связанного заказа
}

@OnEvent('delivery.completed')
async handleDeliveryCompleted(event: DeliveryCompletedEvent) {
  // Завершаем заказ
}
```

## 📊 Аналитика и отчеты

### Order Statistics

```typescript
interface OrderStatistics {
  // Общая статистика
  totalOrders: number;
  totalRevenue: number;
  averageOrderValue: number;
  
  // По статусам
  byStatus: {
    status: OrderStatus;
    count: number;
    value: number;
    percentage: number;
  }[];
  
  // По типам
  byType: {
    type: OrderType;
    count: number;
    value: number;
  }[];
  
  // По периодам
  byPeriod: {
    period: string;
    orders: number;
    revenue: number;
    growth: number;
  }[];
  
  // Топ клиенты
  topCustomers: {
    customerId: string;
    customerName: string;
    orderCount: number;
    totalValue: number;
  }[];
  
  // Топ продукты
  topProducts: {
    productId: string;
    productName: string;
    quantity: number;
    revenue: number;
  }[];
}
```

### Fulfillment Report

```typescript
interface FulfillmentReport {
  // Метрики выполнения
  averageFulfillmentTime: number; // часов
  onTimeDeliveryRate: number; // %
  cancellationRate: number; // %
  returnRate: number; // %
  
  // По складам
  byWarehouse: {
    warehouseId: string;
    warehouseName: string;
    ordersProcessed: number;
    averageTime: number;
    efficiency: number;
  }[];
  
  // По перевозчикам
  byCarrier: {
    carrier: string;
    deliveries: number;
    onTimeRate: number;
    damageRate: number;
  }[];
  
  // Проблемные заказы
  problematicOrders: {
    orderId: string;
    orderNumber: string;
    issue: string;
    daysDelayed: number;
  }[];
}
```

## 🔄 Интеграция с другими модулями

### Production Module
- Автоматическое создание Production Orders
- Отслеживание статуса производства
- Обновление при завершении

### Inventory Module
- Проверка наличия товаров
- Резервирование под заказ
- Списание при отгрузке

### Logistics Module
- Создание Delivery Orders
- Управление доставкой
- Отслеживание груза

### Finance Module
- Создание счетов
- Обработка платежей
- Возвраты и кредиты

## 🎨 Примеры использования

### Создание заказа из сделки

```typescript
const order = await ordersService.createFromDeal(dealId, {
  deliveryAddress: {
    street: 'ул. Абая, 150',
    city: 'Алматы',
    postalCode: '050000',
    country: 'Kazakhstan',
    contactName: 'Асет Жумабеков',
    contactPhone: '+77012345678'
  },
  requestedDeliveryDate: '2024-02-15',
  paymentMethod: 'transfer',
  priority: OrderPriority.HIGH,
  notes: 'Срочная доставка, звонить за час'
}, userId);
```

### Массовая обработка заказов

```typescript
// Подтвердить несколько заказов
await ordersService.bulkChangeStatus(
  orderIds,
  OrderStatus.CONFIRMED,
  userId
);

// Создать отгрузку для готовых заказов
const readyOrders = await ordersService.findAll(workspaceId, {
  status: OrderStatus.READY,
  warehouseId: 'warehouse-1'
});

await ordersService.createBulkShipment({
  orderIds: readyOrders.items.map(o => o.id),
  carrier: 'DHL',
  scheduledDate: '2024-02-10'
});
```

## 🚀 Оптимизация производительности

### Индексы
- Уникальный индекс по orderNumber
- Составной индекс (organizationId, workspaceId)
- Индекс по status для фильтрации
- Индекс по customerId для связей
- Индекс по dealId для связей
- Индекс по createdAt для сортировки

### Кеширование
- Кеш активных заказов (TTL: 1 минута)
- Кеш статистики (TTL: 5 минут)
- Кеш отчетов (TTL: 10 минут)

### Batch Processing
- Массовое создание до 50 заказов
- Массовое обновление статусов
- Массовая отгрузка

---

© 2025 Prometric ERP. Orders Module Documentation.