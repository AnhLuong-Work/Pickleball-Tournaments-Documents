# Documents — Navigation Guide for Claude

Đây là repo tài liệu tổng hợp cho **AppPickleball** — ứng dụng quản lý giải đấu Pickleball.
Tech stack: .NET 8 (Backend) · React + Vite + TypeScript (Web) · React Native Expo (Mobile) · PostgreSQL · Redis · SignalR · FCM

---

## Cấu Trúc Thư Mục

```
Documents/
├── CLAUDE.md                   ← file này — index & navigation
│
├── API-CONTRACT/               ← Hợp đồng API chi tiết (request/response schema)
│   ├── 00_API_Overview.md      ← danh sách tất cả 52 endpoints + enums + HTTP codes
│   ├── 01_Authentication_API_Contracts.md
│   ├── 02_User_Profile_API_Contracts.md
│   ├── 03_Tournament_Management_API_Contracts.md
│   ├── 04_Participant_Management_API_Contracts.md
│   ├── 05_Match_Scoring_API_Contracts.md
│   ├── 06_Community_Game_API_Contracts.md
│   ├── 07_Chat_Notification_API_Contracts.md
│   └── API_Contract.md         ← master doc tổng hợp
│
├── ARCHITECTURE/               ← Kiến trúc hệ thống
│   ├── Architecture_Overview.md    ← tổng quan product, tech stack, modules, DB schema, roadmap
│   └── Backend_Architecture_DevOps.md ← chi tiết Clean Architecture, layers, DevOps, CI/CD
│
├── DATABASE/                   ← Thiết kế cơ sở dữ liệu
│   ├── Database_Design.md      ← ERD, chi tiết 18 bảng, indexes, business rules
│   ├── Database-design-format.md
│   └── create_pickleball_database.sql ← script tạo DB
│
├── MAINFLOWS/                  ← Luồng nghiệp vụ end-to-end
│   ├── 00_Flow_Overview.md
│   ├── 01_Auth_Flow.md
│   ├── 02_Tournament_Lifecycle_Flow.md
│   ├── 03_Match_Scoring_Flow.md
│   ├── 04_Community_Game_Flow.md
│   └── 05_Notification_Flow.md
│
├── SCREEN-INVENTORY/           ← Danh sách màn hình
│   ├── Web_Screen_Inventory.md
│   └── Mobile_Screen_Inventory.md
│
├── BA-SPEC/                    ← Business Analysis — acceptance criteria & business rules
│   ├── 01_Auth_BA_Spec.md
│   ├── 02_Tournament_BA_Spec.md
│   ├── 03_Match_Scoring_BA_Spec.md
│   ├── 04_Community_BA_Spec.md
│   └── 05_Notification_BA_Spec.md
│
├── CONVENTIONS/                ← Coding conventions
│   ├── Backend_DotNet_Convention.md
│   ├── Frontend_React_Convention.md
│   └── Agent_Skills_Guide.md
│
├── ENVIRONMENT/                ← Setup môi trường
│   ├── Local_Setup.md
│   └── Environment_Variables.md
│
├── REALTIME/                   ← SignalR real-time contracts
│   └── SignalR_Contracts.md
│
└── THAM-KHAO/                  ← Tài liệu tham khảo ngoài
    └── README.md
```

---

## Khi Nào Đọc File Nào

| Tình huống | File cần đọc |
|-----------|-------------|
| Build API endpoint mới | [API-CONTRACT/00_API_Overview.md](./API-CONTRACT/00_API_Overview.md) → file module tương ứng |
| Hiểu luồng nghiệp vụ trước khi code | [MAINFLOWS/00_Flow_Overview.md](./MAINFLOWS/00_Flow_Overview.md) |
| Viết validation / business logic | [BA-SPEC/](./BA-SPEC/) file tương ứng |
| Build màn hình frontend | [SCREEN-INVENTORY/Web_Screen_Inventory.md](./SCREEN-INVENTORY/Web_Screen_Inventory.md) |
| Thiết kế DB / thêm entity | [DATABASE/Database_Design.md](./DATABASE/Database_Design.md) |
| Hiểu kiến trúc tổng thể | [ARCHITECTURE/Architecture_Overview.md](./ARCHITECTURE/Architecture_Overview.md) |
| Setup SignalR client | [REALTIME/SignalR_Contracts.md](./REALTIME/SignalR_Contracts.md) |
| Setup môi trường dev | [ENVIRONMENT/Local_Setup.md](./ENVIRONMENT/Local_Setup.md) |
| Biết env variables cần | [ENVIRONMENT/Environment_Variables.md](./ENVIRONMENT/Environment_Variables.md) |
| Code convention BE | [CONVENTIONS/Backend_DotNet_Convention.md](./CONVENTIONS/Backend_DotNet_Convention.md) |
| Code convention FE | [CONVENTIONS/Frontend_React_Convention.md](./CONVENTIONS/Frontend_React_Convention.md) |
| Biết skills/agents có sẵn | [CONVENTIONS/Agent_Skills_Guide.md](./CONVENTIONS/Agent_Skills_Guide.md) |

---

## Vai Trò Người Dùng

| Role | Mô tả |
|------|-------|
| `Admin` | Quản trị hệ thống toàn phần |
| `Creator` | Người tạo và quản lý giải đấu |
| `Player` | Người tham gia giải đấu |
| `User` / `Guest` | Người dùng chưa join giải, chỉ xem |

## Module Map

| Module | Phase | Files liên quan |
|--------|:-----:|-----------------|
| M1 — Auth & Profile | 1 | `01_Auth*`, `02_User*` |
| M2 — Tournament Management | 1 | `03_Tournament*`, `04_Participant*` |
| M3 — Match & Scoring | 1 | `05_Match*` |
| M4 — Khám phá & Tìm kiếm | 1 | `03_Tournament*` (GET endpoints) |
| M5 — Community Game | 2 | `06_Community*` |
| M6 — Chat | 2 | `07_Chat*` |
| M7 — Notification | 1 | `07_Chat_Notification*` |
