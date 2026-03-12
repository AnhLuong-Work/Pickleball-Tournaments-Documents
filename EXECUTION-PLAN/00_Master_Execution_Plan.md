# Master Execution Plan — Build AppPickleball từ Zero

**Phiên bản:** 1.0 | **Ngày:** Tháng 3, 2026
**Mục tiêu:** Claude CLI có thể build toàn bộ hệ thống không cần hỏi thêm

---

## Tổng Quan 5 Giai Đoạn

```
PHASE 0: Bootstrap
  → Tạo repos, scaffold structure, cài dependencies

PHASE 1: Database
  → Tạo schema PostgreSQL, seed data, verify kết nối

PHASE 2: Backend
  → Build từng layer theo thứ tự: Domain → Infra → Application → API
  → Verify từng module với /api-test

PHASE 3: Frontend Web
  → Scaffold React app, build từng feature module
  → Kết nối với BE đã chạy

PHASE 4: Deploy
  → Docker build, push, deploy VPS
  → Setup Nginx, SSL, CI/CD
```

---

## PHASE 0 — Bootstrap (Thực hiện 1 lần)

### Bước 0.1: Tạo repos
```bash
# BE repo đã có tại: C:\Users\LENOVO\Desktop\AppPick\BE
# Tạo FE repo
mkdir pickleball-web && cd pickleball-web && git init

# Tạo Mobile repo
mkdir pickleball-mobile && cd pickleball-mobile && git init
```

### Bước 0.2: Scaffold các repo
→ Xem chi tiết: [`01_Project_Bootstrap.md`](./01_Project_Bootstrap.md)

### Bước 0.3: Copy CLAUDE.md vào repo FE và Mobile
```bash
# Copy template vào repo FE
cp Documents/EXECUTION-PLAN/CLAUDE_FE_Web.md pickleball-web/CLAUDE.md

# Copy template vào repo Mobile
cp Documents/EXECUTION-PLAN/CLAUDE_Mobile.md pickleball-mobile/CLAUDE.md
```

✅ **Verify Phase 0:**
```bash
dotnet build BE/AppPickleball.slnx  # 0 errors
cd pickleball-web && npm run build  # exit 0
```

---

## PHASE 1 — Database

### Bước 1.1: Start infrastructure
```bash
cd BE && docker-compose up -d
# Chờ 10 giây cho PostgreSQL ready
```

### Bước 1.2: Tạo schema
```bash
docker exec -i pickleball-postgres psql -U pickleballuser -d pickleballdb \
  < Documents/DATABASE/create_pickleball_database.sql
```

### Bước 1.3: Seed data
```bash
docker exec -i pickleball-postgres psql -U pickleballuser -d pickleballdb \
  < Documents/DATABASE/seed_data.sql
```

✅ **Verify Phase 1:**
```bash
docker exec pickleball-postgres psql -U pickleballuser -d pickleballdb \
  -c "SELECT COUNT(*) FROM users;"
# Expected: >= 3 rows (seed users)
```

---

## PHASE 2 — Backend Build

→ Xem chi tiết: [`02_Backend_Build_Order.md`](./02_Backend_Build_Order.md)

### Thứ Tự Build (KHÔNG được đảo)
```
1. Domain/Entities (no dependencies)
2. Domain/Enums
3. Infrastructure/Persistence/Configurations
4. Infrastructure/Persistence/DbContext
5. Infrastructure/Repositories
6. Infrastructure/DI
7. Application/Interfaces
8. Application/Features/{Module}/Dtos
9. Application/Features/{Module}/Commands|Queries
10. Application/Features/{Module}/Validators
11. API/Controllers
12. API/Program.cs extensions
```

### Thứ Tự Build Theo Module
```
M1: Auth & Profile       → Build trước (tất cả modules cần Auth)
M2: Tournament           → Build sau Auth
M4: Discovery            → Dùng chung endpoints với M2
M3: Match & Scoring      → Build sau Tournament
M7: Notification         → Build song song với M3
M5: Community Game       → Phase 2
M6: Chat                 → Phase 2
```

✅ **Verify Phase 2:**
```bash
cd BE && dotnet build                           # 0 errors
dotnet run --project AppPickleball.Api &        # start server
sleep 5
curl -s https://localhost:7001/health | grep "Healthy"
curl -s -X POST https://localhost:7001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"Admin@123"}' | grep "accessToken"
```

---

## PHASE 3 — Frontend Web

→ Xem chi tiết: [`03_Frontend_Build_Order.md`](./03_Frontend_Build_Order.md)

### Thứ Tự Build Pages
```
1. Setup: axios, react-query, zustand, router
2. Auth pages: Login, Register, VerifyEmail
3. Layout: Header, Sidebar, BottomNav
4. Tournament List + Detail
5. Tournament Create + Manage (Creator)
6. Match Score Input + Bracket View
7. Profile (My + Edit + Others)
8. Notification List
9. Community Lobby + Game Detail (Phase 2)
10. Chat (Phase 2)
```

✅ **Verify Phase 3:**
```bash
cd pickleball-web && npm run build  # 0 errors
# Test E2E: login, create tournament, view list
```

---

## PHASE 4 — Deploy

→ Xem chi tiết: [`DEPLOYMENT/Deploy_Target.md`](../DEPLOYMENT/Deploy_Target.md)

### Thứ Tự Deploy
```
1. Build Docker images (BE + FE)
2. Push images lên Docker Hub / GHCR
3. SSH vào VPS
4. Pull images, chạy docker-compose production
5. Cấu hình Nginx + SSL
6. Verify production health
7. Setup GitHub Actions CI/CD (auto-deploy sau)
```

✅ **Verify Phase 4:**
```bash
curl https://api.pickleballapp.com/health
curl https://pickleballapp.com  # 200 OK
```

---

## Dependency Map

```
PostgreSQL ──────────────────────┐
                                 ▼
Redis ────────────────────► BE API (Docker)
                                 │
FCM, Cloudinary, SMTP ──────────►│
                                 │
                                 ▼
                          Nginx (reverse proxy)
                                 │
                    ┌────────────┴────────────┐
                    ▼                         ▼
             React Web App             React Native App
             (static files)           (Expo / APK / IPA)
```

---

## Time Estimate Per Phase

| Phase | Scope | Estimate |
|-------|-------|---------|
| 0 — Bootstrap | 3 repos scaffold | 30 phút |
| 1 — Database | Schema + seed | 15 phút |
| 2 — Backend Phase 1 | M1+M2+M3+M7 | 2-3 ngày |
| 3 — Frontend Phase 1 | 15 screens | 2-3 ngày |
| 4 — Deploy | VPS + CI/CD | 2-4 giờ |
| **Total Phase 1** | | **~1 tuần** |

---

## Checklist Tổng (Done When All ✅)

- [ ] `dotnet build` 0 errors
- [ ] `npm run build` 0 errors
- [ ] DB schema created, seed data loaded
- [ ] `/health` endpoint trả `Healthy`
- [ ] Auth flow: register → verify → login → get token
- [ ] Tournament CRUD hoạt động
- [ ] Score input + BXH update
- [ ] SignalR live score test
- [ ] FE kết nối BE (login thành công từ browser)
- [ ] Docker images build thành công
- [ ] Production deploy lên VPS
- [ ] HTTPS hoạt động
- [ ] GitHub Actions pipeline green
