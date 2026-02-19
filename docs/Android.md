# Android Build Guide

Native Android support for Memoka — sideloadable APK that connects to any self-hosted Serverpod backend.

## Prerequisites

- Flutter SDK 3.32+
- Android SDK (API 26–36)
- JDK 17
- Android device or emulator

## Quick Start

```bash
cd memoka_flutter

# Install dependencies
flutter pub get

# Debug APK (uses debug signing, no keystore needed)
flutter build apk --debug

# Run on connected device/emulator
flutter run

# With compile-time server URL
flutter run --dart-define=SERVER_URL=https://memoka.example.com/
```

## Emulator Setup

See [Emulator.md](Emulator.md) for full setup instructions including socat proxy configuration, VS Code port conflict workaround, and troubleshooting.

## Server URL Configuration

The app needs a Serverpod backend URL. There are three ways to configure it:

### 1. First-launch setup screen
On first launch, the app shows a setup screen where you enter your server URL and test the connection. The URL is saved to SharedPreferences.

### 2. Compile-time override
```bash
flutter build apk --dart-define=SERVER_URL=https://memoka.example.com/
```

### 3. Settings
Once connected, go to Settings → Server → Change to update the URL.

### Debug mode
In debug builds, the URL field pre-fills with `http://localhost:8080/` (works with adb reverse). In release builds, the field is empty.

### Tailscale / LAN setup
For real devices on the same network, use your server's Tailscale hostname or LAN IP:
```
https://memoka.tailnet.ts.net/
http://192.168.1.100:8080/
```

## Release Signing

### 1. Generate a keystore

```bash
keytool -genkey -v \
  -keystore memoka-release.keystore \
  -alias memoka \
  -keyalg RSA -keysize 2048 \
  -validity 10000
```

### 2. Create `android/key.properties`

```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=memoka
storeFile=../../memoka-release.keystore
```

This file is gitignored. The `storeFile` path is relative to `android/app/`.

### 3. Build release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Or with server URL baked in:
flutter build apk --release --dart-define=SERVER_URL=https://memoka.example.com/
```

Without `key.properties`, the release build falls back to debug signing (fine for sideloading, not for Play Store).

## Launcher Icon

The app icon uses `flutter_launcher_icons`. Icon PNGs are pre-generated from `icon.svg`. To regenerate after changing the icon:

```bash
# If icon.svg changed, re-export PNGs:
python3 -c "
import cairosvg
cairosvg.svg2png(url='assets/images/icon.svg', write_to='assets/images/icon.png', output_width=1024, output_height=1024)
cairosvg.svg2png(url='assets/images/icon.svg', write_to='assets/images/icon_foreground.png', output_width=1024, output_height=1024)
"

# Generate adaptive icons for all densities
dart run flutter_launcher_icons
```

Config is in `flutter_launcher_icons.yaml`. Adaptive icon uses `#00171F` background.

## Features

### Camera Capture
- Camera button appears in the input bar (next to attachment) on Android
- Uses `image_picker` with `ImageSource.camera`
- Captured photo routes through the standard file upload dialog
- Requires CAMERA permission (requested at runtime)

### Share Intent
- Share text, images, videos, or files from any Android app to Memoka
- Opens a dialog with channel picker, text field, and media previews
- Supports single and multiple file shares
- Handles both cold start (app not running) and warm start (app in background)

### Supported intent types
| Action | MIME types |
|--------|-----------|
| `ACTION_SEND` | `text/plain`, `image/*`, `video/*`, `application/*` |
| `ACTION_SEND_MULTIPLE` | `image/*`, `video/*` |

## Permissions

| Permission | Rationale |
|-----------|-----------|
| `INTERNET` | Connect to Serverpod backend |
| `CAMERA` | Capture photos from input bar |
| `READ_MEDIA_IMAGES` | Access shared images (Android 13+) |
| `READ_MEDIA_VIDEO` | Access shared videos (Android 13+) |

## Media URL Resolution

The app resolves media URLs differently based on the server:

- **Dev server** (localhost/10.0.2.2 on port 8080): Media is served from port 8082 (Serverpod's web server)
- **Production** (everything else): Media is served from the same base URL (assumes reverse proxy routes `/media` correctly)

This means Tailscale and reverse-proxy setups work without port swapping.

## Application Identity

- Package: `com.memoka.app`
- Compile SDK: 36
- Target SDK: 35
- Min SDK: 26 (Android 8.0)
- Splash: `#00171F` background

## Troubleshooting

### "Connection failed" on server setup (emulator)
1. Ensure Serverpod is running: `curl -6 http://[::1]:8080/` should return 200
2. Set up ADB reverse: `adb reverse tcp:8080 tcp:8080`
3. If still failing (IPv6-only server), set up the IPv4→IPv6 proxy (see Emulator Setup above)
4. Use `http://localhost:8080/` as the URL (pre-filled in debug builds)

### "Connection failed" on server setup (real device)
- Use your server's LAN IP or Tailscale hostname, not `localhost`
- Ensure the device and server are on the same network
- Ensure the URL ends with `/`

### Media not loading
- Dev: ensure the web server is running on port 8082 and adb reverse includes port 8082
- Production: ensure your reverse proxy forwards `/media` requests

### Camera not working
- Check that camera permission is granted in Android settings
- Some emulators don't support camera; test on a real device

### Share intent not showing Memoka
- The share intent filters are registered in AndroidManifest.xml
- After installing, restart the device or clear the share sheet cache
