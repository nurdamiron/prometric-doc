# 📋 Customers Module - Полная техническая документация

## 📌 Обзор модуля

Модуль Customers является ядром CRM-функционала системы Prometric ERP. Обеспечивает полное управление клиентской базой, включая лиды, потенциальных и активных клиентов, с поддержкой B2B и B2C операций.

## 🏗️ Архитектура модуля

### Основные компоненты

```typescript
CustomersModule
├── Controllers
│   └── CustomersController (REST API endpoints)
├── Services
│   ├── CustomersService (основная бизнес-логика)
│   ├── CustomerValidationService (валидация данных)
│   ├── CustomerEventsService (обработка событий)
│   └── CustomerAnalyticsService (аналитика)
├── Entities
│   ├── Customer (основная сущность)
│   ├── CustomerContact (контактные лица)
│   ├── CustomerAddress (адреса)
│   └── CustomerNote (заметки)
├── DTOs
│   ├── CreateCustomerDto
│   ├── UpdateCustomerDto
│   ├── CustomerQueryDto
│   └── CustomerResponseDto
└── Validators
    ├── IINValidator (ИИН валидация)
    └── BINValidator (БИН валидация)
```

## 📊 Entity: Customer

### Основные поля

```typescript
@Entity('customers')
@Index(['organizationId', 'workspaceId'])
@Index(['email'], { unique: true })
@Index(['iin'], { unique: true, where: 'iin IS NOT NULL' })
@Index(['bin'], { unique: true, where: 'bin IS NOT NULL' })
export class Customer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  organizationId: string;

  @Column()
  workspaceId: string;

  @Column({ type: 'enum', enum: CustomerType, default: CustomerType.COMPANY })
  type: CustomerType; // INDIVIDUAL | COMPANY

  @Column({ type: 'enum', enum: CustomerStatus, default: CustomerStatus.LEAD })
  status: CustomerStatus; // LEAD | PROSPECT | ACTIVE | INACTIVE | CHURNED

  @Column()
  name: string; // Полное имя или название компании

  @Column({ unique: true })
  email: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true })
  iin: string; // ИИН для физлиц (12 цифр)

  @Column({ nullable: true })
  bin: string; // БИН для юрлиц (12 цифр)

  @Column({ nullable: true })
  companyName: string;

  @Column({ nullable: true })
  companySize: string; // 1-10 | 11-50 | 51-200 | 201-500 | 500+

  @Column({ nullable: true })
  industry: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  creditLimit: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  currentBalance: number;

  @Column({ type: 'jsonb', nullable: true })
  customFields: Record<string, any>;

  @Column({ type: 'jsonb', nullable: true })
  tags: string[];

  @Column({ nullable: true })
  leadSource: string; // website | referral | cold_call | exhibition | social_media

  @Column({ type: 'timestamp', nullable: true })
  firstPurchaseDate: Date;

  @Column({ type: 'timestamp', nullable: true })
  lastPurchaseDate: Date;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  totalPurchases: number;

  @Column({ type: 'int', default: 0 })
  purchaseCount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  lifetimeValue: number;

  @Column({ type: 'int', default: 5 })
  rating: number; // 1-10

  @Column({ nullable: true })
  assignedTo: string; // ID менеджера

  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  // Связи
  @OneToMany(() => CustomerContact, contact => contact.customer, { cascade: true, eager: true })
  contacts: CustomerContact[];

  @OneToMany(() => CustomerAddress, address => address.customer, { cascade: true, eager: true })
  addresses: CustomerAddress[];

  @OneToMany(() => Deal, deal => deal.customer, { lazy: true })
  deals: Promise<Deal[]>;

  @OneToMany(() => Order, order => order.customer, { lazy: true })
  orders: Promise<Order[]>;

  @OneToMany(() => Invoice, invoice => invoice.customer, { lazy: true })
  invoices: Promise<Invoice[]>;

  @OneToMany(() => CustomerNote, note => note.customer, { lazy: true })
  notes: Promise<CustomerNote[]>;

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

### Enums

```typescript
export enum CustomerType {
  INDIVIDUAL = 'INDIVIDUAL',  // Физическое лицо
  COMPANY = 'COMPANY'         // Юридическое лицо
}

export enum CustomerStatus {
  LEAD = 'LEAD',             // Потенциальный клиент
  PROSPECT = 'PROSPECT',     // Квалифицированный лид
  ACTIVE = 'ACTIVE',         // Активный клиент
  INACTIVE = 'INACTIVE',     // Неактивный клиент
  CHURNED = 'CHURNED'        // Потерянный клиент
}

export enum AddressType {
  BILLING = 'billing',       // Юридический адрес
  SHIPPING = 'shipping',     // Адрес доставки
  OFFICE = 'office',        // Офис
  WAREHOUSE = 'warehouse'    // Склад
}
```

## 📊 Entity: CustomerContact

```typescript
@Entity('customer_contacts')
export class CustomerContact {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  customerId: string;

  @ManyToOne(() => Customer, customer => customer.contacts, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'customerId' })
  customer: Customer;

  @Column()
  firstName: string;

  @Column()
  lastName: string;

  @Column({ nullable: true })
  middleName: string;

  @Column({ nullable: true })
  position: string;

  @Column({ nullable: true })
  department: string;

  @Column()
  email: string;

  @Column()
  phone: string;

  @Column({ nullable: true })
  mobilePhone: string;

  @Column({ type: 'boolean', default: false })
  isPrimary: boolean;

  @Column({ type: 'boolean', default: false })
  isDecisionMaker: boolean;

  @Column({ type: 'jsonb', nullable: true })
  socialMedia: {
    linkedin?: string;
    telegram?: string;
    whatsapp?: string;
  };

  @Column({ nullable: true })
  notes: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

## 📊 Entity: CustomerAddress

```typescript
@Entity('customer_addresses')
export class CustomerAddress {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  customerId: string;

  @ManyToOne(() => Customer, customer => customer.addresses, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'customerId' })
  customer: Customer;

  @Column({ type: 'enum', enum: AddressType })
  type: AddressType;

  @Column()
  street: string;

  @Column({ nullable: true })
  building: string;

  @Column({ nullable: true })
  apartment: string;

  @Column()
  city: string;

  @Column({ nullable: true })
  region: string;

  @Column()
  postalCode: string;

  @Column({ default: 'Kazakhstan' })
  country: string;

  @Column({ type: 'boolean', default: false })
  isPrimary: boolean;

  @Column({ nullable: true })
  contactName: string;

  @Column({ nullable: true })
  contactPhone: string;

  @Column({ nullable: true })
  deliveryInstructions: string;

  @Column({ type: 'jsonb', nullable: true })
  coordinates: {
    latitude: number;
    longitude: number;
  };

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

## 📋 DTOs

### CreateCustomerDto

```typescript
export class CreateCustomerDto {
  @IsEnum(CustomerType)
  type: CustomerType;

  @IsString()
  @MinLength(2)
  @MaxLength(200)
  name: string;

  @IsEmail()
  email: string;

  @IsPhoneNumber('KZ')
  @IsOptional()
  phone?: string;

  @IsString()
  @Length(12, 12)
  @IsOptional()
  @Validate(IINValidator)
  iin?: string; // Для физлиц

  @IsString()
  @Length(12, 12)
  @IsOptional()
  @Validate(BINValidator)
  bin?: string; // Для юрлиц

  @IsString()
  @IsOptional()
  companyName?: string;

  @IsString()
  @IsOptional()
  companySize?: string;

  @IsString()
  @IsOptional()
  industry?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  creditLimit?: number;

  @IsEnum(CustomerStatus)
  @IsOptional()
  status?: CustomerStatus;

  @IsString()
  @IsOptional()
  leadSource?: string;

  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => CreateContactDto)
  contacts?: CreateContactDto[];

  @IsArray()
  @IsOptional()
  @ValidateNested({ each: true })
  @Type(() => CreateAddressDto)
  addresses?: CreateAddressDto[];

  @IsObject()
  @IsOptional()
  customFields?: Record<string, any>;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];

  @IsUUID()
  @IsOptional()
  assignedTo?: string;
}
```

### UpdateCustomerDto

```typescript
export class UpdateCustomerDto extends PartialType(CreateCustomerDto) {
  @IsEnum(CustomerStatus)
  @IsOptional()
  status?: CustomerStatus;

  @IsNumber()
  @Min(1)
  @Max(10)
  @IsOptional()
  rating?: number;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @IsDecimal()
  @IsOptional()
  currentBalance?: number;
}
```

### CustomerQueryDto

```typescript
export class CustomerQueryDto extends PaginationDto {
  @IsEnum(CustomerType)
  @IsOptional()
  type?: CustomerType;

  @IsEnum(CustomerStatus)
  @IsOptional()
  status?: CustomerStatus;

  @IsString()
  @IsOptional()
  search?: string; // Поиск по name, email, phone, iin, bin

  @IsString()
  @IsOptional()
  industry?: string;

  @IsString()
  @IsOptional()
  city?: string;

  @IsUUID()
  @IsOptional()
  assignedTo?: string;

  @IsBoolean()
  @IsOptional()
  @Transform(({ value }) => value === 'true')
  isActive?: boolean;

  @IsString()
  @IsOptional()
  leadSource?: string;

  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Transform(({ value }) => Number(value))
  minPurchases?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Transform(({ value }) => Number(value))
  maxPurchases?: number;

  @IsDateString()
  @IsOptional()
  createdFrom?: string;

  @IsDateString()
  @IsOptional()
  createdTo?: string;

  @IsString()
  @IsOptional()
  @IsIn(['createdAt', 'updatedAt', 'name', 'totalPurchases', 'rating'])
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
@Controller('api/v1/workspaces/:workspaceId/customers')
@UseGuards(JwtAuthGuard, WorkspaceGuard)
export class CustomersController {
  
  // Получить список клиентов с фильтрацией
  @Get()
  @RequirePermissions(Permission.CUSTOMERS_VIEW)
  async findAll(
    @Param('workspaceId') workspaceId: string,
    @Query() query: CustomerQueryDto
  ): Promise<PaginatedResponse<Customer>>

  // Получить клиента по ID
  @Get(':id')
  @RequirePermissions(Permission.CUSTOMERS_VIEW)
  async findOne(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string
  ): Promise<Customer>

  // Создать клиента
  @Post()
  @RequirePermissions(Permission.CUSTOMERS_CREATE)
  async create(
    @Param('workspaceId') workspaceId: string,
    @Body() dto: CreateCustomerDto,
    @CurrentUser() user: User
  ): Promise<Customer>

  // Обновить клиента
  @Put(':id')
  @RequirePermissions(Permission.CUSTOMERS_UPDATE)
  async update(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string,
    @Body() dto: UpdateCustomerDto,
    @CurrentUser() user: User
  ): Promise<Customer>

  // Удалить клиента
  @Delete(':id')
  @RequirePermissions(Permission.CUSTOMERS_DELETE)
  async remove(
    @Param('workspaceId') workspaceId: string,
    @Param('id') id: string
  ): Promise<void>

  // Массовые операции
  @Post('bulk')
  @RequirePermissions(Permission.CUSTOMERS_CREATE)
  async bulkCreate(
    @Param('workspaceId') workspaceId: string,
    @Body() dto: CreateCustomerDto[]
  ): Promise<Customer[]>

  @Delete('bulk')
  @RequirePermissions(Permission.CUSTOMERS_DELETE)
  async bulkDelete(
    @Param('workspaceId') workspaceId: string,
    @Body() ids: string[]
  ): Promise<void>
}
```

### Специализированные endpoints

```typescript
// Управление контактами
@Post(':customerId/contacts')
async addContact(
  @Param('customerId') customerId: string,
  @Body() dto: CreateContactDto
): Promise<CustomerContact>

@Put(':customerId/contacts/:contactId')
async updateContact(
  @Param('customerId') customerId: string,
  @Param('contactId') contactId: string,
  @Body() dto: UpdateContactDto
): Promise<CustomerContact>

@Delete(':customerId/contacts/:contactId')
async removeContact(
  @Param('customerId') customerId: string,
  @Param('contactId') contactId: string
): Promise<void>

// Управление адресами
@Post(':customerId/addresses')
async addAddress(
  @Param('customerId') customerId: string,
  @Body() dto: CreateAddressDto
): Promise<CustomerAddress>

@Put(':customerId/addresses/:addressId')
async updateAddress(
  @Param('customerId') customerId: string,
  @Param('addressId') addressId: string,
  @Body() dto: UpdateAddressDto
): Promise<CustomerAddress>

// Управление заметками
@Post(':customerId/notes')
async addNote(
  @Param('customerId') customerId: string,
  @Body() dto: CreateNoteDto
): Promise<CustomerNote>

@Get(':customerId/notes')
async getNotes(
  @Param('customerId') customerId: string,
  @Query() query: PaginationDto
): Promise<CustomerNote[]>

// Изменение статуса
@Patch(':id/status')
async changeStatus(
  @Param('id') id: string,
  @Body() dto: ChangeStatusDto
): Promise<Customer>

// Конвертация лида в клиента
@Post(':id/convert')
async convertLead(
  @Param('id') id: string,
  @Body() dto: ConvertLeadDto
): Promise<Customer>

// Слияние дубликатов
@Post('merge')
async mergeCustomers(
  @Body() dto: MergeCustomersDto
): Promise<Customer>

// Аналитика
@Get(':id/analytics')
async getAnalytics(
  @Param('id') id: string,
  @Query() query: AnalyticsQueryDto
): Promise<CustomerAnalytics>

@Get(':id/purchase-history')
async getPurchaseHistory(
  @Param('id') id: string,
  @Query() query: PaginationDto
): Promise<PurchaseHistory[]>

@Get(':id/timeline')
async getTimeline(
  @Param('id') id: string,
  @Query() query: TimelineQueryDto
): Promise<TimelineEvent[]>

// Экспорт/Импорт
@Get('export')
async exportCustomers(
  @Query() query: ExportQueryDto,
  @Res() response: Response
): Promise<void>

@Post('import')
@UseInterceptors(FileInterceptor('file'))
async importCustomers(
  @UploadedFile() file: Express.Multer.File,
  @Body() dto: ImportOptionsDto
): Promise<ImportResult>

// Валидация
@Post('validate/iin')
async validateIIN(
  @Body('iin') iin: string
): Promise<ValidationResult>

@Post('validate/bin')
async validateBIN(
  @Body('bin') bin: string
): Promise<ValidationResult>

@Post('check-duplicate')
async checkDuplicate(
  @Body() dto: CheckDuplicateDto
): Promise<DuplicateResult>
```

## 💼 Service Layer

### CustomersService

```typescript
@Injectable()
export class CustomersService {
  constructor(
    @InjectRepository(Customer)
    private customerRepository: Repository<Customer>,
    @InjectRepository(CustomerContact)
    private contactRepository: Repository<CustomerContact>,
    @InjectRepository(CustomerAddress)
    private addressRepository: Repository<CustomerAddress>,
    private eventEmitter: EventEmitter2,
    private cacheManager: Cache,
    private elasticsearchService: ElasticsearchService
  ) {}

  async create(dto: CreateCustomerDto, userId: string): Promise<Customer> {
    const queryRunner = this.connection.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Валидация уникальности
      await this.validateUniqueness(dto);

      // Создаем клиента
      const customer = this.customerRepository.create({
        ...dto,
        createdBy: userId,
        updatedBy: userId
      });

      // Сохраняем с контактами и адресами
      const savedCustomer = await queryRunner.manager.save(customer);

      // Создаем контакты
      if (dto.contacts?.length) {
        const contacts = dto.contacts.map(contact => ({
          ...contact,
          customerId: savedCustomer.id
        }));
        await queryRunner.manager.save(CustomerContact, contacts);
      }

      // Создаем адреса
      if (dto.addresses?.length) {
        const addresses = dto.addresses.map(address => ({
          ...address,
          customerId: savedCustomer.id
        }));
        await queryRunner.manager.save(CustomerAddress, addresses);
      }

      await queryRunner.commitTransaction();

      // Эмитируем событие
      this.eventEmitter.emit('customer.created', {
        customerId: savedCustomer.id,
        type: savedCustomer.type,
        status: savedCustomer.status,
        workspaceId: savedCustomer.workspaceId,
        organizationId: savedCustomer.organizationId,
        createdBy: userId
      });

      // Индексируем в Elasticsearch
      await this.elasticsearchService.index('customers', savedCustomer);

      // Инвалидируем кеш
      await this.cacheManager.del(`customers:${savedCustomer.workspaceId}:*`);

      return savedCustomer;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  async findAll(workspaceId: string, query: CustomerQueryDto): Promise<PaginatedResponse<Customer>> {
    const cacheKey = `customers:${workspaceId}:${JSON.stringify(query)}`;
    
    // Проверяем кеш
    const cached = await this.cacheManager.get<PaginatedResponse<Customer>>(cacheKey);
    if (cached) return cached;

    const qb = this.customerRepository.createQueryBuilder('customer')
      .leftJoinAndSelect('customer.contacts', 'contact')
      .leftJoinAndSelect('customer.addresses', 'address')
      .where('customer.workspaceId = :workspaceId', { workspaceId });

    // Применяем фильтры
    if (query.type) {
      qb.andWhere('customer.type = :type', { type: query.type });
    }

    if (query.status) {
      qb.andWhere('customer.status = :status', { status: query.status });
    }

    if (query.search) {
      qb.andWhere(
        '(customer.name ILIKE :search OR customer.email ILIKE :search OR customer.phone ILIKE :search OR customer.iin = :exactSearch OR customer.bin = :exactSearch)',
        { search: `%${query.search}%`, exactSearch: query.search }
      );
    }

    if (query.industry) {
      qb.andWhere('customer.industry = :industry', { industry: query.industry });
    }

    if (query.assignedTo) {
      qb.andWhere('customer.assignedTo = :assignedTo', { assignedTo: query.assignedTo });
    }

    if (query.tags?.length) {
      qb.andWhere('customer.tags && :tags', { tags: query.tags });
    }

    if (query.minPurchases !== undefined) {
      qb.andWhere('customer.totalPurchases >= :minPurchases', { minPurchases: query.minPurchases });
    }

    if (query.maxPurchases !== undefined) {
      qb.andWhere('customer.totalPurchases <= :maxPurchases', { maxPurchases: query.maxPurchases });
    }

    if (query.createdFrom) {
      qb.andWhere('customer.createdAt >= :createdFrom', { createdFrom: query.createdFrom });
    }

    if (query.createdTo) {
      qb.andWhere('customer.createdAt <= :createdTo', { createdTo: query.createdTo });
    }

    // Сортировка
    const sortBy = query.sortBy || 'createdAt';
    const sortOrder = query.sortOrder || 'DESC';
    qb.orderBy(`customer.${sortBy}`, sortOrder);

    // Пагинация
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    qb.skip(skip).take(limit);

    const [items, total] = await qb.getManyAndCount();

    const result = {
      items,
      total,
      page,
      limit,
      pages: Math.ceil(total / limit)
    };

    // Кешируем результат
    await this.cacheManager.set(cacheKey, result, 300); // 5 минут

    return result;
  }

  async updateCustomerMetrics(customerId: string): Promise<void> {
    const customer = await this.customerRepository.findOne({
      where: { id: customerId }
    });

    if (!customer) return;

    // Получаем все заказы клиента
    const orders = await this.orderRepository.find({
      where: { 
        customerId,
        status: In(['completed', 'delivered'])
      }
    });

    // Вычисляем метрики
    const totalPurchases = orders.reduce((sum, order) => sum + order.totalAmount, 0);
    const purchaseCount = orders.length;
    const firstPurchaseDate = orders.length > 0 
      ? new Date(Math.min(...orders.map(o => o.createdAt.getTime())))
      : null;
    const lastPurchaseDate = orders.length > 0
      ? new Date(Math.max(...orders.map(o => o.createdAt.getTime())))
      : null;

    // Вычисляем lifetime value
    const lifetimeValue = this.calculateLifetimeValue(customer, orders);

    // Обновляем метрики
    await this.customerRepository.update(customerId, {
      totalPurchases,
      purchaseCount,
      firstPurchaseDate,
      lastPurchaseDate,
      lifetimeValue
    });

    // Эмитируем событие
    this.eventEmitter.emit('customer.metrics.updated', {
      customerId,
      totalPurchases,
      purchaseCount,
      lifetimeValue
    });
  }

  private calculateLifetimeValue(customer: Customer, orders: Order[]): number {
    // Средний чек
    const averageOrderValue = orders.length > 0
      ? orders.reduce((sum, o) => sum + o.totalAmount, 0) / orders.length
      : 0;

    // Частота покупок (заказов в месяц)
    const firstDate = customer.firstPurchaseDate || customer.createdAt;
    const monthsSinceFirst = Math.max(1, 
      (Date.now() - firstDate.getTime()) / (1000 * 60 * 60 * 24 * 30)
    );
    const purchaseFrequency = orders.length / monthsSinceFirst;

    // Прогнозируемая продолжительность жизни клиента (в месяцах)
    const estimatedLifetime = this.estimateCustomerLifetime(customer);

    // LTV = Средний чек × Частота покупок × Продолжительность жизни
    return averageOrderValue * purchaseFrequency * estimatedLifetime;
  }

  private estimateCustomerLifetime(customer: Customer): number {
    // Базовая оценка в месяцах на основе статуса и рейтинга
    const baseLifetime = {
      [CustomerStatus.LEAD]: 3,
      [CustomerStatus.PROSPECT]: 6,
      [CustomerStatus.ACTIVE]: 24,
      [CustomerStatus.INACTIVE]: 12,
      [CustomerStatus.CHURNED]: 0
    };

    let lifetime = baseLifetime[customer.status] || 12;

    // Корректируем на основе рейтинга
    lifetime *= (customer.rating / 5);

    return Math.max(1, lifetime);
  }

  async convertLeadToCustomer(leadId: string, dto: ConvertLeadDto): Promise<Customer> {
    const lead = await this.customerRepository.findOne({
      where: { 
        id: leadId,
        status: CustomerStatus.LEAD
      }
    });

    if (!lead) {
      throw new NotFoundException('Lead not found');
    }

    // Обновляем статус
    lead.status = CustomerStatus.ACTIVE;
    lead.assignedTo = dto.assignedTo || lead.assignedTo;

    const updated = await this.customerRepository.save(lead);

    // Создаем первую сделку если указано
    if (dto.createDeal) {
      this.eventEmitter.emit('deal.create.requested', {
        customerId: updated.id,
        title: dto.dealTitle || `Deal with ${updated.name}`,
        value: dto.dealValue || 0,
        assignedTo: updated.assignedTo,
        workspaceId: updated.workspaceId,
        organizationId: updated.organizationId
      });
    }

    // Эмитируем событие конвертации
    this.eventEmitter.emit('customer.lead.converted', {
      customerId: updated.id,
      previousStatus: CustomerStatus.LEAD,
      newStatus: CustomerStatus.ACTIVE,
      convertedBy: dto.convertedBy,
      timestamp: new Date()
    });

    return updated;
  }

  async mergeCustomers(primaryId: string, duplicateIds: string[]): Promise<Customer> {
    const queryRunner = this.connection.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const primary = await this.customerRepository.findOne({
        where: { id: primaryId },
        relations: ['contacts', 'addresses']
      });

      if (!primary) {
        throw new NotFoundException('Primary customer not found');
      }

      const duplicates = await this.customerRepository.findByIds(duplicateIds);

      // Переносим все связанные данные на основного клиента
      for (const duplicate of duplicates) {
        // Переносим контакты
        await queryRunner.manager.update(CustomerContact, 
          { customerId: duplicate.id },
          { customerId: primaryId }
        );

        // Переносим адреса
        await queryRunner.manager.update(CustomerAddress,
          { customerId: duplicate.id },
          { customerId: primaryId }
        );

        // Переносим сделки
        await queryRunner.manager.update(Deal,
          { customerId: duplicate.id },
          { customerId: primaryId }
        );

        // Переносим заказы
        await queryRunner.manager.update(Order,
          { customerId: duplicate.id },
          { customerId: primaryId }
        );

        // Объединяем метрики
        primary.totalPurchases += duplicate.totalPurchases;
        primary.purchaseCount += duplicate.purchaseCount;
        
        if (!primary.firstPurchaseDate || 
            (duplicate.firstPurchaseDate && duplicate.firstPurchaseDate < primary.firstPurchaseDate)) {
          primary.firstPurchaseDate = duplicate.firstPurchaseDate;
        }

        if (!primary.lastPurchaseDate || 
            (duplicate.lastPurchaseDate && duplicate.lastPurchaseDate > primary.lastPurchaseDate)) {
          primary.lastPurchaseDate = duplicate.lastPurchaseDate;
        }

        // Объединяем теги
        primary.tags = [...new Set([...(primary.tags || []), ...(duplicate.tags || [])])];

        // Объединяем custom fields
        primary.customFields = {
          ...duplicate.customFields,
          ...primary.customFields
        };
      }

      // Сохраняем обновленного основного клиента
      await queryRunner.manager.save(primary);

      // Удаляем дубликаты
      await queryRunner.manager.delete(Customer, duplicateIds);

      await queryRunner.commitTransaction();

      // Эмитируем событие
      this.eventEmitter.emit('customers.merged', {
        primaryCustomerId: primaryId,
        mergedCustomerIds: duplicateIds,
        timestamp: new Date()
      });

      return primary;
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  private async validateUniqueness(dto: CreateCustomerDto): Promise<void> {
    // Проверяем email
    const emailExists = await this.customerRepository.findOne({
      where: { 
        email: dto.email,
        organizationId: dto.organizationId
      }
    });

    if (emailExists) {
      throw new ConflictException('Customer with this email already exists');
    }

    // Проверяем ИИН для физлиц
    if (dto.type === CustomerType.INDIVIDUAL && dto.iin) {
      const iinExists = await this.customerRepository.findOne({
        where: { 
          iin: dto.iin,
          organizationId: dto.organizationId
        }
      });

      if (iinExists) {
        throw new ConflictException('Customer with this IIN already exists');
      }
    }

    // Проверяем БИН для юрлиц
    if (dto.type === CustomerType.COMPANY && dto.bin) {
      const binExists = await this.customerRepository.findOne({
        where: { 
          bin: dto.bin,
          organizationId: dto.organizationId
        }
      });

      if (binExists) {
        throw new ConflictException('Customer with this BIN already exists');
      }
    }
  }
}
```

## 🎯 Events

### Эмитируемые события

```typescript
// Создание клиента
'customer.created': {
  customerId: string;
  type: CustomerType;
  status: CustomerStatus;
  workspaceId: string;
  organizationId: string;
  createdBy: string;
}

// Обновление клиента
'customer.updated': {
  customerId: string;
  changes: Partial<Customer>;
  updatedBy: string;
}

// Удаление клиента
'customer.deleted': {
  customerId: string;
  deletedBy: string;
}

// Изменение статуса
'customer.status.changed': {
  customerId: string;
  previousStatus: CustomerStatus;
  newStatus: CustomerStatus;
  changedBy: string;
}

// Конвертация лида
'customer.lead.converted': {
  customerId: string;
  previousStatus: CustomerStatus;
  newStatus: CustomerStatus;
  convertedBy: string;
}

// Обновление метрик
'customer.metrics.updated': {
  customerId: string;
  totalPurchases: number;
  purchaseCount: number;
  lifetimeValue: number;
}

// Слияние клиентов
'customers.merged': {
  primaryCustomerId: string;
  mergedCustomerIds: string[];
}

// Назначение менеджера
'customer.assigned': {
  customerId: string;
  assignedTo: string;
  assignedBy: string;
}
```

### Обрабатываемые события

```typescript
@OnEvent('deal.won')
async handleDealWon(event: DealWonEvent) {
  // Обновляем статус клиента на ACTIVE
  // Обновляем метрики покупок
}

@OnEvent('order.completed')
async handleOrderCompleted(event: OrderCompletedEvent) {
  // Обновляем метрики клиента
  // Пересчитываем lifetime value
}

@OnEvent('invoice.paid')
async handleInvoicePaid(event: InvoicePaidEvent) {
  // Обновляем баланс клиента
  // Обновляем дату последней покупки
}
```

## 🔐 Безопасность и валидация

### Валидация ИИН/БИН

```typescript
@ValidatorConstraint({ name: 'IINValidator', async: false })
export class IINValidator implements ValidatorConstraintInterface {
  validate(iin: string): boolean {
    if (!iin || iin.length !== 12) return false;
    
    // Проверяем что все символы - цифры
    if (!/^\d{12}$/.test(iin)) return false;
    
    // Проверяем контрольную сумму по алгоритму
    const weights1 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    const weights2 = [3, 4, 5, 6, 7, 8, 9, 10, 11, 1, 2];
    
    let sum = 0;
    for (let i = 0; i < 11; i++) {
      sum += parseInt(iin[i]) * weights1[i];
    }
    
    let checkDigit = sum % 11;
    
    if (checkDigit === 10) {
      sum = 0;
      for (let i = 0; i < 11; i++) {
        sum += parseInt(iin[i]) * weights2[i];
      }
      checkDigit = sum % 11;
    }
    
    return checkDigit === parseInt(iin[11]);
  }

  defaultMessage(): string {
    return 'Invalid IIN format or checksum';
  }
}

@ValidatorConstraint({ name: 'BINValidator', async: false })
export class BINValidator implements ValidatorConstraintInterface {
  validate(bin: string): boolean {
    if (!bin || bin.length !== 12) return false;
    
    // Проверяем что все символы - цифры
    if (!/^\d{12}$/.test(bin)) return false;
    
    // Проверяем тип юрлица (4-5 позиции)
    const entityType = bin.substring(3, 5);
    const validTypes = ['00', '01', '02', '03', '04', '05'];
    
    return validTypes.includes(entityType);
  }

  defaultMessage(): string {
    return 'Invalid BIN format';
  }
}
```

### Проверка дубликатов

```typescript
async checkDuplicates(dto: CheckDuplicateDto): Promise<DuplicateResult> {
  const duplicates = [];
  
  // Проверяем по email
  if (dto.email) {
    const byEmail = await this.customerRepository.findOne({
      where: { 
        email: dto.email,
        organizationId: dto.organizationId
      }
    });
    if (byEmail) duplicates.push({ field: 'email', customer: byEmail });
  }
  
  // Проверяем по ИИН
  if (dto.iin) {
    const byIIN = await this.customerRepository.findOne({
      where: { 
        iin: dto.iin,
        organizationId: dto.organizationId
      }
    });
    if (byIIN) duplicates.push({ field: 'iin', customer: byIIN });
  }
  
  // Проверяем по БИН
  if (dto.bin) {
    const byBIN = await this.customerRepository.findOne({
      where: { 
        bin: dto.bin,
        organizationId: dto.organizationId
      }
    });
    if (byBIN) duplicates.push({ field: 'bin', customer: byBIN });
  }
  
  // Проверяем по телефону
  if (dto.phone) {
    const normalizedPhone = this.normalizePhone(dto.phone);
    const byPhone = await this.customerRepository.findOne({
      where: { 
        phone: normalizedPhone,
        organizationId: dto.organizationId
      }
    });
    if (byPhone) duplicates.push({ field: 'phone', customer: byPhone });
  }
  
  return {
    hasDuplicates: duplicates.length > 0,
    duplicates,
    suggestedAction: duplicates.length > 0 ? 'merge' : 'create'
  };
}
```

## 📊 Аналитика и отчеты

### Customer Analytics

```typescript
interface CustomerAnalytics {
  // Общие метрики
  totalPurchases: number;
  purchaseCount: number;
  averageOrderValue: number;
  lifetimeValue: number;
  
  // Временные метрики
  firstPurchaseDate: Date;
  lastPurchaseDate: Date;
  daysSinceLastPurchase: number;
  purchaseFrequency: number; // покупок в месяц
  
  // Метрики по категориям
  topCategories: {
    category: string;
    amount: number;
    count: number;
  }[];
  
  // Метрики по продуктам
  topProducts: {
    productId: string;
    productName: string;
    quantity: number;
    amount: number;
  }[];
  
  // Финансовые метрики
  totalRevenue: number;
  totalProfit: number;
  profitMargin: number;
  outstandingBalance: number;
  creditUtilization: number;
  
  // Поведенческие метрики
  churnProbability: number;
  nextPurchasePrediction: Date;
  recommendedProducts: string[];
  
  // Метрики взаимодействия
  totalInteractions: number;
  lastInteractionDate: Date;
  preferredChannel: string;
  responseRate: number;
}
```

### Сегментация клиентов

```typescript
export enum CustomerSegment {
  VIP = 'VIP',                    // Высокая ценность, частые покупки
  LOYAL = 'LOYAL',                // Постоянные клиенты
  PROMISING = 'PROMISING',        // Потенциал роста
  NEW = 'NEW',                    // Новые клиенты
  AT_RISK = 'AT_RISK',           // Риск потери
  DORMANT = 'DORMANT',           // Спящие клиенты
  LOST = 'LOST'                  // Потерянные клиенты
}

async segmentCustomers(): Promise<Map<CustomerSegment, Customer[]>> {
  const segments = new Map<CustomerSegment, Customer[]>();
  
  const customers = await this.customerRepository.find({
    where: { isActive: true }
  });
  
  for (const customer of customers) {
    const segment = this.determineSegment(customer);
    
    if (!segments.has(segment)) {
      segments.set(segment, []);
    }
    
    segments.get(segment).push(customer);
  }
  
  return segments;
}

private determineSegment(customer: Customer): CustomerSegment {
  const daysSinceLastPurchase = customer.lastPurchaseDate
    ? Math.floor((Date.now() - customer.lastPurchaseDate.getTime()) / (1000 * 60 * 60 * 24))
    : Infinity;
  
  // VIP: высокая ценность + недавние покупки
  if (customer.lifetimeValue > 10000000 && daysSinceLastPurchase < 30) {
    return CustomerSegment.VIP;
  }
  
  // LOYAL: регулярные покупки
  if (customer.purchaseCount > 10 && daysSinceLastPurchase < 60) {
    return CustomerSegment.LOYAL;
  }
  
  // NEW: первая покупка в последние 30 дней
  if (customer.purchaseCount === 1 && daysSinceLastPurchase < 30) {
    return CustomerSegment.NEW;
  }
  
  // PROMISING: мало покупок, но недавняя активность
  if (customer.purchaseCount < 5 && daysSinceLastPurchase < 45) {
    return CustomerSegment.PROMISING;
  }
  
  // AT_RISK: были активны, но давно не покупали
  if (customer.purchaseCount > 5 && daysSinceLastPurchase > 90) {
    return CustomerSegment.AT_RISK;
  }
  
  // DORMANT: очень давно не покупали
  if (daysSinceLastPurchase > 180) {
    return CustomerSegment.DORMANT;
  }
  
  // LOST: статус CHURNED или неактивны больше года
  if (customer.status === CustomerStatus.CHURNED || daysSinceLastPurchase > 365) {
    return CustomerSegment.LOST;
  }
  
  return CustomerSegment.PROMISING;
}
```

## 🔄 Интеграция с другими модулями

### Deals Module
- Автоматическое создание сделки при конвертации лида
- Обновление метрик клиента при выигрыше сделки
- Синхронизация контактной информации

### Orders Module
- Обновление истории покупок
- Расчет lifetime value
- Применение персональных скидок

### Finance Module
- Управление кредитным лимитом
- Отслеживание баланса
- История платежей

### Marketing Module
- Сегментация для кампаний
- Персонализированные предложения
- Email маркетинг

### Analytics Module
- RFM анализ (Recency, Frequency, Monetary)
- Прогнозирование оттока
- Кросс-продажи и апсейл

## 🎨 Примеры использования

### Создание B2B клиента

```typescript
const customer = await customersService.create({
  type: CustomerType.COMPANY,
  name: 'ТОО Альфа',
  email: 'info@alpha.kz',
  phone: '+77012345678',
  bin: '123456789012',
  companyName: 'ТОО Альфа',
  companySize: '51-200',
  industry: 'Manufacturing',
  creditLimit: 5000000,
  status: CustomerStatus.PROSPECT,
  contacts: [
    {
      firstName: 'Асет',
      lastName: 'Жумабеков',
      position: 'Директор',
      email: 'aset@alpha.kz',
      phone: '+77011111111',
      isPrimary: true,
      isDecisionMaker: true
    }
  ],
  addresses: [
    {
      type: AddressType.BILLING,
      street: 'ул. Абая, 150',
      city: 'Алматы',
      postalCode: '050000',
      country: 'Kazakhstan',
      isPrimary: true
    },
    {
      type: AddressType.SHIPPING,
      street: 'ул. Розыбакиева, 247',
      city: 'Алматы',
      postalCode: '050060',
      country: 'Kazakhstan'
    }
  ],
  customFields: {
    preferredDeliveryTime: '09:00-18:00',
    taxExempt: false
  },
  tags: ['manufacturing', 'premium', 'almaty']
}, userId);
```

### Поиск и фильтрация

```typescript
const customers = await customersService.findAll(workspaceId, {
  type: CustomerType.COMPANY,
  status: CustomerStatus.ACTIVE,
  industry: 'Manufacturing',
  minPurchases: 100000,
  tags: ['premium'],
  city: 'Алматы',
  sortBy: 'totalPurchases',
  sortOrder: 'DESC',
  page: 1,
  limit: 20
});
```

### Конвертация лида в клиента

```typescript
const converted = await customersService.convertLeadToCustomer(leadId, {
  assignedTo: managerId,
  createDeal: true,
  dealTitle: 'Первая сделка с ТОО Альфа',
  dealValue: 1000000,
  convertedBy: userId
});
```

## 🚀 Оптимизация производительности

### Индексы
- Составной индекс по (organizationId, workspaceId)
- Уникальные индексы по email, iin, bin
- Индекс по status для быстрой фильтрации
- Индекс по assignedTo для фильтрации по менеджеру
- GIN индекс по tags для поиска по тегам
- GIN индекс по customFields для JSONB запросов

### Кеширование
- Redis кеш для списков клиентов (TTL: 5 минут)
- Кеш отдельных клиентов (TTL: 10 минут)
- Инвалидация при изменениях

### Lazy Loading
- Отложенная загрузка deals, orders, invoices
- Загрузка только при необходимости
- Снижение нагрузки на память

### Batch операции
- Массовое создание до 100 клиентов
- Массовое обновление статусов
- Массовое удаление

## 📈 Метрики и мониторинг

### Ключевые метрики
- Количество активных клиентов
- Коэффициент конверсии лидов
- Средний lifetime value
- Коэффициент оттока (churn rate)
- Среднее время конверсии лида

### Логирование
- Все операции CRUD
- Изменения статусов
- Слияние дубликатов
- Ошибки валидации

### Аудит
- История всех изменений
- Кто и когда вносил изменения
- Старые и новые значения

---

© 2025 Prometric ERP. Customer Module Documentation.