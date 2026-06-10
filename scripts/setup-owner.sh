#!/bin/sh
# setup-owner.sh — Erstellt automatisch den n8n Owner-Account
#
# Wird als Init-Container gestartet, wartet bis n8n healthy ist,
# und legt den Demo-Owner an. Idempotent: überspringt wenn
# Owner bereits existiert.

set -eu

N8N_URL="${N8N_URL:-http://c2g-n8n:5678}"
OWNER_EMAIL="${N8N_OWNER_EMAIL:-demo@c2g.local}"
OWNER_FIRSTNAME="${N8N_OWNER_FIRSTNAME:-Demo}"
OWNER_LASTNAME="${N8N_OWNER_LASTNAME:-User}"
OWNER_PASSWORD="${N8N_OWNER_PASSWORD:-Baramundi2026}"

MAX_WAIT=120
INTERVAL=3

log() { echo "[setup-owner] $*"; }

# --- Warte auf n8n ---
log "Warte auf n8n ($N8N_URL) ..."
elapsed=0
while [ "$elapsed" -lt "$MAX_WAIT" ]; do
  if curl -fsS "$N8N_URL/healthz" >/dev/null 2>&1; then
    log "n8n erreichbar nach ${elapsed}s"
    break
  fi
  sleep "$INTERVAL"
  elapsed=$((elapsed + INTERVAL))
done

if [ "$elapsed" -ge "$MAX_WAIT" ]; then
  log "FEHLER: n8n nicht erreichbar nach ${MAX_WAIT}s"
  exit 1
fi

# Kurz warten damit n8n die DB-Migrationen abschließt
sleep 5

# --- Prüfe ob Owner-Setup noch nötig ist ---
settings=$(curl -fsS "$N8N_URL/rest/settings" 2>/dev/null || echo "")
needs_setup=$(echo "$settings" | grep -c '"showSetupOnFirstLoad":true' || true)

if [ "$needs_setup" -eq 0 ]; then
  log "Owner bereits eingerichtet — überspringe"
  exit 0
fi

# --- Owner anlegen ---
log "Erstelle Owner: $OWNER_EMAIL"
response=$(curl -fsS -X POST "$N8N_URL/rest/owner/setup" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$OWNER_EMAIL\",
    \"firstName\": \"$OWNER_FIRSTNAME\",
    \"lastName\": \"$OWNER_LASTNAME\",
    \"password\": \"$OWNER_PASSWORD\"
  }" 2>&1) || true

if echo "$response" | grep -q '"email"'; then
  log "Owner erfolgreich angelegt"
  log "  Email:    $OWNER_EMAIL"
  log "  Passwort: $OWNER_PASSWORD"
else
  log "WARNUNG: Owner-Setup fehlgeschlagen: $response"
  exit 1
fi
