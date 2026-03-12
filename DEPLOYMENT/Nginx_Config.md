# Nginx Configuration

**Lưu tại:** `/etc/nginx/sites-available/pickleball`

---

## Full Nginx Config

```nginx
# Redirect HTTP → HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name pickleballapp.com www.pickleballapp.com api.pickleballapp.com;
    return 301 https://$host$request_uri;
}

# ============================================================
# API — api.pickleballapp.com
# ============================================================
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.pickleballapp.com;

    # SSL (managed by Certbot)
    ssl_certificate /etc/letsencrypt/live/api.pickleballapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.pickleballapp.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;
    limit_req_zone $binary_remote_addr zone=auth:10m rate=10r/m;

    # REST API
    location /api/ {
        limit_req zone=api burst=20 nodelay;

        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
        proxy_connect_timeout 10s;

        # CORS (handled by .NET, không cần ở đây)
    }

    # Auth endpoints — stricter rate limit
    location /api/auth/login {
        limit_req zone=auth burst=5 nodelay;
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # SignalR WebSocket
    location /hubs/ {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;

        # WebSocket upgrade
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Long-lived connections
        proxy_read_timeout 3600s;  # 1 giờ
        proxy_send_timeout 3600s;
        proxy_connect_timeout 10s;
    }

    # Health check (no rate limit)
    location /health {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        access_log off;
    }

    # Swagger (chặn trên production)
    location /swagger {
        return 404;
    }
}

# ============================================================
# WEB APP — pickleballapp.com
# ============================================================
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name pickleballapp.com www.pickleballapp.com;

    ssl_certificate /etc/letsencrypt/live/pickleballapp.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/pickleballapp.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Serve từ Docker container FE (port 3000)
    # Hoặc serve trực tiếp static files từ /var/www/pickleball-web/
    root /var/www/pickleball-web;
    index index.html;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml image/svg+xml;
    gzip_min_length 1024;

    # Cache static assets (JS/CSS có content hash → immutable)
    location ~* \.(js|css|woff|woff2|ttf|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # index.html — không cache (SPA entry point)
    location = /index.html {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        expires 0;
    }

    # SPA fallback — tất cả routes → index.html
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

## Enable Site & SSL

```bash
# Enable site
ln -s /etc/nginx/sites-available/pickleball /etc/nginx/sites-enabled/
nginx -t  # test config
nginx -s reload

# SSL với Certbot
certbot --nginx \
  -d pickleballapp.com \
  -d www.pickleballapp.com \
  -d api.pickleballapp.com \
  --email admin@pickleballapp.com \
  --agree-tos \
  --non-interactive

# Auto-renew (đã tự setup bởi certbot, nhưng verify)
certbot renew --dry-run

# Cron job renew SSL
echo "0 12 * * * /usr/bin/certbot renew --quiet" >> /etc/crontab
```

---

## Deploy FE Static Files

```bash
# Cách 1: Copy từ Docker image (sau khi build)
docker create --name temp-web ghcr.io/<user>/pickleball-web:latest
docker cp temp-web:/usr/share/nginx/html/. /var/www/pickleball-web/
docker rm temp-web

# Cách 2: Proxy qua Docker container FE
# (thay root /var/www/... bằng proxy_pass http://pickleball-web:80)
```

---

## Nginx Monitoring

```bash
# Kiểm tra status
systemctl status nginx

# Xem error log
tail -f /var/log/nginx/error.log

# Xem access log (tìm 5xx errors)
grep " 5[0-9][0-9] " /var/log/nginx/access.log | tail -20

# Rate limit log
grep "limiting requests" /var/log/nginx/error.log
```
