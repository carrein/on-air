# Android Emulator Guide

Running Memoka on the Android emulator requires port forwarding so the emulator can reach the Serverpod backend on the host machine.

## Prerequisites

- Android emulator running (e.g. via Android Studio or `emulator -avd <name>`)
- Serverpod backend running on the host (`dart bin/main.dart` from `memoka_server/`)
- Docker services up (`docker compose up --build --detach` from `memoka_server/`)
- `socat` installed (`brew install socat`)

## Why socat is needed

Serverpod binds to IPv6 (`::`) on macOS. The emulator's ADB reverse forwards to `127.0.0.1` (IPv4) on the host. Two things prevent a direct connection:

1. **Serverpod is IPv6-only** — it listens on `*:8080` over IPv6, not IPv4.
2. **VS Code intercepts ports** — VS Code auto-detects open ports and creates IPv4 listeners on `127.0.0.1:8080/8082`. These forwards are unreliable and can hang instead of proxying, causing `TimeoutException` in the app.

`socat` creates a reliable IPv4→IPv6 bridge on alternate ports (18080/18082), bypassing both problems.

## Setup

### 1. Start socat proxies

```bash
# Bridge IPv4 → IPv6 for API server and web server (media)
socat 'TCP4-LISTEN:18080,fork,reuseaddr' 'TCP6:[::1]:8080' &
socat 'TCP4-LISTEN:18082,fork,reuseaddr' 'TCP6:[::1]:8082' &
```

### 2. Set up ADB reverse

```bash
# Map emulator's localhost ports to the socat proxy ports on the host
adb -s emulator-5554 reverse tcp:8080 tcp:18080
adb -s emulator-5554 reverse tcp:8082 tcp:18082
```

Replace `emulator-5554` with your emulator's device ID from `flutter devices` or `adb devices`.

### 3. Verify

```bash
# Should return HTTP 200
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18080/

# Check ADB reverse rules
adb -s emulator-5554 reverse --list
```

### 4. Launch the app

```bash
cd memoka_flutter
flutter run -d emulator-5554
```

On first launch, the app shows a server setup screen. In debug builds, the URL pre-fills with `http://localhost:8080/` — use that as-is.

## Connection flow

```
App (emulator)
  → localhost:8080
  → ADB reverse → host:18080
  → socat → [::1]:8080
  → Serverpod
```

Media requests follow the same path on port 8082→18082.

## Resetting after reinstall

ADB reverse rules are cleared when the app is reinstalled. Re-run the `adb reverse` commands after each install:

```bash
adb -s emulator-5554 reverse tcp:8080 tcp:18080
adb -s emulator-5554 reverse tcp:8082 tcp:18082
```

The socat processes persist until killed or the terminal is closed.

## Quick reference

```bash
# Full setup from scratch
cd memoka_server
docker compose up --build --detach
dart bin/main.dart --apply-migrations &

socat 'TCP4-LISTEN:18080,fork,reuseaddr' 'TCP6:[::1]:8080' &
socat 'TCP4-LISTEN:18082,fork,reuseaddr' 'TCP6:[::1]:8082' &

adb -s emulator-5554 reverse tcp:8080 tcp:18080
adb -s emulator-5554 reverse tcp:8082 tcp:18082

cd ../memoka_flutter
flutter run -d emulator-5554
```

## Teardown

```bash
# Kill socat proxies
pkill -f socat

# Remove ADB reverse rules
adb -s emulator-5554 reverse --remove-all

# Stop server and services
pkill -f 'dart bin/main.dart'
cd memoka_server && docker compose stop
```

## Troubleshooting

### TimeoutException / Connection refused

1. Check Serverpod is running: `curl -s -o /dev/null -w "%{http_code}" 'http://[::1]:8080/'` → should be `200`
2. Check socat is running: `pgrep -la socat` → should show two processes
3. Check socat proxy works: `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18080/` → should be `200`
4. Check ADB reverse is set: `adb -s emulator-5554 reverse --list` → should show two rules

### Port 18080 already in use

Kill stale socat processes and restart:

```bash
pkill -f socat
socat 'TCP4-LISTEN:18080,fork,reuseaddr' 'TCP6:[::1]:8080' &
socat 'TCP4-LISTEN:18082,fork,reuseaddr' 'TCP6:[::1]:8082' &
```

### Media not loading

Ensure port 8082 is forwarded through both socat and ADB reverse. Media is served from Serverpod's web server on port 8082 in dev mode.

### Without VS Code

If you're not running VS Code (or any editor that auto-forwards ports), direct ADB reverse may work without socat:

```bash
adb -s emulator-5554 reverse tcp:8080 tcp:8080
adb -s emulator-5554 reverse tcp:8082 tcp:8082
```

Test with `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/` — if it returns `200`, socat is not needed.
