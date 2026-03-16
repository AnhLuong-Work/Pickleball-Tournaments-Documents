# Spec: DOCUMENT-DESIGN — Cấu trúc tài liệu thiết kế mới cho AppPickleball

**Ngày:** 2026-03-16
**Phạm vi:** Tổ chức lại toàn bộ tài liệu thiết kế hệ thống AppPickleball từ đầu
**Mục tiêu:** Tạo bộ tài liệu thiết kế đầy đủ, theo thứ tự BA → Architecture → Database → API, phục vụ việc rebuild hệ thống

---

## 1. Bối cảnh

AppPickleball đang được rebuild hoàn toàn từ đầu. Hệ thống hiện tại có các vấn đề về architecture, database design và security cần được giải quyết triệt để thay vì patch từng phần.

Folder `REDESIGN/` đã tồn tại với 3 docs phân tích sơ bộ — sẽ được giữ lại làm archive tham khảo, không sử dụng làm foundation cho thiết kế mới.

---

## 2. Quyết định thiết kế chính

### 2.1 Tại sao viết BA-SPEC trước
Domain entity design (aggregates, value objects, business logic) phụ thuộc vào business rules. Nếu thiết kế domain trước khi có BA, kết quả sẽ sai và phải rework. BA-SPEC phải là input cho tất cả các layer sau.

### 2.2 Tại sao không dùng BA-SPEC cũ
BA-SPEC cũ viết theo kiểu "requirements" cho hệ thống hiện tại. Rebuild từ đầu cần BA-SPEC mới phản ánh đúng business rules, acceptance criteria và edge cases đã được phân tích kỹ hơn.

### 2.3 Tại sao Archive REDESIGN thay vì xóa
3 docs trong REDESIGN có analysis có giá trị (security patterns, database normalization issues, architecture recommendations). Giữ lại làm tài liệu tham khảo trong quá trình viết Architecture docs.

### 2.4 Thứ tự phụ thuộc
```
BA-SPEC (M1→M6)
    → Architecture (Security trước Domain để domain có đủ security entities)
        → Database (schema map từ domain entities)
            → API Contracts (endpoints build từ use cases trong BA)
                → Real-time Contracts (SignalR events map từ API actions)
```

### 2.5 Discovery/Search không phải module riêng
Chức năng tìm kiếm giải đấu, lọc theo khu vực/level thuộc về **M2 — Tournament Management** (GET endpoints, filter params). Không tách riêng thành module để tránh over-engineering.

### 2.6 Module numbering mới vs cũ
Hệ thống cũ có 7 modules (M1-M7), trong đó M4 là "Khám phá & Tìm kiếm" riêng biệt. Thiết kế mới gộp Discovery vào M2, còn lại 6 modules:

| Module mới | Tương đương cũ |
|-----------|---------------|
| M1 — Auth & Profile | M1 Auth + M2 User Profile |
| M2 — Tournament Management | M2 Tournament + M4 Discovery/Search |
| M3 — Match & Scoring | M3 Match Scoring |
| M4 — Community Game | M5 Community Game |
| M5 — Chat | M6 Chat |
| M6 — Notification | M7 Notification |

---

## 3. Cấu trúc DOCUMENT-DESIGN

```
Documents/
├── REDESIGN/                        ← archive, không chỉnh sửa
└── DOCUMENT-DESIGN/
    ├── 00_Overview.md               ← System overview, tech stack, module map, module mapping cũ→mới
    │
    ├── 01_BA-SPEC/
    │   ├── M1_Auth_BA.md            ← Auth & Profile business rules
    │   ├── M2_Tournament_BA.md      ← Tournament lifecycle + Discovery/Search business rules
    │   ├── M3_Match_BA.md           ← Match & Scoring business rules
    │   ├── M4_Community_BA.md       ← Community Game business rules
    │   ├── M5_Chat_BA.md            ← Chat business rules
    │   └── M6_Notification_BA.md    ← Notification business rules
    │
    ├── 02_Architecture/
    │   ├── Clean_Architecture.md    ← Layer structure, project layout, DI
    │   ├── Security_Layer.md        ← JWT, refresh token rotation, OAuth2, UserSession, AuditLog entities
    │   ├── Domain_Design.md         ← All aggregates (bao gồm security entities), value objects, domain logic
    │   └── Infrastructure.md        ← EF Core, Redis, SignalR hubs, external services
    │
    ├── 03_Database/
    │   ├── Schema.md                ← All tables, columns, relationships, constraints
    │   └── Indexes.md               ← Performance indexes, query patterns được optimize
    │
    ├── 04_API/
    │   ├── Standards.md             ← Response format, error codes, auth headers, pagination
    │   ├── M1_Auth_API.md
    │   ├── M2_Tournament_API.md
    │   ├── M3_Match_API.md
    │   ├── M4_Community_API.md
    │   ├── M5_Chat_API.md
    │   └── M6_Notification_API.md
    │
    ├── 05_Realtime/
    │   └── SignalR_Contracts.md     ← Hub events, payload schema, connection lifecycle, client subscriptions
    │
    └── 06_Environment/
        ├── Local_Setup.md           ← PostgreSQL, Redis, Docker setup, run instructions
        └── Environment_Variables.md ← All env vars với mô tả, required/optional
```

---

## 4. Nội dung mỗi loại document

### 4.1 BA-SPEC (mỗi module)
- **Actors & Roles** — ai dùng feature này, quyền gì
- **User Stories** — dạng "As a [role], I want [action] so that [benefit]"
- **Business Rules** — điều kiện, validation, edge cases
- **Acceptance Criteria** — định nghĩa "done"
- **State Machine** (nếu có) — lifecycle của entities (e.g., Tournament: Draft → Open → InProgress → Completed)

### 4.2 Architecture docs
- **Clean_Architecture.md** — folder structure, layer boundaries, dependency rules, DI setup
- **Security_Layer.md** — JWT payload, refresh token rotation flow, OAuth2 providers, UserSession entity, AuditLog entity, RateLimitLog entity *(viết trước Domain_Design)*
- **Domain_Design.md** — mỗi aggregate: properties, value objects, domain methods, invariants *(bao gồm security aggregates từ Security_Layer)*
- **Infrastructure.md** — DbContext, Repository implementations, Redis caching strategy, SignalR hub structure

### 4.3 Database docs
- **Schema.md** — mỗi table: columns, types, constraints, FK relationships, rationale
- **Indexes.md** — indexes per table, query patterns được optimize

> **Note:** Migrations.md không tạo ở giai đoạn design — migration strategy thuộc implementation phase, viết sau khi Schema.md đã stable.

### 4.4 API docs
- **Standards.md** — response wrapper format, error response schema, HTTP status codes, auth headers, pagination convention
- **Mỗi module API** — endpoints, request/response schema, auth requirements, error cases

### 4.5 Real-time docs
- **SignalR_Contracts.md** — danh sách Hub methods, event names, payload schemas, connection lifecycle, auth token passing, client subscription model

### 4.6 Environment docs
- **Local_Setup.md** — prerequisite, Docker Compose, database seed, run commands
- **Environment_Variables.md** — tất cả env vars, mô tả, required/optional, example values

---

## 5. Thứ tự tạo documents

### Phase A — Foundation
1. `00_Overview.md` — viết ngay, cung cấp context cho tất cả docs sau

### Phase B — Business Analysis
2. `01_BA-SPEC/M1_Auth_BA.md` — M1 trước vì Auth là dependency của tất cả modules
3. `01_BA-SPEC/M2_Tournament_BA.md` — bao gồm Discovery/Search
4. `01_BA-SPEC/M3_Match_BA.md`
5. `01_BA-SPEC/M4_Community_BA.md`
6. `01_BA-SPEC/M5_Chat_BA.md`
7. `01_BA-SPEC/M6_Notification_BA.md`

### Phase C — Architecture (sau khi có đủ BA-SPEC)
8. `02_Architecture/Clean_Architecture.md`
9. `02_Architecture/Security_Layer.md` ← trước Domain để định nghĩa security entities
10. `02_Architecture/Domain_Design.md` ← dựa trên BA-SPEC + Security_Layer
11. `02_Architecture/Infrastructure.md`

### Phase D — Database (sau khi có Domain Design)
12. `03_Database/Schema.md` — dựa trên Domain_Design.md
13. `03_Database/Indexes.md`

### Phase E — API (sau khi có Database)
14. `04_API/Standards.md`
15-20. `04_API/M1_Auth_API.md` → `M6_Notification_API.md`

### Phase F — Real-time & Environment
21. `05_Realtime/SignalR_Contracts.md` — sau khi có API contracts
22. `06_Environment/Local_Setup.md`
23. `06_Environment/Environment_Variables.md`

---

## 6. Tech Stack (reference)

| Layer | Technology |
|-------|-----------|
| Backend | .NET 10 Web API, Clean Architecture |
| ORM | Entity Framework Core 10 |
| Database | PostgreSQL 16 |
| Cache | Redis |
| Real-time | SignalR |
| Auth | JWT + Refresh Token Rotation + OAuth2 (Google, Apple, Facebook) |
| Mobile Push | FCM |
| Frontend Web | React + Vite + TypeScript |
| Mobile | React Native Expo |

---

## 7. Modules

| Module | Mô tả |
|--------|-------|
| M1 — Auth & Profile | Đăng ký, đăng nhập, OAuth, quản lý profile |
| M2 — Tournament Management | Tạo, quản lý, tham gia giải đấu, tìm kiếm & khám phá |
| M3 — Match & Scoring | Ghi nhận kết quả trận đấu |
| M4 — Community Game | Game cộng đồng không chính thức |
| M5 — Chat | Nhắn tin trong giải đấu |
| M6 — Notification | Push notification, in-app notification |

## 8. Roles & Authorization

**System roles (3, hierarchy):** `Admin` ⊃ `Creator` ⊃ `User`

| Role | Quyền | Default |
|------|-------|---------|
| `User` | Join giải, xem, chat, community game | Khi đăng ký |
| `Creator` | User's + tạo/quản lý giải đấu | Upgrade từ User |
| `Admin` | Tất cả + quản trị hệ thống | Set thủ công |

**Contextual roles** (không phải system role):
- `Organizer` — user tạo giải đó (`tournaments.created_by`)
- `Participant` — user join giải đó (bảng `participants`)

**Authorization pattern:** Wrap trong `HasPermission()` — không check role trực tiếp trong business logic. Cho phép scale lên full RBAC sau này mà không refactor.
