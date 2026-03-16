# DOCUMENT-DESIGN Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tạo toàn bộ bộ tài liệu thiết kế mới cho AppPickleball trong folder DOCUMENT-DESIGN, phục vụ việc rebuild hệ thống từ đầu.

**Architecture:** Tài liệu được tổ chức theo dependency chain: BA-SPEC → Architecture → Database → API → Real-time → Environment. Mỗi phase chỉ bắt đầu khi phase trước hoàn tất vì nội dung sau phụ thuộc trực tiếp vào quyết định của phase trước.

**Tech Stack:** .NET 10 Web API · EF Core 10 · PostgreSQL 16 · Redis · SignalR · JWT + OAuth2 (Google, Apple, Facebook) · FCM · React + Vite + TypeScript · React Native Expo

**Spec:** `docs/superpowers/specs/2026-03-16-document-design-structure.md`

---

## Chunk 1: Foundation Setup

**Files:**
- Create: `DOCUMENT-DESIGN/00_Overview.md`
- Create: folder structure toàn bộ DOCUMENT-DESIGN

---

### Task 1: Tạo folder structure

- [ ] **Step 1: Tạo tất cả folders**

```bash
mkdir -p "DOCUMENT-DESIGN/01_BA-SPEC"
mkdir -p "DOCUMENT-DESIGN/02_Architecture"
mkdir -p "DOCUMENT-DESIGN/03_Database"
mkdir -p "DOCUMENT-DESIGN/04_API"
mkdir -p "DOCUMENT-DESIGN/05_Realtime"
mkdir -p "DOCUMENT-DESIGN/06_Environment"
```

- [ ] **Step 2: Verify**

```bash
find DOCUMENT-DESIGN -type d
```
Expected: 7 folders (root + 6 subfolders)

---

### Task 2: Viết `DOCUMENT-DESIGN/00_Overview.md`

**Sections bắt buộc:**
1. **Giới thiệu** — AppPickleball là gì, mục đích rebuild
2. **Tech Stack** — bảng đầy đủ (Backend, ORM, DB, Cache, Realtime, Auth, Push, Web, Mobile)
3. **Module Map** — bảng 6 modules với mô tả + mapping so với hệ thống cũ (7 modules → 6 modules)
4. **Cấu trúc tài liệu** — sơ đồ folder DOCUMENT-DESIGN, mô tả từng folder
5. **Thứ tự đọc** — bảng "khi nào đọc file nào" (giống CLAUDE.md nhưng cho DOCUMENT-DESIGN)
6. **Roles** — Admin, Creator, Player, User/Guest

**Nguồn tham khảo:**
- `REDESIGN/01_Current_Architecture_Audit.md` — system overview hiện tại
- `docs/superpowers/specs/2026-03-16-document-design-structure.md` — module map, tech stack

- [ ] **Step 1: Viết 00_Overview.md**
- [ ] **Step 2: Review — đủ 6 sections, module mapping rõ ràng, roles đầy đủ**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/00_Overview.md
git commit -m "docs: add DOCUMENT-DESIGN overview"
```

---

## Chunk 2: BA-SPEC Phase (M1–M3)

**Files:**
- Create: `DOCUMENT-DESIGN/01_BA-SPEC/M1_Auth_BA.md`
- Create: `DOCUMENT-DESIGN/01_BA-SPEC/M2_Tournament_BA.md`
- Create: `DOCUMENT-DESIGN/01_BA-SPEC/M3_Match_BA.md`

**Template BA-SPEC (áp dụng cho mỗi module):**
```markdown
## 1. Actors & Roles
| Actor | Quyền trong module này |
|-------|----------------------|

## 2. User Stories
| ID | As a... | I want to... | So that... |
|----|---------|-------------|------------|

## 3. Business Rules
### BR-XX: [Tên rule]
- Condition: ...
- Validation: ...
- Edge cases: ...

## 4. Acceptance Criteria
### AC-XX: [Tên feature]
- Given: ...
- When: ...
- Then: ...

## 5. State Machine (nếu có)
[Diagram hoặc bảng transitions]
```

---

### Task 3: Viết `M1_Auth_BA.md`

**Scope:** Đăng ký email, đăng nhập email, OAuth2 (Google/Apple/Facebook), refresh token, đổi mật khẩu, xác thực email, quản lý profile, upload avatar.

**Business Rules cần cover:**
- Email format validation, password strength (min 8 ký tự, ít nhất 1 số 1 chữ hoa)
- Email verify trước khi login được không?
- OAuth: user đã có email account thì merge hay tạo mới?
- Refresh token: rotate on use, expire sau bao lâu?
- Rate limit: bao nhiêu lần login fail thì lock?
- Profile: field nào required, field nào optional?
- Avatar: max size, allowed formats?

**Nguồn tham khảo:**
- `REDESIGN/02_Architecture_Recommendations.md` — security patterns, token rotation
- `BA-SPEC/01_Auth_BA_Spec.md` — BA cũ (tham khảo, không copy)

- [ ] **Step 1: Viết M1_Auth_BA.md với đủ 5 sections**
- [ ] **Step 2: Review — đủ actors, business rules cho email+OAuth, state machine (email verification flow)**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/01_BA-SPEC/M1_Auth_BA.md
git commit -m "docs: add M1 Auth BA spec"
```

---

### Task 4: Viết `M2_Tournament_BA.md`

**Scope:** Tạo giải đấu, publish, registration (open/waitlist/close), bracket generation, check-in, start, kết thúc, tìm kiếm & khám phá giải đấu.

**Business Rules cần cover:**
- Tournament types: Singles, Doubles (khác nhau thế nào về participant structure?)
- Capacity: MinCapacity/MaxCapacity, khi nào tự động close registration?
- Waitlist: auto-promote khi có slot trống không?
- Registration deadline vs tournament start date
- Creator role: ai được tạo? Player thường có tạo được không?
- Bracket: single elimination, double elimination, round robin? Tự động hay manual?
- Check-in window: bắt buộc hay optional?
- Cancel tournament: điều kiện, refund policy (nếu có)
- Discovery/Search: filter theo khu vực, level, date, type; sort options

**Nguồn tham khảo:**
- `REDESIGN/03_Database_Recommendations.md` — Tournament capacity, waitlist design
- `BA-SPEC/02_Tournament_BA_Spec.md` — BA cũ

- [ ] **Step 1: Viết M2_Tournament_BA.md với đủ 5 sections**
- [ ] **Step 2: Review — lifecycle state machine đầy đủ (Draft→Open→InProgress→Completed→Cancelled), business rules capacity/waitlist rõ, Discovery/Search có section riêng**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/01_BA-SPEC/M2_Tournament_BA.md
git commit -m "docs: add M2 Tournament BA spec"
```

---

### Task 5: Viết `M3_Match_BA.md`

**Scope:** Ghi nhận điểm số, xác nhận kết quả, dispute, lịch sử trận đấu.

**Business Rules cần cover:**
- Ai được phép record score? Chỉ Creator? Cả 2 players?
- Score format: Singles khác Doubles không? Game to 11 hay 15 hay 21?
- Match games: bao nhiêu game per match? Best of 3? Best of 5?
- Confirmation: cả 2 bên phải confirm không? Timeout confirm?
- Dispute: ai handle dispute? Creator? Admin?
- Retroactive score edit: cho phép hay không?
- Walkover/Forfeit: xử lý thế nào?

**Nguồn tham khảo:**
- `REDESIGN/03_Database_Recommendations.md` — MatchGames table design
- `BA-SPEC/03_Match_Scoring_BA_Spec.md` — BA cũ

- [ ] **Step 1: Viết M3_Match_BA.md với đủ 5 sections**
- [ ] **Step 2: Review — score recording flow rõ, confirmation state machine, dispute handling có AC**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/01_BA-SPEC/M3_Match_BA.md
git commit -m "docs: add M3 Match BA spec"
```

---

## Chunk 3: BA-SPEC Phase (M4–M6)

**Files:**
- Create: `DOCUMENT-DESIGN/01_BA-SPEC/M4_Community_BA.md`
- Create: `DOCUMENT-DESIGN/01_BA-SPEC/M5_Chat_BA.md`
- Create: `DOCUMENT-DESIGN/01_BA-SPEC/M6_Notification_BA.md`

---

### Task 6: Viết `M4_Community_BA.md`

**Scope:** Game cộng đồng không chính thức — tạo game pickup, join, track kết quả.

**Business Rules cần cover:**
- Community game vs Tournament: điểm khác biệt chính (informal, no bracket, quick setup)
- Ai có thể tạo? Ai có thể join?
- Max players per game?
- Location-based: có filter theo khu vực không?
- Scheduling: date/time, recurring game?
- Kết quả: có track hay optional?
- Cancel/leave: rules?

**Nguồn tham khảo:**
- `BA-SPEC/04_Community_BA_Spec.md` — BA cũ

- [ ] **Step 1: Viết M4_Community_BA.md với đủ 5 sections**
- [ ] **Step 2: Review — phân biệt rõ Community vs Tournament, state machine game lifecycle**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/01_BA-SPEC/M4_Community_BA.md
git commit -m "docs: add M4 Community BA spec"
```

---

### Task 7: Viết `M5_Chat_BA.md`

**Scope:** Nhắn tin real-time trong context giải đấu/community game.

**Business Rules cần cover:**
- Chat rooms: 1 room per tournament? Per match? Per community game?
- Ai có quyền vào room? Chỉ participants? Spectators?
- Message types: text only? Media (ảnh)?
- Message history: lưu bao lâu?
- Moderation: Creator/Admin có delete message không?
- Real-time: SignalR — gửi message khi offline thì sao?
- Notifications: khi có message mới thì notify thế nào?

**Nguồn tham khảo:**
- `BA-SPEC/05_Notification_BA_Spec.md` — BA cũ (có Chat section)
- `REALTIME/SignalR_Contracts.md` — contracts cũ

- [ ] **Step 1: Viết M5_Chat_BA.md với đủ 5 sections**
- [ ] **Step 2: Review — room membership rules rõ, online/offline message delivery có AC**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/01_BA-SPEC/M5_Chat_BA.md
git commit -m "docs: add M5 Chat BA spec"
```

---

### Task 8: Viết `M6_Notification_BA.md`

**Scope:** Push notification (FCM), in-app notification, notification preferences.

**Business Rules cần cover:**
- Notification triggers: tournament updates, match scheduled, score recorded, chat message, waitlist promoted
- Delivery channels: push (FCM) + in-app
- User preferences: opt-out per notification type?
- Read/unread state
- Notification history: giữ bao lâu?
- Batch notifications: nhiều events cùng lúc thì gộp hay gửi riêng?
- Silent vs alerting notifications

**Nguồn tham khảo:**
- `BA-SPEC/05_Notification_BA_Spec.md` — BA cũ

- [ ] **Step 1: Viết M6_Notification_BA.md với đủ 5 sections**
- [ ] **Step 2: Review — đủ trigger list, preference matrix (channel x type), delivery flow**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/01_BA-SPEC/M6_Notification_BA.md
git commit -m "docs: add M6 Notification BA spec"
```

---

## Chunk 4: Architecture Phase

**Files:**
- Create: `DOCUMENT-DESIGN/02_Architecture/Clean_Architecture.md`
- Create: `DOCUMENT-DESIGN/02_Architecture/Security_Layer.md`
- Create: `DOCUMENT-DESIGN/02_Architecture/Domain_Design.md`
- Create: `DOCUMENT-DESIGN/02_Architecture/Infrastructure.md`

> **Prerequisite:** Tất cả BA-SPEC (Chunk 2 + 3) phải hoàn tất trước.

---

### Task 9: Viết `Clean_Architecture.md`

**Sections bắt buộc:**
1. **Layer Structure** — 4 layers: Domain, Application, Infrastructure, API + dependency rules (inner layers không biết outer)
2. **Project Layout** — folder structure chi tiết cho solution `.sln` và 4 projects
3. **Dependency Injection** — cách register services, lifetime (Singleton/Scoped/Transient) cho từng loại
4. **MediatR Pipeline** — ValidationBehavior, LoggingBehavior, AuthorizationBehavior thứ tự
5. **Error Handling** — exception hierarchy (DomainException, ApplicationException, InfrastructureException), middleware flow
6. **Coding Conventions** — naming, file organization, async patterns

- [ ] **Step 1: Viết Clean_Architecture.md với đủ 6 sections**
- [ ] **Step 2: Review — dependency rules rõ ràng (không có circular), folder structure đủ chi tiết để scaffold**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/02_Architecture/Clean_Architecture.md
git commit -m "docs: add Clean Architecture design"
```

---

### Task 10: Viết `Security_Layer.md`

> **Viết trước Domain_Design** vì Domain_Design cần biết security entities.

**Sections bắt buộc:**
1. **JWT Design** — payload claims, expiry (access token: 15 phút, refresh token: 7 ngày), signing algorithm (RS256 hay HS256?)
2. **Refresh Token Rotation** — flow diagram: issue → use → rotate → revoke, storage strategy
3. **OAuth2 Providers** — Google, Apple, Facebook: flow, token exchange, account linking logic
4. **Security Entities** — schema cho: `UserSession`, `UserAuthProvider`, `EmailVerification`, `AuditLog`, `RateLimitLog`
5. **Rate Limiting** — strategy (IP-based, user-based), limits per endpoint group
6. **Authorization** — Policy-based auth, role definitions, permission matrix per module

**Nguồn tham khảo:**
- `REDESIGN/02_Architecture_Recommendations.md` — security patterns section

- [ ] **Step 1: Viết Security_Layer.md với đủ 6 sections**
- [ ] **Step 2: Review — refresh token rotation flow rõ, security entity schemas đủ fields, permission matrix cover 6 modules**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/02_Architecture/Security_Layer.md
git commit -m "docs: add Security Layer design"
```

---

### Task 11: Viết `Domain_Design.md`

> **Prerequisite:** Security_Layer.md phải hoàn tất.

**Sections bắt buộc:**
1. **Aggregate Overview** — danh sách tất cả aggregates + aggregate roots
2. **Aggregates chi tiết** — mỗi aggregate: properties, value objects, domain methods, invariants, relationships

**Aggregates cần document:**

| Aggregate Root | Entities trong aggregate | Value Objects |
|---------------|--------------------------|---------------|
| `User` | `UserProfile`, `UserSession`, `UserAuthProvider`, `EmailVerification` | `Email`, `PhoneNumber`, `FullName` |
| `Tournament` | `Participant`, `TournamentWaitlist` | `TournamentCapacity`, `RegistrationPeriod` |
| `Match` | `MatchGame` | `Score`, `MatchResult` |
| `Group` | `SinglesGroupMember`, `DoublesGroupMember` | — |
| `CommunityGame` | `CommunityGameParticipant` | — |
| `ChatRoom` | `Message` | — |
| `Notification` | — | — |
| `AuditLog` | — | — |

**Nguồn tham khảo:**
- `REDESIGN/03_Database_Recommendations.md` — table schemas
- `Security_Layer.md` (vừa viết) — security entity schemas

- [ ] **Step 1: Viết Domain_Design.md — aggregate overview + tất cả aggregates chi tiết**
- [ ] **Step 2: Review — đủ tất cả aggregates từ bảng trên, domain methods phản ánh business rules từ BA-SPEC, không có anemic domain model**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/02_Architecture/Domain_Design.md
git commit -m "docs: add Domain Design"
```

---

### Task 12: Viết `Infrastructure.md`

**Sections bắt buộc:**
1. **DbContext** — cấu hình, entity configurations, interceptors (audit, soft delete)
2. **Repository Pattern** — generic repository, specification pattern, Unit of Work
3. **Caching Strategy** — Redis: cache keys convention, TTL per entity type, cache invalidation
4. **SignalR** — Hub structure, connection management, group membership
5. **External Services** — OAuth providers (HttpClient config), FCM (push notification), Email service
6. **Background Jobs** — Hangfire hay built-in? Jobs cần thiết (token cleanup, notification dispatch)

**Nguồn tham khảo:**
- `REDESIGN/02_Architecture_Recommendations.md` — Repository, Caching sections

- [ ] **Step 1: Viết Infrastructure.md với đủ 6 sections**
- [ ] **Step 2: Review — cache key convention rõ, repository interfaces match domain aggregates, background jobs list đầy đủ**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/02_Architecture/Infrastructure.md
git commit -m "docs: add Infrastructure design"
```

---

## Chunk 5: Database Phase

**Files:**
- Create: `DOCUMENT-DESIGN/03_Database/Schema.md`
- Create: `DOCUMENT-DESIGN/03_Database/Indexes.md`

> **Prerequisite:** Domain_Design.md phải hoàn tất.

---

### Task 13: Viết `Schema.md`

**Format mỗi table:**
```markdown
### Table: `table_name`
**Aggregate:** [tên aggregate]
**Mô tả:** [một dòng]

| Column | Type | Nullable | Default | Mô tả |
|--------|------|----------|---------|-------|

**Constraints:**
- PK: `id`
- FK: `user_id` → `users.id` ON DELETE CASCADE
- UNIQUE: (`email`)
- CHECK: `status IN ('active', 'inactive')`
```

**Tables cần document (từ Domain_Design):**
- `users`, `user_profiles`, `user_sessions`, `user_auth_providers`, `email_verifications`
- `tournaments`, `participants`, `tournament_waitlists`
- `groups`, `singles_group_members`, `doubles_group_members`
- `matches`, `match_games`
- `community_games`, `community_game_participants`
- `chat_rooms`, `messages`
- `notifications`
- `audit_logs`, `rate_limit_logs`

**Nguồn tham khảo:**
- `REDESIGN/03_Database_Recommendations.md` — recommended schemas
- `Domain_Design.md` (vừa viết) — aggregate properties
- `DATABASE/Database_Design.md` — schema cũ (tham khảo, không copy)

- [ ] **Step 1: Viết Schema.md — tất cả tables với format chuẩn**
- [ ] **Step 2: Review — tất cả aggregates từ Domain_Design có table tương ứng, FK constraints đúng, không thiếu audit fields (created_at, updated_at)**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/03_Database/Schema.md
git commit -m "docs: add Database Schema"
```

---

### Task 14: Viết `Indexes.md`

**Format mỗi index:**
```markdown
### `idx_table_column`
- **Table:** `table_name`
- **Columns:** `(col1, col2)`
- **Type:** B-tree / GIN / GiST
- **Query pattern:** `WHERE col1 = ? AND col2 = ?`
- **Lý do:** [tại sao cần index này]
```

**Indexes cần tạo (minimum):**
- `users`: index on `email` (login lookup)
- `user_sessions`: index on `user_id`, `refresh_token`, `expires_at`
- `tournaments`: index on `status`, `start_date`, `created_by`; GIN index on `name` (full-text search)
- `participants`: index on `tournament_id`, `user_id`
- `matches`: index on `tournament_id`, `status`
- `notifications`: index on `user_id`, `is_read`, `created_at`
- `audit_logs`: index on `user_id`, `created_at`, `entity_type`
- `messages`: index on `chat_room_id`, `created_at`

- [ ] **Step 1: Viết Indexes.md — tất cả indexes với format chuẩn**
- [ ] **Step 2: Review — mỗi index có query pattern cụ thể, không có duplicate indexes**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/03_Database/Indexes.md
git commit -m "docs: add Database Indexes"
```

---

## Chunk 6: API Phase

**Files:**
- Create: `DOCUMENT-DESIGN/04_API/Standards.md`
- Create: `DOCUMENT-DESIGN/04_API/M1_Auth_API.md`
- Create: `DOCUMENT-DESIGN/04_API/M2_Tournament_API.md`
- Create: `DOCUMENT-DESIGN/04_API/M3_Match_API.md`
- Create: `DOCUMENT-DESIGN/04_API/M4_Community_API.md`
- Create: `DOCUMENT-DESIGN/04_API/M5_Chat_API.md`
- Create: `DOCUMENT-DESIGN/04_API/M6_Notification_API.md`

> **Prerequisite:** Schema.md phải hoàn tất.

---

### Task 15: Viết `Standards.md`

**Sections bắt buộc:**
1. **Base URL** — `/api/v1/`
2. **Response Wrapper**
```json
{
  "success": true,
  "data": {},
  "message": "string",
  "errors": [],
  "pagination": { "page": 1, "pageSize": 20, "total": 100 }
}
```
3. **Error Response**
```json
{
  "success": false,
  "code": "TOURNAMENT_NOT_FOUND",
  "message": "Giải đấu không tồn tại",
  "errors": [{ "field": "id", "message": "..." }]
}
```
4. **HTTP Status Codes** — bảng mapping (200, 201, 400, 401, 403, 404, 409, 422, 429, 500)
5. **Authentication** — `Authorization: Bearer <token>`, endpoints nào public vs protected
6. **Pagination** — query params: `?page=1&pageSize=20`, response pagination object
7. **Filtering & Sorting** — convention: `?filter[status]=active&sort=createdAt:desc`
8. **Error Codes** — enum tất cả error codes theo module

- [ ] **Step 1: Viết Standards.md với đủ 8 sections**
- [ ] **Step 2: Review — response format nhất quán, error codes có prefix module (AUTH_*, TOURNAMENT_*), pagination rõ ràng**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/04_API/Standards.md
git commit -m "docs: add API Standards"
```

---

### Task 16: Viết `M1_Auth_API.md` đến `M6_Notification_API.md`

**Format mỗi endpoint:**
```markdown
### POST /api/v1/auth/login
**Auth:** Public
**Description:** Đăng nhập bằng email/password

**Request:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Response 200:**
```json
{
  "accessToken": "string",
  "refreshToken": "string",
  "expiresIn": 900
}
```

**Errors:**
- `401 AUTH_INVALID_CREDENTIALS` — email hoặc password sai
- `403 AUTH_EMAIL_NOT_VERIFIED` — email chưa xác thực
- `429 AUTH_RATE_LIMIT_EXCEEDED` — quá nhiều lần thử
```

**Nguồn tham khảo:**
- `API-CONTRACT/` folder — contracts cũ (tham khảo, không copy)
- BA-SPEC tương ứng (vừa viết) — user stories → endpoints
- Schema.md (vừa viết) — field names chính xác

- [ ] **Step 1: Viết M1_Auth_API.md** — endpoints: register, login, logout, refresh-token, verify-email, forgot-password, reset-password, google-oauth, apple-oauth, facebook-oauth, get-profile, update-profile, upload-avatar
- [ ] **Step 2: Commit M1**

```bash
git add DOCUMENT-DESIGN/04_API/M1_Auth_API.md
git commit -m "docs: add M1 Auth API contracts"
```

- [ ] **Step 3: Viết M2_Tournament_API.md** — endpoints: CRUD tournament, publish, open/close registration, join/leave/waitlist, check-in, start, complete, cancel, list (với filters), get detail, bracket
- [ ] **Step 4: Commit M2**

```bash
git add DOCUMENT-DESIGN/04_API/M2_Tournament_API.md
git commit -m "docs: add M2 Tournament API contracts"
```

- [ ] **Step 5: Viết M3_Match_API.md** — endpoints: list matches, get match, record score, confirm score, dispute, match history
- [ ] **Step 6: Commit M3**

```bash
git add DOCUMENT-DESIGN/04_API/M3_Match_API.md
git commit -m "docs: add M3 Match API contracts"
```

- [ ] **Step 7: Viết M4_Community_API.md** — endpoints: CRUD community game, join/leave, record result, list (với filters)
- [ ] **Step 8: Commit M4**

```bash
git add DOCUMENT-DESIGN/04_API/M4_Community_API.md
git commit -m "docs: add M4 Community API contracts"
```

- [ ] **Step 9: Viết M5_Chat_API.md** — endpoints: get chat rooms, get messages (paginated), send message, delete message
- [ ] **Step 10: Commit M5**

```bash
git add DOCUMENT-DESIGN/04_API/M5_Chat_API.md
git commit -m "docs: add M5 Chat API contracts"
```

- [ ] **Step 11: Viết M6_Notification_API.md** — endpoints: list notifications, mark read, mark all read, delete, get preferences, update preferences
- [ ] **Step 12: Commit M6**

```bash
git add DOCUMENT-DESIGN/04_API/M6_Notification_API.md
git commit -m "docs: add M6 Notification API contracts"
```

---

## Chunk 7: Real-time & Environment Phase

**Files:**
- Create: `DOCUMENT-DESIGN/05_Realtime/SignalR_Contracts.md`
- Create: `DOCUMENT-DESIGN/06_Environment/Local_Setup.md`
- Create: `DOCUMENT-DESIGN/06_Environment/Environment_Variables.md`

> **Prerequisite:** API Phase (Chunk 6) phải hoàn tất.

---

### Task 17: Viết `SignalR_Contracts.md`

**Sections bắt buộc:**
1. **Connection** — URL, auth (token qua query string hay header?), reconnect strategy
2. **Hubs** — danh sách hubs (TournamentHub, MatchHub, ChatHub, NotificationHub)
3. **Events per Hub** — format:

```markdown
#### Server → Client: `MatchScoreUpdated`
**Hub:** MatchHub
**Trigger:** Khi score được record và confirm
**Payload:**
```json
{
  "matchId": "uuid",
  "homeScore": 11,
  "awayScore": 9,
  "gameNumber": 1
}
```
**Client subscribe:** Tất cả participants của tournament chứa match này
```

4. **Group Management** — ai join group nào, khi nào leave
5. **Error Handling** — hub exceptions, reconnection flow

**Nguồn tham khảo:**
- `REALTIME/SignalR_Contracts.md` — contracts cũ
- API Phase (vừa viết) — actions nào trigger real-time events

- [ ] **Step 1: Viết SignalR_Contracts.md với đủ 5 sections, tất cả events**
- [ ] **Step 2: Review — mỗi API action có real-time event tương ứng (nếu cần), payload schemas đầy đủ**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/05_Realtime/SignalR_Contracts.md
git commit -m "docs: add SignalR real-time contracts"
```

---

### Task 18: Viết `Local_Setup.md` và `Environment_Variables.md`

**Local_Setup.md sections:**
1. **Prerequisites** — .NET 10 SDK, Node.js, Docker, PostgreSQL client
2. **Clone & Setup** — git clone, restore packages
3. **Docker Compose** — PostgreSQL 16 + Redis (cung cấp docker-compose.yml mẫu)
4. **Database Setup** — run migrations, seed data
5. **Run** — backend, frontend web, mobile
6. **Verify** — health check endpoint, swagger URL

**Environment_Variables.md — bảng tất cả vars:**
```markdown
| Variable | Required | Example | Mô tả |
|----------|----------|---------|-------|
| DATABASE_URL | Yes | postgres://... | Connection string PostgreSQL |
| REDIS_URL | Yes | redis://localhost:6379 | Redis connection |
| JWT_SECRET | Yes | (random 256-bit) | JWT signing key |
| JWT_ISSUER | Yes | apppickleball.com | JWT issuer |
| GOOGLE_CLIENT_ID | No | 123.apps.google.com | OAuth Google |
...
```

- [ ] **Step 1: Viết Local_Setup.md**
- [ ] **Step 2: Viết Environment_Variables.md — tất cả vars từ Infrastructure.md**
- [ ] **Step 3: Commit**

```bash
git add DOCUMENT-DESIGN/06_Environment/
git commit -m "docs: add Environment setup docs"
```

---

## Checklist hoàn thành

- [ ] Chunk 1: Foundation (00_Overview)
- [ ] Chunk 2: BA-SPEC M1-M3
- [ ] Chunk 3: BA-SPEC M4-M6
- [ ] Chunk 4: Architecture (4 files)
- [ ] Chunk 5: Database (2 files)
- [ ] Chunk 6: API (7 files)
- [ ] Chunk 7: Real-time + Environment (3 files)

**Total: 19 documents + folder structure**
