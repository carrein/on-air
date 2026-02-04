# On Air - Quick Deployment Guide

This is a quick reference for deploying On Air. See [docs/Deployment.md](docs/Deployment.md) for the full deployment plan.

## Prerequisites

- Docker and Docker Compose
- PostgreSQL and Redis (provided in your hosting docker-compose)
- Environment variables configured (see [docs/.env.example](docs/.env.example))

## Local Testing

### Test Compiled Binary

Before building Docker image, verify the compiled binary works:

```bash
cd on_air_server
dart compile exe bin/main.dart -o server
./server --mode production
```

Verify it finds `config/production.yaml` and starts correctly.

### Build Docker Image Locally

```bash
# Generate Serverpod code first
cd on_air_server
dart pub get
dart pub global activate serverpod_cli 3.2.3
serverpod generate
cd ..

# Build Docker image
docker build -t on_air:test .

# Run with test environment
docker run --rm \
  -p 8080:8080 \
  -p 8082:8082 \
  -e DATABASE_HOST=host.docker.internal \
  -e DATABASE_PORT=5432 \
  -e DATABASE_NAME=on_air \
  -e DATABASE_USER=on_air_user \
  -e DATABASE_PASSWORD=test_password \
  -e REDIS_HOST=host.docker.internal \
  -e REDIS_PORT=6379 \
  -e REDIS_USER=default \
  -e PUBLIC_HOST=localhost \
  -e SERVICE_SECRET=$(openssl rand -base64 32) \
  -e EMAIL_SECRET_PEPPER=$(openssl rand -base64 32) \
  -e JWT_PRIVATE_KEY=$(openssl rand -base64 64) \
  -e JWT_REFRESH_PEPPER=$(openssl rand -base64 32) \
  on_air:test

# Test healthcheck and access points
curl http://localhost:8082/           # webServer (Flutter app)
curl http://localhost:8080/serverpod/ # apiServer (API endpoints)
```

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

## Hosting Setup

See [docs/Deployment.md](docs/Deployment.md) for complete docker-compose configuration.

Quick reference:

```yaml
services:
  on_air:
    image: ghcr.io/carrein/on_air:latest
    restart: unless-stopped
    ports:
      - "8080:8080"  # apiServer - API endpoints
      - "8082:8082"  # webServer - Flutter app and static files
    environment:
      # Passwords use SERVERPOD_PASSWORD_* prefix
      SERVERPOD_PASSWORD_database: ${ON_AIR_DB_PASSWORD}
      SERVERPOD_PASSWORD_redis: ""
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
      test: ["CMD", "curl", "-f", "http://localhost:8082/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  # Note: Services MUST be named 'postgresql' and 'redis' to match production.yaml
  # Access the app at: http://your-host:8082/app/
```

## Troubleshooting

**Container crashes on startup:**
```bash
# Check logs
docker logs on_air

# Check migrations
docker exec on_air ls -la /app/migrations

# Connect to database manually
docker exec -it on_air_postgresql psql -U on_air_user -d on_air
```

**Migration failures:**
```bash
# Create manual backup before risky migrations
docker exec on_air_postgresql pg_dump -U on_air_user -d on_air > backup.sql

# Restore if needed
docker exec -i on_air_postgresql psql -U on_air_user -d on_air < backup.sql
```

**Healthcheck failing:**
```bash
# Test endpoints manually
docker exec on_air curl -v http://localhost:8082/           # webServer
docker exec on_air curl -v http://localhost:8080/serverpod/ # apiServer

# Check if server is running
docker exec on_air ps aux
```

## Files

- `Dockerfile` - Multi-stage build configuration
- `.github/workflows/release.yml` - GitHub Action for automated builds
- `.dockerignore` - Build context exclusions
- `docs/Deployment.md` - Complete deployment documentation
- `docs/.env.example` - Environment variables template
