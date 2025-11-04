# Build stage
FROM elixir:1.19-otp-28-alpine AS builder

ENV MIX_ENV=prod

# Install build dependencies
RUN apk update --no-cache && apk add --no-cache build-base git npm

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files
COPY mix.exs mix.lock ./
COPY config config

# Install dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy application code
COPY . .

# Build assets
RUN mix assets.deploy

# Build release
RUN mix release --overwrite

RUN ls -la /app/_build/prod/rel/group_deals/ | grep erts
RUN find /app/_build/prod/rel/group_deals -name "erts-*" -type d

# Runtime stage
FROM alpine:3.22 AS runtime

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    openssl \
    ncurses-libs \
    libgcc \
    libstdc++ \
    ca-certificates \
    postgresql-client \
    netcat-openbsd

WORKDIR /app

# Create non-root user
RUN adduser -D -s /bin/sh appuser && \
    chown -R appuser:appuser /app

# Copy release from builder
COPY --from=builder --chown=appuser:appuser /app/_build/prod/rel/group_deals ./
COPY --chown=appuser:appuser bin/docker-entrypoint.sh /app/bin/docker-entrypoint.sh
RUN chmod +x /app/bin/docker-entrypoint.sh

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD nc -z localhost 4000 || exit 1

# Start the application
ENTRYPOINT ["/app/bin/docker-entrypoint.sh"]
CMD ["start"]