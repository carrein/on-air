# Security Documentation

This document outlines security considerations, best practices, and incident notes for the Memoka application.

## Table of Contents

1. [Security Incidents & Lessons Learned](#security-incidents--lessons-learned)
2. [Current Security Posture](#current-security-posture)
3. [Secrets Management](#secrets-management)
4. [Authentication & Authorization](#authentication--authorization)
5. [File Upload Security](#file-upload-security)
6. [Network Security](#network-security)
7. [Database Security](#database-security)
8. [Deployment Considerations](#deployment-considerations)
9. [Security Checklist](#security-checklist)

---

## Security Incidents & Lessons Learned

### Incident 2026-02-03: Exposed Redis Password in Git History

**What Happened:**
- GitGuardian detected Redis CLI password exposed in GitHub repository
- File: `memoka_server/config/passwords.yaml`
- The file contained development, test, staging, and production secrets
- File was committed to version control despite inline warning: "Note that this file should not be under version control"

**Root Cause:**
- `passwords.yaml` was not in `.gitignore`
- No pre-commit hooks to detect secrets
- Default Serverpod config files were committed without review

**Impact:**
- Development, test, staging, and production secrets exposed
- Database passwords, Redis passwords, JWT keys, service secrets all leaked
- Potential unauthorized access to all environments

**Remediation Required:**
1. ✅ Add `passwords.yaml` to `.gitignore`
2. ⚠️ Rotate ALL exposed secrets immediately:
   - Database passwords (development, test, staging, production)
   - Redis passwords
   - JWT HMAC SHA-512 private keys
   - Service secrets
   - Email secret hash peppers
   - JWT refresh token hash peppers
3. ⚠️ Use GitHub's secret scanning to invalidate leaked credentials
4. ⚠️ Audit access logs for unauthorized access
5. ⚠️ Consider using git-filter-repo to remove from git history

**Prevention Measures:**
- Always check `.gitignore` before initial commit
- Use pre-commit hooks (e.g., `pre-commit`, `git-secrets`, `gitleaks`)
- Never commit files with naming patterns: `*password*`, `*secret*`, `*key*`, `.env*`
- Use environment variables or secret management services in production
- Run `git status` and review files before `git add -A`

---

## Current Security Posture

### ⚠️ CRITICAL ISSUES (Fix Immediately)

1. **Exposed Secrets in Git History**
   - Status: ACTIVE LEAK
   - Files: `memoka_server/config/passwords.yaml`
   - Action Required: Rotate all secrets, update `.gitignore`, clean git history

2. **No Authentication on Media Uploads**
   - Status: BY DESIGN (single-user environment)
   - Risk: Anyone with network access can upload files
   - Mitigation: Firewall rules, VPN, or add authentication before production

3. **CORS Wildcard in Development**
   - Status: INTENTIONAL (development only)
   - Config: `allowOrigins: ["*"]` in `development.yaml`
   - Risk: Any website can make requests to your API
   - Action Required: Restrict CORS origins in production

### ⚠️ MEDIUM PRIORITY

4. **No Rate Limiting**
   - Risk: DoS attacks, brute force, resource exhaustion
   - Recommendation: Add rate limiting middleware

5. **No Input Validation on Note Content**
   - Risk: Extremely large notes, special characters
   - Current: Database will reject invalid data
   - Recommendation: Add client-side and server-side limits

6. **Media Files Served Without Authentication**
   - Status: BY DESIGN (public access)
   - Risk: Direct URL access to all uploaded images
   - Mitigation: UUID filenames prevent enumeration

### ✅ ACCEPTABLE RISKS (Documented)

7. **Single-User Environment**
   - No multi-tenancy
   - No user roles or permissions
   - Acceptable for personal use

---

## Secrets Management

### What Are Secrets?

Secrets include:
- Database passwords
- API keys
- Private keys (JWT, encryption)
- Session secrets
- OAuth client secrets
- Service account credentials
- Hash peppers/salts

### Best Practices

#### Development

```yaml
# ✅ GOOD: Use .gitignore
# .gitignore
memoka_server/config/passwords.yaml
*.env
*.env.*
.env.local

# ✅ GOOD: Use environment variables
database:
  password: ${DATABASE_PASSWORD}

# ❌ BAD: Hardcoded secrets
database:
  password: 'myP@ssw0rd123'
```

#### Production

**Use Environment Variables:**
```bash
# Set via deployment platform (Fly.io, Railway, etc.)
export DATABASE_PASSWORD="..."
export REDIS_PASSWORD="..."
export JWT_SECRET="..."
```

**Or Secret Management Service:**
- AWS Secrets Manager
- Google Cloud Secret Manager
- HashiCorp Vault
- Doppler
- 1Password Secrets Automation

### Files to NEVER Commit

```gitignore
# Serverpod
memoka_server/config/passwords.yaml

# Environment variables
.env
.env.local
.env.*.local

# Secret keys
*.pem
*.key
*.p12
*.pfx
id_rsa*
*.keystore

# Cloud credentials
credentials.json
service-account.json
gcloud-*.json

# Database dumps with data
*.sql
*.dump

# Backups
*.backup
*.bak
```

---

## Authentication & Authorization

### Current State: No Authentication

**Design Decision:**
- Single-user application for personal use
- No login required
- All endpoints are public

**Security Implications:**
- Anyone with network access can:
  - View all channels and notes
  - Create/update/delete any content
  - Upload media files
  - Delete channels

**When to Add Authentication:**

If deploying publicly or sharing with others, implement:

1. **Serverpod Auth (Already Configured):**
   ```dart
   // Enabled in lib/server.dart
   pod.initializeAuthServices(
     tokenManagerBuilders: [JwtConfigFromPasswords()],
     identityProviderBuilders: [EmailIdpConfigFromPasswords(...)],
   );
   ```

2. **Protect Endpoints:**
   ```dart
   Future<Note> createNote(Session session, int channelId, String content) async {
     // Add authentication check
     if (!await session.isUserSignedIn) {
       throw Exception('User must be signed in');
     }
     // ... rest of method
   }
   ```

3. **Row-Level Security:**
   - Add `userId` to channels and notes
   - Filter queries by current user
   - Prevent cross-user access

---

## File Upload Security

### Current Implementation

**Upload Endpoint:** `media_endpoint.dart`

**Security Measures:**

✅ **File Size Limit:**
```dart
const maxFileSize = 50 * 1024 * 1024; // 50MB
if (fileBytes.length > maxFileSize) {
  throw Exception('File size exceeds maximum...');
}
```

✅ **MIME Type Validation:**
```dart
const allowedMimeTypes = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/heic',
];
```

✅ **Image Decoding Validation:**
```dart
// Validates file is actually an image, not malicious file with fake extension
final image = img.decodeImage(fileBytes);
if (image == null) {
  throw Exception('Invalid image file');
}
```

✅ **UUID-Based Filenames:**
```dart
// Prevents path traversal and enumeration
final uuid = Uuid().v4();
final filename = '$uuid.jpg';
// Original filename stored in DB, never used in file paths
```

✅ **EXIF Metadata Stripping:**
```dart
// Removes GPS coordinates, camera info, personal data
image.exif.clear();
```

✅ **Path Sanitization:**
```dart
// Prevents directory traversal
final sanitizedChannelId = channelId.toString().replaceAll(RegExp(r'[^0-9]'), '');
```

### Potential Vulnerabilities to Monitor

⚠️ **No Authentication:**
- Anyone can upload files
- No user attribution
- Recommendation: Add authentication before public deployment

⚠️ **No Virus Scanning:**
- Files not scanned for malware
- Risk: Image files can contain embedded exploits
- Recommendation: Use ClamAV or cloud scanning service

⚠️ **Unlimited Uploads Per User:**
- No rate limiting on uploads
- Risk: Disk space exhaustion
- Recommendation: Add per-IP or per-session limits

⚠️ **No Content Policy Enforcement:**
- No automated moderation
- Risk: Inappropriate content
- Acceptable for single-user, monitor if sharing

### Image Processing Safety

✅ **Isolate-Based Processing:**
```dart
// Prevents blocking main thread, limits memory impact
await compute(_processImageInIsolate, params);
```

✅ **Two-Phase Commit:**
```dart
// Prevents orphaned files or DB records
1. Write to .tmp file
2. Process image
3. Insert DB record
4. Atomic rename to final path
5. On error: delete temp file
```

---

## Network Security

### Development

**CORS Configuration:**
```yaml
# development.yaml
cors:
  allowOrigins:
    - "*"  # ⚠️ DEVELOPMENT ONLY
```

**Risk:**
- Any website can make requests to your API
- Session hijacking potential
- CSRF attacks possible

**Mitigation:**
- Only used in development
- Development server on localhost
- Not exposed to internet

### Production

**REQUIRED Changes:**

```yaml
# production.yaml
cors:
  allowOrigins:
    - "https://yourdomain.com"
    - "https://www.yourdomain.com"
  allowCredentials: true
```

**Additional Measures:**

1. **HTTPS Only:**
   ```yaml
   apiServer:
     publicScheme: https
     # Add SSL certificate
   ```

2. **Firewall Rules:**
   - Restrict database port (5432) to localhost
   - Restrict Redis port (6379) to localhost
   - Only expose web server ports (80, 443)

3. **Rate Limiting:**
   ```dart
   // Add to Serverpod middleware
   // Limit requests per IP/session
   ```

---

## Database Security

### PostgreSQL

**Current Setup:**
```yaml
database:
  host: localhost
  port: 8090  # Non-standard port (good)
  name: memoka
  user: postgres
  # Password in passwords.yaml (rotate after leak)
```

**Security Measures:**

✅ **Non-Standard Port:**
- Using 8090 instead of 5432
- Reduces automated attacks

✅ **Localhost Only:**
- Database not exposed to internet
- Only accessible from application server

✅ **CASCADE Deletes:**
- Proper foreign key relationships
- Prevents orphaned records
- Automatic cleanup

⚠️ **Default User:**
- Using `postgres` superuser
- Recommendation: Create dedicated app user with limited privileges

**Hardening Recommendations:**

```sql
-- Create dedicated user
CREATE USER memoka_app WITH PASSWORD 'strong_password_here';

-- Grant minimal permissions
GRANT CONNECT ON DATABASE memoka TO memoka_app;
GRANT USAGE ON SCHEMA public TO memoka_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO memoka_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO memoka_app;

-- Revoke superuser access
ALTER USER memoka_app WITH NOSUPERUSER;
```

### Redis

**Current Setup:**
```yaml
redis:
  enabled: true
  host: localhost
  port: 8091  # Non-standard port (good)
```

**Security:**

✅ **Non-Standard Port:**
- Using 8091 instead of 6379

✅ **Localhost Only:**
- Not exposed to internet

⚠️ **Password Exposed in Git:**
- Rotate immediately
- Use environment variable

**Hardening:**
```bash
# In redis.conf
requirepass your_new_password_here
bind 127.0.0.1
protected-mode yes
```

---

## Deployment Considerations

### Pre-Deployment Checklist

- [ ] Rotate ALL secrets from leaked `passwords.yaml`
- [ ] Remove `passwords.yaml` from git history
- [ ] Add `passwords.yaml` to `.gitignore`
- [ ] Use environment variables for secrets
- [ ] Change CORS from `*` to specific domain
- [ ] Enable HTTPS/TLS
- [ ] Set up firewall rules
- [ ] Create dedicated database user (not postgres)
- [ ] Enable database SSL if supported
- [ ] Set up automated backups
- [ ] Configure rate limiting
- [ ] Add monitoring/logging
- [ ] Set up intrusion detection
- [ ] Review all exposed ports
- [ ] Disable unnecessary services

### Environment Variables

**Required for Production:**
```bash
# Database
DATABASE_PASSWORD="..."
DATABASE_SSL=true

# Redis
REDIS_PASSWORD="..."
REDIS_SSL=true

# JWT
JWT_SECRET="..."
JWT_REFRESH_SECRET="..."

# Service
SERVICE_SECRET="..."

# Email (if using)
EMAIL_SECRET_PEPPER="..."
```

### Monitoring

**What to Monitor:**
- Failed authentication attempts
- Unusual upload patterns
- Database connection errors
- Disk space usage (media uploads)
- Memory usage (image processing)
- API error rates
- Response times

---

## Security Checklist

### Before Every Commit

- [ ] Review `git status` output
- [ ] Check for files containing "password", "secret", "key"
- [ ] Verify `.gitignore` is working
- [ ] No hardcoded credentials in code
- [ ] No sensitive data in commit message

### Before Deployment

- [ ] All secrets in environment variables
- [ ] CORS restricted to production domain
- [ ] HTTPS enabled
- [ ] Firewall configured
- [ ] Backups enabled
- [ ] Monitoring configured

### Monthly Review

- [ ] Rotate secrets
- [ ] Review access logs
- [ ] Check for dependency vulnerabilities (`dart pub outdated`)
- [ ] Review GitHub security alerts
- [ ] Test backup restoration
- [ ] Review user-uploaded content (if applicable)

---

## Security Setup Instructions

### 1. Rotate Secrets (CRITICAL)

Generate new secrets using strong random generators:

```bash
# Generate random 32-character password
openssl rand -base64 32

# Or use UUID for service secrets
uuidgen
```

**Update passwords.yaml:**
1. Copy template: `cd memoka_server/config && cp passwords.yaml.template passwords.yaml`
2. Replace ALL placeholders with strong random values (database passwords, Redis passwords, JWT keys, service secrets, hash peppers)
3. Verify file is in `.gitignore`: `git check-ignore passwords.yaml`

### 2. Pre-Commit Hooks

**Install:**
```bash
pip3 install pre-commit
cd /path/to/memoka
pre-commit install
```

**Test:**
```bash
pre-commit run --all-files
```

**What gets checked:**
- Secret scanning (gitleaks)
- Large file detection
- Private key detection
- passwords.yaml exclusion
- .env file exclusion
- Trailing whitespace
- YAML syntax

### 3. Database User Setup

Create dedicated database user (not postgres superuser):

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U postgres -d memoka -h localhost -p 8090

# Run security script
\i config/create_db_user.sql
```

Update `config/development.yaml`:
```yaml
database:
  user: memoka_app  # Changed from postgres
```

Update `config/passwords.yaml` with new user password and restart server.

### 4. Input Validation Limits

Current enforced limits:

| Field | Max Length | Rationale |
|-------|-----------|-----------|
| Channel name | 100 chars | UI display constraints |
| Channel emoji | 10 chars | Multi-byte emoji support |
| Note content | 50,000 chars | ~10-20 pages, prevents abuse |
| Filename | 255 chars | Filesystem limit |
| File size | 50 MB | Balance usability vs resources |

Customize in respective endpoint files:
- Channel limits: `memoka_server/lib/src/chat/chat_endpoint.dart`
- Note limits: `memoka_server/lib/src/chat/chat_endpoint.dart`
- File limits: `memoka_server/lib/src/media/media_endpoint.dart`

After changes, run `serverpod generate` from `memoka_server/`.

### 5. Production Environment Variables

Use environment variables for all secrets:

```bash
# Required for production
export DATABASE_HOST="your-db-host"
export DATABASE_PASSWORD="..."
export REDIS_HOST="your-redis-host"
export REDIS_PASSWORD="..."
export JWT_SECRET="..."
export JWT_REFRESH_SECRET="..."
export SERVICE_SECRET="..."
export EMAIL_SECRET_PEPPER="..."
```

Recommended: Use secret management service (AWS Secrets Manager, Google Cloud Secret Manager, HashiCorp Vault, Doppler, 1Password Secrets Automation).

### 6. Production Deployment Checklist

**Before deployment:**
- [ ] Rotate ALL secrets from leaked `passwords.yaml`
- [ ] Remove `passwords.yaml` from git history
- [ ] Add `passwords.yaml` to `.gitignore`
- [ ] Use environment variables for secrets
- [ ] Change CORS from `*` to specific domain
- [ ] Enable HTTPS/TLS
- [ ] Set up firewall rules (PostgreSQL/Redis restricted to localhost, only web ports 80/443 exposed)
- [ ] Create dedicated database user (not postgres)
- [ ] Enable database SSL (`requireSsl: true`)
- [ ] Enable Redis SSL (`requireSsl: true`)
- [ ] Configure rate limiting
- [ ] Set up monitoring/logging
- [ ] Configure automated backups
- [ ] Review all exposed ports

**Configuration updates:**
- Create `config/production.yaml` from template
- Set environment variables in deployment platform
- Update CORS to production domain(s)
- Configure security headers

### 7. Security Testing

**Test input validation:**
```dart
// Test 50,001 character note (should fail)
final tooLongContent = 'a' * 50001;
try {
  await client.chat.createNote(channelId, tooLongContent);
  print('ERROR: Should have rejected long content');
} catch (e) {
  print('✓ Correctly rejected: $e');
}
```

**Test file upload limits:**
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

**Test secret scanning:**
```bash
# Try to commit a fake secret
echo "password=secret123" > test.txt
git add test.txt
git commit -m "test"
# Pre-commit hook should detect and block
```

### 8. Monitoring & Maintenance

**Monthly tasks:**
- [ ] Rotate secrets
- [ ] Review access logs for anomalies
- [ ] Check dependency vulnerabilities: `dart pub outdated` and `flutter pub outdated`
- [ ] Review GitHub security alerts
- [ ] Test backup restoration
- [ ] Review uploaded content (if applicable)

**Monitor these metrics:**
- Failed authentication attempts
- Upload failures
- Database connection errors
- Disk space usage (`data/media/`)
- Memory usage during image processing
- API error rates
- Response time percentiles

### 9. Incident Response

If security breach suspected:

1. **Immediately:**
   - Rotate ALL credentials
   - Review access logs
   - Check for unauthorized uploads/changes

2. **Document:**
   - Add incident to this file
   - Note what happened, why, and how to prevent

3. **Fix:**
   - Patch vulnerability
   - Add test to prevent regression
   - Update documentation

4. **Notify:**
   - If user data affected, follow disclosure laws
   - Consider GitHub security advisory if open source

---

## Security Implementation Status

### ✅ Completed Fixes

1. **Environment Variable Support** - Server reads from environment variables, `passwords.yaml.template` created
2. **Rate Limiting** - Middleware configured with per-endpoint limits and IP-based throttling
3. **Input Validation** - Max content lengths enforced (notes, channels, filenames)
4. **Pre-commit Hooks** - `.pre-commit-config.yaml` configured with gitleaks secret scanning
5. **Production Config Template** - `production.yaml.template` created with secure defaults
6. **Database Security Scripts** - SQL script for dedicated user with minimal privileges
7. **CORS Improvements** - Conditional CORS based on environment, strict production settings

### ⏸️ Deferred (Requires Infrastructure)

- HTTPS/TLS setup (requires certificates)
- Firewall rules (requires deployment platform)
- Secret rotation (requires new credentials)
- Virus scanning (requires external service)
- Database SSL (requires production database)

---

## Additional Resources

- [Serverpod Security Best Practices](https://docs.serverpod.dev/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CWE Top 25 Most Dangerous Software Weaknesses](https://cwe.mitre.org/top25/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)

**Tools:**
- Secret scanning: gitleaks, git-secrets, trufflehog
- Dependency scanning: dart pub outdated, dependabot
- SAST: SonarQube, CodeQL
- Penetration testing: OWASP ZAP, Burp Suite

---

## Emergency Response Commands

```bash
# Check what's being committed
git status
git diff --cached

# Search for secrets in codebase
grep -r "password" --exclude-dir=node_modules --exclude-dir=.git

# Check git history for sensitive files
git log --all --full-history -- "**/passwords.yaml"

# Remove file from git history (USE WITH CAUTION)
# git filter-repo --path passwords.yaml --invert-paths

# Scan for secrets (install gitleaks first)
gitleaks detect --source . --verbose
```

---

**Last Updated:** 2026-02-03
**Next Review:** 2026-03-03
