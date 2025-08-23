# 💼 Deals Module - Полная техническая документация

## 📌 Обзор модуля

Модуль Deals управляет полным циклом продаж от первого контакта до закрытия сделки. Включает pipeline management, прогнозирование, автоматизацию процессов и интеграцию с производством при выигрыше сделки.

## 🏗️ Архитектура модуля

### Основные компоненты

```typescript
DealsModule
├── Controllers
│   ├── DealsController (основные операции)
│   └── DealActivitiesController (активности)
├── Services
│   ├── DealsService (бизнес-логика)
│   ├── DealPipelineService (управление воронкой)
│   ├── DealForecastingService (прогнозирование)
│   └── DealAutomationService (автоматизация)
├── Entities
│   ├── Deal (основная сущность)
│   ├── DealProduct (продукты в сделке)
│   ├── DealActivity (активности)
│   └── DealAttachment (вложения)
├── DTOs
│   ├── CreateDealDto
│   ├── UpdateDealDto
│   ├── ChangeDealStageDto
│   └── DealQueryDto
├── Orchestrators
│   └── DealWonOrchestrator (обработка выигранных сделок)
└── Events
    ├── DealCreatedEvent
    ├── DealWonEvent
    └── DealLostEvent
```

## 📊 Entity: Deal

### Основная сущность

```typescript
@Entity('deals')
@Index(['organizationId', 'workspaceId'])
@Index(['stage'])
@Index(['customerId'])
@Index(['assignedTo'])
@Index(['expectedCloseDate'])
export class Deal {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  organizationId: string;

  @Column()
  workspaceId: string;

  @Column()
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'enum', enum: DealStage, default: DealStage.LEAD })
  stage: DealStage;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  value: number;

  @Column({ default: 'KZT' })
  currency: string;

  @Column({ type: 'int', default: 10 })
  probability: number; // 0-100%

  @Column({ type: 'timestamp', nullable: true })
  expectedCloseDate: Date;

  @Column({ type: 'timestamp', nullable: true })
  actualCloseDate: Date;

  @Column({ nullable: true })
  customerId: string;

  @ManyToOne(() => Customer, customer => customer.deals, { 
    nullable: true, 
    lazy: true 
  })
  @JoinColumn({ name: 'customerId' })
  customer: Promise<Customer>;

  @Column({ nullable: true })
  contactPersonId: string;

  @Column({ nullable: true })
  assignedTo: string; // ID сотрудника

  @Column({ nullable: true })
  leadSource: string;

  @Column({ nullable: true })
  campaignId: string;

  @Column({ type: 'enum', enum: DealPriority, default: DealPriority.MEDIUM })
  priority: DealPriority;

  @Column({ nullable: true })
  lostReason: string;

  @Column({ nullable: true })
  competitorInfo: string;

  @Column({ type: 'timestamp', nullable: true })
  wonAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  lostAt: Date;

  @Column({ type: 'int', default: 0 })
  daysInStage: number;

  @Column({ type: 'int', default: 0 })
  totalDaysInPipeline: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  commission: number;

  @Column({ nullable: true })
  commissionType: string; // 'fixed' | 'percentage'

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  discount: number;

  @Column({ nullable: true })
  discountType: string; // 'fixed' | 'percentage'

  @Column({ type: 'jsonb', nullable: true })
  customFields: Record<string, any>;

  @Column({ type: 'jsonb', nullable: true })
  tags: string[];

  @Column({ type: 'jsonb', nullable: true })
  stageHistory: {
    stage: DealStage;
    enteredAt: Date;
    leftAt?: Date;
    duration?: number;
    changedBy: string;
  }[];

  @Column({ type: 'boolean', default: false })
  isRecurring: boolean;

  @Column({ nullable: true })
  recurringInterval: string; // 'monthly' | 'quarterly' | 'yearly'

  @Column({ type: 'decimal', precision: 12, scale: 2, nullable: true })
  @Transform(value => value ? parseFloat(value) : null)
  recurringValue: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  expectedRevenue: number; // value * probability / 100

  // Связи
  @OneToMany(() => DealProduct, product => product.deal, { 
    cascade: true, 
    eager: true 
  })
  products: DealProduct[];

  @OneToMany(() => DealActivity, activity => activity.deal, { 
    lazy: true 
  })
  activities: Promise<DealActivity[]>;

  @OneToMany(() => DealAttachment, attachment => attachment.deal, { 
    lazy: true 
  })
  attachments: Promise<DealAttachment[]>;

  @OneToMany(() => Order, order => order.deal, { 
    lazy: true 
  })
  orders: Promise<Order[]>;

  @OneToMany(() => Invoice, invoice => invoice.deal, { 
    lazy: true 
  })
  invoices: Promise<Invoice[]>;

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
  @BeforeUpdate()
  calculateExpectedRevenue() {
    this.expectedRevenue = (this.value * this.probability) / 100;
  }

  @BeforeUpdate()
  updateDaysInStage() {
    if (this.stageHistory && this.stageHistory.length > 0) {
      const currentStage = this.stageHistory[this.stageHistory.length - 1];
      const days = Math.floor(
        (Date.now() - new Date(currentStage.enteredAt).getTime()) / 
        (1000 * 60 * 60 * 24)
      );
      this.daysInStage = days;
    }
  }
}
```

### Enums

```typescript
export enum DealStage {
  LEAD = 'LEAD',                    // Первичный контакт
  QUALIFIED = 'QUALIFIED',          // Квалифицированный лид
  PROPOSAL = 'PROPOSAL',            // Отправлено предложение
  NEGOTIATION = 'NEGOTIATION',      // Переговоры
  CLOSING = 'CLOSING',              // Финальная стадия
  WON = 'WON',                      // Выиграна
  LOST = 'LOST'                     // Проиграна
}

export enum DealPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  URGENT = 'URGENT'
}

export enum ActivityType {
  CALL = 'CALL',
  EMAIL = 'EMAIL',
  MEETING = 'MEETING',
  TASK = 'TASK',
  NOTE = 'NOTE',
  PROPOSAL_SENT = 'PROPOSAL_SENT',
  CONTRACT_SENT = 'CONTRACT_SENT',
  DEMO = 'DEMO'
}
```

## 📊 Entity: DealProduct

```typescript
@Entity('deal_products')
@Index(['dealId'])
export class DealProduct {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  dealId: string;

  @ManyToOne(() => Deal, deal => deal.products, { 
    onDelete: 'CASCADE' 
  })
  @JoinColumn({ name: 'dealId' })
  deal: Deal;

  @Column()
  productId: string;

  @Column()
  productName: string;

  @Column({ nullable: true })
  productCode: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  @Transform(value => parseFloat(value))
  quantity: number;

  @Column()
  unit: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  @Transform(value => parseFloat(value))
  unitPrice: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  discount: number;

  @Column({ nullable: true })
  discountType: string; // 'fixed' | 'percentage'

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  @Transform(value => parseFloat(value))
  tax: number; // процент НДС

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  @Transform(value => parseFloat(value))
  totalPrice: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  @Transform(value => value ? parseFloat(value) : null)
  cost: number; // себестоимость для расчета маржи

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  @Transform(value => value ? parseFloat(value) : null)
  margin: number; // маржа в процентах

  @Column({ type: 'text', nullable: true })
  notes: string;

  @Column({ type: 'jsonb', nullable: true })
  specifications: Record<string, any>;

  @Column({ type: 'int', default: 0 })
  sortOrder: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  // Вычисляемые методы
  @BeforeInsert()
  @BeforeUpdate()
  calculateTotalPrice() {
    let subtotal = this.quantity * this.unitPrice;
    
    if (this.discount > 0) {
      if (this.discountType === 'percentage') {
        subtotal -= (subtotal * this.discount / 100);
      } else {
        subtotal -= this.discount;
      }
    }
    
    const taxAmount = subtotal * (this.tax / 100);
    this.totalPrice = subtotal + taxAmount;
  }

  @BeforeInsert()
  @BeforeUpdate()
  calculateMargin() {
    if (this.cost && this.cost > 0) {
      const profit = this.unitPrice - this.cost;
      this.margin = (profit / this.unitPrice) * 100;
    }
  }
}
```

## 📊 Entity: DealActivity

```typescript
@Entity('deal_activities')
@Index(['dealId'])
@Index(['type'])
@Index(['scheduledAt'])
export class DealActivity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  dealId: string;

  @ManyToOne(() => Deal, deal => deal.activities, { 
    onDelete: 'CASCADE' 
  })
  @JoinColumn({ name: 'dealId' })
  deal: Deal;

  @Column({ type: 'enum', enum: ActivityType })
  type: ActivityType;

  @Column()
  subject: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'timestamp', nullable: true })
  scheduledAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date;

  @Column({ type: 'int', nullable: true })
  duration: number; // в минутах

  @Column({ nullable: true })
  outcome: string;

  @Column({ nullable: true })
  nextAction: string;

  @Column({ nullable: true })
  contactPersonId: string;

  @Column({ nullable: true })
  assignedTo: string;

  @Column({ type: 'jsonb', nullable: true })
  participants: {
    userId: string;
    name: string;
    role: string;
  }[];

  @Column({ type: 'jsonb', nullable: true })
  location: {
    type: 'online' | 'office' | 'client_site' | 'other';
    address?: string;
    meetingLink?: string;
  };

  @Column({ type: 'jsonb', nullable: true })
  attachments: {
    fileName: string;
    fileUrl: string;
    fileSize: number;
    mimeType: string;
  }[];

  @Column({ type: 'boolean', default: false })
  isCompleted: boolean;

  @Column({ type: 'boolean', default: false })
  isCancelled: boolean;

  @Column({ nullable: true })
  cancelReason: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @Column({ nullable: true })
  createdBy: string;

  @Column({ nullable: true })
  completedBy: string;
}
```

## 📋 DTOs

### CreateDealDto

```typescript
export class CreateDealDto {
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  title: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsEnum(DealStage)
  @IsOptional()
  stage?: DealStage;

  @IsNumber()
  @Min(0)
  value: number;

  @IsString()
  @IsOptional()
  currency?: string;

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  probability?: number;

  @IsDateString()
  @IsOptional()
  expectedCloseDate?: string;

  @IsUUID()
  customerId: string;

  @IsUUID()
  @IsOptional()
  contactPersonId?: string;

  @IsUUID()
  @IsOptional()
  assignedTo?: string;

  @IsString()
  @IsOptional()
  leadSource?: string;

  @IsEnum(DealPriority)
  @IsOptional()
  priority?: DealPriority;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateDealProductDto)
  @IsOptional()
  products?: CreateDealProductDto[];

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
  @IsOptional()
  commission?: number;

  @IsString()
  @IsIn(['fixed', 'percentage'])
  @IsOptional()
  commissionType?: string;

  @IsBoolean()
  @IsOptional()
  isRecurring?: boolean;

  @IsString()
  @IsIn(['monthly', 'quarterly', 'yearly'])
  @IsOptional()
  recurringInterval?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  recurringValue?: number;

  @IsObject()
  @IsOptional()
  customFields?: Record<string, any>;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];
}
```

### UpdateDealDto

```typescript
export class UpdateDealDto extends PartialType(CreateDealDto) {
  @IsEnum(DealStage)
  @IsOptional()
  stage?: DealStage;

  @IsDateString()
  @IsOptional()
  actualCloseDate?: string;

  @IsString()
  @IsOptional()
  lostReason?: string;

  @IsString()
  @IsOptional()
  competitorInfo?: string;
}
```

### ChangeDealStageDto

```typescript
export class ChangeDealStageDto {
  @IsEnum(DealStage)
  stage: DealStage;

  @IsString()
  @IsOptional()
  reason?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsString()
  @IsOptional()
  lostReason?: string; // Обязательно для LOST

  @IsString()
  @IsOptional()
  competitorInfo?: string; // Для LOST

  @IsNumber()
  @Min(0)
  @Max(100)
  @IsOptional()
  probability?: number; // Обновить вероятность
}
```

### DealQueryDto

```typescript
export class DealQueryDto extends PaginationDto {
  @IsEnum(DealStage)
  @IsOptional()
  stage?: DealStage;

  @IsArray()
  @IsEnum(DealStage, { each: true })
  @IsOptional()
  stages?: DealStage[]; // Множественный фильтр

  @IsUUID()
  @IsOptional()
  customerId?: string;

  @IsUUID()
  @IsOptional()
  assignedTo?: string;

  @IsEnum(DealPriority)
  @IsOptional()
  priority?: DealPriority;

  @IsString()
  @IsOptional()
  search?: string; // Поиск по title, description

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Transform(({ value }) => Number(value))
  minValue?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Transform(({ value }) => Number(value))
  maxValue?: number;

  @IsDateString()
  @IsOptional()
  expectedCloseDateFrom?: string;

  @IsDateString()
  @IsOptional()
  expectedCloseDateTo?: string;

  @IsDateString()
  @IsOptional()
  createdFrom?: string;

  @IsDateString()
  @IsOptional()
  createdTo?: string;

  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => value === 'true')
  isRecurring?: boolean;

  @IsString()
  @IsOptional()
  leadSource?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];

  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => value === 'true')
  includeArchived?: boolean;

  @IsString()
  @IsOptional()
  @IsIn(['createdAt', 'updatedAt', 'value', 'probability', 'expectedCloseDate', 'stage'])
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
@Controller('api/v1/workspaces/:workspaceId/deals')
@UseGuards(JwtAuthGuard, WorkspaceGuard)
export class DealsController {
  
  // Получить список сделок
  @Get()
  @RequirePermissions(Permission.DEALS_VIEW)
  async findAll(
    @Param('workspaceId') workspaceId: string,
    @Query() query: DealQueryDto
  ): Promise<PaginatedResponse<Deal>>

  // Получить сделку по ID
  @Get(':id')
  @RequirePermissions(Permission.DEALS_VIEW)
  async findOne(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string
  ): Promise<Deal>

  // Создать сделку
  @Post()
  @RequirePermissions(Permission.DEALS_CREATE)
  async create(
    @Param('workspaceId') workspaceId: string,
    @Body() dto: CreateDealDto,
    @CurrentUser() user: User
  ): Promise<Deal>

  // Обновить сделку
  @Put(':id')
  @RequirePermissions(Permission.DEALS_UPDATE)
  async update(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string,
    @Body() dto: UpdateDealDto,
    @CurrentUser() user: User
  ): Promise<Deal>

  // Удалить сделку
  @Delete(':id')
  @RequirePermissions(Permission.DEALS_DELETE)
  async remove(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string
  ): Promise<void>

  // Изменить стадию сделки
  @Patch(':id/stage')
  @RequirePermissions(Permission.DEALS_UPDATE)
  async changeStage(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string,
    @Body() dto: ChangeDealStageDto,
    @CurrentUser() user: User
  ): Promise<Deal>

  // Клонировать сделку
  @Post(':id/clone')
  @RequirePermissions(Permission.DEALS_CREATE)
  async clone(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string,
    @Body() dto: CloneDealDto
  ): Promise<Deal>

  // Массовые операции
  @Patch('bulk/stage')
  @RequirePermissions(Permission.DEALS_UPDATE)
  async bulkChangeStage(
    @Param('workspaceId') workspaceId: string,
    @Body() dto: BulkChangeStageDto
  ): Promise<void>

  @Delete('bulk')
  @RequirePermissions(Permission.DEALS_DELETE)
  async bulkDelete(
    @Param('workspaceId') workspaceId: string,
    @Body() ids: string[]
  ): Promise<void>
}
```

### Pipeline endpoints

```typescript
// Получить pipeline (канбан-доска)
@Get('pipeline')
async getPipeline(
  @Param('workspaceId') workspaceId: string,
  @Query() query: PipelineQueryDto
): Promise<PipelineResponse>

// Переместить сделку между стадиями
@Patch(':id/move')
async moveDeal(
  @Param('id') id: string,
  @Body() dto: MoveDealDto
): Promise<Deal>

// Получить статистику по pipeline
@Get('pipeline/stats')
async getPipelineStats(
  @Param('workspaceId') workspaceId: string,
  @Query() query: StatsQueryDto
): Promise<PipelineStats>

// Получить историю изменений стадий
@Get(':id/stage-history')
async getStageHistory(
  @Param('id') id: string
): Promise<StageHistoryEntry[]>
```

### Activity endpoints

```typescript
// Добавить активность
@Post(':dealId/activities')
async addActivity(
  @Param('dealId') dealId: string,
  @Body() dto: CreateActivityDto
): Promise<DealActivity>

// Получить активности сделки
@Get(':dealId/activities')
async getActivities(
  @Param('dealId') dealId: string,
  @Query() query: ActivityQueryDto
): Promise<DealActivity[]>

// Отметить активность выполненной
@Patch(':dealId/activities/:activityId/complete')
async completeActivity(
  @Param('dealId') dealId: string,
  @Param('activityId') activityId: string,
  @Body() dto: CompleteActivityDto
): Promise<DealActivity>

// Отменить активность
@Patch(':dealId/activities/:activityId/cancel')
async cancelActivity(
  @Param('dealId') dealId: string,
  @Param('activityId') activityId: string,
  @Body() dto: CancelActivityDto
): Promise<DealActivity>
```

### Analytics endpoints

```typescript
// Прогноз продаж
@Get('forecast')
async getForecast(
  @Param('workspaceId') workspaceId: string,
  @Query() query: ForecastQueryDto
): Promise<ForecastResponse>

// Воронка продаж
@Get('funnel')
async getSalesFunnel(
  @Param('workspaceId') workspaceId: string,
  @Query() query: FunnelQueryDto
): Promise<FunnelResponse>

// Конверсия по стадиям
@Get('conversion')
async getConversionRates(
  @Param('workspaceId') workspaceId: string,
  @Query() query: ConversionQueryDto
): Promise<ConversionRates>

// Производительность менеджеров
@Get('performance')
async getPerformance(
  @Param('workspaceId') workspaceId: string,
  @Query() query: PerformanceQueryDto
): Promise<PerformanceMetrics>

// Win/Loss анализ
@Get('win-loss')
async getWinLossAnalysis(
  @Param('workspaceId') workspaceId: string,
  @Query() query: WinLossQueryDto
): Promise<WinLossAnalysis>
```

## 💼 Service Layer

### DealsService

```typescript
@Injectable()
export class DealsService {
  constructor(
    @InjectRepository(Deal)
    private dealRepository: Repository<Deal>,
    @InjectRepository(DealProduct)
    private dealProductRepository: Repository<DealProduct>,
    @InjectRepository(DealActivity)
    private activityRepository: Repository<DealActivity>,
    private eventEmitter: EventEmitter2,
    private cacheManager: Cache,
    private notificationService: NotificationService
  ) {}

  async create(dto: CreateDealDto, userId: string): Promise<Deal> {
    const queryRunner = this.connection.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Устанавливаем начальные значения
      const dealData = {
        ...dto,
        stage: dto.stage || DealStage.LEAD,
        probability: this.getDefaultProbability(dto.stage || DealStage.LEAD),
        expectedRevenue: 0,
        stageHistory: [{
          stage: dto.stage || DealStage.LEAD,
          enteredAt: new Date(),
          changedBy: userId
        }],
        createdBy: userId,
        updatedBy: userId
      };

      // Создаем сделку
      const deal = this.dealRepository.create(dealData);
      deal.calculateExpectedRevenue();
      
      const savedDeal = await queryRunner.manager.save(deal);

      // Создаем продукты
      if (dto.products?.length) {
        const products = dto.products.map((product, index) => ({
          ...product,
          dealId: savedDeal.id,
          sortOrder: index
        }));
        await queryRunner.manager.save(DealProduct, products);
      }

      await queryRunner.commitTransaction();

      // Эмитируем событие
      this.eventEmitter.emit('deal.created', {
        dealId: savedDeal.id,
        customerId: savedDeal.customerId,
        value: savedDeal.value,
        stage: savedDeal.stage,
        workspaceId: savedDeal.workspaceId,
        organizationId: savedDeal.organizationId,
        createdBy: userId
      });

      // Отправляем уведомление
      if (savedDeal.assignedTo && savedDeal.assignedTo !== userId) {
        await this.notificationService.send({
          userId: savedDeal.assignedTo,
          type: 'DEAL_ASSIGNED',
          title: 'Новая сделка назначена вам',
          message: `Сделка "${savedDeal.title}" на сумму ${savedDeal.value} ${savedDeal.currency}`,
          link: `/deals/${savedDeal.id}`
        });
      }

      return savedDeal;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  async changeStage(
    dealId: string, 
    dto: ChangeDealStageDto, 
    userId: string
  ): Promise<Deal> {
    const deal = await this.dealRepository.findOne({
      where: { id: dealId },
      relations: ['products']
    });

    if (!deal) {
      throw new NotFoundException('Deal not found');
    }

    const previousStage = deal.stage;
    const now = new Date();

    // Обновляем историю стадий
    if (deal.stageHistory && deal.stageHistory.length > 0) {
      const currentStageEntry = deal.stageHistory[deal.stageHistory.length - 1];
      currentStageEntry.leftAt = now;
      currentStageEntry.duration = Math.floor(
        (now.getTime() - new Date(currentStageEntry.enteredAt).getTime()) / 1000
      );
    }

    // Добавляем новую стадию в историю
    deal.stageHistory = [
      ...(deal.stageHistory || []),
      {
        stage: dto.stage,
        enteredAt: now,
        changedBy: userId
      }
    ];

    // Обновляем основные поля
    deal.stage = dto.stage;
    deal.probability = dto.probability || this.getDefaultProbability(dto.stage);
    deal.updatedBy = userId;

    // Обработка выигранной сделки
    if (dto.stage === DealStage.WON && previousStage !== DealStage.WON) {
      deal.wonAt = now;
      deal.actualCloseDate = now;
      deal.probability = 100;
      
      // Эмитируем событие deal.won
      this.eventEmitter.emit('deal.won', {
        dealId: deal.id,
        customerId: deal.customerId,
        customerName: null, // Будет загружено lazy
        dealValue: deal.value,
        currency: deal.currency,
        products: deal.products,
        workspaceId: deal.workspaceId,
        organizationId: deal.organizationId,
        userId: userId,
        wonAt: now
      });

      // Уведомление об успехе
      await this.notificationService.broadcast({
        workspaceId: deal.workspaceId,
        type: 'DEAL_WON',
        title: '🎉 Сделка выиграна!',
        message: `Сделка "${deal.title}" на сумму ${deal.value} ${deal.currency} успешно закрыта`,
        priority: 'high'
      });
    }

    // Обработка проигранной сделки
    if (dto.stage === DealStage.LOST && previousStage !== DealStage.LOST) {
      deal.lostAt = now;
      deal.actualCloseDate = now;
      deal.probability = 0;
      deal.lostReason = dto.lostReason;
      deal.competitorInfo = dto.competitorInfo;
      
      // Эмитируем событие deal.lost
      this.eventEmitter.emit('deal.lost', {
        dealId: deal.id,
        customerId: deal.customerId,
        lostReason: dto.lostReason,
        competitorInfo: dto.competitorInfo,
        workspaceId: deal.workspaceId,
        organizationId: deal.organizationId,
        userId: userId,
        lostAt: now
      });
    }

    // Обновляем время в стадии и pipeline
    deal.updateDaysInStage();
    deal.totalDaysInPipeline = Math.floor(
      (now.getTime() - deal.createdAt.getTime()) / (1000 * 60 * 60 * 24)
    );

    // Пересчитываем ожидаемый доход
    deal.calculateExpectedRevenue();

    const updatedDeal = await this.dealRepository.save(deal);

    // Эмитируем событие изменения стадии
    this.eventEmitter.emit('deal.stage.changed', {
      dealId: deal.id,
      previousStage,
      newStage: dto.stage,
      changedBy: userId,
      timestamp: now
    });

    // Инвалидируем кеш
    await this.cacheManager.del(`deals:${deal.workspaceId}:*`);

    return updatedDeal;
  }

  async getPipeline(
    workspaceId: string, 
    query: PipelineQueryDto
  ): Promise<PipelineResponse> {
    const stages = Object.values(DealStage).filter(
      stage => stage !== DealStage.WON && stage !== DealStage.LOST
    );

    const pipeline = {};

    for (const stage of stages) {
      const qb = this.dealRepository.createQueryBuilder('deal')
        .leftJoinAndSelect('deal.products', 'products')
        .where('deal.workspaceId = :workspaceId', { workspaceId })
        .andWhere('deal.stage = :stage', { stage });

      // Применяем фильтры
      if (query.assignedTo) {
        qb.andWhere('deal.assignedTo = :assignedTo', { assignedTo: query.assignedTo });
      }

      if (query.customerId) {
        qb.andWhere('deal.customerId = :customerId', { customerId: query.customerId });
      }

      if (query.dateFrom) {
        qb.andWhere('deal.createdAt >= :dateFrom', { dateFrom: query.dateFrom });
      }

      if (query.dateTo) {
        qb.andWhere('deal.createdAt <= :dateTo', { dateTo: query.dateTo });
      }

      // Сортировка внутри стадии
      qb.orderBy('deal.priority', 'DESC')
        .addOrderBy('deal.value', 'DESC')
        .addOrderBy('deal.createdAt', 'ASC');

      const deals = await qb.getMany();

      pipeline[stage] = {
        deals,
        count: deals.length,
        totalValue: deals.reduce((sum, deal) => sum + deal.value, 0),
        expectedRevenue: deals.reduce((sum, deal) => sum + deal.expectedRevenue, 0)
      };
    }

    return {
      pipeline,
      summary: {
        totalDeals: Object.values(pipeline).reduce((sum: number, stage: any) => sum + stage.count, 0),
        totalValue: Object.values(pipeline).reduce((sum: number, stage: any) => sum + stage.totalValue, 0),
        totalExpectedRevenue: Object.values(pipeline).reduce((sum: number, stage: any) => sum + stage.expectedRevenue, 0)
      }
    };
  }

  async getForecast(
    workspaceId: string, 
    query: ForecastQueryDto
  ): Promise<ForecastResponse> {
    const endDate = new Date(query.endDate || new Date());
    endDate.setMonth(endDate.getMonth() + (query.months || 3));

    const deals = await this.dealRepository.find({
      where: {
        workspaceId,
        stage: Not(In([DealStage.WON, DealStage.LOST])),
        expectedCloseDate: LessThanOrEqual(endDate)
      }
    });

    // Группируем по месяцам
    const forecastByMonth = {};
    
    deals.forEach(deal => {
      const monthKey = format(deal.expectedCloseDate, 'yyyy-MM');
      
      if (!forecastByMonth[monthKey]) {
        forecastByMonth[monthKey] = {
          month: monthKey,
          committed: 0,      // probability >= 75%
          bestCase: 0,       // probability >= 50%
          pipeline: 0,       // все сделки
          weighted: 0        // взвешенный прогноз
        };
      }
      
      forecastByMonth[monthKey].pipeline += deal.value;
      forecastByMonth[monthKey].weighted += deal.expectedRevenue;
      
      if (deal.probability >= 75) {
        forecastByMonth[monthKey].committed += deal.value;
      }
      
      if (deal.probability >= 50) {
        forecastByMonth[monthKey].bestCase += deal.value;
      }
    });

    // Добавляем исторические данные для точности прогноза
    const historicalWinRate = await this.calculateWinRate(workspaceId);
    
    Object.values(forecastByMonth).forEach((month: any) => {
      month.realistic = month.weighted * historicalWinRate;
    });

    return {
      forecast: Object.values(forecastByMonth),
      summary: {
        totalPipeline: deals.reduce((sum, d) => sum + d.value, 0),
        totalWeighted: deals.reduce((sum, d) => sum + d.expectedRevenue, 0),
        totalCommitted: deals.filter(d => d.probability >= 75).reduce((sum, d) => sum + d.value, 0),
        averageDealSize: deals.length > 0 ? deals.reduce((sum, d) => sum + d.value, 0) / deals.length : 0,
        winRate: historicalWinRate
      }
    };
  }

  private async calculateWinRate(workspaceId: string): Promise<number> {
    const last90Days = new Date();
    last90Days.setDate(last90Days.getDate() - 90);

    const [wonCount, totalClosed] = await Promise.all([
      this.dealRepository.count({
        where: {
          workspaceId,
          stage: DealStage.WON,
          wonAt: MoreThanOrEqual(last90Days)
        }
      }),
      this.dealRepository.count({
        where: {
          workspaceId,
          stage: In([DealStage.WON, DealStage.LOST]),
          actualCloseDate: MoreThanOrEqual(last90Days)
        }
      })
    ]);

    return totalClosed > 0 ? wonCount / totalClosed : 0.3; // Default 30%
  }

  private getDefaultProbability(stage: DealStage): number {
    const probabilities = {
      [DealStage.LEAD]: 10,
      [DealStage.QUALIFIED]: 25,
      [DealStage.PROPOSAL]: 50,
      [DealStage.NEGOTIATION]: 75,
      [DealStage.CLOSING]: 90,
      [DealStage.WON]: 100,
      [DealStage.LOST]: 0
    };
    
    return probabilities[stage] || 10;
  }

  async getConversionRates(
    workspaceId: string,
    query: ConversionQueryDto
  ): Promise<ConversionRates> {
    const stages = [
      DealStage.LEAD,
      DealStage.QUALIFIED,
      DealStage.PROPOSAL,
      DealStage.NEGOTIATION,
      DealStage.CLOSING,
      DealStage.WON
    ];

    const conversions = [];
    
    for (let i = 0; i < stages.length - 1; i++) {
      const fromStage = stages[i];
      const toStage = stages[i + 1];
      
      // Считаем сделки, прошедшие через обе стадии
      const passedThrough = await this.dealRepository
        .createQueryBuilder('deal')
        .where('deal.workspaceId = :workspaceId', { workspaceId })
        .andWhere('JSON_CONTAINS(deal.stageHistory, :fromStage)', {
          fromStage: JSON.stringify({ stage: fromStage })
        })
        .andWhere('JSON_CONTAINS(deal.stageHistory, :toStage)', {
          toStage: JSON.stringify({ stage: toStage })
        })
        .getCount();
      
      // Считаем все сделки в исходной стадии
      const totalInStage = await this.dealRepository.count({
        where: {
          workspaceId,
          stage: fromStage
        }
      });
      
      const rate = totalInStage > 0 ? (passedThrough / totalInStage) * 100 : 0;
      
      conversions.push({
        from: fromStage,
        to: toStage,
        rate,
        count: passedThrough
      });
    }

    // Общая конверсия LEAD -> WON
    const totalLeads = await this.dealRepository.count({
      where: {
        workspaceId,
        stage: In([DealStage.LEAD, DealStage.WON])
      }
    });
    
    const totalWon = await this.dealRepository.count({
      where: {
        workspaceId,
        stage: DealStage.WON
      }
    });
    
    const overallConversion = totalLeads > 0 ? (totalWon / totalLeads) * 100 : 0;

    return {
      conversions,
      overallConversion,
      averageTimeInStage: await this.calculateAverageTimeInStage(workspaceId)
    };
  }

  private async calculateAverageTimeInStage(workspaceId: string): Promise<any> {
    const deals = await this.dealRepository.find({
      where: { 
        workspaceId,
        stageHistory: Not(IsNull())
      }
    });

    const timeByStage = {};
    
    deals.forEach(deal => {
      if (deal.stageHistory) {
        deal.stageHistory.forEach(entry => {
          if (entry.duration) {
            if (!timeByStage[entry.stage]) {
              timeByStage[entry.stage] = {
                total: 0,
                count: 0
              };
            }
            
            timeByStage[entry.stage].total += entry.duration;
            timeByStage[entry.stage].count++;
          }
        });
      }
    });

    const averages = {};
    Object.keys(timeByStage).forEach(stage => {
      averages[stage] = Math.round(
        timeByStage[stage].total / timeByStage[stage].count / (60 * 60 * 24)
      ); // В днях
    });

    return averages;
  }
}
```

## 🎯 Deal Won Orchestrator

```typescript
@Injectable()
export class DealWonOrchestrator {
  private readonly logger = new Logger(DealWonOrchestrator.name);

  constructor(
    private dataSource: DataSource,
    private ordersService: OrdersService,
    private invoiceService: InvoiceService,
    private customerService: CustomersService,
    private inventoryService: InventoryService,
    private eventEmitter: EventEmitter2
  ) {}

  @OnEvent('deal.won')
  async handleDealWon(event: DealWonEvent) {
    this.logger.log(`Processing won deal: ${event.dealId}`);
    
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // 1. Создаем Order из Deal
      const order = await this.createOrderFromDeal(event, queryRunner);
      this.logger.log(`Order created: ${order.id}`);

      // 2. Создаем Invoice
      const invoice = await this.createInvoiceFromDeal(event, queryRunner);
      this.logger.log(`Invoice created: ${invoice.id}`);

      // 3. Обновляем статус клиента на ACTIVE
      await this.customerService.updateStatus(
        event.customerId,
        CustomerStatus.ACTIVE
      );

      // 4. Эмитируем событие для создания Production Order
      this.eventEmitter.emit('order.created', {
        orderId: order.id,
        customerId: event.customerId,
        dealId: event.dealId,
        items: event.products,
        workspaceId: event.workspaceId,
        organizationId: event.organizationId
      });

      await queryRunner.commitTransaction();

      // 5. Отправляем уведомления
      this.eventEmitter.emit('notification.send', {
        type: 'DEAL_WON_PROCESSED',
        recipients: [event.userId],
        data: {
          dealId: event.dealId,
          orderId: order.id,
          invoiceId: invoice.id
        }
      });

    } catch (error) {
      await queryRunner.rollbackTransaction();
      this.logger.error(`Failed to process won deal: ${error.message}`);
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  private async createOrderFromDeal(
    event: DealWonEvent,
    queryRunner: any
  ): Promise<Order> {
    const orderData = {
      dealId: event.dealId,
      customerId: event.customerId,
      orderNumber: `ORD-${Date.now()}`,
      status: OrderStatus.PENDING,
      items: event.products.map(p => ({
        productId: p.productId,
        productName: p.productName,
        quantity: p.quantity,
        unitPrice: p.unitPrice,
        discount: p.discount,
        tax: p.tax,
        totalPrice: p.totalPrice
      })),
      totalAmount: event.dealValue,
      currency: event.currency,
      organizationId: event.organizationId,
      workspaceId: event.workspaceId,
      createdBy: event.userId
    };

    const order = queryRunner.manager.create(Order, orderData);
    return queryRunner.manager.save(order);
  }

  private async createInvoiceFromDeal(
    event: DealWonEvent,
    queryRunner: any
  ): Promise<Invoice> {
    const invoiceData = {
      dealId: event.dealId,
      customerId: event.customerId,
      invoiceNumber: `INV-${Date.now()}`,
      status: InvoiceStatus.DRAFT,
      items: event.products,
      subtotal: event.dealValue,
      taxAmount: event.dealValue * 0.12, // 12% НДС
      totalAmount: event.dealValue * 1.12,
      currency: event.currency,
      dueDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // +30 дней
      organizationId: event.organizationId,
      workspaceId: event.workspaceId,
      createdBy: event.userId
    };

    const invoice = queryRunner.manager.create(Invoice, invoiceData);
    return queryRunner.manager.save(invoice);
  }
}
```

## 🎯 Events

### Эмитируемые события

```typescript
// Создание сделки
'deal.created': {
  dealId: string;
  customerId: string;
  value: number;
  stage: DealStage;
  workspaceId: string;
  organizationId: string;
  createdBy: string;
}

// Обновление сделки
'deal.updated': {
  dealId: string;
  changes: Partial<Deal>;
  updatedBy: string;
}

// Изменение стадии
'deal.stage.changed': {
  dealId: string;
  previousStage: DealStage;
  newStage: DealStage;
  changedBy: string;
}

// Выигрыш сделки
'deal.won': {
  dealId: string;
  customerId: string;
  customerName: string;
  dealValue: number;
  currency: string;
  products: DealProduct[];
  workspaceId: string;
  organizationId: string;
  userId: string;
  wonAt: Date;
}

// Проигрыш сделки
'deal.lost': {
  dealId: string;
  customerId: string;
  lostReason: string;
  competitorInfo: string;
  workspaceId: string;
  organizationId: string;
  userId: string;
  lostAt: Date;
}

// Назначение сделки
'deal.assigned': {
  dealId: string;
  assignedTo: string;
  assignedBy: string;
}

// Добавление активности
'deal.activity.added': {
  dealId: string;
  activityId: string;
  type: ActivityType;
  scheduledAt: Date;
}

// Завершение активности
'deal.activity.completed': {
  dealId: string;
  activityId: string;
  outcome: string;
}
```

### Обрабатываемые события

```typescript
@OnEvent('customer.created')
async handleCustomerCreated(event: CustomerCreatedEvent) {
  // Можем автоматически создать сделку для нового клиента
}

@OnEvent('product.price.changed')
async handleProductPriceChanged(event: ProductPriceChangedEvent) {
  // Обновляем цены в открытых сделках
}

@OnEvent('order.completed')
async handleOrderCompleted(event: OrderCompletedEvent) {
  // Обновляем метрики сделки
}
```

## 📊 Аналитика и отчеты

### Sales Funnel

```typescript
interface SalesFunnel {
  stages: {
    stage: DealStage;
    count: number;
    value: number;
    percentage: number;
    conversionRate: number;
    averageTime: number; // дней
  }[];
  
  totalDeals: number;
  totalValue: number;
  overallConversion: number;
  averageDealSize: number;
  averageSalesCycle: number; // дней
}
```

### Performance Metrics

```typescript
interface PerformanceMetrics {
  byManager: {
    userId: string;
    name: string;
    metrics: {
      dealsCreated: number;
      dealsWon: number;
      dealsLost: number;
      totalRevenue: number;
      winRate: number;
      averageDealSize: number;
      averageSalesCycle: number;
      activitiesCompleted: number;
    };
  }[];
  
  byPeriod: {
    period: string; // '2024-01', '2024-Q1', '2024'
    metrics: {
      newDeals: number;
      wonDeals: number;
      lostDeals: number;
      revenue: number;
      growth: number; // % vs previous period
    };
  }[];
  
  bySource: {
    source: string;
    count: number;
    revenue: number;
    conversionRate: number;
    averageDealSize: number;
  }[];
}
```

## 🔄 Интеграция с другими модулями

### Orders Module
- Автоматическое создание Order при выигрыше сделки
- Синхронизация статусов и сумм
- Отслеживание выполнения

### Production Module
- Создание Production Order для manufactured products
- Планирование производства
- Резервирование мощностей

### Finance Module
- Автоматическое создание Invoice
- Расчет комиссий
- Отслеживание платежей

### Inventory Module
- Проверка наличия товаров
- Резервирование под сделку
- Управление поставками

## 🎨 Примеры использования

### Создание B2B сделки

```typescript
const deal = await dealsService.create({
  title: 'Поставка оборудования для ТОО Альфа',
  description: 'Комплексная поставка производственного оборудования',
  stage: DealStage.QUALIFIED,
  value: 15000000,
  currency: 'KZT',
  probability: 50,
  expectedCloseDate: '2024-03-15',
  customerId: 'customer-uuid',
  assignedTo: 'manager-uuid',
  priority: DealPriority.HIGH,
  products: [
    {
      productId: 'product-1',
      productName: 'Станок токарный',
      quantity: 2,
      unitPrice: 5000000,
      tax: 12
    },
    {
      productId: 'product-2',
      productName: 'Станок фрезерный',
      quantity: 1,
      unitPrice: 5000000,
      tax: 12
    }
  ],
  tags: ['equipment', 'manufacturing', 'high-value'],
  customFields: {
    deliveryLocation: 'Алматы',
    installationRequired: true,
    trainingIncluded: true
  }
}, userId);
```

### Pipeline management

```typescript
// Получить pipeline
const pipeline = await dealsService.getPipeline(workspaceId, {
  assignedTo: managerId,
  dateFrom: '2024-01-01',
  dateTo: '2024-12-31'
});

// Переместить сделку
await dealsService.changeStage(dealId, {
  stage: DealStage.PROPOSAL,
  probability: 50,
  notes: 'Коммерческое предложение отправлено'
}, userId);
```

## 🚀 Оптимизация производительности

### Индексы
- Составной индекс (organizationId, workspaceId)
- Индекс по stage для pipeline queries
- Индекс по customerId для связанных запросов
- Индекс по assignedTo для фильтрации
- Индекс по expectedCloseDate для прогнозов

### Кеширование
- Pipeline кеш (TTL: 1 минута)
- Forecast кеш (TTL: 5 минут)
- Analytics кеш (TTL: 10 минут)

### Lazy Loading
- Активности загружаются по запросу
- Вложения загружаются отдельно
- История изменений - отдельный endpoint

---

© 2025 Prometric ERP. Deals Module Documentation.