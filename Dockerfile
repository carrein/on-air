# Multi-stage Dockerfile for Memoka
# Stage 1: Build Flutter web app
# Stage 2: Build Serverpod server
# Stage 3: Runtime

# Stage 1: Flutter Web Build
FROM ghcr.io/cirruslabs/flutter:stable AS flutter_builder

WORKDIR /build

# Copy Flutter app and client library (needed for pubspec dependency)
COPY memoka_flutter/ ./memoka_flutter/
COPY memoka_client/ ./memoka_client/

# Build Flutter web app
WORKDIR /build/memoka_flutter
RUN flutter pub get
RUN flutter build web --release --base-href /app/

# Stage 2: Serverpod Server Build
FROM dart:stable AS server_builder

WORKDIR /build

# Copy server and client packages
COPY memoka_server/ ./memoka_server/
COPY memoka_client/ ./memoka_client/

# Get dependencies
WORKDIR /build/memoka_server
RUN dart pub get

WORKDIR /build/memoka_client
RUN dart pub get

# Copy Flutter web build from Stage 1
WORKDIR /build/memoka_server
COPY --from=flutter_builder /build/memoka_flutter/build/web ./web/app

# Compile server to native executable
RUN dart compile exe bin/main.dart -o server

# Stage 3: Runtime
FROM debian:stable-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y curl ca-certificates ffmpeg && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy compiled server binary
COPY --from=server_builder /build/memoka_server/server ./server

# Copy configuration files
COPY --from=server_builder /build/memoka_server/config ./config

# Copy migrations
COPY --from=server_builder /build/memoka_server/migrations ./migrations

# Copy web files (static + Flutter app)
COPY --from=server_builder /build/memoka_server/web ./web

# Create media upload directory with proper permissions
RUN mkdir -p /app/data/media && chmod 755 /app/data/media

# Ensure server binary is executable
RUN chmod +x /app/server

# Expose both Serverpod ports
EXPOSE 8080 8082
# 8080: apiServer - API endpoints
# 8082: webServer - Static files and Flutter app

# Run server with production config and migrations
CMD ["/app/server", "--mode", "production", "--apply-migrations"]
