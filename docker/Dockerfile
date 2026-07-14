# syntax=docker/dockerfile:1.7
#
# come2gether-2026-challenge — n8n-demo image
#
# n8n + the baramundi n8n Connector (vendored tarball). Self-contained:
# builds from files inside THIS repo only — no sibling repositories.
#
# The bConnect Mock and the MCP Gateway are NOT bundled here; they run as
# their own services (pulled from GHCR by docker-compose.yml). This image
# therefore always targets an external bConnect (mock service or real bMS)
# via BCONNECT_BASE_URL — the embedded mock has been removed.
#
# Build context: the repository root.
#   docker build -f docker/Dockerfile -t c2g/n8n-demo:dev .
#
# Build inputs (already present in the build context):
#   ./vendor/n8n-nodes-baramundi-management-suite-*.tgz   (the connector)
#   ./workflows/*.json                                    (example workflows)
#   ./docker/entrypoint.sh + seed scripts

# ---------------------------------------------------------------------------
# Stage 1: builder — resolve the connector npm package from the vendored tarball
# ---------------------------------------------------------------------------
ARG N8N_VERSION=2.19.4
ARG NODE_BUILDER_VERSION=24-alpine
ARG ALPINE_TOOLS_VERSION=3.22

FROM node:${NODE_BUILDER_VERSION} AS builder
WORKDIR /build

COPY vendor/n8n-nodes-baramundi-management-suite-*.tgz ./

WORKDIR /build/custom
# --omit=peer + --legacy-peer-deps: skip n8n-workflow / n8n-nodes-base etc.
# (peer deps of the connector). They are provided by the n8n runtime image,
# and pulling them here drags in `isolated-vm` which needs Python + g++.
RUN set -eux; \
    npm init -y >/dev/null; \
    npm install --omit=dev --omit=peer --no-audit --no-fund --legacy-peer-deps \
        /build/n8n-nodes-baramundi-management-suite-*.tgz

# ---------------------------------------------------------------------------
# Stage 2: tools — fetch curl + jq from a regular Alpine image.
# ---------------------------------------------------------------------------
FROM alpine:${ALPINE_TOOLS_VERSION} AS tools
# hadolint ignore=DL3018
RUN apk add --no-cache curl jq

# ---------------------------------------------------------------------------
# Stage 3: runtime — n8n base + custom node + seed data + entrypoint
# ---------------------------------------------------------------------------
FROM n8nio/n8n:${N8N_VERSION} AS runtime

ARG N8N_VERSION
ARG CONNECTOR_VERSION=0.9.1
ARG IMAGE_VERSION=0.1.0
ARG VCS_REF=unknown
ARG BUILD_DATE

LABEL org.opencontainers.image.title="come2gether-2026-challenge n8n-demo" \
      org.opencontainers.image.description="n8n + baramundi n8n Connector for the come2gether 2026 Challenge. Targets an external bConnect (mock service or real bMS). Demo / dev only." \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.vendor="baramundi software GmbH" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/baramundisoftware/come2gether-2026-challenge" \
      com.baramundi.n8n.version="${N8N_VERSION}" \
      com.baramundi.connector.version="${CONNECTOR_VERSION}"

USER root

# n8n 2.x uses Docker-Hardened-Images / Alpine 3.22 — no apk, no curl,
# no jq. tini is already present; libcurl + friends too. We just COPY the
# curl + jq binaries plus jq's two private libs (libjq, libonig).
COPY --from=tools /usr/bin/curl /usr/bin/curl
COPY --from=tools /usr/bin/jq /usr/bin/jq
COPY --from=tools /usr/lib/libjq.so.1 /usr/lib/libjq.so.1
COPY --from=tools /usr/lib/libonig.so.5 /usr/lib/libonig.so.5

# Custom node directory (installed under n8n's user-customs path)
COPY --from=builder --chown=node:node /build/custom /home/node/.n8n/custom

# Seed: workflow JSON files imported on first boot
COPY --chown=node:node workflows/*.json /seed/workflows/

# Entrypoint + first-boot seed scripts
COPY --chown=root:root docker/entrypoint.sh /entrypoint.sh
COPY --chown=root:root docker/seed-workflows.sh /seed-workflows.sh
COPY --chown=root:root docker/n8n-bootstrap-api-key.sh /n8n-bootstrap-api-key.sh
RUN chmod 0755 /entrypoint.sh /seed-workflows.sh /n8n-bootstrap-api-key.sh

RUN mkdir -p /home/node/.n8n /seed && \
    chown -R node:node /home/node/.n8n /seed

USER node
WORKDIR /home/node

ENV N8N_HOST=0.0.0.0 \
    N8N_PORT=5678 \
    N8N_DIAGNOSTICS_ENABLED=false \
    N8N_PERSONALIZATION_ENABLED=false \
    BCONNECT_BASE_URL=http://bconnect-mock:3433/bconnect \
    BCONNECT_USERNAME=mockuser \
    BCONNECT_PASSWORD=mockpass \
    SEED_WORKFLOWS=true \
    DISABLE_EMBEDDED_MOCK=true

EXPOSE 5678

HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD curl -fsS http://localhost:5678/healthz || exit 1

ENTRYPOINT ["/sbin/tini", "-g", "--", "/entrypoint.sh"]
