# CI/CD Pipeline — GitHub Actions

---

## Overview

```
Push to main branch
    │
    ├── Job 1: test-backend    (dotnet test)
    ├── Job 2: test-frontend   (npm test + build)
    │
    └── (if both pass) Job 3: deploy
            ├── Build Docker images
            ├── Push to GHCR
            └── SSH deploy to VPS
```

---

## GitHub Secrets Cần Setup

Vào GitHub repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret Name | Value |
|-------------|-------|
| `VPS_HOST` | IP hoặc domain VPS (vd: `123.45.67.89`) |
| `VPS_USER` | SSH user (vd: `root` hoặc `deploy`) |
| `VPS_SSH_KEY` | Private SSH key (dùng `ssh-keygen`, public key copy lên VPS) |
| `GHCR_TOKEN` | GitHub Personal Access Token (scopes: `write:packages`) |
| `DB_CONNECTION_STRING` | Production connection string |
| `JWT_SECRET_KEY` | Production JWT secret |
| `CLOUDINARY_API_SECRET` | Cloudinary secret |
| `FCM_SERVER_KEY` | Firebase server key |
| `EMAIL_PASSWORD` | SMTP password |
| `REDIS_PASSWORD` | Redis password |
| `VITE_API_URL` | `https://api.pickleballapp.com/api` |
| `VITE_SIGNALR_URL` | `https://api.pickleballapp.com` |
| `VITE_GOOGLE_CLIENT_ID` | Google OAuth Client ID |

---

## Workflow File — Backend

**Lưu tại:** `AppPickleball/.github/workflows/backend-ci.yml`

```yaml
name: Backend CI/CD

on:
  push:
    branches: [main]
    paths:
      - 'AppPickleball.**/**'
      - '.github/workflows/backend-ci.yml'
  pull_request:
    branches: [main]
    paths:
      - 'AppPickleball.**/**'

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/pickleball-api

jobs:
  test:
    name: Test Backend
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: testdb
        ports: ["5432:5432"]
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup .NET 8
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'

      - name: Restore
        run: dotnet restore AppPickleball.slnx

      - name: Build
        run: dotnet build AppPickleball.slnx --no-restore -c Release

      - name: Test
        run: dotnet test AppPickleball.slnx --no-build -c Release --verbosity normal
        env:
          ConnectionStrings__DefaultConnection: "Host=localhost;Port=5432;Database=testdb;Username=testuser;Password=testpass"

  build-and-push:
    name: Build & Push Docker Image
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    outputs:
      image-tag: ${{ steps.meta.outputs.version }}

    steps:
      - uses: actions/checkout@v4

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=,suffix=,format=short
            type=raw,value=latest

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: AppPickleball.Api/Dockerfile
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    name: Deploy to VPS
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /opt/pickleball

            # Login to GHCR
            echo "${{ secrets.GHCR_TOKEN }}" | docker login ghcr.io -u ${{ github.actor }} --password-stdin

            # Pull new image
            docker pull ghcr.io/${{ github.repository_owner }}/pickleball-api:latest

            # Restart API container (zero-downtime với health check)
            docker-compose -f docker-compose.prod.yml --env-file .env.production \
              up -d --no-deps api

            # Wait for health check
            sleep 15
            curl -f http://localhost:8080/health || (echo "Health check failed!" && exit 1)

            echo "✅ Backend deployed successfully"
```

---

## Workflow File — Frontend

**Lưu tại:** `pickleball-web/.github/workflows/frontend-ci.yml`

```yaml
name: Frontend CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/pickleball-web

jobs:
  test:
    name: Test & Build Frontend
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js 20
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: TypeScript check
        run: npx tsc --noEmit

      - name: Lint
        run: npm run lint

      - name: Build (test build succeeds)
        run: npm run build
        env:
          VITE_API_URL: https://api.pickleballapp.com/api
          VITE_SIGNALR_URL: https://api.pickleballapp.com

  build-and-push:
    name: Build & Push Docker Image
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GHCR_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ghcr.io/${{ env.IMAGE_NAME }}:latest
          build-args: |
            VITE_API_URL=${{ secrets.VITE_API_URL }}
            VITE_SIGNALR_URL=${{ secrets.VITE_SIGNALR_URL }}
            VITE_GOOGLE_CLIENT_ID=${{ secrets.VITE_GOOGLE_CLIENT_ID }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    name: Deploy FE to VPS
    needs: build-and-push
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            # Pull new FE image
            docker pull ghcr.io/${{ github.repository_owner }}/pickleball-web:latest

            # Copy static files to nginx serve dir
            docker create --name temp-web ghcr.io/${{ github.repository_owner }}/pickleball-web:latest
            docker cp temp-web:/usr/share/nginx/html/. /var/www/pickleball-web/
            docker rm temp-web

            # Reload nginx (không cần restart)
            nginx -s reload

            echo "✅ Frontend deployed successfully"
```

---

## PR Checks (Optional)

**Lưu tại:** `.github/workflows/pr-check.yml`

```yaml
name: PR Check

on:
  pull_request:
    branches: [main, develop]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup .NET 8
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'
      - run: dotnet build AppPickleball.slnx
      - run: dotnet test AppPickleball.slnx --no-build
```

---

## Setup SSH Key cho VPS

```bash
# Trên máy local
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/pickleball_deploy
# → tạo ra: pickleball_deploy (private) + pickleball_deploy.pub (public)

# Copy public key lên VPS
ssh-copy-id -i ~/.ssh/pickleball_deploy.pub root@<VPS_IP>
# Hoặc: cat pickleball_deploy.pub >> ~/.ssh/authorized_keys (trên VPS)

# Copy private key vào GitHub Secret VPS_SSH_KEY
cat ~/.ssh/pickleball_deploy
# → paste toàn bộ nội dung vào secret VPS_SSH_KEY
```
