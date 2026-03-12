# Docker Infrastructure

---

## 1. Dockerfile — Backend (.NET 8)

**Lưu tại:** `AppPickleball.Api/Dockerfile`

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj files và restore (layer cache tốt hơn)
COPY ["AppPickleball.Api/AppPickleball.Api.csproj", "AppPickleball.Api/"]
COPY ["AppPickleball.Application/AppPickleball.Application.csproj", "AppPickleball.Application/"]
COPY ["AppPickleball.Domain/AppPickleball.Domain.csproj", "AppPickleball.Domain/"]
COPY ["AppPickleball.Infrastructure/AppPickleball.Infrastructure.csproj", "AppPickleball.Infrastructure/"]
COPY ["AppPickleball.Share/AppPickleball.Share.csproj", "AppPickleball.Share/"]
RUN dotnet restore "AppPickleball.Api/AppPickleball.Api.csproj"

# Copy source và build
COPY . .
WORKDIR "/src/AppPickleball.Api"
RUN dotnet build "AppPickleball.Api.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "AppPickleball.Api.csproj" -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Non-root user (security)
RUN adduser --disabled-password --gecos '' appuser
USER appuser

COPY --from=publish /app/publish .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080
ENTRYPOINT ["dotnet", "AppPickleball.Api.dll"]
```

---

## 2. Dockerfile — Frontend (React + Nginx)

**Lưu tại:** `pickleball-web/Dockerfile`

```dockerfile
# Build stage
FROM node:20-alpine AS build
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source và build
COPY . .
# Build args cho env vars (set lúc docker build)
ARG VITE_API_URL
ARG VITE_SIGNALR_URL
ARG VITE_GOOGLE_CLIENT_ID
RUN npm run build

# Nginx stage
FROM nginx:1.25-alpine AS final
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.site.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**`pickleball-web/nginx.site.conf`** (serve React SPA):
```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip
    gzip on;
    gzip_types text/css application/javascript application/json;

    # Cache static assets
    location ~* \.(js|css|png|jpg|ico|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # SPA fallback — tất cả routes → index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

## 3. docker-compose.dev.yml — Development

**Lưu tại:** `BE/docker-compose.dev.yml`

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: pickleball-postgres
    environment:
      POSTGRES_USER: pickleballuser
      POSTGRES_PASSWORD: pickleballpass
      POSTGRES_DB: pickleballdb
    ports:
      - "5432:5432"
    volumes:
      - postgres_dev_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U pickleballuser -d pickleballdb"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: pickleball-redis
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_dev_data:/data

  mailhog:
    image: mailhog/mailhog:latest
    container_name: pickleball-mailhog
    ports:
      - "1025:1025"   # SMTP
      - "8025:8025"   # Web UI

volumes:
  postgres_dev_data:
  redis_dev_data:
```

---

## 4. docker-compose.prod.yml — Production

**Lưu tại:** `/opt/pickleball/docker-compose.prod.yml` (trên VPS)

```yaml
version: '3.8'

services:
  api:
    image: ghcr.io/${GITHUB_USERNAME}/pickleball-api:${IMAGE_TAG:-latest}
    container_name: pickleball-api
    restart: unless-stopped
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_URLS=http://+:8080
      - ConnectionStrings__DefaultConnection=${DB_CONNECTION_STRING}
      - ConnectionStrings__Redis=${REDIS_CONNECTION_STRING}
      - Jwt__SecretKey=${JWT_SECRET_KEY}
      - EmailSettings__Password=${EMAIL_PASSWORD}
      - Cloudinary__ApiSecret=${CLOUDINARY_API_SECRET}
      - Firebase__ServerKey=${FCM_SERVER_KEY}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    networks:
      - pickleball-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  web:
    image: ghcr.io/${GITHUB_USERNAME}/pickleball-web:${IMAGE_TAG:-latest}
    container_name: pickleball-web
    restart: unless-stopped
    networks:
      - pickleball-network

  postgres:
    image: postgres:16-alpine
    container_name: pickleball-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_prod_data:/var/lib/postgresql/data
    networks:
      - pickleball-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5
    # KHÔNG expose port ra ngoài (chỉ internal)

  redis:
    image: redis:7-alpine
    container_name: pickleball-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_prod_data:/data
    networks:
      - pickleball-network

networks:
  pickleball-network:
    driver: bridge

volumes:
  postgres_prod_data:
  redis_prod_data:
```

---

## 5. .env.production Template

**Lưu tại:** `/opt/pickleball/.env.production` (KHÔNG commit vào git)

```env
GITHUB_USERNAME=your-github-username
IMAGE_TAG=latest

# Database
DB_USER=pickleballuser
DB_PASSWORD=super_strong_password_here
DB_NAME=pickleballdb
DB_CONNECTION_STRING=Host=postgres;Port=5432;Database=pickleballdb;Username=pickleballuser;Password=super_strong_password_here;Pooling=true;MinPoolSize=5;MaxPoolSize=20

# Redis
REDIS_PASSWORD=redis_password_here
REDIS_CONNECTION_STRING=redis:6379,password=redis_password_here

# JWT
JWT_SECRET_KEY=your-jwt-secret-key-minimum-64-characters-for-production

# Email
EMAIL_PASSWORD=your-smtp-password

# Cloudinary
CLOUDINARY_API_SECRET=your-cloudinary-secret

# FCM
FCM_SERVER_KEY=your-fcm-server-key
```

---

## 6. Deployment Commands

```bash
# Pull latest images và restart
cd /opt/pickleball
docker-compose -f docker-compose.prod.yml --env-file .env.production pull
docker-compose -f docker-compose.prod.yml --env-file .env.production up -d

# Xem logs
docker-compose -f docker-compose.prod.yml logs -f api

# Health check
curl http://localhost:8080/health

# Rollback
docker-compose -f docker-compose.prod.yml stop api
docker image tag pickleball-api:previous pickleball-api:latest
docker-compose -f docker-compose.prod.yml up -d api
```
