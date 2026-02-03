u/docs/channel.md
u/docs/link.md
u/docs/media.md
u/docs/overview.md
u/docs/plan.md
u/docs/security.md
u/docs/ux.md

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a full-stack application built with Serverpod (v3.2.3), consisting of three main packages:

- **on_air_server**: Serverpod backend server (Dart)
- **on_air_client**: Generated client library (Dart)
- **on_air_flutter**: Flutter mobile/web application

Serverpod is a backend framework for Dart/Flutter that handles database connections, endpoints, authentication, and code generation.

## Architecture

### Three-Tier Structure

1. **Server Layer** (`on_air_server/`)
   - Endpoints define the server API in `lib/src/*_endpoint.dart`
   - Protocol models are defined in `.spy.yaml` files (e.g., `lib/src/greetings/greeting.spy.yaml`)
   - Generated code lives in `lib/src/generated/` and should NEVER be manually edited
   - Server entry point: `lib/server.dart` initializes Serverpod, auth services, and web routes

2. **Client Layer** (`on_air_client/`)
   - Auto-generated from server code via `serverpod generate`
   - Provides type-safe API to call server endpoints
   - Code in this package is mostly generated; manual edits are rare

3. **Flutter App** (`on_air_flutter/`)
   - Uses `on_air_client` to communicate with the server
   - Client instance initialized in `lib/main.dart` with server URL from `assets/config.json`
   - Authentication support via `serverpod_auth_idp_flutter`

### Code Generation Workflow

Serverpod uses code generation extensively. When you modify:

- Endpoint methods in `*_endpoint.dart`
- Protocol models in `*.spy.yaml`
- Database table definitions

You MUST run `serverpod generate` from the `on_air_server/` directory to regenerate:

- Protocol classes (`lib/src/generated/protocol.dart`)
- Endpoint dispatchers (`lib/src/generated/endpoints.dart`)
- Client code in `on_air_client/`
- Test helpers

**Never manually edit files in `lib/src/generated/` directories.**

### Authentication Architecture

- JWT-based authentication via `serverpod_auth_idp_server`
- Email identity provider configured in `lib/server.dart`
- Verification codes for registration/password reset are logged to console (see `_sendRegistrationCode` and `_sendPasswordResetCode` in `lib/server.dart`)
- Endpoints: `emailIdp` (login, registration, password reset) and `jwtRefresh`

### Database & Services

- PostgreSQL (with pgvector extension) on port 8090 (dev) / 9090 (test)
- Redis on port 8091 (dev) / 9091 (test)
- Managed via Docker Compose (`on_air_server/docker-compose.yaml`)
- Separate containers for development and testing
- Migrations stored in `on_air_server/migrations/` with registry in `migration_registry.txt`

## Common Commands

### Server Development

From `on_air_server/`:

```bash
# Start database services (REQUIRED before running server)
docker compose up --build --detach

# Install dependencies
dart pub get

# Install Serverpod CLI (one-time setup)
dart pub global activate serverpod_cli 3.2.3

# Regenerate code after changing endpoints or models
serverpod generate

# Run server (starts on default port 8080)
dart bin/main.dart

# Run server with migrations applied
dart bin/main.dart --apply-migrations

# Stop services when done
docker compose stop

# Run tests
dart test

# Stop and remove test containers/volumes
docker compose down -v
```

### Flutter Development

From `on_air_flutter/`:

```bash
# Install dependencies
flutter pub get

# Run the app (ensure server is running first)
flutter run

# Build web app and copy to server's web directory
# (Run from on_air_server directory)
cd ../on_air_flutter
flutter build web --base-href /app/ --wasm --output ../on_air_server/web/app
```

### Testing

Integration tests use `withServerpod` test helper from `serverpod_test` package. Tests automatically:

- Start Serverpod in test mode
- Use test database/redis containers (ports 9090/9091)
- Roll back database after each test
- Apply migrations before test suite runs

Example test structure:

```dart
withServerpod('Given Example endpoint', (sessionBuilder, endpoints) {
  test('when calling `hello` then should return greeting', () async {
    final greeting = await endpoints.greeting.hello(sessionBuilder, 'Michael');
    expect(greeting.message, 'Hello Michael');
  });
});
```

## Development Workflow

1. **Adding a new endpoint**:
   - Create `*_endpoint.dart` file in `on_air_server/lib/src/`
   - Define class extending `Endpoint` with methods
   - Run `serverpod generate` to update generated code
   - Access via `client.<endpointName>.<method>()` in Flutter

2. **Adding a data model**:
   - Create `*.spy.yaml` file defining the class and fields
   - Add `table: <name>` if it represents a database table
   - Run `serverpod generate` to create model classes
   - Create database migration if needed

3. **Creating a migration**:
   - Modify table definitions in `.spy.yaml` files
   - Run `serverpod create-migration` to generate migration files
   - Migrations are stored in timestamped directories under `migrations/`
   - Apply with `--apply-migrations` flag or manually

## Project-Specific Details

### Environment Variables

CI/CD uses these environment variables (see `.github/workflows/tests.yml`):

- `SERVERPOD_PASSWORD_database`: PostgreSQL password for tests
- `SERVERPOD_PASSWORD_redis`: Redis password for tests

### Web Routes

Server serves:

- Static files from `web/static/` at root
- Flutter web app from `web/app/` at `/app` (if built)
- App config at `/app/assets/assets/config.json` (dynamically generated from server config)

### Current Endpoints

- `chat`: Channel and note management with real-time WebSocket updates
  - Channels: create, update, delete, list, pin/unpin
  - Notes: create, update, delete, list with pagination
  - Link previews: automatic URL detection and metadata fetching (see `docs/link.md`)
  - Real-time streaming: WebSocket events for live updates
- `emailIdp`: Email authentication (login, registration, password reset)
- `jwtRefresh`: Token refresh
- `greeting`: Example endpoint with `hello` method

## Important Conventions

- Endpoint class names must end with `Endpoint` (e.g., `GreetingEndpoint`)
- When accessed from client, the `Endpoint` suffix is removed (e.g., `client.greeting`)
- All server-side code generation is triggered by `serverpod generate`
- Docker services MUST be running before starting the server
- Test environment uses separate database/redis instances to avoid conflicts
