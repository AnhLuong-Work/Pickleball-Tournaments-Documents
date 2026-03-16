# AppPickleball — Khuyến Nghị Kiến Trúc
**Ngày:** 2026-03-16 | **Loại:** Gợi ý thiết kế lại

---

## 1. 🔐 Lớp Bảo Mật & Xác Thực

### Vấn Đề Hiện Tại
- ❌ Không có ghi nhật ký kiểm toán tập trung
- ❌ Không có giới hạn tốc độ trên các endpoint API (chỉ auth)
- ❌ Không có ID tương quan yêu cầu để theo dõi
- ❌ OTP được lưu trong bảng Users (trộn lẫn các mối quan tâm)
- ❌ Quản lý refresh token không rõ ràng

### Khuyến Nghị

#### 1.1 Thêm Bảng Ghi Nhật Ký Kiểm Toán
```sql
CREATE TABLE "AuditLogs" (
  "Id" BIGINT PRIMARY KEY,
  "UserId" INT FK,
  "Action" VARCHAR(50),           -- 'login', 'password_change', 'profile_update'
  "ResourceType" VARCHAR(50),     -- 'User', 'Tournament', 'Match'
  "ResourceId" INT,
  "OldValues" JSONB,              -- Trạng thái trước
  "NewValues" JSONB,              -- Trạng thái mới
  "IPAddress" VARCHAR(45),
  "UserAgent" VARCHAR(500),
  "StatusCode" INT,               -- 200, 400, 403...
  "CreatedAt" TIMESTAMPTZ
);

-- Indexes cho truy vấn
CREATE INDEX idx_audit_user_date ON "AuditLogs"("UserId", "CreatedAt" DESC);
CREATE INDEX idx_audit_resource ON "AuditLogs"("ResourceType", "ResourceId");
```

**Trường hợp sử dụng:** Theo dõi các hoạt động nhạy cảm (thay đổi mật khẩu, thay đổi người tạo giải, chỉnh sửa điểm)

#### 1.2 Tách Riêng OTP/Xác Thực Email
```sql
CREATE TABLE "EmailVerifications" (
  "Id" INTEGER PRIMARY KEY,
  "UserId" INT FK UNIQUE,         -- 1 xác thực chờ xử lý trên mỗi người dùng
  "Code" VARCHAR(6) NOT NULL,     -- OTP 6 chữ số
  "CodeHash" VARCHAR(255),        -- Hash của mã (không lưu mã rõ)
  "Attempts" INT DEFAULT 0,       -- Theo dõi những lần cố gắng sai
  "ExpiresAt" TIMESTAMPTZ,        -- 15 phút từ tạo
  "VerifiedAt" TIMESTAMPTZ,
  "CreatedAt" TIMESTAMPTZ
);
```

**Lợi ích:** Tách biệt sạch sẽ từ bảng Users, dễ quản lý hết hạn

#### 1.3 Kho Giới Hạn Tốc Độ (Redis + DB Fallback)
```sql
CREATE TABLE "RateLimitLogs" (
  "Id" INTEGER PRIMARY KEY,
  "Key" VARCHAR(255),             -- "login_192.168.1.1", "api_user_123"
  "Attempts" INT,
  "ExpiresAt" TIMESTAMPTZ,
  "LastAttemptAt" TIMESTAMPTZ
);

-- Khuyến nghị: Sử dụng Redis cho dữ liệu hot, đồng bộ với DB để lưu trữ
```

**Lợi ích:** Giới hạn tốc độ các endpoint API (mặc định 100 yêu cầu/phút cho mỗi người dùng)

#### 1.4 Quản Lý Thiết Bị/Phiên
```sql
CREATE TABLE "UserSessions" (
  "Id" INTEGER PRIMARY KEY,
  "UserId" INT FK,
  "DeviceId" VARCHAR(255),        -- UUID được tạo bởi client
  "DeviceName" VARCHAR(255),      -- "iPhone 15 Pro", "Chrome trên Windows"
  "IPAddress" VARCHAR(45),
  "UserAgent" VARCHAR(500),
  "RefreshTokenHash" VARCHAR(255),-- Hash của token (không bao giờ lưu mã rõ)
  "LastUsedAt" TIMESTAMPTZ,
  "ExpiresAt" TIMESTAMPTZ,
  "IsActive" BOOLEAN DEFAULT TRUE,
  "CreatedAt" TIMESTAMPTZ
);
```

**Lợi ích:** Quản lý token tốt hơn, hỗ trợ đa thiết bị, người dùng có thể thu hồi các thiết bị cụ thể

#### 1.5 ID Yêu Cầu API/ID Tương Quan
```
Trong middleware:
- Tạo RequestId duy nhất (UUID) cho mỗi yêu cầu
- Thêm vào response headers: X-Request-Id
- Chuyển qua các audit logs, error logs, tracing
- Giúp gỡ lỗi: có thể theo dõi yêu cầu thông qua tất cả các dịch vụ
```

---

## 2. 🗄️ Lớp Truy Cập Dữ Liệu

### Vấn Đề Hiện Tại
- ❌ Không có đề cập đến các mẫu tối ưu hóa truy vấn
- ❌ Không có chiến lược lớp caching
- ❌ Không xử lý soft-delete
- ❌ Không có theo dõi thay đổi để kiểm toán

### Khuyến Nghị

#### 2.1 Repository Pattern với Specifications
```csharp
// Thay vì: GetTournamentsByStatusAndCreator(status, creatorId)
// Sử dụng:
var spec = new TournamentSpecification()
  .ByStatus("open")
  .ByCreator(userId)
  .WithParticipants()
  .PageBy(pageNumber, pageSize);

var tournaments = await _tournamentRepository.GetAsync(spec);
```

**Lợi ích:** Có thể tái sử dụng, có thể kiểm tra, ý định rõ ràng

#### 2.2 Unit of Work Pattern
```csharp
using (var uow = _unitOfWork.Begin())
{
  var tournament = await _tournamentRepo.GetAsync(id);
  tournament.Status = "ready";
  tournament.UpdatedAt = DateTime.UtcNow;

  await uow.CommitAsync(); // Giao dịch duy nhất
}
```

**Lợi ích:** Hoạt động nguyên tử, rollback khi thất bại

#### 2.3 Caching Decorators
```csharp
// Truy cập cơ sở dữ liệu
IRepository<Tournament> _repo;

// Thêm lớp caching
var cachedRepo = new CachedRepository<Tournament>(_repo, _redis);

// Tự động:
// - Kiểm tra Redis trước
// - Nếu miss, truy vấn DB
// - Kết quả cache (khóa: "tournament_{id}", TTL: 5 phút)
```

**Lợi ích:** Caching trong suốt, giảm tải DB

---

## 3. 🔄 Domain-Driven Design (DDD)

### Vấn Đề Hiện Tại
- ❌ Trộn lẫn các mối quan tâm trong bảng Users
- ❌ Không có mô hình domain mạnh mẽ
- ❌ Logic nghiệp vụ phân tán trong các dịch vụ

### Khuyến Nghị

#### 3.1 User Aggregate Root
```csharp
public class User
{
  public UserId Id { get; }
  public Email Email { get; }
  public PasswordHash PasswordHash { get; }  // Value Object
  public UserProfile Profile { get; }        // Aggregate
  public UserAuthentication Auth { get; }    // Aggregate riêng
}

// Value Objects
public class Email
{
  public string Value { get; }
  // Logic xác thực
}

public class PasswordHash
{
  public string Hash { get; }
  public bool Verify(string password) { }
}
```

**Lợi ích:** Đóng gói, xác thực ở mức domain, dễ kiểm tra hơn

#### 3.2 Domain Events
```csharp
public class UserRegisteredEvent : DomainEvent
{
  public UserId UserId { get; }
  public Email Email { get; }
  // Trigger: gửi email chào mừng, tạo cài đặt mặc định
}

public class EmailVerifiedEvent : DomainEvent
{
  // Trigger: thông báo cho người tạo về người chơi mới
}

public class MatchCompletedEvent : DomainEvent
{
  // Trigger: cập nhật xếp hạng, gửi thông báo
}
```

**Lợi ích:** Tách rời, mở rộng được, ý định rõ ràng

---

## 4. 🏗️ Cải Thiện Clean Architecture

### Lớp Hiện Tại
✅ Tốt: API → Application → Domain → Infrastructure

### Khuyến Nghị

#### 4.1 Thêm Lớp Xử Lý Lỗi
```
Lớp API
  └─ Middleware: ExceptionHandler
      └─ Map Domain Exceptions → HTTP responses
      └─ Ghi nhật ký tất cả lỗi với RequestId
      └─ Trả về định dạng lỗi chuẩn (RFC 7807)

Ví dụ:
  EntityNotFoundException → 404
  InsufficientPermissionException → 403
  TournamentFullException → 422
  RateLimitException → 429
```

#### 4.2 Thêm Lớp Xác Thực
```csharp
// Request DTOs với Fluent Validation
public class CreateTournamentRequest
{
  public string Name { get; set; }
  public string Type { get; set; }  // "singles" | "doubles"
}

public class CreateTournamentValidator : AbstractValidator<CreateTournamentRequest>
{
  public CreateTournamentValidator()
  {
    RuleFor(x => x.Name)
      .NotEmpty()
      .Length(3, 200);

    RuleFor(x => x.Type)
      .Must(x => x == "singles" || x == "doubles");
  }
}

// Middleware: xác thực tự động tất cả các yêu cầu
```

#### 4.3 Thêm Lớp Response Wrapper
```csharp
// Tất cả API responses theo định dạng này
public class ApiResponse<T>
{
  public T Data { get; set; }
  public ApiMeta Meta { get; set; }        // Phân trang, liên kết
  public string RequestId { get; set; }    // Để theo dõi
}

public class ApiMeta
{
  public int Page { get; set; }
  public int PageSize { get; set; }
  public int TotalCount { get; set; }
  public string NextUrl { get; set; }
}
```

---

## 5. 📡 Real-time & SignalR

### Vấn Đề Hiện Tại
- ❌ Thiết kế hub SignalR không được ghi chép
- ❌ Không có connection fallback
- ❌ Không có message queue cho người dùng ngoại tuyến

### Khuyến Nghị

#### 5.1 Hub Design Pattern
```csharp
public class MatchScoringHub : Hub
{
  // Tham gia phòng trận đấu
  public async Task JoinMatch(string matchId)
  {
    await Groups.AddToGroupAsync(Connection.ConnectionId, $"match_{matchId}");
  }

  // Phát sóng cập nhật điểm
  public async Task ScoreUpdated(string matchId, ScoreDto score)
  {
    // Xác minh người dùng được phép cập nhật
    // Lưu trữ vào DB
    // Phát sóng đến nhóm
    await Clients.Group($"match_{matchId}")
      .SendAsync("OnScoreUpdated", score);
  }

  // Offline queue (Redis)
  // Nếu người dùng ngắt kết nối, message được xếp hàng
  // Kết nối lại: nhận được các message trong hàng đợi
}
```

#### 5.2 Message Queue Để Đảm Bảo Độ Tin Cậy
```
Các sự kiện real-time (điểm, chat):
1. Người dùng gửi sự kiện
2. API lưu trữ vào DB
3. Phát sóng đến người dùng trực tuyến (SignalR)
4. Xếp hàng cho người dùng ngoại tuyến (Redis queue)
5. Người dùng kết nối lại: nhận được các message trong hàng đợi

Lợi ích:
- Không mất message
- Hoạt động với mạng không đáng tin cậy
- Kiến trúc offline-first
```

---

## 6. 🔍 Khả Quan Sát & Giám Sát

### Khuyến Nghị

#### 6.1 Structured Logging
```csharp
public class LoggingMiddleware
{
  public async Task InvokeAsync(HttpContext context)
  {
    var requestId = context.Request.Headers["X-Request-Id"]
      ?? Guid.NewGuid().ToString();

    _logger.LogInformation(
      "Request {RequestId} {Method} {Path} from {IP}",
      requestId,
      context.Request.Method,
      context.Request.Path,
      context.Connection.RemoteIpAddress
    );

    try
    {
      await _next(context);
    }
    finally
    {
      _logger.LogInformation(
        "Response {RequestId} {StatusCode} in {ElapsedMs}ms",
        requestId,
        context.Response.StatusCode,
        stopwatch.ElapsedMilliseconds
      );
    }
  }
}
```

#### 6.2 Các Metrics Chính Để Theo Dõi
- Độ trễ yêu cầu theo endpoint
- Tỷ lệ lỗi (4xx, 5xx)
- Thời lượng truy vấn cơ sở dữ liệu
- Số lượng kết nối SignalR
- Tỷ lệ giao hàng thông báo
- Tỷ lệ cache hit

#### 6.3 Endpoint Health Check
```csharp
public class HealthController : ControllerBase
{
  [HttpGet("/health")]
  public async Task<IActionResult> Health()
  {
    var checks = new
    {
      Database = await _db.CanConnectAsync(),
      Redis = await _redis.PingAsync(),
      Email = await _emailService.CanConnectAsync(),
      FCM = await _fcmService.CanConnectAsync()
    };

    var allHealthy = checks.GetType().GetProperties()
      .All(p => (bool)p.GetValue(checks));

    return allHealthy ? Ok(checks) : StatusCode(503, checks);
  }
}
```

---

## 7. 📦 Dependency Injection & Configuration

### Khuyến Nghị

```csharp
// Startup: Thiết lập DI rõ ràng, được tổ chức
public void ConfigureServices(IServiceCollection services)
{
  // Hạ tầng
  services.AddDbContext<PickleballDbContext>(options =>
    options.UseNpgsql(_configuration.GetConnectionString("Default")));
  services.AddStackExchangeRedisCache(...);

  // Repositories
  services.AddScoped(typeof(IRepository<>), typeof(EfRepository<>));

  // Dịch vụ Ứng dụng
  services.AddScoped<ITournamentService, TournamentService>();
  services.AddScoped<IAuthService, AuthService>();

  // Caching
  services.Decorate(typeof(IRepository<>), typeof(CachedRepository<>));

  // Xác thực
  services.AddValidatorsFromAssembly(typeof(Program).Assembly);

  // API
  services.AddControllers(options =>
  {
    options.Filters.Add<ValidationFilter>();
    options.Filters.Add<ExceptionFilter>();
  });
}
```

---

## Tóm Tắt: Cải Thiện Kiến Trúc

| Thành phần | Hiện tại | Khuyến nghị |
|-----------|---------|-------------|
| **Ghi nhật ký kiểm toán** | ❌ Không | ✅ Bảng AuditLogs + middleware |
| **Giới hạn tốc độ** | ❌ Chỉ auth | ✅ API-wide (Redis + DB) |
| **Quản lý Phiên** | 🟡 RefreshTokens only | ✅ Bảng UserSessions |
| **Lưu trữ OTP** | 🟡 Bảng Users | ✅ Bảng EmailVerifications |
| **Xử lý Lỗi** | 🟡 Cơ bản | ✅ Middleware + định dạng chuẩn |
| **Xác thực** | 🟡 Cơ bản | ✅ FluentValidation + middleware |
| **Caching** | 🟡 Redis được ghi chú | ✅ Decorator pattern + chiến lược TTL |
| **DDD** | ❌ Không | ✅ Aggregates + Value Objects + Domain Events |
| **Real-time** | 🟡 SignalR cơ bản | ✅ Hub patterns + offline queue |
| **Giám sát** | ❌ Không | ✅ Structured logs + metrics + health checks |

---

*Những khuyến nghị này tạo thành nền tảng cho bảo mật, khả năng mở rộng và khả năng bảo trì.*
