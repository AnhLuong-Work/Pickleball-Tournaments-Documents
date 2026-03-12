# Local Development Setup

**Stack:** .NET 8 · React (Vite) · PostgreSQL · Redis · Docker

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| .NET SDK | 8.0+ | Backend |
| Node.js | 20+ (LTS) | Frontend |
| Docker Desktop | Latest | PostgreSQL + Redis |
| Git | Any | Source control |
| VS Code / JetBrains Rider | Any | IDE |

---

## 1. Clone Repos

```bash
# Backend
git clone <backend-repo-url>
cd AppPickleball

# Frontend Web
git clone <frontend-web-repo-url>
cd pickleball-web

# Mobile
git clone <mobile-repo-url>
cd pickleball-mobile
```

---

## 2. Setup Database & Redis (Docker)

```bash
# Từ thư mục BE (có docker-compose.yml)
docker-compose up -d

# Services được start:
# - PostgreSQL 16 tại localhost:5432
# - Redis 7 tại localhost:6379
# - (Optional) pgAdmin tại localhost:5050
```

### docker-compose.yml mẫu
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: pickleballuser
      POSTGRES_PASSWORD: pickleballpass
      POSTGRES_DB: pickleballdb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

---

## 3. Setup Database Schema

```bash
# Chạy script tạo schema
cd Documents/DATABASE
psql -U pickleballuser -d pickleballdb -f create_pickleball_database.sql

# Hoặc dùng pgAdmin / DataGrip
# Connect: localhost:5432, DB: pickleballdb
```

---

## 4. Setup Backend

### 4a. User Secrets (Dev)
```bash
cd AppPickleball.Api

dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=localhost;Port=5432;Database=pickleballdb;Username=pickleballuser;Password=pickleballpass"
dotnet user-secrets set "Jwt:SecretKey" "your-super-secret-key-at-least-32-chars"
dotnet user-secrets set "EmailSettings:Password" "your-smtp-password"
dotnet user-secrets set "GoogleAuth:ClientSecret" "your-google-client-secret"
dotnet user-secrets set "Cloudinary:ApiSecret" "your-cloudinary-secret"
```

### 4b. Restore & Run
```bash
cd /path/to/AppPickleball

dotnet restore
dotnet build

# Run
dotnet run --project AppPickleball.Api

# API available at: https://localhost:7001
# Swagger UI: https://localhost:7001/swagger
```

---

## 5. Setup Frontend Web

```bash
cd pickleball-web

# Install dependencies
npm install

# Tạo .env.local
cp .env.example .env.local
# Sửa VITE_API_URL=https://localhost:7001/api

# Run dev server
npm run dev
# Available at: http://localhost:5173
```

---

## 6. Setup Mobile

```bash
cd pickleball-mobile

# Install dependencies
npm install

# Tạo .env
cp .env.example .env
# Sửa EXPO_PUBLIC_API_URL=https://localhost:7001/api

# Run trên simulator
npx expo start

# iOS: nhấn 'i' (cần Xcode)
# Android: nhấn 'a' (cần Android Studio)
# Expo Go: scan QR code
```

---

## 7. Verify Setup

```bash
# Backend health check
curl https://localhost:7001/health

# Test auth endpoint
curl -X POST https://localhost:7001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test@123","name":"Test User"}'
```

---

## 8. External Services (Dev)

### Cloudinary (Free tier)
1. Tạo account tại cloudinary.com
2. Lấy Cloud Name, API Key, API Secret
3. Set vào user-secrets

### Firebase FCM (Push Notification)
1. Tạo project tại console.firebase.google.com
2. Thêm Android + iOS app
3. Download `google-services.json` (Android) và `GoogleService-Info.plist` (iOS)
4. Lấy Server Key → set vào user-secrets

### Google OAuth
1. Google Cloud Console → Credentials → OAuth 2.0 Client ID
2. Thêm redirect URI: `https://localhost:7001/api/auth/social/google/callback`
3. Set Client ID + Secret vào user-secrets

### SMTP Email (Dev)
Dùng MailHog (local email catcher) hoặc Mailtrap:
```bash
docker run -p 1025:1025 -p 8025:8025 mailhog/mailhog
# UI tại http://localhost:8025
```

---

## 9. Troubleshooting

| Lỗi | Nguyên nhân | Fix |
|-----|------------|-----|
| `Connection refused 5432` | PostgreSQL chưa chạy | `docker-compose up -d` |
| `JWT key too short` | SecretKey < 32 chars | Tăng độ dài key |
| `CORS error` | API URL sai | Kiểm tra `VITE_API_URL` |
| `SSL cert error` | Self-signed cert | `dotnet dev-certs https --trust` |
| `EF migration missing` | Project không dùng EF migrations | Chạy SQL script thủ công |
