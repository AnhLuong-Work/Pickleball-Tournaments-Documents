# Deploy Target — Server Spec & Strategy

---

## Production Infrastructure

### Option A: VPS Ubuntu (Recommended — Full Control)

| Item | Spec |
|------|------|
| **Provider** | DigitalOcean / Vultr / Linode / Hetzner |
| **OS** | Ubuntu 22.04 LTS |
| **CPU** | 2 vCPU (minimum) |
| **RAM** | 4GB (minimum, 8GB recommended) |
| **Storage** | 50GB SSD |
| **Bandwidth** | 2TB/month |
| **Cost** | ~$24/month (4GB RAM VPS) |

**Services chạy trên VPS:**
```
VPS
├── Docker + Docker Compose
├── Nginx (reverse proxy + SSL)
├── .NET 8 API container       → port 5000 (internal)
├── PostgreSQL container       → port 5432 (internal only)
├── Redis container            → port 6379 (internal only)
└── Certbot (Let's Encrypt SSL)
```

### Option B: Platform-as-a-Service (Easier, less control)

| Service | What | Cost |
|---------|------|------|
| Railway.app | BE + DB + Redis | ~$10-20/month |
| Render.com | BE + DB | ~$14/month |
| Vercel | FE static (free tier) | Free |
| Supabase | PostgreSQL managed | Free tier |

---

## Domain Setup

```
pickleballapp.com           → React Web App (Nginx static)
api.pickleballapp.com       → .NET API (Nginx → port 5000)
```

**DNS Records:**
```
A    @              → VPS IP
A    api            → VPS IP
A    www            → VPS IP
CNAME www           → @
```

---

## Server First-time Setup

```bash
# 1. Update OS
ssh root@<VPS_IP>
apt update && apt upgrade -y

# 2. Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER

# 3. Install Docker Compose
apt install docker-compose-plugin -y

# 4. Install Nginx + Certbot
apt install nginx certbot python3-certbot-nginx -y

# 5. Create app directory
mkdir -p /opt/pickleball
cd /opt/pickleball

# 6. Clone hoặc copy docker-compose.prod.yml
# (sẽ được tạo bởi GitHub Actions)

# 7. Create .env.production
nano .env.production
# (fill tất cả production env variables)

# 8. SSL Cert
certbot --nginx -d pickleballapp.com -d api.pickleballapp.com -d www.pickleballapp.com
# Auto-renew: certbot renew --dry-run
```

---

## Docker Registry

Dùng **GitHub Container Registry (GHCR)** — free với public/private repos:

```
ghcr.io/<github-username>/pickleball-api:latest
ghcr.io/<github-username>/pickleball-web:latest
```

Hoặc **Docker Hub** (free, public images):
```
<dockerhub-username>/pickleball-api:latest
<dockerhub-username>/pickleball-web:latest
```

---

## Deployment Strategy

```
Developer push code → GitHub
    │
    ▼
GitHub Actions trigger (on push to main)
    │
    ▼
Build Docker images (BE + FE)
    │
    ▼
Run tests (unit + integration)
    │
    ├─[Tests fail]──► Stop, notify
    │
    ▼
Push images to GHCR
    │
    ▼
SSH vào VPS
    │
    ▼
Pull new images
    │
    ▼
docker-compose up -d (zero-downtime với --no-deps --scale)
    │
    ▼
Health check: curl https://api.pickleballapp.com/health
    │
    ├─[Unhealthy]──► Rollback (docker-compose down + pull previous image)
    │
    ▼
Deploy complete ✅
```

---

## Backup Strategy

```bash
# Cron job backup PostgreSQL (chạy lúc 2h sáng hàng ngày)
0 2 * * * docker exec pickleball-postgres pg_dump -U pickleballuser pickleballdb \
  | gzip > /opt/backups/db_$(date +%Y%m%d).sql.gz

# Giữ 30 ngày gần nhất
find /opt/backups -name "*.sql.gz" -mtime +30 -delete
```

---

## Monitoring

| Tool | Mục đích | Setup |
|------|---------|-------|
| UptimeRobot | Ping /health mỗi 5 phút, alert khi down | Free tier |
| Sentry | Error tracking BE + FE | Free tier 5K errors/month |
| Loki + Grafana | Log aggregation (optional) | Docker container |

```bash
# Health endpoint phải trả:
# {"status":"Healthy","checks":{"database":"Healthy","redis":"Healthy"}}
```
