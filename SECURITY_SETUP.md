# Security Setup Guide

This guide walks through implementing the security measures documented in `docs/security.md`.

## Quick Start Checklist

- [ ] Rotate all secrets in `passwords.yaml`
- [ ] Set up pre-commit hooks
- [ ] Create dedicated database user
- [ ] Review input validation limits
- [ ] Configure production environment variables
- [ ] Test security measures

---

## 1. Rotate Secrets (CRITICAL - Do First!)

### Generate New Secrets

Use strong random generators for all secrets:

```bash
# Generate a random 32-character password
openssl rand -base64 32

# Or use UUID for service secrets
uuidgen
```

### Update passwords.yaml

1. Copy the template:
   ```bash
   cd on_air_server/config
   cp passwords.yaml.template passwords.yaml
   ```

2. Replace ALL placeholders with strong random values:
   - Database passwords
   - Redis passwords
   - JWT keys (use 64+ character strings)
   - Service secrets
   - Hash peppers

3. Verify the file is in `.gitignore`:
   ```bash
   git check-ignore passwords.yaml
   # Should output: passwords.yaml
   ```

---

## 2. Set Up Pre-Commit Hooks

### Install Pre-Commit

```bash
# macOS/Linux
pip3 install pre-commit

# Verify installation
pre-commit --version
```

### Install Hooks

```bash
cd /path/to/on_air
pre-commit install
```

### Test Hooks

```bash
# Run hooks on all files
pre-commit run --all-files

# Hooks will now run automatically on git commit
```

### What Gets Checked

- ✅ Secret scanning (gitleaks)
- ✅ Large file detection
- ✅ Private key detection
- ✅ passwords.yaml exclusion
- ✅ .env file exclusion
- ✅ Trailing whitespace
- ✅ YAML syntax

---

## 3. Create Dedicated Database User

### Why?

Currently using `postgres` superuser (can do anything). Create restricted user that can only:
- Read/write data
- NOT create databases
- NOT create users
- NOT modify schema (except via migrations)

### Steps

1. Connect to PostgreSQL as superuser:
   ```bash
   # If using Docker Compose
   docker compose exec postgres psql -U postgres -d on_air

   # Or directly
   psql -U postgres -d on_air -h localhost -p 8090
   ```

2. Run the security script:
   ```sql
   \i config/create_db_user.sql
   ```

   Or from command line:
   ```bash
   psql -U postgres -d on_air -h localhost -p 8090 -f config/create_db_user.sql
   ```

3. Update `config/development.yaml`:
   ```yaml
   database:
     user: on_air_app  # Changed from postgres
   ```

4. Update `config/passwords.yaml`:
   ```yaml
   development:
     database: 'your_strong_password_here'
   ```

5. Test connection:
   ```bash
   psql -U on_air_app -d on_air -h localhost -p 8090
   ```

6. Restart server and verify it works

---

## 4. Input Validation Limits

The following limits are now enforced:

| Field | Max Length | Why |
|-------|-----------|-----|
| Channel name | 100 chars | UI display constraints |
| Channel emoji | 10 chars | Multi-byte emoji support |
| Note content | 50,000 chars | ~10-20 pages, prevents abuse |
| Filename | 255 chars | Filesystem limit |
| File size | 50 MB | Balance usability vs resources |

### Customizing Limits

Edit the following files:

**Channel limits** (`on_air_server/lib/src/chat/chat_endpoint.dart`):
```dart
if (name.length > 100) { // Change 100 to your limit
```

**Note limits** (`on_air_server/lib/src/chat/chat_endpoint.dart`):
```dart
if (content.length > 50000) { // Change 50000 to your limit
```

**File limits** (`on_air_server/lib/src/media/media_endpoint.dart`):
```dart
static const int maxFileSize = 50 * 1024 * 1024; // Change 50 to your MB limit
```

After changing, run `serverpod generate` from `on_air_server/`.

---

## 5. Production Environment Variables

### Option A: Using passwords.yaml (Not Recommended)

The template already supports environment variables:

```yaml
# config/passwords.yaml
production:
  database: '${DATABASE_PASSWORD}'
  serviceSecret: '${SERVICE_SECRET}'
  # ...
```

Set environment variables before starting server:
```bash
export DATABASE_PASSWORD="your_secure_password"
export SERVICE_SECRET="your_secure_secret"
# ...
dart bin/main.dart
```

### Option B: Pure Environment Variables (Recommended)

Modify `lib/server.dart` to read directly from environment:

```dart
// At the top of server.dart
import 'dart:io' show Platform;

// In run() function
final pod = Serverpod(
  args,
  Protocol(),
  Endpoints(),
  // Override with environment variables
  serverpodConfig: ServerpodConfig(
    databasePassword: Platform.environment['DATABASE_PASSWORD'] ?? pod.config.databasePassword,
    // ...
  ),
);
```

### Option C: Use a Secret Manager (Best for Production)

- AWS Secrets Manager
- Google Cloud Secret Manager
- HashiCorp Vault
- Doppler
- 1Password Secrets Automation

---

## 6. Production Deployment Checklist

### Before First Deploy

- [ ] All secrets rotated and in environment variables
- [ ] `passwords.yaml` removed from git history (if committed)
- [ ] CORS updated to production domain(s)
- [ ] HTTPS/TLS configured
- [ ] Database user is `on_air_app`, not `postgres`
- [ ] Database SSL enabled (`requireSsl: true`)
- [ ] Redis password set
- [ ] Redis SSL enabled (`requireSsl: true`)
- [ ] Firewall rules configured:
  - [ ] PostgreSQL port (5432) restricted to localhost
  - [ ] Redis port (6379) restricted to localhost
  - [ ] Only web ports (80, 443) exposed
- [ ] Rate limiting enabled
- [ ] Security headers configured
- [ ] Logging configured (console logs disabled in production)
- [ ] Backup strategy in place
- [ ] Monitoring/alerting configured

### Configuration Files to Update

1. **config/production.yaml** (use template):
   ```bash
   cp config/production.yaml.template config/production.yaml
   # Edit with your domain and settings
   ```

2. **Environment Variables** (set in deployment platform):
   ```bash
   DATABASE_HOST=your-db-host
   DATABASE_PASSWORD=your-db-password
   REDIS_HOST=your-redis-host
   REDIS_PASSWORD=your-redis-password
   JWT_PRIVATE_KEY=your-jwt-key
   SERVICE_SECRET=your-service-secret
   # ... etc
   ```

---

## 7. Testing Security Measures

### Test Input Validation

```dart
// Test in Dart:
final tooLongContent = 'a' * 50001;
try {
  await client.chat.createNote(channelId, tooLongContent);
  print('ERROR: Should have rejected long content');
} catch (e) {
  print('✓ Correctly rejected: $e');
}
```

### Test File Upload Limits

```dart
// Test 51MB file (should fail)
final tooLargeFile = Uint8List(51 * 1024 * 1024);
try {
  await client.media.uploadMediaAndCreateNote(...);
  print('ERROR: Should have rejected large file');
} catch (e) {
  print('✓ Correctly rejected: $e');
}
```

### Test Secret Scanning

```bash
# Try to commit a fake secret
echo "password=secret123" > test.txt
git add test.txt
git commit -m "test"

# Pre-commit hook should detect and block it
# If it doesn't, check your hook installation
```

---

## 8. Monitoring & Maintenance

### Monthly Tasks

- [ ] Rotate secrets
- [ ] Review access logs for anomalies
- [ ] Check for dependency vulnerabilities:
  ```bash
  cd on_air_server && dart pub outdated
  cd on_air_flutter && flutter pub outdated
  ```
- [ ] Review GitHub security alerts
- [ ] Test backup restoration
- [ ] Review uploaded content (if applicable)

### Set Up Monitoring

Monitor these metrics:
- Failed authentication attempts (if auth enabled)
- Upload failures
- Database connection errors
- Disk space usage (especially `data/media/`)
- Memory usage during image processing
- API error rates
- Response time percentiles

---

## 9. Incident Response

If you suspect a security breach:

1. **Immediately**:
   - Rotate ALL credentials
   - Review access logs
   - Check for unauthorized uploads/changes

2. **Document**:
   - Add incident to `docs/security.md`
   - Note what happened, why, and how to prevent

3. **Fix**:
   - Patch vulnerability
   - Add test to prevent regression
   - Update this guide if needed

4. **Notify**:
   - If user data affected, follow disclosure laws
   - Consider GitHub security advisory if open source

---

## 10. Getting Help

### Resources

- Serverpod Security: https://docs.serverpod.dev/
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- Flutter Security: https://docs.flutter.dev/security

### Tools

- **Secret Scanning**: gitleaks, git-secrets, trufflehog
- **Dependency Scanning**: dart pub outdated, dependabot
- **SAST**: SonarQube, CodeQL
- **Penetration Testing**: OWASP ZAP, Burp Suite

---

**Remember**: Security is not a one-time task. Regular review and updates are essential!
