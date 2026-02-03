# On Air

Real-time chat-style notes application with Serverpod backend and Flutter frontend.

## Features

- 📝 Real-time notes with WebSocket streaming
- 📁 Organized channels with pinning support
- 🔗 Automatic link previews
- 🖼️ Image uploads with drag-and-drop and paste support
- 💬 Markdown formatting
- 🎨 Clean, sharp UI design

## Documentation

- [Project Overview](docs/overview.md)
- [Implementation Plan](docs/plan.md)
- [Channel Management](docs/channel.md)
- [Link Previews](docs/link.md)
- [Media Uploads](docs/media.md)
- [UX Design](docs/ux.md)
- **[Security Documentation](docs/security.md)** ⚠️ **Read before deployment!**
- **[Security Setup Guide](SECURITY_SETUP.md)** - Step-by-step hardening

## Quick Start

### Prerequisites

- Dart SDK 3.0+
- Flutter 3.10+
- Docker & Docker Compose
- PostgreSQL client (optional, for manual DB access)

### Development Setup

1. **Start database services**:
   ```bash
   cd on_air_server
   docker compose up --build --detach
   ```

2. **Install dependencies**:
   ```bash
   # Server
   cd on_air_server
   dart pub get

   # Flutter
   cd ../on_air_flutter
   flutter pub get
   ```

3. **Set up secrets** (IMPORTANT!):
   ```bash
   cd on_air_server/config
   cp passwords.yaml.template passwords.yaml
   # Edit passwords.yaml with strong random values
   # NEVER commit passwords.yaml!
   ```

4. **Run database migrations**:
   ```bash
   cd on_air_server
   dart bin/main.dart --apply-migrations
   ```

5. **Start the server**:
   ```bash
   dart bin/main.dart
   ```

6. **Run Flutter app** (in a new terminal):
   ```bash
   cd on_air_flutter
   flutter run -d chrome
   ```

## Security

⚠️ **CRITICAL**: This application has NO authentication by design (single-user environment).

**Before deploying publicly or sharing with others:**

1. Read [docs/security.md](docs/security.md) - Full security documentation
2. Follow [SECURITY_SETUP.md](SECURITY_SETUP.md) - Hardening checklist
3. Rotate all secrets in `passwords.yaml`
4. Add authentication (see docs/security.md)
5. Configure CORS for production domain
6. Enable HTTPS
7. Set up firewall rules

**Recent Security Incident**: Passwords file was nearly exposed. See [docs/security.md](docs/security.md#security-incidents--lessons-learned) for details and prevention measures.

## Architecture

Built with [Serverpod](https://serverpod.dev) v3.2.3:

- **on_air_server**: Backend with real-time streaming, media uploads, link previews
- **on_air_client**: Auto-generated type-safe API client
- **on_air_flutter**: Cross-platform Flutter app (Web/Mobile)

Key technologies:
- PostgreSQL with pgvector
- Redis for real-time messaging
- Riverpod for state management
- Markdown rendering
- Image processing with EXIF handling

See [CLAUDE.md](CLAUDE.md) for detailed architecture and development workflow.

## Contributing

This is a personal project. Security issues should be reported privately.

## License

[Add your license here]
