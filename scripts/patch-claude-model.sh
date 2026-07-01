#!/bin/bash
# patch-claude-model.sh — Setzt das Claude-Model in Workflow 3
#
# n8n import:workflow leert __rl Resource-Locator-Felder.
# Dieses Script patcht den Wert nach dem Import per REST API.
# Läuft auf dem Host (nicht im Container).

set -eu

N8N_URL="${N8N_URL:-http://localhost:5678}"
OWNER_EMAIL="${N8N_OWNER_EMAIL:-demo@c2g.local}"
OWNER_PASSWORD="${N8N_OWNER_PASSWORD:-Baramundi2026}"
CLAUDE_MODEL="${CLAUDE_MODEL:-claude-opus-4-8}"
COOKIE=$(mktemp)

log() { echo "[patch-model] $*"; }

# Login
curl -fsS -X POST "$N8N_URL/rest/login" \
  -H "Content-Type: application/json" \
  -d "{\"emailOrLdapLoginId\":\"$OWNER_EMAIL\",\"password\":\"$OWNER_PASSWORD\"}" \
  -c "$COOKIE" >/dev/null 2>&1 || { log "Login fehlgeschlagen"; exit 1; }

# Workflow 3 holen
wf=$(curl -fsS "$N8N_URL/rest/workflows/c2g-2026-wf-03" -b "$COOKIE" 2>/dev/null)
if ! echo "$wf" | grep -q '"Claude"'; then
  log "Workflow 3 nicht gefunden"
  rm -f "$COOKIE"
  exit 1
fi

# Prüfe ob Model bereits gesetzt
current=$(echo "$wf" | grep -o '"value":"[^"]*","mode":"id"' | head -1 | grep -o '"value":"[^"]*"' | cut -d'"' -f4)
if [ "$current" = "$CLAUDE_MODEL" ]; then
  log "Model bereits korrekt: $CLAUDE_MODEL"
  rm -f "$COOKIE"
  exit 0
fi

# Model patchen: leeren Wert ersetzen
patched=$(echo "$wf" | sed 's/"value":"","mode":"id"/"value":"'"$CLAUDE_MODEL"'","mode":"id"/g')

curl -fsS -X PATCH "$N8N_URL/rest/workflows/c2g-2026-wf-03" \
  -H "Content-Type: application/json" \
  -b "$COOKIE" \
  -d "$patched" >/dev/null 2>&1 && log "Model gesetzt: $CLAUDE_MODEL" || log "Patch fehlgeschlagen"

rm -f "$COOKIE"
