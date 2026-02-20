# Deployment Plan

This document outlines the deployment strategy for Memoka as a self-hosted service.

## Architecture Decision

**Recommendation: Single Container (Server + Frontend)**

The server and frontend should be combined into a single Docker container because:

1. The Serverpod server already serves the Flutter web app from `/app` route
2. Simpler deployment and CI/CD pipeline
3. No CORS or routing complexity between separate services
4. Matches the existing development workflow where Flutter web is built into `memoka_server/web/app/`
5. Appropriate for the application scale and self-hosting use case

**Total Services:**
- `memoka` - Combined Serverpod backend + Flutter web frontend (we build)
- `postgresql` - Database (you provide in hosting docker-compose)
- `redis` - Cache (you provide in hosting docker-compose)

## Dockerfile Strategy

Multi-stage Dockerfile at repository root:

**Stage 1: Flutter Web Build**
- Use `ghcr.io/cirruslabs/flutter:stable` base image
- Copy `memoka_flutter/` and `memoka_client/` directories (client needed for pubspec dependency)
- Run `flutter pub get`
- Build web app with `flutter build web --release --base-href /app/`
- Output: `build/web/` directory
- **Note:** `--wasm` flag not used due to compilation issues in Docker

**Stage 2: Serverpod Server Build**
- Use `dart:stable` base image
- Copy `memoka_server/` directory
- Copy generated client library `memoka_client/` (needed for server dependencies)
  - **Note:** Ensure `serverpod generate` has been run before Docker build, or add generation step here
- Run `dart pub get` in both directories
- Copy Flutter web build from Stage 1 into `memoka_server/web/app/`
- Compile server with `dart compile exe bin/main.dart -o server`

**Stage 3: Runtime**
- Use `debian:stable-slim` or `ubuntu:24.04` base image (NOT Alpine - Dart binaries require glibc)
- Install runtime dependencies:
  ```dockerfile
  RUN apt-get update && \
      apt-get install -y curl ca-certificates && \
      rm -rf /var/lib/apt/lists/*
  ```
- Set WORKDIR to `/app` (critical for relative path resolution)
- Copy compiled server binary from Stage 2 to `/app/server`
- Copy `config/` directory (production.yaml, passwords.yaml) to `/app/config/`
- Copy `migrations/` directory to `/app/migrations/`
- Copy `web/` directory (static files + Flutter app) to `/app/web/`
- Create `/app/data/media` directory and set permissions:
  ```dockerfile
  RUN mkdir -p /app/data/media && chmod 755 /app/data/media
  ```
- Ensure binary has execute permissions:
  ```dockerfile
  RUN chmod +x /app/server
  ```
- Expose port 8080
- Set entrypoint (note: `--mode production` reads from `config/production.yaml`):
  ```dockerfile
  CMD ["/app/server", "--mode", "production", "--apply-migrations"]
  ```

**Important Notes:**
- Serverpod requires YAML config files with environment variable substitution (verify `${VAR_NAME:-default}` syntax works)
- All paths in server.dart are relative to WORKDIR: `web/static`, `web/app`, `data/media`, `migrations/`
- `--mode production` flag tells Serverpod to load `config/production.yaml` (not an env var)
- Migration strategy: `--apply-migrations` on startup prevents zero-downtime deployments and causes crash loops if migrations fail. For a VPN-protected self-hosted app this is acceptable. For production with high availability requirements, consider running migrations in a separate init container or job.
- Healthcheck requires `curl` to be available in the runtime image
- **Critical:** Test compiled binary locally before deploying to verify path resolution:
  ```bash
  cd memoka_server
  dart compile exe bin/main.dart -o server
  ./server --mode production --apply-migrations
  ```

## Environment Variables

**Important:** Serverpod does NOT support `${VAR}` substitution in YAML files. The `production.yaml` file contains default values optimized for Docker deployment.

The container uses these default values from `config/production.yaml`:
- Database: `postgresql:5432` (Docker service name)
- Redis: `redis:6379` (Docker service name)

**Required Environment Variables (Passwords):**

Use `SERVERPOD_PASSWORD_*` prefix for all secrets:

- `SERVERPOD_PASSWORD_database` - Database password (required)
- `SERVERPOD_PASSWORD_redis` - Redis password (empty string for no password)
- `SERVERPOD_PASSWORD_serviceSecret` - Service secret (generate with `openssl rand -base64 32`)
- `SERVERPOD_PASSWORD_emailSecretHashPepper` - Email hash pepper (generate with `openssl rand -base64 32`)
- `SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey` - JWT signing key (generate with `openssl rand -base64 64`)
- `SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper` - JWT refresh token pepper (generate with `openssl rand -base64 32`)

**Optional Overrides:**

If you need different database/redis hosts, modify `config/production.yaml` before building the Docker image, or ensure your docker-compose services are named `postgresql` and `redis`.

## GitHub Action Workflow

`.github/workflows/release.yml` triggers on release publish:

```yaml
name: Build and Push Docker Image

on:
  release:
    types: [published]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Generate Serverpod code
        run: |
          cd memoka_server
          dart pub get
          dart pub global activate serverpod_cli 3.2.3
          serverpod generate

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

**Tagging Strategy:**
- `latest` - Always points to most recent release
- `1.2.3` - Specific version from release tag (e.g., `v1.2.3`)
- `1.2` - Minor version (e.g., `v1.2.3` → `1.2` tag)

## Example Hosting Docker Compose

This is an example configuration for your hosting server's `docker-compose.yml`:

```yaml
version: '3.8'

services:
  memoka:
    container_name: memoka
    image: ghcr.io/carrein/memoka:latest
    restart: unless-stopped
    ports:
      - "8080:8080"  # apiServer - API endpoints (required for Flutter client)
      - "8082:8082"  # webServer - Static files and Flutter app
    environment:
      # Passwords (SERVERPOD_PASSWORD_* prefix required)
      SERVERPOD_PASSWORD_database: ${MEMOKA_DB_PASSWORD}
      SERVERPOD_PASSWORD_redis: ""  # Empty for no password
      SERVERPOD_PASSWORD_serviceSecret: ${MEMOKA_SERVICE_SECRET}
      SERVERPOD_PASSWORD_emailSecretHashPepper: ${MEMOKA_EMAIL_PEPPER}
      SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey: ${MEMOKA_JWT_KEY}
      SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper: ${MEMOKA_JWT_REFRESH_PEPPER}
    depends_on:
      postgresql:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8082/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - memoka_network
    labels:
      - com.centurylinklabs.watchtower.enable=true

  postgresql:
    container_name: memoka_postgresql
    image: pgvector/pgvector:pg17
    restart: unless-stopped
    environment:
      POSTGRES_USER: memoka_user
      POSTGRES_PASSWORD: ${MEMOKA_DB_PASSWORD}
      POSTGRES_DB: memoka
    volumes:
      - memoka_postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U memoka_user -d memoka"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - memoka_network

  redis:
    container_name: memoka_redis
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - memoka_redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - memoka_network

networks:
  memoka_network:
    driver: bridge

volumes:
  memoka_postgres_data:
  memoka_redis_data:
```

**Environment Variables (.env file):**
```env
MEMOKA_DB_PASSWORD=your_secure_database_password
MEMOKA_SERVICE_SECRET=your_service_secret_here
MEMOKA_EMAIL_PEPPER=your_email_pepper_here
MEMOKA_JWT_KEY=your_jwt_private_key_here
MEMOKA_JWT_REFRESH_PEPPER=your_jwt_refresh_pepper_here
```

**Generate secrets:**
```bash
echo "MEMOKA_SERVICE_SECRET=$(openssl rand -base64 32)"
echo "MEMOKA_EMAIL_PEPPER=$(openssl rand -base64 32)"
echo "MEMOKA_JWT_KEY=$(openssl rand -base64 64)"
echo "MEMOKA_JWT_REFRESH_PEPPER=$(openssl rand -base64 32)"
```

**Notes:**
- Using `pgvector/pgvector:pg17` for PostgreSQL because Memoka uses pgvector extension
- Redis runs without password in VPN environment (empty string for `SERVERPOD_PASSWORD_redis`)
- Configuration: `production.yaml` uses Docker service names (`postgresql:5432`, `redis:6379`)
- Passwords: Use `SERVERPOD_PASSWORD_*` environment variables for all secrets
- Service names: Database and Redis services MUST be named `postgresql` and `redis` in docker-compose
- **Port mapping:** BOTH ports 8080 (apiServer) and 8082 (webServer) must be exposed:
  - Port 8080: API endpoints (e.g., `/serverpod/chat/getChannels`)
  - Port 8082: Flutter web app (at `/app/`) and static files
  - Access the app at: `http://your-host:8082/app/`
  - The Flutter client will connect to `http://your-host:8080/` for API calls
- Healthchecks ensure PostgreSQL and Redis are ready before Serverpod starts
- Watchtower will auto-update when new `latest` tag is pushed
- If using reverse proxy (Traefik/Nginx), adjust port mapping and add proxy labels

## Local Testing

### Test Compiled Binary

Before building Docker image, verify the compiled binary works:

```bash
cd memoka_server
dart compile exe bin/main.dart -o server
./server --mode production
```

Verify it finds `config/production.yaml` and starts correctly.

### Build Docker Image Locally

```bash
# Generate Serverpod code first
cd memoka_server
dart pub get
dart pub global activate serverpod_cli 3.2.3
serverpod generate
cd ..

# Build Docker image
docker build -t memoka:test .

# Run with test environment
docker run --rm \
  -p 8080:8080 \
  -p 8082:8082 \
  -e DATABASE_HOST=host.docker.internal \
  -e DATABASE_PORT=5432 \
  -e DATABASE_NAME=memoka \
  -e DATABASE_USER=memoka_user \
  -e DATABASE_PASSWORD=test_password \
  -e REDIS_HOST=host.docker.internal \
  -e REDIS_PORT=6379 \
  -e REDIS_USER=default \
  -e PUBLIC_HOST=localhost \
  -e SERVICE_SECRET=$(openssl rand -base64 32) \
  -e EMAIL_SECRET_PEPPER=$(openssl rand -base64 32) \
  -e JWT_PRIVATE_KEY=$(openssl rand -base64 64) \
  -e JWT_REFRESH_PEPPER=$(openssl rand -base64 32) \
  memoka:test

# Test healthcheck and access points
curl http://localhost:8082/           # webServer (Flutter app)
curl http://localhost:8080/serverpod/ # apiServer (API endpoints)
```

## Reverse Proxy Configuration

If using a reverse proxy (recommended for HTTPS), you need to handle both Serverpod ports:

**Option A: Simple - Expose both ports to localhost and proxy both**
```yaml
ports:
  - "127.0.0.1:8080:8080"  # apiServer - only accessible from localhost
  - "127.0.0.1:8082:8082"  # webServer - only accessible from localhost
```

Then configure your reverse proxy (Nginx/Traefik/Caddy) to:
- Route `/app/` and static files to port 8082
- Route `/serverpod/` API endpoints to port 8080
- Or simply proxy both ports on different subdomains/paths

**Option B: Traefik with multiple services**
```yaml
# Remove ports, use Traefik network
labels:
  # Web server (Flutter app)
  - traefik.enable=true
  - traefik.http.routers.memoka_web.rule=Host(`memoka.example.com`)
  - traefik.http.routers.memoka_web.entrypoints=websecure
  - traefik.http.routers.memoka_web.tls.certresolver=letsencrypt
  - traefik.http.services.memoka_web.loadbalancer.server.port=8082

  # API server (Serverpod endpoints)
  - traefik.http.routers.memoka_api.rule=Host(`memoka.example.com`) && PathPrefix(`/serverpod`)
  - traefik.http.routers.memoka_api.entrypoints=websecure
  - traefik.http.routers.memoka_api.tls.certresolver=letsencrypt
  - traefik.http.services.memoka_api.loadbalancer.server.port=8080
networks:
  - traefik_proxy
  - memoka_network
```

**Note:** The Flutter client needs to know the apiServer URL. Update `memoka_flutter/lib/main.dart` if using custom routing.

## Single-Port Deployment with Caddy

**Problem**: Serverpod uses separate ports for the API server (8080) and web server (8082). Exposing multiple ports through a reverse proxy is cumbersome and non-standard.

**Solution**: Use path-based routing in Caddy to serve both the API and web app through a single external port.

### Architecture

```
Browser → https://your-domain.com:12000/
         ↓
    Caddy (path-based routing)
         ↓
    /app/* → memoka:8082 (Web Server - Flutter app)
    /chat, /auth, etc. → memoka:8080 (API Server - Serverpod endpoints)
```

### Key Configuration

#### Flutter Web Client (`lib/main.dart`)

Use the current URL's port dynamically instead of hardcoding port 8080:

```dart
Future<String> getServerUrl() async {
  if (kIsWeb) {
    // Use same origin (host + port) as the web app
    final uri = Uri.base;
    return '${uri.scheme}://${uri.host}:${uri.port}/';
  }
  return 'http://localhost:8080/';
}
```

The client automatically adapts to any domain/port it's served from.

#### Production Config (`config/production.yaml`)

Use generic defaults with environment variable overrides:

```yaml
apiServer:
  port: 8080
  host: 0.0.0.0
  publicHost: localhost  # Override with SERVERPOD_apiServer_publicHost
  publicPort: 443  # Override with SERVERPOD_apiServer_publicPort
  publicScheme: https

webServer:
  port: 8082
  host: 0.0.0.0
  publicHost: localhost  # Override with SERVERPOD_webServer_publicHost
  publicPort: 443  # Override with SERVERPOD_webServer_publicPort
  publicScheme: https
```

#### Caddy Configuration

**Critical**: Order matters! Match `/app/*` first, then route everything else to API.

```caddyfile
{$TAILNET_DOMAIN}.{$TAILNET_DNS_NAME}:{$MEMOKA_REVERSE_PROXY_PORT} {
  # Redirect root to /app/
  redir / /app/ 308

  # Web app and static files (MUST come first)
  handle /app/* {
    reverse_proxy memoka:8082
    header Cross-Origin-Resource-Policy cross-origin
  }

  # Everything else goes to API server (/chat, /auth, etc.)
  handle {
    reverse_proxy memoka:8080
  }
}
```

**Why this order?** Caddy matches directives top-to-bottom. If the generic `handle` came first, it would catch everything including `/app/*`.

#### Docker Compose Environment Variables

```yaml
services:
  memoka:
    image: ghcr.io/carrein/memoka:latest
    environment:
      # Passwords
      SERVERPOD_PASSWORD_database: ${MEMOKA_DB_PASSWORD}
      SERVERPOD_PASSWORD_redis: ""
      SERVERPOD_PASSWORD_serviceSecret: ${MEMOKA_SERVICE_SECRET}
      SERVERPOD_PASSWORD_emailSecretHashPepper: ${MEMOKA_EMAIL_PEPPER}
      SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey: ${MEMOKA_JWT_KEY}
      SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper: ${MEMOKA_JWT_REFRESH_PEPPER}

      # Public URL configuration (set to your actual domain/port)
      SERVERPOD_apiServer_publicHost: "your-domain.ts.net"
      SERVERPOD_apiServer_publicPort: "12000"
      SERVERPOD_webServer_publicHost: "your-domain.ts.net"
      SERVERPOD_webServer_publicPort: "12000"
```

### Domain/Port Agnostic Deployment

You can deploy to **any domain and port** without rebuilding the image:

```yaml
# Deploy to catallenya.kamori-mulley.ts.net:12000
SERVERPOD_apiServer_publicHost: "catallenya.kamori-mulley.ts.net"
SERVERPOD_apiServer_publicPort: "12000"

# Or deploy to zzz.a-s.ts.net:4000
SERVERPOD_apiServer_publicHost: "zzz.a-s.ts.net"
SERVERPOD_apiServer_publicPort: "4000"
```

The Flutter web client uses `Uri.base`, so it automatically connects to the right URL.

### Single-Port Troubleshooting

**Icons not loading**: Material Icons missing in Flutter web app
Cause: Fonts served with `Cross-Origin-Embedder-Policy: require-corp` need `Cross-Origin-Resource-Policy` header
Fix: Add CORP header in Caddy (already in config above): `header Cross-Origin-Resource-Policy cross-origin`

**405 Method Not Allowed**: API requests fail with 405 error
Cause: Requests to `/chat` not matching Caddy routing, going to web server instead of API server
Fix: Ensure Caddy routes non-`/app/*` paths to API server (port 8080), not web server (port 8082)

**Client connecting to port 8080**: Browser trying `https://domain:8080/chat` instead of `https://domain:12000/chat`
Cause: Old Flutter build with hardcoded port cached in browser
Fix: Hard refresh browser (Ctrl+Shift+R) or use incognito window

**Environment variables not taking effect**: Config still shows old domain/port
Cause: Container hasn't been restarted, or image hasn't been rebuilt
Fix:
```bash
docker compose pull memoka
docker compose up -d memoka
```

### How It Works

1. **User accesses**: `https://your-domain.ts.net:12000/app/`
2. **Caddy serves**: Flutter web app from `memoka:8082`
3. **Browser loads**: Flutter JavaScript
4. **Flutter calls**: `getServerUrl()` which returns `https://your-domain.ts.net:12000/`
5. **API request**: `https://your-domain.ts.net:12000/chat` (POST)
6. **Caddy routes**: `/chat` → `memoka:8080` (API server)
7. **Response**: Success!

### Single-Port Deployment Checklist

- [ ] Set environment variables in docker-compose.yaml
- [ ] Update Caddyfile with path-based routing
- [ ] Reload Caddy: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`
- [ ] Pull new image: `docker compose pull memoka`
- [ ] Restart container: `docker compose up -d memoka`
- [ ] Hard refresh browser (Ctrl+Shift+R)
- [ ] Test: Verify API calls work

## Release Process

1. Ensure all changes are committed and pushed
2. Create a new release on GitHub:
   - Go to Releases → "Draft a new release"
   - Create new tag (e.g., `v1.0.0`)
   - Add release notes
   - Click "Publish release"
3. GitHub Action will automatically:
   - Generate Serverpod code
   - Build Docker image
   - Push to GHCR with tags `latest` and version number
4. Watchtower on hosting server will detect and deploy the update

## Deployment Steps

**Initial Setup:**

1. Create repository secrets (if needed):
   - None required - GitHub Actions uses `GITHUB_TOKEN` automatically

2. Ensure GitHub Container Registry is enabled:
   - Go to repo Settings → Packages
   - Enable package visibility settings

**Release Process:**

1. Test changes locally:
   ```bash
   cd memoka_server
   docker compose up  # Test with local dev environment
   ```

2. Create a release on GitHub:
   - Go to Releases → "Draft a new release"
   - Create new tag (e.g., `v1.0.0`)
   - Add release notes
   - Click "Publish release"

3. GitHub Action automatically:
   - Builds Docker image
   - Pushes to GHCR with tags `latest` and `1.0.0`
   - Watchtower on hosting server detects `latest` update
   - Pulls new image and restarts container

4. Monitor deployment:
   - Check Action logs on GitHub
   - Check Watchtower logs on server
   - Verify application is running: `docker logs memoka`

**Manual Deployment (if needed):**

```bash
# On hosting server
docker pull ghcr.io/carrein/memoka:latest
docker compose up -d memoka
docker logs -f memoka  # Check for errors
```

## Database Migrations

Migrations are automatically applied on container start because the Dockerfile runs the server with `--apply-migrations` flag.

**Migration behavior:**
- First deployment: All migrations run, schema created
- Updates: Only new migrations run
- Rollback: Manual process (restore from backup or manual SQL fixes)

**Disaster Recovery (if migrations fail):**

If migrations fail and the container is in a crash loop, you have these options:

1. **Manual backup before risky migrations:**
   ```bash
   docker exec memoka_postgresql pg_dump -U memoka_user -d memoka > backup.sql
   docker exec -i memoka_postgresql psql -U memoka_user -d memoka < backup.sql
   ```

2. **Connect to database and fix manually:**
   ```bash
   docker exec -it memoka_postgresql psql -U memoka_user -d memoka
   ```

3. **Roll back to previous container version:**
   ```bash
   docker pull ghcr.io/carrein/memoka:v1.0.0  # Previous working version
   docker compose up -d memoka
   ```

## Troubleshooting

**Container crashes on startup:**
```bash
docker logs memoka
docker exec memoka ls -la /app/migrations
docker exec -it memoka_postgresql psql -U memoka_user -d memoka
```

**Migration failures:**
```bash
docker exec memoka_postgresql pg_dump -U memoka_user -d memoka > backup.sql
docker exec -i memoka_postgresql psql -U memoka_user -d memoka < backup.sql
```

**Healthcheck failing:**
```bash
docker exec memoka curl -v http://localhost:8082/           # webServer
docker exec memoka curl -v http://localhost:8080/serverpod/ # apiServer
docker exec memoka ps aux
```

## Monitoring and Troubleshooting

**Check logs:**
```bash
docker logs memoka
docker logs memoka_postgresql
docker logs memoka_redis
```

**Database connection test:**
```bash
docker exec memoka_postgresql psql -U memoka_user -d memoka -c "SELECT version();"
```

**Redis connection test:**
```bash
docker exec memoka_redis redis-cli ping
```

## Security Considerations

1. **Secrets Management:**
   - Never commit passwords to git
   - Use `.env` file or secrets management system
   - Rotate database/redis passwords periodically

2. **Network Security:**
   - Use internal network for database/redis communication
   - Only expose web server ports through reverse proxy
   - Enable HTTPS via reverse proxy

3. **Container Updates:**
   - Watchtower auto-updates on `latest` tag
   - Pin to specific version tags (`v1.0.0`) for more control
   - Test updates in staging environment first

## Alternative: Separate Frontend Container (Not Recommended)

If you decide to use separate containers despite the recommendation:

**Pros:**
- Independent scaling of frontend/backend
- Separate CI/CD pipelines
- Can serve frontend from CDN

**Cons:**
- More complex setup
- CORS configuration required
- Two containers to build and maintain
- Need to coordinate releases between frontend/backend
- Reverse proxy routing complexity

## Files

- `Dockerfile` - Multi-stage build configuration (at repository root)
- `.github/workflows/release.yml` - GitHub Action for automated builds
- `.dockerignore` - Build context exclusions
- `docs/.env.example` - Environment variables template
