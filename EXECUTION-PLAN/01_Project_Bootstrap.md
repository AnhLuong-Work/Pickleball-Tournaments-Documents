# Project Bootstrap — Scaffold Từ Đầu

**Chạy từng lệnh theo thứ tự. Copy-paste chính xác.**

---

## 1. Backend — .NET 8 Solution

### 1.1 Tạo Solution & Projects
```bash
cd C:\Users\LENOVO\Desktop\AppPick\BE

# Solution đã tồn tại (AppPickleball.slnx)
# Nếu tạo mới từ đầu:
dotnet new sln -n AppPickleball

# Tạo các projects
dotnet new webapi -n AppPickleball.Api --framework net8.0 --no-openapi
dotnet new classlib -n AppPickleball.Application --framework net8.0
dotnet new classlib -n AppPickleball.Domain --framework net8.0
dotnet new classlib -n AppPickleball.Infrastructure --framework net8.0
dotnet new classlib -n AppPickleball.Share --framework net8.0

# Thêm vào solution
dotnet sln add AppPickleball.Api/AppPickleball.Api.csproj
dotnet sln add AppPickleball.Application/AppPickleball.Application.csproj
dotnet sln add AppPickleball.Domain/AppPickleball.Domain.csproj
dotnet sln add AppPickleball.Infrastructure/AppPickleball.Infrastructure.csproj
dotnet sln add AppPickleball.Share/AppPickleball.Share.csproj
```

### 1.2 Project References
```bash
# Api → Application, Infrastructure, Share
dotnet add AppPickleball.Api reference AppPickleball.Application
dotnet add AppPickleball.Api reference AppPickleball.Infrastructure
dotnet add AppPickleball.Api reference AppPickleball.Share

# Application → Domain, Share
dotnet add AppPickleball.Application reference AppPickleball.Domain
dotnet add AppPickleball.Application reference AppPickleball.Share

# Infrastructure → Application, Domain
dotnet add AppPickleball.Infrastructure reference AppPickleball.Application
dotnet add AppPickleball.Infrastructure reference AppPickleball.Domain
```

### 1.3 NuGet Packages
```bash
# Infrastructure
dotnet add AppPickleball.Infrastructure package Npgsql.EntityFrameworkCore.PostgreSQL --version 8.0.*
dotnet add AppPickleball.Infrastructure package Microsoft.EntityFrameworkCore --version 8.0.*
dotnet add AppPickleball.Infrastructure package StackExchange.Redis --version 2.7.*
dotnet add AppPickleball.Infrastructure package Cloudinary.NET --version 1.25.*
dotnet add AppPickleball.Infrastructure package FirebaseAdmin --version 2.4.*
dotnet add AppPickleball.Infrastructure package MailKit --version 4.3.*
dotnet add AppPickleball.Infrastructure package BCrypt.Net-Next --version 4.0.*
dotnet add AppPickleball.Infrastructure package MassTransit.RabbitMQ --version 8.2.*

# Application
dotnet add AppPickleball.Application package MediatR --version 12.2.*
dotnet add AppPickleball.Application package FluentValidation --version 11.9.*
dotnet add AppPickleball.Application package FluentValidation.DependencyInjectionExtensions --version 11.9.*
dotnet add AppPickleball.Application package Microsoft.Extensions.Localization --version 8.0.*

# Api
dotnet add AppPickleball.Api package Microsoft.AspNetCore.Authentication.JwtBearer --version 8.0.*
dotnet add AppPickleball.Api package Swashbuckle.AspNetCore --version 6.5.*
dotnet add AppPickleball.Api package Swashbuckle.AspNetCore.Annotations --version 6.5.*
dotnet add AppPickleball.Api package Serilog.AspNetCore --version 8.0.*
dotnet add AppPickleball.Api package Serilog.Sinks.Console --version 5.0.*
dotnet add AppPickleball.Api package Microsoft.AspNetCore.SignalR --version 8.0.*

# Verify build
dotnet build
```

### 1.4 Folder Structure (tạo thủ công hoặc để Claude tạo khi cần)
```
AppPickleball.Domain/
├── Common/
│   ├── BaseEntity.cs
│   └── BaseCreatedEntity.cs
├── Entities/
└── Enums/

AppPickleball.Application/
├── Common/
│   ├── Interfaces/
│   ├── Exceptions/
│   ├── Settings/
│   └── Behaviours/
└── Features/
    ├── Auth/
    ├── Tournament/
    ├── Participant/
    ├── Match/
    ├── Notification/
    ├── User/
    └── Community/

AppPickleball.Infrastructure/
├── Persistence/
│   ├── Configurations/
│   ├── Repositories/
│   └── PickleballDbContext.cs
├── Services/
└── DependencyInjection.cs

AppPickleball.Api/
├── Controllers/
├── Middleware/
├── Hubs/
└── Extensions/

AppPickleball.Share/
├── Wrappers/
│   └── ApiResponse.cs
└── Resources/
    ├── SharedResource.resx
    ├── SharedResource.en.resx
    └── SharedResource.vi.resx
```

---

## 2. Frontend Web — React + Vite

### 2.1 Scaffold
```bash
cd C:\Users\LENOVO\Desktop\AppPick

npm create vite@5 pickleball-web -- --template react-ts
cd pickleball-web
```

### 2.2 Cài Dependencies
```bash
# Core
npm install react-router-dom@6
npm install @tanstack/react-query@5
npm install axios@1.6
npm install zustand@4

# Forms
npm install react-hook-form@7
npm install zod@3
npm install @hookform/resolvers@3

# UI
npm install clsx tailwind-merge
npm install lucide-react
npm install @radix-ui/react-dialog @radix-ui/react-tabs @radix-ui/react-dropdown-menu

# SignalR
npm install @microsoft/signalr@8

# Date
npm install date-fns@3

# Image upload
npm install react-image-crop

# Notification toast
npm install sonner

# Dev dependencies
npm install -D tailwindcss@3 postcss autoprefixer
npm install -D @types/node
npx tailwindcss init -p
```

### 2.3 Config Files

**`tailwind.config.ts`**
```typescript
import type { Config } from 'tailwindcss'
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: { extend: {} },
  plugins: [],
} satisfies Config
```

**`src/index.css`** (thêm vào đầu)
```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**`.env.example`**
```env
VITE_API_URL=https://localhost:7001/api
VITE_SIGNALR_URL=https://localhost:7001
VITE_GOOGLE_CLIENT_ID=your-google-client-id
VITE_CLOUDINARY_CLOUD_NAME=your-cloud-name
```

**`vite.config.ts`**
```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') }
  },
  server: {
    port: 5173,
    proxy: {
      '/api': { target: 'https://localhost:7001', secure: false },
      '/hubs': { target: 'https://localhost:7001', ws: true, secure: false }
    }
  }
})
```

### 2.4 Folder Structure
```
src/
├── api/
│   ├── axios.ts
│   ├── auth.api.ts
│   ├── tournament.api.ts
│   ├── participant.api.ts
│   ├── match.api.ts
│   ├── user.api.ts
│   ├── notification.api.ts
│   └── community.api.ts
├── components/
│   ├── ui/           (Button, Input, Modal, Badge, Spinner, Card...)
│   ├── layout/       (Header, Sidebar, PageLayout, BottomNav)
│   └── common/       (TournamentCard, UserAvatar, StatusBadge...)
├── features/
│   ├── auth/
│   ├── tournament/
│   ├── match/
│   ├── community/
│   ├── chat/
│   ├── profile/
│   └── notification/
├── hooks/            (useDebounce, useInfiniteScroll, useSignalR)
├── lib/              (cn, formatDate, formatScore)
├── routes/           (AppRouter.tsx, ProtectedRoute.tsx)
├── stores/           (auth.store.ts, notification.store.ts)
└── types/            (index.ts — all shared types)
```

### 2.5 Verify
```bash
npm run dev    # http://localhost:5173 → React app
npm run build  # 0 errors, dist/ created
```

---

## 3. Mobile — React Native Expo

### 3.1 Scaffold
```bash
cd C:\Users\LENOVO\Desktop\AppPick

npx create-expo-app@latest pickleball-mobile --template blank-typescript
cd pickleball-mobile
```

### 3.2 Cài Dependencies
```bash
npx expo install expo-router expo-constants expo-linking expo-status-bar
npx expo install expo-secure-store expo-image-picker expo-location
npx expo install expo-notifications
npx expo install react-native-maps

npm install @tanstack/react-query@5
npm install zustand@4
npm install axios@1.6
npm install react-hook-form@7 zod@3 @hookform/resolvers@3
npm install @microsoft/signalr@8
npm install date-fns@3
npm install nativewind@4
npm install -D tailwindcss
```

### 3.3 Config

**`app.config.ts`**
```typescript
import { ExpoConfig } from 'expo/config'
export default (): ExpoConfig => ({
  name: 'Pickleball App',
  slug: 'pickleball-app',
  version: '1.0.0',
  scheme: 'pickleballapp',
  android: { package: 'com.pickleball.app', googleServicesFile: './google-services.json' },
  ios: { bundleIdentifier: 'com.pickleball.app', googleServicesFile: './GoogleService-Info.plist' },
  plugins: ['expo-router', 'expo-secure-store', ['expo-notifications', { icon: './assets/notification-icon.png' }]],
  extra: {
    apiUrl: process.env.EXPO_PUBLIC_API_URL ?? 'https://localhost:7001/api',
    signalrUrl: process.env.EXPO_PUBLIC_SIGNALR_URL ?? 'https://localhost:7001',
  }
})
```

**`.env.example`**
```env
EXPO_PUBLIC_API_URL=https://api.pickleballapp.com/api
EXPO_PUBLIC_SIGNALR_URL=https://api.pickleballapp.com
EXPO_PUBLIC_GOOGLE_CLIENT_ID_ANDROID=xxx.apps.googleusercontent.com
EXPO_PUBLIC_GOOGLE_CLIENT_ID_IOS=xxx.apps.googleusercontent.com
```

### 3.4 Verify
```bash
npx expo start  # QR code → scan với Expo Go
```

---

## 4. Infrastructure (Docker)

### 4.1 docker-compose.dev.yml (Development)
```bash
# Chạy từ thư mục BE
docker-compose -f docker-compose.dev.yml up -d

# Verify
docker ps  # phải thấy: postgres, redis, mailhog
docker exec pickleball-postgres pg_isready  # "accepting connections"
```

→ Template: xem [`DEPLOYMENT/Docker_Infrastructure.md`](../DEPLOYMENT/Docker_Infrastructure.md)
