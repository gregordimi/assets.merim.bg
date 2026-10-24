# assets.merim.bg — Static Assets CDN

High-performance, lightweight Nginx CDN container for hosting static assets under `https://assets.merim.bg` on Hetzner VPS (`coolify-ubuntu-16gb-fsn1-1`), managed via **Coolify** (or standalone Docker Compose).

---

## 1. Directory Structure

### Server Persistent Volume
Location on Hetzner server (`/mnt/volume-fsn1-1/assets-cdn`):
```text
/mnt/volume-fsn1-1/assets-cdn/
├── docker-compose.yml
├── nginx.conf
└── data/
    ├── stores/                   # Retailer favicons & banners ({uuid}_favicon.png)
    ├── product_sample_images_new/ # Category images (1001_001.png ... 1008_101.png)
    ├── ribi/                     # Blog fish images
    └── assets/                   # Generic static assets (mail-sig.png)
```

### Git Repository
```text
.
├── docker-compose.yml
├── nginx.conf
├── .env.example
├── .gitignore
├── sync-assets.sh                # Helper script to rsync assets to server
├── verify.sh                     # Automated HTTP 200 & header verification script
├── README.md
└── data/
    ├── stores/.gitkeep
    ├── product_sample_images_new/.gitkeep
    ├── ribi/.gitkeep
    └── assets/.gitkeep
```

---

## 2. Server Setup (Hetzner VPS)

SSH into your server and prepare the persistent storage directory:

```bash
mkdir -p /mnt/volume-fsn1-1/assets-cdn/data
cd /mnt/volume-fsn1-1/assets-cdn
```

---

## 3. Transfer Assets from Local Machine to Server

### Option A: Using the provided helper script
From your local terminal in this repository:
```bash
./sync-assets.sh <YOUR_SERVER_IP>
```
*You can optionally pass the source directory as the 2nd argument:*
```bash
./sync-assets.sh <YOUR_SERVER_IP> ../merim-bg-landing/public/storage/
```

### Option B: Manual `rsync`
Run from your local Mac terminal inside `merim-bg-landing`:
```bash
rsync -avzP public/storage/ root@<YOUR_SERVER_IP>:/mnt/volume-fsn1-1/assets-cdn/data/
```

### Verify permissions on the server:
```bash
chmod -R 755 /mnt/volume-fsn1-1/assets-cdn/data
```

---

## 4. Deployment

### Option A: In Coolify UI (Recommended)
1. In Coolify, navigate to **Projects** → Select your environment.
2. Click **+ Add Resource** → **Docker Compose**.
3. **Name**: `merim-assets-cdn`
4. **Domains (FQDN)**: `https://assets.merim.bg`
5. **Container Port**: `80`
6. Paste the contents of `docker-compose.yml`.
7. Click **Deploy**. Coolify's Traefik reverse proxy will automatically provision and renew Let's Encrypt SSL certificates.

### Option B: Standalone Terminal via SSH
If managing directly on the server:
```bash
cd /mnt/volume-fsn1-1/assets-cdn
docker compose up -d
```

---

## 5. Verification Checklist

You can test the deployment using the automated verification script:
```bash
./verify.sh https://assets.merim.bg
```

Or run manual `curl -I` tests:
```bash
# 1. Health check
curl -I https://assets.merim.bg/healthz

# 2. Test Retailer Favicon
curl -I https://assets.merim.bg/stores/merim-favicon.png

# 3. Test Retailer UUID Logo
curl -I https://assets.merim.bg/stores/0ba9ce3e-2572-5b7c-8357-61f8928779b0_favicon.png

# 4. Test Product Category Sample Image
curl -I https://assets.merim.bg/product_sample_images_new/1001_001_small.png

# 5. Test Last Product Category
curl -I https://assets.merim.bg/product_sample_images_new/1008_101.png

# 6. Test Blog Fish Image
curl -I https://assets.merim.bg/ribi/lavrak.png
```

### Expected Response Headers:
```http
HTTP/2 200 (or HTTP/1.1 200 OK)
access-control-allow-origin: *
cache-control: public, max-age=31536000, immutable
```

---

## 6. Architecture & Features

- **Aggressive Caching**: `Cache-Control: public, max-age=31536000, immutable` for all media & font formats to maximize edge and browser cache hit ratios.
- **Universal CORS**: `Access-Control-Allow-Origin: *` to prevent cross-origin canvas and image blocking.
- **Strict 404 Fallback**: CDN never falls back to an `index.html` (preventing broken image HTML payloads).
- **Gzip Compression**: Enabled for SVG, text, json, and font definitions.
- **Health Check**: Native `/healthz` endpoint returning HTTP 200 for Docker and Coolify health probes.
