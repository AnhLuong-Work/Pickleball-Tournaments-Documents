# Coding Convention - .NET & PostgreSQL

## Mục đích
Tài liệu này định nghĩa các quy chuẩn code và database cho dự án Call Center SaaS sử dụng .NET và PostgreSQL.

---

## 1. NAMING CONVENTIONS

### 1.1. Database (PostgreSQL)

#### Tables
- **Format**: `snake_case` (chữ thường, phân cách bằng gạch dưới)
- **Số nhiều**: Tên bảng luôn ở dạng số nhiều
- **Ví dụ**:
  ```sql
  users
  service_packages
  payment_history
  call_logs
  chat_sessions
  ```

#### Columns
- **Format**: `snake_case`
- **Boolean**: Prefix với `is_`, `has_`, `can_`
- **Timestamps**: Suffix với `_at` hoặc `_date`
- **Foreign Keys**: `{table_singular}_id`
- **Ví dụ**:
  ```sql
  id
  full_name
  email_address
  is_active
  has_permission
  created_at
  updated_at
  tenant_id
  service_package_id
  ```

#### Indexes
- **Format**: `idx_{table}_{column(s)}`
- **Unique**: `uq_{table}_{column(s)}`
- **Foreign Key**: `fk_{table}_{referenced_table}`
- **Ví dụ**:
  ```sql
  idx_users_email
  idx_users_tenant_id_role
  uq_users_email
  fk_users_tenant
  ```

#### Constraints
- **Primary Key**: `pk_{table}`
- **Foreign Key**: `fk_{table}_{referenced_table}`
- **Check**: `ck_{table}_{column}`
- **Ví dụ**:
  ```sql
  pk_users
  fk_users_tenants
  ck_users_status
  ```

#### Schemas
- **Format**: `snake_case`
- **Tenant Schema**: `tenant_{uuid}`
- **Ví dụ**:
  ```sql
  public
  tenant_123e4567_e89b_12d3_a456_426614174000
  ```

#### Enums
- **Format**: `snake_case`
- **Suffix**: Không bắt buộc nhưng nên có `_type` hoặc `_status`
- **Ví dụ**:
  ```sql
  user_role
  tenant_status
  payment_status
  call_direction
  ```

---

### 1.2. .NET Code

#### Namespaces
- **Format**: `PascalCase`
- **Structure**: `{Company}.{Product}.{Feature}.{SubFeature}`
- **Ví dụ**:
  ```csharp
  CallCenter.Core.Domain.Entities
  CallCenter.Core.Application.Services
  CallCenter.Infrastructure.Persistence
  CallCenter.API.Controllers
  ```

#### Classes
- **Format**: `PascalCase`
- **Singular**: Luôn dùng số ít
- **Suffix**: Theo mục đích
  - Entity: Không suffix
  - DTO: `Dto`
  - Request/Response: `Request`, `Response`
  - Service: `Service`
  - Repository: `Repository`
  - Controller: `Controller`
  - Validator: `Validator`
- **Ví dụ**:
  ```csharp
  User
  Tenant
  ServicePackage
  CreateUserDto
  LoginRequest
  LoginResponse
  UserService
  UserRepository
  UsersController
  CreateUserValidator
  ```

#### Interfaces
- **Format**: `PascalCase`
- **Prefix**: `I`
- **Ví dụ**:
  ```csharp
  IUserService
  IUserRepository
  IUnitOfWork
  IEmailService
  ```

#### Methods
- **Format**: `PascalCase`
- **Verb-first**: Bắt đầu bằng động từ
- **Async suffix**: Thêm `Async` cho async methods
- **Ví dụ**:
  ```csharp
  GetUserById()
  CreateUser()
  UpdateUserStatus()
  DeleteUser()
  GetUserByIdAsync()
  CreateUserAsync()
  ```

#### Properties
- **Format**: `PascalCase`
- **Boolean**: Prefix với `Is`, `Has`, `Can`
- **Ví dụ**:
  ```csharp
  Id
  FullName
  EmailAddress
  IsActive
  HasPermission
  CanEdit
  CreatedAt
  UpdatedAt
  ```

#### Fields
- **Private**: `_camelCase` (prefix với underscore)
- **Const**: `PascalCase`
- **Static readonly**: `PascalCase`
- **Ví dụ**:
  ```csharp
  private readonly IUserService _userService;
  private string _userName;
  public const int MaxRetryCount = 3;
  public static readonly string DefaultRole = "User";
  ```

#### Parameters
- **Format**: `camelCase`
- **Ví dụ**:
  ```csharp
  public User GetUserById(Guid userId)
  public void CreateUser(CreateUserDto createUserDto)
  ```

#### Local Variables
- **Format**: `camelCase`
- **Ví dụ**:
  ```csharp
  var user = await _userService.GetUserByIdAsync(userId);
  var isValid = ValidateUser(user);
  ```

#### Enums
- **Enum Name**: `PascalCase`, singular
- **Enum Values**: `PascalCase`
- **Ví dụ**:
  ```csharp
  public enum UserRole
  {
      SuperAdmin,
      TenantAdmin,
      Employee,
      Customer
  }
  
  public enum TenantStatus
  {
      Active,
      Trial,
      Suspended,
      Expired
  }
  ```

---

## 2. DATABASE CONVENTIONS

### 2.1. Data Types

#### PostgreSQL → .NET Mapping
```
PostgreSQL              .NET Type
─────────────────────────────────────
UUID                    Guid
VARCHAR(n)              string
TEXT                    string
INTEGER                 int
BIGINT                  long
DECIMAL(p,s)            decimal
BOOLEAN                 bool
TIMESTAMP               DateTime
DATE                    DateOnly (.NET 6+) / DateTime
TIME                    TimeOnly (.NET 6+) / TimeSpan
JSONB                   string / JsonDocument / custom class
ENUM                    enum (với Npgsql)
```

#### Recommended Types
```sql
-- IDs
id UUID PRIMARY KEY DEFAULT gen_random_uuid()

-- Strings
email VARCHAR(255)
phone VARCHAR(20)
name VARCHAR(255)
description TEXT

-- Numbers
price DECIMAL(15,2)
quantity INTEGER
storage_gb DECIMAL(10,2)

-- Dates (luôn dùng TIMESTAMPTZ để đảm bảo UTC)
created_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
updated_at TIMESTAMPTZ
start_date DATE
end_date DATE

-- Boolean
is_active BOOLEAN NOT NULL DEFAULT TRUE
is_deleted BOOLEAN NOT NULL DEFAULT FALSE

-- JSON
metadata JSONB
settings JSONB
```

### 2.2. Primary Keys
- **Always use UUID**: `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
- **Never use**: SERIAL, auto-increment integers
- **Why**: Better for distributed systems, multi-tenant, security

### 2.3. Foreign Keys
- **Always define**: Explicit FK constraints
- **Naming**: `{table_singular}_id`
- **On Delete**: Specify behavior
  ```sql
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE
  user_id UUID REFERENCES users(id) ON DELETE SET NULL
  ```

### 2.4. Timestamps
- **Standard columns**: Mọi bảng nên có
  ```sql
  created_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  updated_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id),
  updated_by UUID REFERENCES users(id)
  ```

- **Soft Delete**: Thêm cho bảng quan trọng
  ```sql
  deleted_at TIMESTAMPTZ,
  deleted_by UUID REFERENCES users(id)
  ```

> ⚠️ **Lưu ý:** `updated_at` KHÔNG có default value. Nó được set bởi `SaveChangesAsync()` khi entity bị modify, không set khi insert.

### 2.5. Indexes
- **Primary Key**: Tự động có index
- **Foreign Key**: Luôn tạo index
  ```sql
  CREATE INDEX idx_users_tenant_id ON users(tenant_id);
  ```

- **Search fields**: Email, phone, code...
  ```sql
  CREATE INDEX idx_users_email ON users(email);
  CREATE INDEX idx_customers_phone ON customers(phone);
  ```

- **Composite indexes**: Cho queries thường dùng
  ```sql
  CREATE INDEX idx_users_tenant_role ON users(tenant_id, role);
  CREATE INDEX idx_call_logs_employee_date ON call_logs(employee_id, start_time);
  ```

- **Partial indexes**: Cho filtered queries
  ```sql
  CREATE INDEX idx_users_active ON users(id) WHERE is_active = TRUE;
  ```

### 2.6. Constraints
```sql
-- NOT NULL
email VARCHAR(255) NOT NULL

-- UNIQUE
email VARCHAR(255) UNIQUE NOT NULL

-- CHECK
status VARCHAR(20) CHECK (status IN ('active', 'inactive'))
price DECIMAL(15,2) CHECK (price >= 0)

-- DEFAULT
is_active BOOLEAN NOT NULL DEFAULT TRUE
created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
```

---

## 3. .NET CODE CONVENTIONS

### 3.1. Project Structure (Clean Architecture)
```
ServiceName.sln
│
├── ServiceName.Domain/
│   ├── Common/          # BaseEntity, BaseCreatedEntity
│   ├── Entities/
│   └── Enums/
│
├── ServiceName.Application/
│   ├── Common/
│   │   ├── Behaviours/   # Logging, Validation pipeline
│   │   ├── Exceptions/
│   │   ├── Interfaces/   # IRepository, IUnitOfWork
│   │   ├── Services/     # ICurrentUserService, IEmailService
│   │   └── Settings/     # JwtSettings, EmailSettings
│   └── Features/
│       └── {Domain}/
│           ├── Commands/{Name}/  # Command + Handler + Validator
│           ├── Queries/{Name}/   # Query + Handler
│           └── Dtos/
│
├── ServiceName.Infrastructure/
│   ├── Persistence/
│   │   ├── Configurations/   # EF Core IEntityTypeConfiguration
│   │   └── Repositories/     # Repository + UnitOfWork impl
│   └── Services/             # Email, Token services
│
├── ServiceName.Share/
│   ├── Wrappers/     # ApiResponse<T>
│   └── Resources/    # .resx localization files
│
└── ServiceName.Api/
    ├── Controllers/
    ├── Middleware/    # ExceptionHandlerMiddleware
    └── Filters/
```

> **Lưu ý:** Project KHÔNG sử dụng EF Core Migrations. Schema quản lý qua SQL scripts.

### 3.2. Entity Classes
```csharp
using System;

namespace CallCenter.Core.Domain.Entities
{
    /// <summary>
    /// Represents a user in the system
    /// </summary>
    public class User
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public UserRole Role { get; set; }
        public Guid? TenantId { get; set; }
        public UserStatus Status { get; set; }
        public DateTime? LastLogin { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public Guid? CreatedBy { get; set; }
        public Guid? UpdatedBy { get; set; }
        
        // Navigation properties
        public virtual Tenant? Tenant { get; set; }
    }
}
```

### 3.3. Entity Configuration (EF Core)
```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace CallCenter.Infrastructure.Persistence.Configurations
{
    public class UserConfiguration : IEntityTypeConfiguration<User>
    {
        public void Configure(EntityTypeBuilder<User> builder)
        {
            // Table
            builder.ToTable("users");
            
            // Primary Key
            builder.HasKey(u => u.Id);
            builder.Property(u => u.Id)
                .HasColumnName("id")
                .HasDefaultValueSql("gen_random_uuid()");
            
            // Properties
            builder.Property(u => u.Email)
                .HasColumnName("email")
                .HasMaxLength(255)
                .IsRequired();
            
            builder.Property(u => u.PasswordHash)
                .HasColumnName("password_hash")
                .HasMaxLength(255)
                .IsRequired();
            
            builder.Property(u => u.FullName)
                .HasColumnName("full_name")
                .HasMaxLength(255)
                .IsRequired();
            
            builder.Property(u => u.Phone)
                .HasColumnName("phone")
                .HasMaxLength(20);
            
            builder.Property(u => u.Role)
                .HasColumnName("role")
                .HasConversion<string>()
                .IsRequired();
            
            builder.Property(u => u.TenantId)
                .HasColumnName("tenant_id");
            
            builder.Property(u => u.Status)
                .HasColumnName("status")
                .HasConversion<string>()
                .IsRequired();
            
            builder.Property(u => u.LastLogin)
                .HasColumnName("last_login");
            
            builder.Property(u => u.CreatedAt)
                .HasColumnName("created_at")
                .IsRequired();
            
            builder.Property(u => u.UpdatedAt)
                .HasColumnName("updated_at")
                .IsRequired();
            
            builder.Property(u => u.CreatedBy)
                .HasColumnName("created_by");
            
            builder.Property(u => u.UpdatedBy)
                .HasColumnName("updated_by");
            
            // Indexes
            builder.HasIndex(u => u.Email)
                .HasDatabaseName("idx_users_email")
                .IsUnique();
            
            builder.HasIndex(u => u.TenantId)
                .HasDatabaseName("idx_users_tenant_id");
            
            builder.HasIndex(u => u.Role)
                .HasDatabaseName("idx_users_role");
            
            builder.HasIndex(u => new { u.TenantId, u.Role })
                .HasDatabaseName("idx_users_tenant_role");
            
            // Relationships
            builder.HasOne(u => u.Tenant)
                .WithMany()
                .HasForeignKey(u => u.TenantId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
```

### 3.4. Repository Pattern
```csharp
// Interface
public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default);
    Task<IEnumerable<User>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<User>> GetByTenantIdAsync(Guid tenantId, CancellationToken cancellationToken = default);
    Task<User> AddAsync(User user, CancellationToken cancellationToken = default);
    Task UpdateAsync(User user, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}

// Implementation
public class UserRepository : IUserRepository
{
    private readonly ApplicationDbContext _context;
    
    public UserRepository(ApplicationDbContext context)
    {
        _context = context;
    }
    
    public async Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _context.Users
            .Include(u => u.Tenant)
            .FirstOrDefaultAsync(u => u.Id == id, cancellationToken);
    }
    
    public async Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken = default)
    {
        return await _context.Users
            .Include(u => u.Tenant)
            .FirstOrDefaultAsync(u => u.Email == email, cancellationToken);
    }
    
    // ... other methods
}
```

### 3.5. CQRS Handlers (MediatR)
```csharp
// Command
public record CreateUserCommand(string Email, string FullName, string Password) 
    : IRequest<ApiResponse<UserDto>>;

// Handler
public class CreateUserCommandHandler(
    IUserRepository userRepository,
    IUnitOfWork unitOfWork,
    IPasswordHasher passwordHasher,
    IStringLocalizer<SharedResource> localizer)
    : IRequestHandler<CreateUserCommand, ApiResponse<UserDto>>
{
    public async Task<ApiResponse<UserDto>> Handle(
        CreateUserCommand request, CancellationToken ct)
    {
        var existingUser = await userRepository.GetByEmailAsync(request.Email, ct);
        if (existingUser != null)
            return ApiResponse<UserDto>.FailureResponse(
                localizer["User_Email_Already_Exists"],
                errorCode: "EMAIL_EXISTS",
                statusCode: 400);

        var user = new User
        {
            Email = request.Email,
            FullName = request.FullName,
            PasswordHash = passwordHasher.Hash(request.Password),
            CreatedAt = DateTime.UtcNow
        };

        await userRepository.AddAsync(user, ct);
        await unitOfWork.SaveChangesAsync(ct);

        // Map thủ công — không dùng AutoMapper
        var dto = new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            FullName = user.FullName
        };

        return ApiResponse<UserDto>.SuccessResponse(dto, localizer["User_Created"]);
    }
}

// Validator
public class CreateUserCommandValidator : AbstractValidator<CreateUserCommand>
{
    public CreateUserCommandValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage(localizer["Validation_Email_Required"])
            .EmailAddress().WithMessage(localizer["Validation_Email_Invalid"]);

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage(localizer["Validation_Password_Required"])
            .MinimumLength(8);
    }
}
```

### 3.6. DTOs
```csharp
// Read DTO
public class UserDto
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

// Create DTO
public class CreateUserDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public UserRole Role { get; set; }
    public Guid? TenantId { get; set; }
}

// Update DTO
public class UpdateUserDto
{
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public UserStatus? Status { get; set; }
}
```

### 3.7. Validators (FluentValidation)
```csharp
public class CreateUserDtoValidator : AbstractValidator<CreateUserDto>
{
    public CreateUserDtoValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format")
            .MaximumLength(255).WithMessage("Email must not exceed 255 characters");
        
        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(8).WithMessage("Password must be at least 8 characters")
            .Matches(@"[A-Z]").WithMessage("Password must contain at least one uppercase letter")
            .Matches(@"[a-z]").WithMessage("Password must contain at least one lowercase letter")
            .Matches(@"[0-9]").WithMessage("Password must contain at least one number")
            .Matches(@"[\W_]").WithMessage("Password must contain at least one special character");
        
        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Full name is required")
            .MaximumLength(255).WithMessage("Full name must not exceed 255 characters");
        
        RuleFor(x => x.Phone)
            .MaximumLength(20).WithMessage("Phone must not exceed 20 characters")
            .When(x => !string.IsNullOrEmpty(x.Phone));
        
        RuleFor(x => x.Role)
            .IsInEnum().WithMessage("Invalid role");
    }
}
```

### 3.8. Controllers
```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : BaseApiController
{
    public UsersController(IMediator mediator, ILogger<BaseApiController> logger)
        : base(mediator, logger) { }

    [HttpPost]
    [SwaggerOperation(Summary = "Tạo user mới")]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<UserDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserCommand command)
    {
        var result = await _mediator.Send(command);
        return result.Success ? Ok(result) : BadRequest(result);
    }
}
```

---

## 4. BEST PRACTICES

### 4.1. Database

#### ✅ DO
- Luôn dùng UUID cho primary keys
- Luôn có `created_at`, `updated_at`
- Luôn định nghĩa foreign key constraints
- Luôn tạo indexes cho foreign keys
- Dùng ENUM cho các giá trị cố định
- Dùng JSONB cho dữ liệu linh hoạt
- Dùng transactions cho operations phức tạp
- Implement soft delete cho dữ liệu quan trọng

#### ❌ DON'T
- Không dùng SERIAL/auto-increment
- Không lưu password dạng plain text
- Không dùng `SELECT *`
- Không tạo quá nhiều indexes (ảnh hưởng write performance)
- Không lưu file binary trong database
- Không dùng reserved keywords làm tên bảng/cột

### 4.2. .NET Code

#### ✅ DO
- Luôn dùng `async/await` cho I/O operations
- Luôn validate input
- Luôn log errors và important events
- Luôn dùng `CancellationToken`
- Luôn dispose `IDisposable` resources
- Luôn dùng `string.Empty` thay vì `""`
- Luôn dùng nullable reference types (.NET 6+)
- Luôn handle exceptions properly

#### ❌ DON'T
- Không catch exceptions mà không xử lý
- Không return `null` cho collections (return empty)
- Không hardcode connection strings, secrets
- Không dùng `Thread.Sleep()` (dùng `Task.Delay()`)
- Không expose entities trực tiếp qua API (dùng DTOs)
- Không dùng magic strings/numbers

---

## 5. CODE FORMATTING

### 5.1. C# Style
```csharp
// Braces: Allman style (new line)
public class User
{
    public void DoSomething()
    {
        if (condition)
        {
            // code
        }
    }
}

// Spacing
public void Method(int param1, string param2)  // Space after comma
{
    var result = param1 + 5;  // Spaces around operators
    
    if (result > 10)  // Space before opening brace
    {
        // code
    }
}

// Line length: Max 120 characters
// Indentation: 4 spaces (not tabs)
```

### 5.2. SQL Style
```sql
-- Keywords: UPPERCASE
-- Identifiers: snake_case
-- Indentation: 2 spaces

SELECT
  u.id,
  u.full_name,
  u.email,
  t.name AS tenant_name
FROM users u
INNER JOIN tenants t ON u.tenant_id = t.id
WHERE u.status = 'active'
  AND u.role = 'employee'
ORDER BY u.created_at DESC
LIMIT 10;

-- Line length: Max 100 characters
```

---

## 6. COMMENTS & DOCUMENTATION

### 6.1. XML Documentation (C#)
```csharp
/// <summary>
/// Represents a user in the system
/// </summary>
public class User
{
    /// <summary>
    /// Gets or sets the unique identifier for the user
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// Gets or sets the user's email address
    /// </summary>
    public string Email { get; set; }
}

/// <summary>
/// Creates a new user
/// </summary>
/// <param name="dto">User creation data</param>
/// <returns>The created user</returns>
/// <exception cref="ValidationException">Thrown when validation fails</exception>
public async Task<UserDto> CreateUserAsync(CreateUserDto dto)
{
    // Implementation
}
```

### 6.2. Database Comments
```sql
COMMENT ON TABLE users IS 'System users including all roles';
COMMENT ON COLUMN users.id IS 'Unique identifier (UUID)';
COMMENT ON COLUMN users.email IS 'User email address (unique)';
COMMENT ON COLUMN users.role IS 'User role: super_admin, tenant_admin, employee, customer';
```

---

## 7. VERSION CONTROL

### 7.1. Git Commit Messages
```
Format: <type>(<scope>): <subject>

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation
- style: Formatting
- refactor: Code restructuring
- test: Tests
- chore: Maintenance

Examples:
feat(auth): add JWT authentication
fix(users): resolve email validation issue
docs(readme): update setup instructions
refactor(services): extract user service interface
```

### 7.2. Branch Naming
```
Format: <type>/<ticket-id>-<description>

Examples:
feature/TTS-123-add-user-management
bugfix/TTS-456-fix-login-error
hotfix/TTS-789-security-patch
```

---

## 8. CONFIGURATION

### 8.1. appsettings.json
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=callcenter;Username=postgres;Password=***"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Warning"
    }
  },
  "Jwt": {
    "SecretKey": "***",
    "Issuer": "CallCenter.API",
    "Audience": "CallCenter.Client",
    "ExpirationMinutes": 60
  }
}
```

### 8.2. Environment Variables
```
Format: SCREAMING_SNAKE_CASE

Examples:
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=callcenter
JWT_SECRET_KEY=***
REDIS_CONNECTION_STRING=***
```

---

## 9. TESTING

### 9.1. Test Naming
```csharp
// Format: MethodName_Scenario_ExpectedResult

[Fact]
public async Task GetUserById_ValidId_ReturnsUser()
{
    // Arrange
    var userId = Guid.NewGuid();
    
    // Act
    var result = await _userService.GetUserByIdAsync(userId);
    
    // Assert
    Assert.NotNull(result);
}

[Fact]
public async Task CreateUser_InvalidEmail_ThrowsValidationException()
{
    // Arrange
    var dto = new CreateUserDto { Email = "invalid" };
    
    // Act & Assert
    await Assert.ThrowsAsync<ValidationException>(
        () => _userService.CreateUserAsync(dto));
}
```

---

## 10. TOOLS & EXTENSIONS

### 10.1. Recommended VS Extensions
- ReSharper / Rider
- SonarLint
- EditorConfig
- GitLens
- PostgreSQL Explorer

### 10.2. .editorconfig
```ini
root = true

[*]
charset = utf-8
indent_style = space
insert_final_newline = true
trim_trailing_whitespace = true

[*.cs]
indent_size = 4
csharp_new_line_before_open_brace = all
csharp_prefer_braces = true

[*.sql]
indent_size = 2

[*.json]
indent_size = 2
```

---

## SUMMARY

### Database (PostgreSQL)
- ✅ `snake_case` cho tất cả (tables, columns, indexes...)
- ✅ UUID cho primary keys
- ✅ Plural table names
- ✅ Explicit foreign keys và indexes

### .NET Code
- ✅ `PascalCase` cho classes, methods, properties
- ✅ `camelCase` cho parameters, local variables
- ✅ `_camelCase` cho private fields
- ✅ Clean Architecture structure
- ✅ CQRS + MediatR cho features
- ✅ Repository + Unit of Work pattern
- ✅ Manual DTO mapping (không dùng AutoMapper)
- ✅ FluentValidation + IStringLocalizer
- ✅ Async/await everywhere
- ✅ `DateTime.UtcNow` cho tất cả timestamps

### General
- ✅ Consistent naming
- ✅ Proper documentation
- ✅ Error handling
- ✅ Logging
- ✅ Testing
