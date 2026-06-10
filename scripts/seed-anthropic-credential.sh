#!/bin/sh
# seed-anthropic-credential.sh — Importiert das Anthropic API Credential
#
# Wird im n8n-Container ausgeführt (per Volume gemountet).
# Nutzt n8n import:credentials (wie das bConnect-Credential im Entrypoint).
# Idempotent: Überspringt wenn Marker existiert.

set -eu

MARKER="/home/node/.n8n/.anthropic-credential-seeded"
ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"

log() { echo "[seed-anthropic] $*"; }

if [ -f "$MARKER" ]; then
  log "Anthropic Credential bereits geseeded — überspringe"
  exit 0
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
  log "Kein ANTHROPIC_API_KEY gesetzt — überspringe"
  exit 0
fi

log "Importiere Anthropic API Credential"

tmp=$(mktemp)
cat > "$tmp" << ENDJSON
[{
  "id": "anthropicdefault0",
  "name": "Anthropic API (Challenge)",
  "type": "anthropicApi",
  "data": { "apiKey": "$ANTHROPIC_API_KEY" }
}]
ENDJSON

if n8n import:credentials --input="$tmp"; then
  touch "$MARKER"
  log "Anthropic Credential importiert"
else
  log "WARNUNG: Import fehlgeschlagen"
fi

rm -f "$tmp"
