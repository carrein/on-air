# Single-Port Deployment with Path-Based Routing

**Problem**: Serverpod uses separate ports for the API server (8080) and web server (8082). Exposing multiple ports through a reverse proxy is cumbersome and non-standard.

**Solution**: Use path-based routing in Caddy to serve both the API and web app through a single external port.

## Architecture

```
Browser → https://your-domain.com:12000/
         ↓
    Caddy (path-based routing)
         ↓
    /app/* → memoka:8082 (Web Server - Flutter app)
    /chat, /auth, etc. → memoka:8080 (API Server - Serverpod endpoints)
```

## Key Changes Made

### 1. Flutter Web Client (lib/main.dart)

**Problem**: The Flutter web app was hardcoded to connect to port 8080:
```dart
return '$scheme://$host:8080/';  // ❌ Hardcoded port
```

**Solution**: Use the current URL's port dynamically:
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

**Result**: The client automatically adapts to any domain/port it's served from.

### 2. Production Config (config/production.yaml)

**Problem**: Domain and port were hardcoded in production.yaml.

**Solution**: Use generic defaults with environment variable overrides:
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

### 3. Caddy Configuration

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

### 4. Docker Compose Environment Variables

Set these in your production docker-compose.yaml:

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

## Deployment is Domain/Port Agnostic

You can now deploy to **any domain and port** without rebuilding the image:

```yaml
# Deploy to catallenya.kamori-mulley.ts.net:12000
SERVERPOD_apiServer_publicHost: "catallenya.kamori-mulley.ts.net"
SERVERPOD_apiServer_publicPort: "12000"

# Or deploy to zzz.a-s.ts.net:4000
SERVERPOD_apiServer_publicHost: "zzz.a-s.ts.net"
SERVERPOD_apiServer_publicPort: "4000"
```

The Flutter web client uses `Uri.base`, so it automatically connects to the right URL.

## Troubleshooting

### Issue: Icons not loading

**Symptom**: Material Icons missing in Flutter web app

**Cause**: Fonts served with `Cross-Origin-Embedder-Policy: require-corp` need `Cross-Origin-Resource-Policy` header

**Fix**: Add CORP header in Caddy (already in config above):
```caddyfile
header Cross-Origin-Resource-Policy cross-origin
```

### Issue: 405 Method Not Allowed

**Symptom**: API requests fail with 405 error

**Cause**: Requests to `/chat` not matching Caddy routing, going to web server instead of API server

**Fix**: Ensure Caddy routes non-`/app/*` paths to API server (port 8080), not web server (port 8082)

### Issue: Client trying to connect to port 8080

**Symptom**: Browser trying `https://domain:8080/chat` instead of `https://domain:12000/chat`

**Cause**: Old Flutter build with hardcoded port cached in browser

**Fix**: Hard refresh browser (Ctrl+Shift+R) or use incognito window

### Issue: Environment variables not taking effect

**Symptom**: Config still shows old domain/port after setting env vars

**Cause**: Container hasn't been restarted, or image hasn't been rebuilt

**Fix**:
```bash
docker compose pull memoka
docker compose up -d memoka
```

## How It Works

1. **User accesses**: `https://your-domain.ts.net:12000/app/`
2. **Caddy serves**: Flutter web app from `memoka:8082`
3. **Browser loads**: Flutter JavaScript
4. **Flutter calls**: `getServerUrl()` which returns `https://your-domain.ts.net:12000/`
5. **API request**: `https://your-domain.ts.net:12000/chat` (POST)
6. **Caddy routes**: `/chat` → `memoka:8080` (API server)
7. **Response**: Success! ✨

## Benefits

- ✅ Single external port (simpler firewall/proxy config)
- ✅ Domain/port agnostic (deploy anywhere)
- ✅ Standard HTTPS setup (no weird multi-port routing)
- ✅ Works with Tailscale, Cloudflare, or any reverse proxy
- ✅ No CORS issues (same origin for API and app)
- ✅ Icons load correctly (CORP header configured)

## Files Changed

1. `memoka_flutter/lib/main.dart` - Dynamic port detection
2. `memoka_server/config/production.yaml` - Environment variable support
3. Server Caddyfile - Path-based routing
4. Server docker-compose.yaml - Environment variables

## Deployment Checklist

- [ ] Update production.yaml (already done in image)
- [ ] Update main.dart (already done in image)
- [ ] Set environment variables in docker-compose.yaml
- [ ] Update Caddyfile with path-based routing
- [ ] Reload Caddy: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`
- [ ] Pull new image: `docker compose pull memoka`
- [ ] Restart container: `docker compose up -d memoka`
- [ ] Hard refresh browser (Ctrl+Shift+R)
- [ ] Test: Login and verify API calls work

## Related Documentation

- [deployment.md](./deployment.md) - Full deployment guide with Docker, GitHub Actions, Watchtower
- [Plan.md](./Plan.md) - Project development plan
