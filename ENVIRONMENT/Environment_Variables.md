# Environment Variables Reference

---

## Backend (.NET) — appsettings.json + User Secrets

### Connection Strings
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=pickleballdb;Username=pickleballuser;Password=pickleballpass",
    "Redis": "localhost:6379"
  }
}
```

### JWT Settings
```json
{
  "Jwt": {
    "SecretKey": "your-super-secret-key-minimum-32-characters-long",
    "Issuer": "PickleballApp",
    "Audience": "PickleballUsers",
    "AccessTokenExpiryMinutes": 15,
    "RefreshTokenExpiryDays": 7
  }
}
```

### Email Settings (SMTP)
```json
{
  "EmailSettings": {
    "Host": "smtp.gmail.com",
    "Port": 587,
    "EnableSsl": true,
    "Username": "your-email@gmail.com",
    "Password": "your-app-password",
    "FromName": "Pickleball App",
    "FromEmail": "noreply@pickleballapp.com"
  }
}
```

### Auth Settings
```json
{
  "AuthSettings": {
    "MaxLoginAttempts": 5,
    "LockoutMinutes": 15,
    "OtpExpiryMinutes": 15,
    "PasswordResetExpiryHours": 1
  }
}
```

### Cloudinary
```json
{
  "Cloudinary": {
    "CloudName": "your-cloud-name",
    "ApiKey": "your-api-key",
    "ApiSecret": "your-api-secret",
    "UploadPreset": "pickleball_uploads"
  }
}
```

### Google OAuth
```json
{
  "GoogleAuth": {
    "ClientId": "your-google-client-id.apps.googleusercontent.com",
    "ClientSecret": "your-google-client-secret"
  }
}
```

### Firebase FCM
```json
{
  "Firebase": {
    "ProjectId": "your-firebase-project-id",
    "ServerKey": "your-fcm-server-key",
    "ServiceAccountJson": "path/to/serviceAccount.json"
  }
}
```

### RabbitMQ (Phase 2)
```json
{
  "RabbitMQ": {
    "Host": "localhost",
    "Port": 5672,
    "Username": "guest",
    "Password": "guest",
    "VirtualHost": "/"
  }
}
```

### Session Cleanup
```json
{
  "SessionCleanup": {
    "RetentionDays": 90
  }
}
```

### Logging (Serilog)
```json
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "System": "Warning"
      }
    }
  }
}
```

---

## Frontend Web — .env / .env.local

```env
# API
VITE_API_URL=https://localhost:7001/api
VITE_SIGNALR_URL=https://localhost:7001

# Google OAuth
VITE_GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com

# Cloudinary (public info only)
VITE_CLOUDINARY_CLOUD_NAME=your-cloud-name

# Google Maps
VITE_GOOGLE_MAPS_API_KEY=your-maps-api-key

# App
VITE_APP_NAME=Pickleball App
VITE_APP_VERSION=1.0.0
```

---

## Mobile — .env / app.config.ts

```env
# API
EXPO_PUBLIC_API_URL=https://api.pickleballapp.com
EXPO_PUBLIC_SIGNALR_URL=https://api.pickleballapp.com

# Google OAuth
EXPO_PUBLIC_GOOGLE_CLIENT_ID_ANDROID=xxx.apps.googleusercontent.com
EXPO_PUBLIC_GOOGLE_CLIENT_ID_IOS=xxx.apps.googleusercontent.com

# Cloudinary
EXPO_PUBLIC_CLOUDINARY_CLOUD_NAME=your-cloud-name

# Google Maps
EXPO_PUBLIC_GOOGLE_MAPS_API_KEY=your-maps-key

# Deep link scheme
EXPO_PUBLIC_APP_SCHEME=pickleballapp
```

---

## Environment Files Summary

| File | Môi trường | Commit to git? |
|------|-----------|:--------------:|
| `appsettings.json` | Base config (no secrets) | ✅ |
| `appsettings.Development.json` | Dev non-secret config | ✅ |
| `appsettings.Production.json` | Prod non-secret config | ✅ |
| `.NET User Secrets` | Dev secrets | ❌ (local only) |
| `.env.local` (web) | Local dev | ❌ |
| `.env.example` (web) | Template (no values) | ✅ |
| `.env` (mobile) | Local dev | ❌ |

---

## Production Secrets Management

- **Backend:** Azure Key Vault / AWS Secrets Manager / Doppler
- **Frontend:** Vercel Environment Variables / Netlify Variables
- **Mobile:** EAS Build secrets (`eas secret:create`)
- **CI/CD:** GitHub Actions Secrets

---

## Ports Reference

| Service | Port | URL |
|---------|:----:|-----|
| Backend API | 7001 | https://localhost:7001 |
| Swagger UI | 7001 | https://localhost:7001/swagger |
| Frontend Web | 5173 | http://localhost:5173 |
| PostgreSQL | 5432 | localhost:5432 |
| Redis | 6379 | localhost:6379 |
| pgAdmin | 5050 | http://localhost:5050 |
| MailHog UI | 8025 | http://localhost:8025 |
| MailHog SMTP | 1025 | localhost:1025 |
| RabbitMQ | 5672 | localhost:5672 |
| RabbitMQ UI | 15672 | http://localhost:15672 |
