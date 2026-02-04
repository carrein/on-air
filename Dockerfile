# Multi-stage Dockerfile for On Air
# Stage 1: Build Flutter web app
# Stage 2: Build Serverpod server
# Stage 3: Runtime

# Stage 1: Flutter Web Build
FROM ghcr.io/cirruslabs/flutter:stable AS flutter_builder

WORKDIR /build

# Copy Flutter app and client library (needed for pubspec dependency)
COPY on_air_flutter/ ./on_air_flutter/
COPY on_air_client/ ./on_air_client/

# Build Flutter web app
WORKDIR /build/on_air_flutter
RUN flutter pub get
RUN flutter build web --release --base-href /app/

# Stage 2: Serverpod Server Build
FROM dart:stable AS server_builder

WORKDIR /build

# Copy server and client packages
COPY on_air_server/ ./on_air_server/
COPY on_air_client/ ./on_air_client/

# Get dependencies
WORKDIR /build/on_air_server
RUN dart pub get

WORKDIR /build/on_air_client
RUN dart pub get

# Copy Flutter web build from Stage 1
WORKDIR /build/on_air_server
COPY --from=flutter_builder /build/on_air_flutter/build/web ./web/app

# Compile server to native executable
RUN dart compile exe bin/main.dart -o server

# Stage 3: Runtime
FROM debian:stable-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy compiled server binary
COPY --from=server_builder /build/on_air_server/server ./server

# Copy configuration files
COPY --from=server_builder /build/on_air_server/config ./config

# Copy migrations
COPY --from=server_builder /build/on_air_server/migrations ./migrations

# Copy web files (static + Flutter app)
COPY --from=server_builder /build/on_air_server/web ./web

# Create media upload directory with proper permissions
RUN mkdir -p /app/data/media && chmod 755 /app/data/media

# Ensure server binary is executable
RUN chmod +x /app/server

# Expose port
EXPOSE 8080

# Run server with production config and migrations
CMD ["/app/server", "--mode", "production", "--apply-migrations"]
