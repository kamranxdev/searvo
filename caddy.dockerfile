FROM caddy:2-alpine

# Maintainer info
LABEL maintainer="Searvo"
LABEL description="Caddy reverse proxy for SearXNG search provider"

# Copy Caddyfile configuration
COPY Caddyfile /etc/caddy/Caddyfile

# Verify Caddyfile syntax
RUN caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

# Expose port 8080 (internal, mapped to 4000 by docker-compose)
EXPOSE 8080

# Health check for container orchestration
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/healthz || exit 1

# Run Caddy server
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
