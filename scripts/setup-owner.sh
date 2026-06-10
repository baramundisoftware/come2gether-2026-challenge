#!/bin/sh
# setup-owner.sh — n8n Ersteinrichtung
#
# 1. Erstellt den Owner-Account
# 2. Erstellt das Anthropic Credential via n8n CLI (im n8n-Container)

set -eu

N8N_URL="${N8N_URL:-http://c2g-n8n:5678}"
OWNER_EMAIL="${N8N_OWNER_EMAIL:-demo@c2g.local}"
OWNER_FIRSTNAME="${N8N_OWNER_FIRSTNAME:-Demo}"
OWNER_LASTNAME="${N8N_OWNER_LASTNAME:-User}"
OWNER_PASSWORD="${N8N_OWNER_PASSWORD:-Baramundi2026}"

log() { echo "[setup] $*"; }

# --- Warte auf n8n ---
log "Warte auf n8n ..."
elapsed=0
while [ "$elapsed" -lt 120 ]; do
  curl -fsS "$N8N_URL/healthz" >/dev/null 2>&1 && break
  sleep 3; elapsed=$((elapsed + 3))
done
[ "$elapsed" -ge 120 ] && { log "FEHLER: n8n nicht erreichbar"; exit 1; }
log "n8n erreichbar"
sleep 5

# --- Owner ---
needs_setup=$(curl -fsS "$N8N_URL/rest/settings" 2>/dev/null | grep -c '"showSetupOnFirstLoad":true' || true)
if [ "$needs_setup" -gt 0 ]; then
  log "Erstelle Owner: $OWNER_EMAIL"
  result=$(curl -sS -X POST "$N8N_URL/rest/owner/setup" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$OWNER_EMAIL\",\"firstName\":\"$OWNER_FIRSTNAME\",\"lastName\":\"$OWNER_LASTNAME\",\"password\":\"$OWNER_PASSWORD\"}" 2>&1)
  echo "$result" | grep -q '"email"' && log "Owner OK: $OWNER_EMAIL / $OWNER_PASSWORD" || log "WARNUNG: $result"
else
  log "Owner existiert bereits"
fi

# --- Anthropic Credential (im n8n-Container via n8n CLI) ---
# Das Script ist im n8n-Container gemountet. Wir triggern es über die n8n REST API
# indem wir warten bis Workflows geseeded sind und dann das Credential prüfen.
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  log "Anthropic Key vorhanden — Credential wird vom n8n-Container geseeded"
  log "(Script: /seed-anthropic-credential.sh im n8n-Container)"
fi

log "Fertig"
