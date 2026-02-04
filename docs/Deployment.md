# Deployment Plan

This document outlines the deployment strategy for On Air as a self-hosted service.

## Architecture Decision

**Recommendation: Single Container (Server + Frontend)**

The server and frontend should be combined into a single Docker container because:

1. The Serverpod server already serves the Flutter web app from `/app` route
2. Simpler deployment and CI/CD pipeline
3. No CORS or routing complexity between separate services
4. Matches the existing development workflow where Flutter web is built into `on_air_server/web/app/`
5. Appropriate for the application scale and self-hosting use case

**Total Services:**
- `on_air` - Combined Serverpod backend + Flutter web frontend (we build)
- `postgresql` - Database (you provide in hosting docker-compose)
- `redis` - Cache (you provide in hosting docker-compose)

## Dockerfile Strategy

Create a multi-stage Dockerfile at repository root:

**Stage 1: Flutter Web Build**
- Use `ghcr.io/cirruslabs/flutter:stable` base image
- Copy `on_air_flutter/` and `on_air_client/` directories (client needed for pubspec dependency)
- Run `flutter pub get`
- Build web app with `flutter build web --release --base-href /app/`
- Output: `build/web/` directory
- **Note:** `--wasm` flag not used due to compilation issues in Docker

**Stage 2: Serverpod Server Build**
- Use `dart:stable` base image
- Copy `on_air_server/` directory
- Copy generated client library `on_air_client/` (needed for server dependencies)
  - **Note:** Ensure `serverpod generate` has been run before Docker build, or add generation step here
- Run `dart pub get` in both directories
- Copy Flutter web build from Stage 1 into `on_air_server/web/app/`
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
  cd on_air_server
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

Create `.github/workflows/release.yml`:

```yaml
name: Build and Push Docker Image

# Trigger only when a release is published
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
      # Checkout repository
      - uses: actions/checkout@v4

      # Set up Dart for code generation
      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      # Generate Serverpod code (required for on_air_client)
      - name: Generate Serverpod code
        run: |
          cd on_air_server
          dart pub get
          dart pub global activate serverpod_cli 3.2.3
          serverpod generate

      # Set up Docker Buildx for multi-platform builds
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      # Login to GitHub Container Registry
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Extract version from release tag
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ghcr.io/${{ github.repository }}
          tags: |
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=raw,value=latest,enable={{is_default_branch}}

      # Build and push Docker image
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

**Key differences from your blog example:**
- Added `permissions` for package write access
- Used `docker/metadata-action` for automatic version tagging from release
- Added build cache for faster builds
- Uses latest action versions (v4/v5)

**Tagging Strategy:**
- `latest` - Always points to most recent release
- `1.2.3` - Specific version from release tag (e.g., `v1.2.3`)
- `1.2` - Minor version (e.g., `v1.2.3` → `1.2` tag)

## Example Hosting Docker Compose

This is an example configuration for your hosting server's `docker-compose.yml`:

```yaml
version: '3.8'

services:
  on_air:
    container_name: on_air
    image: ghcr.io/carrein/on_air:latest  # Adjust to your repo name
    restart: unless-stopped
    ports:
      - "8080:8080"  # Adjust if using reverse proxy
    environment:
      # Passwords (SERVERPOD_PASSWORD_* prefix required)
      SERVERPOD_PASSWORD_database: ${ON_AIR_DB_PASSWORD}
      SERVERPOD_PASSWORD_redis: ""  # Empty for no password
      SERVERPOD_PASSWORD_serviceSecret: ${ON_AIR_SERVICE_SECRET}
      SERVERPOD_PASSWORD_emailSecretHashPepper: ${ON_AIR_EMAIL_PEPPER}
      SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey: ${ON_AIR_JWT_KEY}
      SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper: ${ON_AIR_JWT_REFRESH_PEPPER}
    depends_on:
      postgresql:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    networks:
      - on_air_network
    labels:
      - flame.type=application
      - flame.name=On Air
      - flame.url=https://${ON_AIR_PUBLIC_HOST}
      - flame.icon=custom
      - com.centurylinklabs.watchtower.enable=true

  postgresql:
    container_name: on_air_postgresql
    image: pgvector/pgvector:pg17  # Includes pgvector extension
    restart: unless-stopped
    environment:
      POSTGRES_USER: on_air_user
      POSTGRES_PASSWORD: ${ON_AIR_DB_PASSWORD}
      POSTGRES_DB: on_air
    volumes:
      - on_air_postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U on_air_user -d on_air"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - on_air_network

  redis:
    container_name: on_air_redis
    image: redis:7-alpine
    restart: unless-stopped
    # No password for VPN-protected environment
    # Add --requirepass ${REDIS_PASSWORD} if you want password auth
    volumes:
      - on_air_redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - on_air_network

networks:
  on_air_network:
    driver: bridge

volumes:
  on_air_postgres_data:
  on_air_redis_data:
```

**Environment Variables (.env file):**
```env
# Database password
ON_AIR_DB_PASSWORD=your_secure_database_password

# Authentication secrets (generate with commands below)
ON_AIR_SERVICE_SECRET=your_service_secret_here
ON_AIR_EMAIL_PEPPER=your_email_pepper_here
ON_AIR_JWT_KEY=your_jwt_private_key_here
ON_AIR_JWT_REFRESH_PEPPER=your_jwt_refresh_pepper_here
```

**Generate secrets:**
```bash
echo "ON_AIR_SERVICE_SECRET=$(openssl rand -base64 32)"
echo "ON_AIR_EMAIL_PEPPER=$(openssl rand -base64 32)"
echo "ON_AIR_JWT_KEY=$(openssl rand -base64 64)"
echo "ON_AIR_JWT_REFRESH_PEPPER=$(openssl rand -base64 32)"
```

**Notes:**
- Using `pgvector/pgvector:pg17` for PostgreSQL because On Air uses pgvector extension
- Redis runs without password in VPN environment (empty string for `SERVERPOD_PASSWORD_redis`)
- Configuration: `production.yaml` uses Docker service names (`postgresql:5432`, `redis:6379`)
- Passwords: Use `SERVERPOD_PASSWORD_*` environment variables for all secrets
- Service names: Database and Redis services MUST be named `postgresql` and `redis` in docker-compose
- Healthchecks ensure PostgreSQL and Redis are ready before Serverpod starts, preventing crash loops
- `condition: service_healthy` waits for database readiness, not just container start
- On Air service healthcheck enables reverse proxy integration and monitoring
- Watchtower will auto-update when new `latest` tag is pushed
- If using reverse proxy (Traefik/Nginx), adjust port mapping and add proxy labels

## Reverse Proxy Configuration

If using a reverse proxy (recommended for HTTPS), you can:

**Option A: Expose port and proxy to it**
```yaml
ports:
  - "127.0.0.1:8080:8080"  # Only accessible from localhost
```

**Option B: Use proxy network (Traefik example)**
```yaml
# Remove ports, add Traefik labels
labels:
  - traefik.enable=true
  - traefik.http.routers.on_air.rule=Host(`onair.example.com`)
  - traefik.http.routers.on_air.entrypoints=websecure
  - traefik.http.routers.on_air.tls.certresolver=letsencrypt
  - traefik.http.services.on_air.loadbalancer.server.port=8080
networks:
  - traefik_proxy
  - on_air_network
```

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
   cd on_air_server
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
   - Verify application is running: `docker logs on_air`

**Manual Deployment (if needed):**

```bash
# On hosting server
docker pull ghcr.io/carrein/on_air:latest
docker compose up -d on_air
docker logs -f on_air  # Check for errors
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
   # Create backup
   docker exec on_air_postgresql pg_dump -U on_air_user -d on_air > backup.sql

   # Restore if needed
   docker exec -i on_air_postgresql psql -U on_air_user -d on_air < backup.sql
   ```

2. **Connect to database and fix manually:**
   ```bash
   docker exec -it on_air_postgresql psql -U on_air_user -d on_air
   ```

3. **Roll back to previous container version:**
   ```bash
   docker pull ghcr.io/carrein/on_air:v1.0.0  # Previous working version
   docker compose up -d on_air
   ```

## Monitoring and Troubleshooting

**Check logs:**
```bash
docker logs on_air
docker logs on_air_postgresql
docker logs on_air_redis
```

**Check migrations:**
```bash
docker exec on_air ls -la /migrations
```

**Database connection test:**
```bash
docker exec on_air_postgresql psql -U on_air_user -d on_air -c "SELECT version();"
```

**Redis connection test:**
```bash
docker exec on_air_redis redis-cli -a ${ON_AIR_REDIS_PASSWORD} ping
```

## Security Considerations

1. **Secrets Management:**
   - Never commit passwords to git
   - Use `.env` file or secrets management system
   - Rotate database/redis passwords periodically

2. **Network Security:**
   - Use internal network for database/redis communication
   - Only expose port 8080 through reverse proxy
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

**Architecture:**
- `on_air_server` - Serverpod backend (port 8080)
- `on_air_frontend` - Nginx serving Flutter web (port 80)
- PostgreSQL (port 5432)
- Redis (port 6379)

This approach is only recommended if you have specific scaling or deployment needs that require separation.

## Pre-Implementation Verification Checklist

Before implementing the Dockerfile, verify these assumptions:

**1. Serverpod Environment Variable Substitution** ✅ VERIFIED
- [x] `${VAR}` substitution in YAML does NOT work in Serverpod
- [x] `SERVERPOD_PASSWORD_*` environment variables work for passwords
- [x] Configuration values use defaults from `production.yaml`
- [x] Solution: Use Docker service names (`postgresql`, `redis`) in production.yaml

**2. Code Generation in CI** ✅ Addressed in GitHub Action
- [x] GitHub Action now includes `serverpod generate` step before Docker build
- [x] Generated `on_air_client/` code will be available for copying into image
- [ ] **Verify:** Test GitHub Action locally or in CI to confirm generation works

**3. Compiled Binary Path Resolution**
- [ ] Test that `/app/server` (compiled binary) finds `config/production.yaml` relative to `/app` WORKDIR
- [ ] Verify `migrations/` directory is discovered at `/app/migrations/`
- [ ] Confirm `web/` directory is served from `/app/web/`
- [ ] Note: `dart compile exe` may resolve paths differently than `dart run`

**4. Healthcheck Endpoint** ✅ Likely Works
- [x] `server.dart` has `RootRoute()` registered at `/` and `/index.html`
- [ ] **Verify:** Test that root route returns HTTP 200 (should serve the default Serverpod page)
- [ ] Alternative if healthcheck fails: Create explicit `/health` endpoint that returns HTTP 200

**5. Runtime Dependencies**
- [ ] Add to Stage 3: `RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*`
- [ ] Ensure `curl` is available for healthcheck

**6. Directory Permissions**
- [ ] Add to Stage 3: `RUN chmod 755 /app/data/media` or `chown` to server user
- [ ] Ensure media upload directory is writable

**7. Configuration Alignment**
- [ ] Ensure `config/production.yaml` apiServer.port is 8080 (or use env var)
- [ ] Match exposed port, healthcheck port, and config port
- [ ] Remove `--mode production` flag if `SERVERPOD_MODE` env var is set (avoid redundancy)

**8. Port Configuration in production.yaml**
Update `config/production.yaml` to use environment variables (use simple `${VAR}` without defaults):
```yaml
apiServer:
  port: 8080  # Or ${SERVER_PORT} if making it configurable
  publicHost: ${PUBLIC_HOST}
  publicPort: 443  # Or ${PUBLIC_PORT}
  publicScheme: https  # Or ${PUBLIC_SCHEME}
```

**9. Migration Lock Safety** ✅ Acceptable for Single-Instance
- Serverpod uses migration versioning to track applied migrations
- `--apply-migrations` on startup is safe for single-instance deployments
- Risk: Container crash mid-migration could leave database in partial state
- Mitigation: Manual backup before releases with schema changes (see Disaster Recovery section)
- Not recommended for multi-instance high-availability deployments

## Implementation Complete ✅

The deployment is implemented and tested. Here's what was built:

**Completed:**
- ✅ Dockerfile with multi-stage build (Flutter → Dart → Runtime)
- ✅ GitHub Action workflow with code generation
- ✅ Configuration files (`production.yaml`, `passwords.yaml`)
- ✅ `.dockerignore` for optimized builds
- ✅ `DEPLOYMENT.md` quick reference guide
- ✅ Docker image builds successfully
- ✅ Container runs with proper configuration

**Test Results:**
- ✅ Docker build completes in ~1 minute (after image cache)
- ✅ Flutter web builds without `--wasm` (wasm fails in Docker)
- ✅ Serverpod server compiles to native binary
- ✅ Configuration files copied correctly
- ✅ Directory structure works (`/app/config`, `/app/migrations`, `/app/web`)
- ❌ `${VAR}` substitution in YAML doesn't work (use `SERVERPOD_PASSWORD_*` env vars instead)

**Key Configuration:**
- `production.yaml` uses Docker defaults: `postgresql:5432`, `redis:6379`
- Passwords via `SERVERPOD_PASSWORD_*` environment variables
- Migrations run automatically on startup (`--apply-migrations`)
- Healthcheck on port 8080

**Ready for Production:**
1. Generate secrets with `openssl rand -base64 32/64`
2. Set environment variables in docker-compose
3. Ensure services named `postgresql` and `redis`
4. Create GitHub release to trigger build
5. Deploy with Watchtower auto-update
