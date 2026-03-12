# Backend .NET Convention

**Stack:** .NET 8 | Clean Architecture | MediatR + CQRS | EF Core | PostgreSQL

---

## 1. Kiến Trúc Layer

```
AppPickleball.Api          ← Controllers, Middleware, Hubs, Program.cs
AppPickleball.Application  ← Commands, Queries, Handlers, Validators, Interfaces, DTOs
AppPickleball.Domain       ← Entities, Enums, BaseEntity (no dependencies)
AppPickleball.Infrastructure ← EF Core, Repositories, External services
AppPickleball.Share        ← ApiResponse, Localization, Shared utilities
```

**Layer dependencies:**
- `Api` → `Application`, `Infrastructure`, `Share`
- `Application` → `Domain`, `Share`
- `Infrastructure` → `Application`, `Domain`
- `Domain` — no dependencies

---

## 2. CQRS Pattern (MediatR)

### Folder Structure
```
Application/Features/{Domain}/
├── Commands/
│   └── {Name}/
│       ├── {Name}Command.cs          (record : IRequest<ApiResponse<T>>)
│       ├── {Name}CommandHandler.cs   (IRequestHandler<,>)
│       └── {Name}CommandValidator.cs (AbstractValidator<>)
├── Queries/
│   └── {Name}/
│       ├── {Name}Query.cs
│       └── {Name}QueryHandler.cs
└── Dtos/
    └── {Name}Dto.cs
```

### Command/Query Template
```csharp
// Command
public record CreateTournamentCommand(string Name, string Type, int NumGroups)
    : IRequest<ApiResponse<TournamentDto>>;

// Handler
public class CreateTournamentCommandHandler
    : IRequestHandler<CreateTournamentCommand, ApiResponse<TournamentDto>>
{
    public async Task<ApiResponse<TournamentDto>> Handle(
        CreateTournamentCommand request, CancellationToken cancellationToken)
    {
        // logic here — manual mapping, NO AutoMapper
    }
}

// Validator
public class CreateTournamentCommandValidator
    : AbstractValidator<CreateTournamentCommand>
{
    public CreateTournamentCommandValidator(IStringLocalizer<SharedResource> localizer)
    {
        RuleFor(x => x.Name)
            .NotEmpty().WithMessage(localizer["Tournament.Name.Required"])
            .MaximumLength(200);
    }
}
```

---

## 3. Repository Pattern

### Interface Hierarchy
```
IRepository<T>                         ← base CRUD (mọi entity)
ISoftDeletableRepository<T : BaseEntity> ← soft delete operations

// BaseEntity → PHẢI kế thừa cả 2
public interface ITournamentRepository
    : IRepository<Tournament>, ISoftDeletableRepository<Tournament> { }

// BaseCreatedEntity → chỉ IRepository
public interface IRefreshTokenRepository
    : IRepository<RefreshToken> { }
```

### Rules
- KHÔNG gọi `SaveChanges` trong repository
- Luôn commit qua `IUnitOfWork.SaveChangesAsync()`
- Repository chỉ chứa query logic — không có business logic

---

## 4. Domain Entities

```csharp
// BaseEntity — có đầy đủ audit + soft delete
public class Tournament : BaseEntity
{
    public string Name { get; set; }
    // ...
}

// BaseCreatedEntity — chỉ Id + CreatedAt
public class RefreshToken : BaseCreatedEntity
{
    public Guid UserId { get; set; }
    // ...
}
```

### BaseEntity Fields
`Id` (UUID), `CreatedAt`, `UpdatedAt`, `DeletedAt`, `CreatedBy`, `UpdatedBy`, `DeletedBy`, `IsDeleted` (computed)

---

## 5. EF Core Configuration

```csharp
// Luôn snake_case column name
public class TournamentConfiguration : IEntityTypeConfiguration<Tournament>
{
    public void Configure(EntityTypeBuilder<Tournament> builder)
    {
        builder.ToTable("tournaments");

        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id)
            .HasColumnName("id")
            .HasDefaultValueSql("gen_random_uuid()");

        builder.Property(x => x.Name)
            .HasColumnName("name")
            .HasMaxLength(200)
            .IsRequired();

        // Timestamp: TIMESTAMPTZ, default UTC
        builder.Property(x => x.CreatedAt)
            .HasColumnName("created_at")
            .HasColumnType("TIMESTAMPTZ")
            .HasDefaultValueSql("NOW() AT TIME ZONE 'UTC'");

        // Enum → string
        builder.Property(x => x.Status)
            .HasColumnName("status")
            .HasConversion<string>();

        // GlobalQueryFilter: soft delete
        builder.HasQueryFilter(x => x.DeletedAt == null);
    }
}
```

### Rules
- **Explicit `HasColumnName()`** cho MỌI property
- **`TIMESTAMPTZ`** cho DateTime columns (không dùng `TIMESTAMP`)
- **`gen_random_uuid()`** cho UUID primary keys
- **`HasConversion<string>()`** cho Enum properties
- **Unique index filtered**: `WHERE deleted_at IS NULL`

---

## 6. API Response Wrapper

```csharp
// Luôn wrap trong ApiResponse<T>
return Ok(ApiResponse<TournamentDto>.SuccessResponse(dto, localizer["Tournament.Created"]));
return NotFound(ApiResponse<string>.FailureResponse(localizer["Tournament.NotFound"], 404, "NOT_FOUND"));

// Non-generic (no data)
return Ok(ApiResponse.SuccessResponse(localizer["Tournament.Cancelled"]));
```

---

## 7. Controller Style

```csharp
[ApiController]
[Route("api/tournaments")]
public class TournamentsController : BaseApiController
{
    [HttpPost]
    [Authorize]
    [SwaggerOperation(Summary = "Tạo giải đấu mới")]
    [ProducesResponseType(typeof(ApiResponse<TournamentDto>), 201)]
    [ProducesResponseType(typeof(ApiResponse<string>), 400)]
    public async Task<IActionResult> Create([FromBody] CreateTournamentCommand command)
    {
        var result = await _mediator.Send(command);
        return CreatedAtAction(nameof(GetById), new { id = result.Data.Id }, result);
    }
}
```

- Controllers **thin** — chỉ delegate sang MediatR
- Kế thừa `BaseApiController` (có `_mediator`, `_logger`)
- Luôn có `[SwaggerOperation]` và `[ProducesResponseType]`

---

## 8. DateTime Rules
- **Luôn dùng `DateTime.UtcNow`** — KHÔNG dùng `DateTime.Now`
- `DbContext.SaveChangesAsync()` auto-normalize DateTime → UTC
- Column type: `TIMESTAMPTZ`

---

## 9. Localization
```csharp
// KHÔNG hardcode string trong code
// Dùng IStringLocalizer<SharedResource>
_localizer["Tournament.NotFound"]

// Resource files (3 file):
// Share/Resources/SharedResource.resx     (default)
// Share/Resources/SharedResource.en.resx  (English)
// Share/Resources/SharedResource.vi.resx  (Vietnamese)
```

---

## 10. Exception Handling

| Exception | HTTP | Error Code |
|-----------|:----:|-----------|
| `ValidationException` | 400 | VALIDATION_ERROR |
| `NotFoundException` | 404 | NOT_FOUND |
| `DomainException` | 400 | DOMAIN_ERROR |
| `UnauthorizedException` | 401 | UNAUTHORIZED |
| Unhandled | 500 | INTERNAL_SERVER_ERROR |

Throw từ Handler, `ExceptionHandlerMiddleware` bắt và map.

---

## 11. Code Style
- C# 12+: records cho commands, primary constructors where applicable
- Nullable reference types enabled
- 1 class/interface = 1 file
- No direct `SaveChanges` trong repositories
- Vietnamese comments OK (mixed Vi/En)
- No AutoMapper — manual mapping trong Handler
