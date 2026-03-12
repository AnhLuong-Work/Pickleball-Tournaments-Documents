# 🏓 AppPickleball — Tài Liệu Hệ Thống

> Repo tổng hợp **toàn bộ tài liệu kỹ thuật** cho ứng dụng quản lý giải đấu Pickleball.
> Dùng cho: Claude Code CLI · Developer · DevOps · BA · QA

---

## Mục Lục Nhanh

| Muốn làm gì | Đọc ở đâu |
|-------------|----------|
| Hiểu tổng quan hệ thống | [Architecture Overview](./ARCHITECTURE/Architecture_Overview.md) |
| Build dự án từ đầu | [Master Execution Plan](./EXECUTION-PLAN/00_Master_Execution_Plan.md) |
| Code Backend (.NET) | [BE Convention](./CONVENTIONS/Backend_DotNet_Convention.md) · [API Contract](./API-CONTRACT/00_API_Overview.md) |
| Code Frontend (React) | [FE Convention](./CONVENTIONS/Frontend_React_Convention.md) · [Screen Inventory](./SCREEN-INVENTORY/Web_Screen_Inventory.md) |
| Hiểu luồng nghiệp vụ | [Main Flows Overview](./MAINFLOWS/00_Flow_Overview.md) |
| Biết màn hình cần build | [Web Screens](./SCREEN-INVENTORY/Web_Screen_Inventory.md) · [Mobile Screens](./SCREEN-INVENTORY/Mobile_Screen_Inventory.md) |
| Validation / Business rules | [BA-SPEC/](./BA-SPEC/) |
| Cấu trúc database | [Database Design](./DATABASE/Database_Design.md) |
| SignalR real-time | [SignalR Contracts](./REALTIME/SignalR_Contracts.md) |
| Setup môi trường dev | [Local Setup](./ENVIRONMENT/Local_Setup.md) |
| Deploy lên server | [Deploy Target](./DEPLOYMENT/Deploy_Target.md) · [Docker](./DEPLOYMENT/Docker_Infrastructure.md) · [CI/CD](./DEPLOYMENT/CICD_Pipeline.md) |
| Verify toàn bộ hệ thống | [Integration Checklist](./EXECUTION-PLAN/04_Integration_Checklist.md) |

---

## Tech Stack

| Layer | Công nghệ |
|-------|----------|
| **Backend** | .NET 8 · Clean Architecture · MediatR · EF Core |
| **Frontend Web** | React 18 · Vite · TypeScript · TailwindCSS · Zustand |
| **Mobile** | React Native · Expo · TypeScript |
| **Database** | PostgreSQL 16 |
| **Cache** | Redis 7 |
| **Realtime** | ASP.NET Core SignalR |
| **Storage** | Cloudinary (Free tier) |
| **Push Notification** | Firebase FCM |
| **Auth** | JWT + Refresh Token · OAuth2 (Google/Apple/Facebook) |
| **Infrastructure** | Docker · Nginx · GitHub Actions CI/CD |

---

## Cấu Trúc Thư Mục Tài Liệu

```
Documents/
│
├── README.md                        ← 📄 File này — tổng quan toàn bộ
├── CLAUDE.md                        ← 🤖 Navigation guide cho Claude CLI
│
├── EXECUTION-PLAN/                  ← 🚀 Kế hoạch thực thi từ A-Z
│   ├── 00_Master_Execution_Plan.md  ← Thứ tự build toàn bộ dự án
│   ├── 01_Project_Bootstrap.md      ← Scaffold repos từ đầu
│   ├── 02_Backend_Build_Order.md    ← Thứ tự build từng layer BE
│   ├── 03_Frontend_Build_Order.md   ← Thứ tự build pages FE
│   ├── 04_Integration_Checklist.md ← Verify FE+BE hoạt động
│   ├── CLAUDE_FE_Web.md             ← Template CLAUDE.md cho repo FE
│   └── CLAUDE_Mobile.md             ← Template CLAUDE.md cho repo Mobile
│
├── API-CONTRACT/                    ← 📡 Hợp đồng API (52 endpoints)
│   ├── 00_API_Overview.md           ← Tổng hợp tất cả endpoints + enums
│   ├── 01_Authentication_API_Contracts.md
│   ├── 02_User_Profile_API_Contracts.md
│   ├── 03_Tournament_Management_API_Contracts.md
│   ├── 04_Participant_Management_API_Contracts.md
│   ├── 05_Match_Scoring_API_Contracts.md
│   ├── 06_Community_Game_API_Contracts.md
│   ├── 07_Chat_Notification_API_Contracts.md
│   └── API_Contract.md              ← Master doc tổng hợp
│
├── ARCHITECTURE/                    ← 🏗️ Kiến trúc hệ thống
│   ├── Architecture_Overview.md     ← Product overview, tech stack, modules, DB schema
│   └── Backend_Architecture_DevOps.md ← Clean Architecture, layers, CI/CD
│
├── DATABASE/                        ← 🗄️ Cơ sở dữ liệu
│   ├── Database_Design.md           ← ERD, 18 bảng, indexes, business constraints
│   ├── Database-design-format.md    ← Format chuẩn thiết kế bảng
│   ├── create_pickleball_database.sql ← Script tạo schema
│   └── seed_data.sql                ← Dữ liệu mẫu dev/test
│
├── MAINFLOWS/                       ← 🔄 Luồng nghiệp vụ
│   ├── 00_Flow_Overview.md          ← Tổng quan + sơ đồ quan hệ giữa luồng
│   ├── 01_Auth_Flow.md              ← Đăng ký, đăng nhập, OAuth2, refresh token
│   ├── 02_Tournament_Lifecycle_Flow.md ← Vòng đời giải đấu draft→completed
│   ├── 03_Match_Scoring_Flow.md     ← Nhập điểm, BXH, live score
│   ├── 04_Community_Game_Flow.md    ← Tạo game, waitlist, auto-promote
│   └── 05_Notification_Flow.md      ← In-app + FCM push notification
│
├── SCREEN-INVENTORY/                ← 📱 Danh sách màn hình
│   ├── Web_Screen_Inventory.md      ← 21 màn hình React (routes, APIs, components)
│   └── Mobile_Screen_Inventory.md   ← Toàn bộ screens React Native
│
├── BA-SPEC/                         ← 📋 Business Analysis — Rules & Criteria
│   ├── 01_Auth_BA_Spec.md           ← Validation, edge cases Auth
│   ├── 02_Tournament_BA_Spec.md     ← Business rules Tournament
│   ├── 03_Match_Scoring_BA_Spec.md  ← Score validation, standings logic
│   ├── 04_Community_BA_Spec.md      ← Community game rules
│   └── 05_Notification_BA_Spec.md   ← Notification triggers, FCM priority
│
├── CONVENTIONS/                     ← 📐 Coding conventions
│   ├── Backend_DotNet_Convention.md ← .NET patterns, EF Core, CQRS rules
│   ├── Frontend_React_Convention.md ← React, Zustand, React Query patterns
│   ├── FE_BE_Integration.md         ← Auth flow FE, error handling, token storage
│   └── Agent_Skills_Guide.md        ← Claude skills, agent team, git workflow
│
├── ENVIRONMENT/                     ← ⚙️ Môi trường
│   ├── Local_Setup.md               ← Setup dev local step-by-step
│   └── Environment_Variables.md     ← Tất cả env vars (BE + FE + Mobile)
│
├── DEPLOYMENT/                      ← 🚢 Triển khai
│   ├── Deploy_Target.md             ← Server spec, provider, strategy
│   ├── Docker_Infrastructure.md     ← Dockerfile + docker-compose full stack
│   ├── Nginx_Config.md              ← Reverse proxy, SSL, static files
│   └── CICD_Pipeline.md             ← GitHub Actions workflows
│
├── REALTIME/                        ← ⚡ SignalR
│   └── SignalR_Contracts.md         ← 3 hubs, event types, TypeScript interfaces
│
└── THAM-KHAO/                       ← 📚 Tài liệu tham khảo ngoài
    └── README.md
```

---

## Chi Tiết Từng Nhóm Tài Liệu

### EXECUTION-PLAN — Kế Hoạch Thực Thi {#execution-plan}

> **Dành cho:** Claude CLI · Developer mới vào dự án
> **Mục đích:** Có thể build toàn bộ hệ thống từ zero mà không cần hỏi thêm

| File | Nội dung |
|------|---------|
| [00_Master_Execution_Plan.md](./EXECUTION-PLAN/00_Master_Execution_Plan.md) | Roadmap thực thi 5 giai đoạn: Bootstrap → DB → BE → FE → Deploy |
| [01_Project_Bootstrap.md](./EXECUTION-PLAN/01_Project_Bootstrap.md) | Lệnh scaffold chính xác cho cả 3 repos |
| [02_Backend_Build_Order.md](./EXECUTION-PLAN/02_Backend_Build_Order.md) | Thứ tự: Domain → Infrastructure → Application → API |
| [03_Frontend_Build_Order.md](./EXECUTION-PLAN/03_Frontend_Build_Order.md) | Thứ tự: Setup → Auth → Tournament → Match → ... |
| [04_Integration_Checklist.md](./EXECUTION-PLAN/04_Integration_Checklist.md) | Verify commands sau mỗi bước |
| [CLAUDE_FE_Web.md](./EXECUTION-PLAN/CLAUDE_FE_Web.md) | Copy vào `pickleball-web/CLAUDE.md` |
| [CLAUDE_Mobile.md](./EXECUTION-PLAN/CLAUDE_Mobile.md) | Copy vào `pickleball-mobile/CLAUDE.md` |

---

### API-CONTRACT — Hợp Đồng API {#api-contract}

> **Dành cho:** Claude CLI · Backend dev · Frontend dev · QA
> **Mục đích:** Source of truth cho tất cả 52 API endpoints

**52 endpoints** chia thành 7 modules:
- **Auth** (7): register, login, OAuth2, refresh, verify-email, change-password
- **User & Profile** (10): profile, avatar, follow system
- **Tournament** (7): CRUD, status transition, banner upload
- **Participant** (7): invite, request, approve, teams, groups
- **Match & Scoring** (6): schedule, score input/edit, standings, results
- **Community Game** (8): lobby, CRUD, join, waitlist
- **Chat & Notification** (7): rooms, messages, notification

---

### ARCHITECTURE — Kiến Trúc {#architecture}

> **Dành cho:** Claude CLI · Architect · Developer
> **Mục đích:** Hiểu cách các layers và services kết nối với nhau

- Clean Architecture (4 layers: API → Application → Domain ← Infrastructure)
- Tech stack chi tiết với lý do chọn
- Module breakdown (M1–M7) với phase roadmap
- ERD overview

---

### DATABASE — Cơ Sở Dữ Liệu {#database}

> **Dành cho:** Claude CLI · Backend dev · DBA
> **Mục đích:** Tạo và quản lý schema không dùng EF Migrations

**18 bảng** nhóm theo domain:
- Auth: `Users`, `UserAuthProviders`, `RefreshTokens`
- Tournament: `Tournaments`, `Participants`, `Teams`, `Groups`, `GroupMembers`, `Matches`, `MatchScoreHistories`
- Community: `CommunityGames`, `GameParticipants`
- Chat: `ChatRooms`, `ChatMembers`, `Messages`
- Notification: `Notifications`, `DeviceTokens`
- Social: `Follows`

**Không dùng EF Core Migrations** — schema quản lý qua SQL scripts.

---

### MAINFLOWS — Luồng Nghiệp Vụ {#mainflows}

> **Dành cho:** Claude CLI · Developer · BA
> **Mục đích:** Hiểu WHY trước khi code — tránh implement sai thứ tự, sai điều kiện

Mỗi flow mô tả trạng thái, điều kiện chuyển, actors, và edge cases bằng ASCII flowchart.

---

### SCREEN-INVENTORY — Màn Hình {#screen-inventory}

> **Dành cho:** Claude CLI · Frontend dev
> **Mục đích:** Biết chính xác bao nhiêu màn hình, route, components, API calls mỗi màn hình

- **Web:** 21 screens, routes React Router v6, shared components
- **Mobile:** Full navigation structure, permissions, offline support notes

---

### BA-SPEC — Business Analysis {#ba-spec}

> **Dành cho:** Claude CLI · Developer · QA
> **Mục đích:** Acceptance criteria + validation rules để code đúng business logic

Mỗi file có: Acceptance Criteria (checklist), Validation Rules (table), Edge Cases, Business Rules.

---

### CONVENTIONS — Coding Standards {#conventions}

> **Dành cho:** Claude CLI — PHẢI đọc trước khi code
> **Mục đích:** Đảm bảo code nhất quán, đúng pattern

| File | Covers |
|------|--------|
| `Backend_DotNet_Convention.md` | CQRS, Repository, EF Core, ApiResponse, DateTime UTC |
| `Frontend_React_Convention.md` | Folder structure, React Query, Zustand, Axios interceptors |
| `FE_BE_Integration.md` | Token storage, 401 handling, error display, CORS |
| `Agent_Skills_Guide.md` | Available skills, agent team, PR workflow |

---

### ENVIRONMENT — Môi Trường {#environment}

> **Dành cho:** Claude CLI · DevOps · Developer mới
> **Mục đích:** Setup môi trường không cần hỏi

- Local dev: Docker compose DB + Redis, user-secrets BE, .env FE
- Tất cả env variables cho 3 tier: BE (.NET) · FE (Vite) · Mobile (Expo)

---

### DEPLOYMENT — Triển Khai {#deployment}

> **Dành cho:** Claude CLI · DevOps
> **Mục đích:** Deploy toàn bộ stack lên production không cần human can thiệp

| File | Nội dung |
|------|---------|
| `Deploy_Target.md` | VPS Ubuntu 22.04, server requirements, strategy |
| `Docker_Infrastructure.md` | Dockerfile cho BE + FE, docker-compose full stack |
| `Nginx_Config.md` | Reverse proxy, SSL Let's Encrypt, static file serving |
| `CICD_Pipeline.md` | GitHub Actions: build → test → deploy |

---

### REALTIME — SignalR {#realtime}

> **Dành cho:** Claude CLI · Frontend dev · Backend dev
> **Mục đích:** TypeScript-ready event contracts cho 3 hubs

- `TournamentHub` — live scores, standings
- `NotificationHub` — real-time notifications
- `ChatHub` — messaging (Phase 2)

---

## Onboarding — Bắt Đầu Nhanh

> Dành cho **thành viên mới** hoặc **Claude CLI** khi vào dự án lần đầu.

### Ngày 1 — Hiểu hệ thống (1–2 giờ)

```
1. Đọc README này (file bạn đang xem) → nắm tổng quan
2. Đọc Architecture Overview       → hiểu tech stack, layers, modules
3. Đọc MAINFLOWS/00_Flow_Overview  → hiểu luồng nghiệp vụ chính
4. Setup môi trường local          → ENVIRONMENT/Local_Setup.md
```

### Ngày 2 — Đi sâu theo vai trò

> Xem bảng **"Đọc Tài Liệu Theo Vai Trò"** bên dưới — chọn đúng role, đọc đúng docs.

### Ngày 3+ — Bắt đầu code

```
1. Chọn task từ module roadmap (M1 → M7)
2. Đọc BA-SPEC của module đó
3. Đọc API-CONTRACT tương ứng
4. Code theo CONVENTIONS
5. Verify với Integration Checklist
```

### Checklist trước khi code task đầu tiên

- [ ] Đã đọc `CONVENTIONS/` cho role của mình
- [ ] Đã đọc `BA-SPEC/` của module đang làm
- [ ] Đã setup local DB với `DATABASE/create_pickleball_database.sql`
- [ ] Đã seed data với `DATABASE/seed_data.sql`
- [ ] Đã kiểm tra `ENVIRONMENT/Environment_Variables.md` — đủ env vars
- [ ] Claude CLI: đã đọc `CLAUDE.md` trong repo

---

## Đọc Tài Liệu Theo Vai Trò

### Backend Developer (.NET)

| Ưu tiên | Tài liệu | Mục đích |
|:-------:|---------|---------|
| 🔴 Bắt buộc | [Backend_DotNet_Convention.md](./CONVENTIONS/Backend_DotNet_Convention.md) | CQRS, Repository, EF Core patterns |
| 🔴 Bắt buộc | [Architecture_Overview.md](./ARCHITECTURE/Architecture_Overview.md) | Hiểu layer dependencies |
| 🔴 Bắt buộc | [Database_Design.md](./DATABASE/Database_Design.md) + [create_pickleball_database.sql](./DATABASE/create_pickleball_database.sql) | Schema, relationships, indexes |
| 🔴 Bắt buộc | [API-CONTRACT/](./API-CONTRACT/00_API_Overview.md) | Endpoint contracts, request/response |
| 🟡 Quan trọng | [MAINFLOWS/](./MAINFLOWS/00_Flow_Overview.md) | Business flows trước khi code |
| 🟡 Quan trọng | [BA-SPEC/](./BA-SPEC/) | Validation rules, edge cases |
| 🟡 Quan trọng | [SignalR_Contracts.md](./REALTIME/SignalR_Contracts.md) | Hub events, payload types |
| 🟢 Khi cần | [Backend_Architecture_DevOps.md](./ARCHITECTURE/Backend_Architecture_DevOps.md) | CI/CD, deployment flow |
| 🟢 Khi cần | [seed_data.sql](./DATABASE/seed_data.sql) | Dữ liệu test sẵn có |

---

### Frontend Developer (React Web)

| Ưu tiên | Tài liệu | Mục đích |
|:-------:|---------|---------|
| 🔴 Bắt buộc | [Frontend_React_Convention.md](./CONVENTIONS/Frontend_React_Convention.md) | Folder structure, Zustand, React Query |
| 🔴 Bắt buộc | [FE_BE_Integration.md](./CONVENTIONS/FE_BE_Integration.md) | Token storage, 401 refresh, CORS |
| 🔴 Bắt buộc | [Web_Screen_Inventory.md](./SCREEN-INVENTORY/Web_Screen_Inventory.md) | Danh sách 21 màn hình, routes, components |
| 🔴 Bắt buộc | [API-CONTRACT/](./API-CONTRACT/00_API_Overview.md) | Biết endpoint nào gọi từ màn nào |
| 🟡 Quan trọng | [MAINFLOWS/](./MAINFLOWS/00_Flow_Overview.md) | Hiểu flow trước khi build UI |
| 🟡 Quan trọng | [SignalR_Contracts.md](./REALTIME/SignalR_Contracts.md) | TypeScript interfaces cho realtime |
| 🟢 Khi cần | [Environment_Variables.md](./ENVIRONMENT/Environment_Variables.md) | VITE_ env vars |
| 🟢 Khi cần | [BA-SPEC/](./BA-SPEC/) | Validation messages, UI edge cases |

---

### Mobile Developer (React Native / Expo)

| Ưu tiên | Tài liệu | Mục đích |
|:-------:|---------|---------|
| 🔴 Bắt buộc | [Frontend_React_Convention.md](./CONVENTIONS/Frontend_React_Convention.md) | Shared convention FE/Mobile |
| 🔴 Bắt buộc | [FE_BE_Integration.md](./CONVENTIONS/FE_BE_Integration.md) | Auth flow, token (expo-secure-store) |
| 🔴 Bắt buộc | [Mobile_Screen_Inventory.md](./SCREEN-INVENTORY/Mobile_Screen_Inventory.md) | Navigation structure, permissions |
| 🔴 Bắt buộc | [API-CONTRACT/](./API-CONTRACT/00_API_Overview.md) | Endpoint list |
| 🟡 Quan trọng | [SignalR_Contracts.md](./REALTIME/SignalR_Contracts.md) | Realtime events |
| 🟡 Quan trọng | [05_Notification_Flow.md](./MAINFLOWS/05_Notification_Flow.md) | FCM push notification flow |
| 🟢 Khi cần | [Environment_Variables.md](./ENVIRONMENT/Environment_Variables.md) | Expo env vars |

---

### Business Analyst / Product Owner

| Ưu tiên | Tài liệu | Mục đích |
|:-------:|---------|---------|
| 🔴 Bắt buộc | [Architecture_Overview.md](./ARCHITECTURE/Architecture_Overview.md) | Tổng quan product, modules, roadmap |
| 🔴 Bắt buộc | [MAINFLOWS/](./MAINFLOWS/00_Flow_Overview.md) | Nghiệp vụ end-to-end |
| 🔴 Bắt buộc | [BA-SPEC/](./BA-SPEC/) | Acceptance criteria, business rules |
| 🟡 Quan trọng | [Web_Screen_Inventory.md](./SCREEN-INVENTORY/Web_Screen_Inventory.md) | Danh sách màn hình, user roles |
| 🟡 Quan trọng | [Mobile_Screen_Inventory.md](./SCREEN-INVENTORY/Mobile_Screen_Inventory.md) | Mobile UX |
| 🟢 Khi cần | [API-CONTRACT/00_API_Overview.md](./API-CONTRACT/00_API_Overview.md) | Scope của từng tính năng |

---

### QA / Tester

| Ưu tiên | Tài liệu | Mục đích |
|:-------:|---------|---------|
| 🔴 Bắt buộc | [BA-SPEC/](./BA-SPEC/) | Acceptance criteria để viết test cases |
| 🔴 Bắt buộc | [API-CONTRACT/](./API-CONTRACT/00_API_Overview.md) | Request/response để test API |
| 🔴 Bắt buộc | [seed_data.sql](./DATABASE/seed_data.sql) | Dữ liệu test sẵn có (users, tournaments) |
| 🟡 Quan trọng | [MAINFLOWS/](./MAINFLOWS/00_Flow_Overview.md) | End-to-end flows để test regression |
| 🟡 Quan trọng | [04_Integration_Checklist.md](./EXECUTION-PLAN/04_Integration_Checklist.md) | Checklist verify hệ thống |
| 🟢 Khi cần | [Environment_Variables.md](./ENVIRONMENT/Environment_Variables.md) | Setup test environment |

---

### DevOps / Infrastructure

| Ưu tiên | Tài liệu | Mục đích |
|:-------:|---------|---------|
| 🔴 Bắt buộc | [Deploy_Target.md](./DEPLOYMENT/Deploy_Target.md) | Server spec, provider, strategy |
| 🔴 Bắt buộc | [Docker_Infrastructure.md](./DEPLOYMENT/Docker_Infrastructure.md) | Dockerfile + docker-compose |
| 🔴 Bắt buộc | [CICD_Pipeline.md](./DEPLOYMENT/CICD_Pipeline.md) | GitHub Actions workflows |
| 🔴 Bắt buộc | [Nginx_Config.md](./DEPLOYMENT/Nginx_Config.md) | Reverse proxy, SSL, WebSocket |
| 🟡 Quan trọng | [Environment_Variables.md](./ENVIRONMENT/Environment_Variables.md) | Tất cả secrets cần thiết |
| 🟢 Khi cần | [create_pickleball_database.sql](./DATABASE/create_pickleball_database.sql) | Init DB production |

---

### Claude CLI / AI Agent

| Ưu tiên | Tài liệu | Mục đích |
|:-------:|---------|---------|
| 🔴 Bắt buộc | `CLAUDE.md` (trong repo đang làm) | Rules và navigation |
| 🔴 Bắt buộc | [00_Master_Execution_Plan.md](./EXECUTION-PLAN/00_Master_Execution_Plan.md) | Thứ tự build toàn bộ |
| 🔴 Bắt buộc | [Backend_DotNet_Convention.md](./CONVENTIONS/Backend_DotNet_Convention.md) hoặc [Frontend_React_Convention.md](./CONVENTIONS/Frontend_React_Convention.md) | Code đúng pattern |
| 🔴 Bắt buộc | BA-SPEC + MAINFLOWS của module đang build | Không code sai logic |
| 🟡 Quan trọng | API-CONTRACT của module đang build | Request/response schema |
| 🟡 Quan trọng | [Database_Design.md](./DATABASE/Database_Design.md) | Entity relationships |

---

## Repos Liên Quan

| Repo | CLAUDE.md | Mô tả |
|------|:---------:|-------|
| `AppPickleball` (BE) | ✅ `BE/CLAUDE.md` | .NET 8 API |
| `pickleball-web` (FE) | 📄 `EXECUTION-PLAN/CLAUDE_FE_Web.md` → copy vào root | React Vite App |
| `pickleball-mobile` | 📄 `EXECUTION-PLAN/CLAUDE_Mobile.md` → copy vào root | React Native Expo |
| `Documents` (docs) | ✅ `CLAUDE.md` | Repo tài liệu này |

---

## Modules & Phase Roadmap

| Module | Tên | Phase | Status |
|--------|-----|:-----:|--------|
| M1 | Auth & Profile | 1 | 🟡 Cần build |
| M2 | Tournament Management | 1 | 🟡 Cần build |
| M3 | Match & Scoring | 1 | 🟡 Cần build |
| M4 | Khám phá & Tìm kiếm | 1 | 🟡 Cần build |
| M7 | Notification | 1 | 🟡 Cần build |
| M5 | Community Game | 2 | ⏳ Phase 2 |
| M6 | Chat | 2 | ⏳ Phase 2 |

---

## Quy Tắc Quan Trọng Cho Claude CLI

> Claude CLI PHẢI tuân thủ các rules sau khi làm việc trong project này:

1. **Đọc CLAUDE.md trong mỗi repo trước khi làm bất cứ điều gì**
2. **Đọc BA-SPEC trước khi code business logic**
3. **Đọc MAINFLOWS trước khi code feature mới**
4. **KHÔNG commit vào main/develop** — luôn tạo branch `agent/YYYYMMDD-slug`
5. **Build verify sau mỗi thay đổi:** `dotnet build` (BE) hoặc `npm run build` (FE)
6. **Không hardcode strings** — dùng localization (BE) hoặc constants (FE)
7. **DateTime.UtcNow** — không bao giờ `DateTime.Now`
8. **Manual mapping** — không AutoMapper
9. **Tài liệu là source of truth** — không tự suy diễn business logic

---

*Cập nhật lần cuối: Tháng 3, 2026 — v1.1*
