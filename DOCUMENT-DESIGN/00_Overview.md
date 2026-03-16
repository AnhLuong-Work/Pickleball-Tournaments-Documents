# DOCUMENT-DESIGN — Navigation Guide

## 1. Giới thiệu

**AppPickleball** là ứng dụng quản lý giải đấu Pickleball, hỗ trợ toàn bộ vòng đời của một giải đấu: từ tạo giải, đăng ký tham gia, ghi nhận kết quả trận đấu, đến thông báo real-time và chat trong giải.

Tài liệu trong folder `DOCUMENT-DESIGN/` phục vụ việc **rebuild hệ thống hoàn toàn từ đầu** trên nền tech stack mới (.NET 10 + React + React Native Expo).

> **Lưu ý:** Folder `REDESIGN/` (cũ) được giữ nguyên làm **archive tham khảo** — không dùng làm source of truth cho lần rebuild này.

---

## 2. Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | .NET 10 Web API, Clean Architecture |
| ORM | Entity Framework Core 10 |
| Database | PostgreSQL 16 |
| Cache | Redis |
| Real-time | SignalR |
| Auth | JWT + Refresh Token Rotation + OAuth2 (Google, Apple, Facebook) |
| Mobile Push | FCM (Firebase Cloud Messaging) |
| Frontend Web | React + Vite + TypeScript |
| Mobile | React Native Expo |

---

## 3. Module Map

Hệ thống mới được tổ chức thành **6 modules**, gộp lại từ 7 modules cũ để giảm chồng chéo:

| Module Mới | Mô tả | Module Cũ tương đương |
|-----------|-------|----------------------|
| M1 — Auth & Profile | Đăng ký, đăng nhập, OAuth, quản lý profile | M1 Auth + M2 User Profile |
| M2 — Tournament Management | Tạo, quản lý, tham gia giải đấu, tìm kiếm | M2 Tournament + M4 Discovery/Search |
| M3 — Match & Scoring | Ghi nhận kết quả và lịch sử trận đấu | M3 Match Scoring |
| M4 — Community Game | Game cộng đồng không chính thức | M5 Community Game |
| M5 — Chat | Nhắn tin trong giải đấu | M6 Chat |
| M6 — Notification | Push notification, in-app notification | M7 Notification |

---

## 4. Cấu Trúc Tài Liệu

```
DOCUMENT-DESIGN/
├── 00_Overview.md           ← file này — navigation guide
├── 01_BA-SPEC/              ← Business Analysis: acceptance criteria & business rules (viết đầu tiên)
├── 02_Architecture/         ← Kiến trúc hệ thống: Clean Architecture, Security, Domain, Infrastructure
├── 03_Database/             ← Database schema, ERD, indexes, migration notes
├── 04_API/                  ← API contracts chi tiết per module (request/response schema)
├── 05_Realtime/             ← SignalR real-time contracts (events, hubs, payloads)
└── 06_Environment/          ← Setup môi trường dev, environment variables
```

---

## 5. Thứ Tự Đọc

| Tình huống | File cần đọc |
|-----------|-------------|
| Hiểu business rules của Auth | `01_BA-SPEC/M1_Auth_BA.md` |
| Hiểu business rules của Tournament | `01_BA-SPEC/M2_Tournament_BA.md` |
| Hiểu business rules của Match & Scoring | `01_BA-SPEC/M3_Match_Scoring_BA.md` |
| Hiểu business rules của Community Game | `01_BA-SPEC/M4_Community_Game_BA.md` |
| Hiểu business rules của Chat | `01_BA-SPEC/M5_Chat_BA.md` |
| Hiểu business rules của Notification | `01_BA-SPEC/M6_Notification_BA.md` |
| Thiết kế kiến trúc hệ thống | `02_Architecture/Clean_Architecture.md` |
| Thiết kế security (JWT, OAuth) | `02_Architecture/Security_Layer.md` |
| Thiết kế domain entities | `02_Architecture/Domain_Design.md` |
| Setup infrastructure (DB, cache) | `02_Architecture/Infrastructure.md` |
| Thiết kế database tables | `03_Database/Schema.md` |
| Thêm indexes / optimize queries | `03_Database/Indexes.md` |
| Build API endpoint | `04_API/Standards.md` → file module tương ứng |
| Setup SignalR client | `05_Realtime/SignalR_Contracts.md` |
| Setup môi trường dev | `06_Environment/Local_Setup.md` |
| Biết env variables cần thiết | `06_Environment/Environment_Variables.md` |

---

## 6. Roles

Hệ thống dùng **3 system roles** với permission abstraction — dễ scale sau này mà không cần refactor business logic.

| Role | Mô tả | Default |
|------|-------|---------|
| `User` | Join giải, xem, chat, community game | ✅ Khi đăng ký |
| `Creator` | Tất cả của User + tạo/quản lý giải đấu | Upgrade từ User |
| `Admin` | Tất cả quyền + quản trị hệ thống | Set thủ công |

**Hierarchy:** `Admin` ⊃ `Creator` ⊃ `User` — mỗi user có đúng 1 role.

**Contextual roles** (trong từng giải đấu, không phải system role):
- `Organizer` — user đã tạo giải đó (lưu qua `tournaments.created_by`)
- `Participant` — user đã join giải đó (lưu qua bảng `participants`)

**Authorization pattern:**
```csharp
// Luôn check permission, không check role trực tiếp
if (user.HasPermission("tournament.create")) { ... }
// → dễ swap sang full RBAC sau này nếu cần
```
