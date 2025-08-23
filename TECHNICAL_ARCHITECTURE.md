# 🔧 PROMETRIC ERP - ТЕХНИЧЕСКАЯ АРХИТЕКТУРА

## 📋 СОДЕРЖАНИЕ

1. [Обзор архитектуры](#обзор-архитектуры)
2. [Backend архитектура](#backend-архитектура)
3. [База данных](#база-данных)
4. [Event-Driven архитектура](#event-driven-архитектура)
5. [Безопасность](#безопасность)
6. [Масштабирование](#масштабирование)
7. [Deployment](#deployment)

---

## 🏗️ ОБЗОР АРХИТЕКТУРЫ

### Микросервисная архитектура

```
┌─────────────────────────────────────────────────────────────┐
│                     Load Balancer (Nginx)                   │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Frontend   │     │   Backend    │     │  AI Service  │
│   (Next.js)  │     │   (NestJS)   │     │  (Node.js)   │
│   Port 3000  │     │   Port 5001  │     │  Port 8080   │
└──────────────┘     └──────────────┘     └──────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
            ┌──────────────┐   ┌──────────────┐
            │  PostgreSQL  │   │    Redis     │
            │   AWS RDS    │   │    Cache     │
            └──────────────┘   └──────────────┘
```

### Технологический стек

#### Backend (NestJS)
```typescript
// Основные зависимости
{
  "@nestjs/core": "^10.0.0",
  "@nestjs/platform-express": "^10.0.0",
  "@nestjs/typeorm": "^10.0.0",
  "@nestjs/cqrs": "^10.0.0",
  "@nestjs/swagger": "^7.0.0",
  "@nestjs/websockets": "^10.0.0",
  "@nestjs/bull": "^10.0.0",
  "typeorm": "^0.3.17",
  "pg": "^8.11.0",
  "redis": "^4.6.0",
  "bull": "^4.11.0",
  "socket.io": "^4.6.0",
  "bcrypt": "^5.1.0",
  "jsonwebtoken": "^9.0.0"
}
```

#### Frontend (Next.js)
```typescript
{
  "next": "^14.0.0",
  "react": "^18.2.0",
  "typescript": "^5.0.0",
  "@tanstack/react-query": "^5.0.0",
  "zustand": "^4.4.0",
  "tailwindcss": "^3.3.0",
  "framer-motion": "^10.0.0",
  "recharts": "^2.9.0",
  "react-hook-form": "^7.47.0",
  "zod": "^3.22.0"
}
```

---

## 🎯 BACKEND АРХИТЕКТУРА

### Структура модулей

```
src/
├── auth/                 # Аутентификация и авторизация
│   ├── application/      # CQRS команды и запросы
│   ├── domain/          # Доменная логика
│   ├── infrastructure/  # Контроллеры и сервисы
│   └── guards/          # Guards для защиты роутов
│
├── organizations/       # Управление организациями
│   ├── controllers/
│   ├── services/
│   ├── entities/
│   └── dto/
│
├── workspaces/         # Рабочие пространства
│   ├── controllers/
│   ├── services/
│   └── entities/
│
├── customers/          # CRM модуль
│   ├── controllers/
│   ├── services/
│   ├── entities/
│   └── events/
│
├── deals/              # Управление сделками
│   ├── controllers/
│   ├── services/
│   ├── entities/
│   └── orchestrators/
│
├── products/           # Продукты и инвентарь
│   ├── controllers/
│   ├── services/
│   ├── entities/
│   └── repositories/
│
├── orders/             # Заказы
│   ├── controllers/
│   ├── services/
│   └── entities/
│
├── production/         # Производство
│   ├── controllers/
│   ├── services/
│   ├── adapters/
│   └── entities/
│
├── finance/            # Финансовый модуль
│   ├── controllers/
│   ├── services/
│   └── entities/
│
├── hr/                 # HR модуль
│   ├── controllers/
│   ├── services/
│   └── entities/
│
├── tasks/              # Управление задачами
│   ├── controllers/
│   ├── services/
│   ├── domain/
│   └── listeners/
│
├── documents/          # Документооборот
│   ├── controllers/
│   ├── services/
│   └── listeners/
│
├── notifications/      # Уведомления
│   ├── services/
│   ├── listeners/
│   └── websockets/
│
├── analytics/          # Аналитика
│   ├── services/
│   └── listeners/
│
├── orchestrators/      # Event orchestrators
│   ├── deal-won.orchestrator.ts
│   └── order-fulfillment.orchestrator.ts
│
├── infrastructure/     # Инфраструктурный слой
│   ├── redis/
│   ├── websocket/
│   └── database/
│
└── shared/            # Общие компоненты
    ├── decorators/
    ├── filters/
    ├── interceptors/
    └── utils/
```

### CQRS Pattern

```typescript
// Пример команды
export class CreateDealCommand {
  constructor(
    public readonly workspaceId: string,
    public readonly customerId: string,
    public readonly title: string,
    public readonly value: number,
    public readonly products: DealProduct[]
  ) {}
}

// Пример обработчика команды
@CommandHandler(CreateDealCommand)
export class CreateDealHandler implements ICommandHandler<CreateDealCommand> {
  constructor(
    private readonly dealsService: DealsService,
    private readonly eventBus: EventBus
  ) {}

  async execute(command: CreateDealCommand): Promise<Deal> {
    const deal = await this.dealsService.create(command);
    
    // Публикуем событие
    this.eventBus.publish(new DealCreatedEvent(deal));
    
    return deal;
  }
}
```

### Domain-Driven Design

```typescript
// Aggregate Root
@Entity('deals')
export class Deal extends BaseEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column('decimal', { precision: 10, scale: 2 })
  value: number;

  @Column({
    type: 'enum',
    enum: DealStage,
    default: DealStage.NEW
  })
  stage: DealStage;

  @ManyToOne(() => Customer)
  @JoinColumn({ name: 'customerId' })
  customer: Customer;

  @OneToMany(() => DealProduct, dp => dp.deal)
  products: DealProduct[];

  // Domain methods
  public moveToWon(): void {
    if (this.stage === DealStage.WON) {
      throw new Error('Deal is already won');
    }
    
    this.stage = DealStage.WON;
    this.wonAt = new Date();
    this.actualCloseDate = new Date();
    this.probability = 100;
  }

  public moveToLost(reason: string): void {
    this.stage = DealStage.LOST;
    this.lostAt = new Date();
    this.lostReason = reason;
    this.probability = 0;
  }
}
```

---

## 🗄️ БАЗА ДАННЫХ

### Структура основных таблиц

```sql
-- Organizations
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  bin VARCHAR(12) UNIQUE NOT NULL,
  "ownerId" UUID REFERENCES users(id),
  "isActive" BOOLEAN DEFAULT true,
  "createdAt" TIMESTAMP DEFAULT NOW(),
  "updatedAt" TIMESTAMP DEFAULT NOW()
);

-- Workspaces
CREATE TABLE workspaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'personal' | 'company'
  "ownerId" UUID REFERENCES users(id),
  "organizationId" UUID REFERENCES organizations(id),
  "isActive" BOOLEAN DEFAULT true,
  "createdAt" TIMESTAMP DEFAULT NOW()
);

-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  "firstName" VARCHAR(100),
  "lastName" VARCHAR(100),
  status VARCHAR(50) DEFAULT 'active',
  "registrationStatus" VARCHAR(50) DEFAULT 'pending',
  "emailVerified" BOOLEAN DEFAULT false,
  "createdAt" TIMESTAMP DEFAULT NOW()
);

-- Employees
CREATE TABLE employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "userId" UUID REFERENCES users(id),
  "organizationId" UUID REFERENCES organizations(id),
  "workspaceId" UUID REFERENCES workspaces(id),
  name VARCHAR(255),
  email VARCHAR(255),
  position VARCHAR(100),
  status VARCHAR(50) DEFAULT 'pending',
  "organizationRole" VARCHAR(50),
  "departmentId" UUID REFERENCES departments(id),
  "createdAt" TIMESTAMP DEFAULT NOW()
);

-- Customers
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "workspaceId" UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50), -- 'INDIVIDUAL' | 'COMPANY'
  email VARCHAR(255),
  phone VARCHAR(50),
  "contactPerson" VARCHAR(255),
  address TEXT,
  "createdAt" TIMESTAMP DEFAULT NOW()
);

-- Deals
CREATE TABLE deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "workspaceId" UUID NOT NULL,
  "customerId" UUID REFERENCES customers(id),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  value DECIMAL(10, 2),
  stage VARCHAR(50) DEFAULT 'NEW',
  probability INTEGER DEFAULT 0,
  "expectedCloseDate" TIMESTAMP,
  "actualCloseDate" TIMESTAMP,
  "wonAt" TIMESTAMP,
  "lostAt" TIMESTAMP,
  "lostReason" TEXT,
  "assignedTo" UUID REFERENCES employees(id),
  "createdAt" TIMESTAMP DEFAULT NOW()
);

-- Products
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "workspaceId" UUID NOT NULL,
  "organizationId" UUID,
  name VARCHAR(255) NOT NULL,
  code VARCHAR(50) UNIQUE,
  description TEXT,
  unit VARCHAR(50),
  price DECIMAL(10, 2),
  cost DECIMAL(10, 2),
  status VARCHAR(50) DEFAULT 'ACTIVE',
  "vatRate" DECIMAL(5, 2),
  "vatIncluded" BOOLEAN DEFAULT true,
  "createdAt" TIMESTAMP DEFAULT NOW()
);

-- Orders
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "workspaceId" UUID NOT NULL,
  "orderNumber" VARCHAR(50) UNIQUE,
  "customerId" UUID REFERENCES customers(id),
  "dealId" UUID REFERENCES deals(id),
  status VARCHAR(50) DEFAULT 'pending',
  "totalAmount" DECIMAL(10, 2),
  "createdAt" TIMESTAMP DEFAULT NOW()
);
```

### Индексы для оптимизации

```sql
-- Performance indexes
CREATE INDEX idx_deals_workspace ON deals("workspaceId");
CREATE INDEX idx_deals_customer ON deals("customerId");
CREATE INDEX idx_deals_stage ON deals(stage);
CREATE INDEX idx_deals_created ON deals("createdAt");

CREATE INDEX idx_orders_workspace ON orders("workspaceId");
CREATE INDEX idx_orders_deal ON orders("dealId");
CREATE INDEX idx_orders_status ON orders(status);

CREATE INDEX idx_customers_workspace ON customers("workspaceId");
CREATE INDEX idx_products_workspace ON products("workspaceId");
```

---

## 📡 EVENT-DRIVEN АРХИТЕКТУРА

### Event Bus (EventEmitter2)

```typescript
// Конфигурация EventEmitter2
@Module({
  imports: [
    EventEmitterModule.forRoot({
      wildcard: true,
      delimiter: '.',
      newListener: false,
      removeListener: false,
      maxListeners: 10,
      verboseMemoryLeak: false,
      ignoreErrors: false,
    }),
  ],
})
export class AppModule {}
```

### События системы

```typescript
// Событие выигранной сделки
export class DealWonEvent {
  constructor(
    public readonly dealId: string,
    public readonly workspaceId: string,
    public readonly customerId: string,
    public readonly value: number,
    public readonly products: DealProduct[]
  ) {}
}

// Оркестратор для обработки события
@Injectable()
export class DealWonOrchestrator {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly invoicesService: InvoicesService,
    private readonly notificationsService: NotificationsService,
    private readonly eventEmitter: EventEmitter2
  ) {}

  @OnEvent('deal.won')
  async handleDealWon(event: DealWonEvent) {
    try {
      // 1. Создаем заказ
      const order = await this.ordersService.createFromDeal({
        dealId: event.dealId,
        customerId: event.customerId,
        workspaceId: event.workspaceId,
        items: event.products
      });

      // 2. Создаем счет
      const invoice = await this.invoicesService.create({
        orderId: order.id,
        customerId: event.customerId,
        amount: event.value
      });

      // 3. Отправляем уведомления
      await this.notificationsService.notifyDealWon(event);

      // 4. Публикуем событие создания заказа
      this.eventEmitter.emit('order.created', {
        orderId: order.id,
        dealId: event.dealId
      });

    } catch (error) {
      console.error('Failed to process deal.won event:', error);
      // Implement retry logic or dead letter queue
    }
  }
}
```

### WebSocket Real-time Updates

```typescript
@WebSocketGateway({
  cors: {
    origin: process.env.FRONTEND_URL,
    credentials: true
  }
})
export class RealtimeGateway {
  @WebSocketServer()
  server: Server;

  @SubscribeMessage('subscribe')
  handleSubscribe(client: Socket, payload: { workspaceId: string }) {
    client.join(`workspace:${payload.workspaceId}`);
  }

  // Отправка обновлений
  sendUpdate(workspaceId: string, event: string, data: any) {
    this.server
      .to(`workspace:${workspaceId}`)
      .emit(event, data);
  }
}
```

---

## 🔐 БЕЗОПАСНОСТЬ

### JWT Authentication

```typescript
// JWT Strategy
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private configService: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get('JWT_SECRET'),
    });
  }

  async validate(payload: JwtPayload) {
    return {
      userId: payload.sub,
      email: payload.email,
      workspaceId: payload.workspaceId,
      organizationId: payload.organizationId,
      role: payload.role
    };
  }
}
```

### Guards и Decorators

```typescript
// Role-based guard
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()]
    );
    
    if (!requiredRoles) {
      return true;
    }
    
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some((role) => user.roles?.includes(role));
  }
}

// Workspace isolation
@Injectable()
export class WorkspaceGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const workspaceId = request.params.workspaceId;
    const userWorkspaceId = request.user.workspaceId;
    
    return workspaceId === userWorkspaceId;
  }
}
```

### Data Validation

```typescript
// DTO validation with class-validator
export class CreateDealDto {
  @IsNotEmpty()
  @IsString()
  title: string;

  @IsUUID()
  customerId: string;

  @IsNumber()
  @Min(0)
  value: number;

  @IsEnum(DealStage)
  stage: DealStage;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => DealProductDto)
  products: DealProductDto[];
}
```

---

## 📈 МАСШТАБИРОВАНИЕ

### Horizontal Scaling

```yaml
# docker-compose.yml для масштабирования
version: '3.8'

services:
  backend:
    image: prometric-backend
    deploy:
      replicas: 3
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
    ports:
      - "5001-5003:5001"

  nginx:
    image: nginx
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    ports:
      - "80:80"
    depends_on:
      - backend
```

### Caching Strategy

```typescript
// Redis caching
@Injectable()
export class CacheService {
  constructor(
    @Inject(CACHE_MANAGER) private cacheManager: Cache
  ) {}

  async get<T>(key: string): Promise<T | null> {
    return await this.cacheManager.get<T>(key);
  }

  async set<T>(key: string, value: T, ttl?: number): Promise<void> {
    await this.cacheManager.set(key, value, ttl);
  }

  async invalidate(pattern: string): Promise<void> {
    const keys = await this.cacheManager.store.keys(pattern);
    await Promise.all(keys.map(key => this.cacheManager.del(key)));
  }
}

// Usage in service
@Injectable()
export class ProductsService {
  constructor(private cacheService: CacheService) {}

  async findAll(workspaceId: string): Promise<Product[]> {
    const cacheKey = `products:${workspaceId}`;
    
    // Try cache first
    const cached = await this.cacheService.get<Product[]>(cacheKey);
    if (cached) return cached;
    
    // Fetch from DB
    const products = await this.productsRepository.find({
      where: { workspaceId }
    });
    
    // Cache for 5 minutes
    await this.cacheService.set(cacheKey, products, 300);
    
    return products;
  }
}
```

### Queue Processing (Bull)

```typescript
// Queue processor for heavy tasks
@Processor('reports')
export class ReportsProcessor {
  @Process('generate')
  async generateReport(job: Job<ReportJobData>) {
    const { workspaceId, type, params } = job.data;
    
    // Heavy processing
    const report = await this.analyticsService.generateReport(
      workspaceId,
      type,
      params
    );
    
    // Save to S3
    const url = await this.s3Service.uploadReport(report);
    
    // Notify user
    await this.notificationService.notifyReportReady(
      job.data.userId,
      url
    );
    
    return { url };
  }
}
```

---

## 🚀 DEPLOYMENT

### Production Configuration

```env
# Production .env
NODE_ENV=production

# Database
DATABASE_HOST=prometric.cde42ec8m1u7.eu-north-1.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_USERNAME=prometric
DATABASE_PASSWORD=<secure-password>
DATABASE_NAME=prometric
DATABASE_SSL=true

# Redis
REDIS_HOST=redis-cluster.aws.com
REDIS_PORT=6379
REDIS_PASSWORD=<secure-password>

# JWT
JWT_SECRET=<long-random-string>
JWT_EXPIRATION=24h
REFRESH_TOKEN_EXPIRATION=7d

# AWS
AWS_REGION=eu-north-1
AWS_ACCESS_KEY_ID=<access-key>
AWS_SECRET_ACCESS_KEY=<secret-key>
S3_BUCKET=prometric-files

# Google Cloud (AI)
GOOGLE_APPLICATION_CREDENTIALS=./google-vertex.json

# Monitoring
SENTRY_DSN=https://xxx@sentry.io/xxx
NEW_RELIC_LICENSE_KEY=xxx
```

### CI/CD Pipeline (GitHub Actions)

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
      - run: npm run test:e2e

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build Docker image
        run: docker build -t prometric-backend .
      
      - name: Push to Registry
        run: |
          docker tag prometric-backend:latest registry.railway.app/prometric-backend:latest
          docker push registry.railway.app/prometric-backend:latest
      
      - name: Deploy to Railway
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
        run: railway up
```

### Monitoring

```typescript
// Health checks
@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
    private redis: RedisHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.db.pingCheck('database'),
      () => this.redis.pingCheck('redis'),
    ]);
  }
}

// Metrics collection
@Injectable()
export class MetricsService {
  private readonly metrics = new Map<string, number>();

  increment(key: string, value = 1) {
    const current = this.metrics.get(key) || 0;
    this.metrics.set(key, current + value);
  }

  async flush() {
    // Send to monitoring service
    await this.sendToNewRelic(this.metrics);
    this.metrics.clear();
  }
}
```

---

## 📊 PERFORMANCE OPTIMIZATION

### Database Optimization

```typescript
// Query optimization with relations
async findDealWithDetails(dealId: string): Promise<Deal> {
  return this.dealsRepository.findOne({
    where: { id: dealId },
    relations: {
      customer: true,
      products: {
        product: true
      },
      assignedTo: true
    },
    select: {
      customer: {
        id: true,
        name: true,
        email: true
      },
      products: {
        id: true,
        quantity: true,
        unitPrice: true,
        product: {
          id: true,
          name: true,
          code: true
        }
      }
    }
  });
}

// Batch processing
async processBatch<T>(
  items: T[],
  processor: (item: T) => Promise<void>,
  batchSize = 100
): Promise<void> {
  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    await Promise.all(batch.map(processor));
  }
}
```

### API Response Optimization

```typescript
// Pagination
export class PaginationDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

// Response compression
app.use(compression());

// Response caching
@Get()
@CacheKey('products-list')
@CacheTTL(300)
async findAll(@Query() pagination: PaginationDto) {
  return this.productsService.findAll(pagination);
}
```

---

## 🔄 MIGRATION STRATEGY

### Database Migrations

```typescript
// TypeORM migration example
export class AddDealWonAt1234567890 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.addColumn('deals', new TableColumn({
      name: 'wonAt',
      type: 'timestamp',
      isNullable: true
    }));
    
    // Update existing WON deals
    await queryRunner.query(`
      UPDATE deals 
      SET "wonAt" = "updatedAt" 
      WHERE stage = 'WON' AND "wonAt" IS NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropColumn('deals', 'wonAt');
  }
}
```

---

## 📝 ЗАКЛЮЧЕНИЕ

Техническая архитектура Prometric ERP построена на современных принципах:

- ✅ **Микросервисная архитектура** для масштабируемости
- ✅ **Event-driven подход** для слабой связанности
- ✅ **CQRS pattern** для разделения команд и запросов
- ✅ **Domain-Driven Design** для бизнес-логики
- ✅ **Multi-tenancy** через workspace isolation
- ✅ **Horizontal scaling** готовность
- ✅ **Comprehensive monitoring** и health checks
- ✅ **Security best practices** на всех уровнях

Система готова к production использованию и может масштабироваться под нагрузки enterprise-уровня.

---

*© 2025 Prometric ERP Technical Documentation v1.0.0*