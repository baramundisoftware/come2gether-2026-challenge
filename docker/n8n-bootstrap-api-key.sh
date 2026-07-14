#!/bin/sh
#
# docker/n8n-bootstrap-api-key.sh — Phase 4 P4.5a
#
# Creates an instance owner (if none exists) and issues a public-API key
# against a running n8n container, then echoes the API key to stdout.
# Designed for CI smoke runs where the container is fresh.
#
# Usage (host-side, container already running):
#   N8N_API_KEY="$(BOOTSTRAP_HOST=http://localhost:5678 \
#                  bash docker/n8n-bootstrap-api-key.sh)"
#
# Usage (inside the container):
#   docker exec <container> /n8n-bootstrap-api-key.sh
#
# Discovered facts about n8n 1.65 auth:
#   - n8n 1.x deprecated N8N_BASIC_AUTH_*; /rest/* needs JWT cookie auth
#     and /api/v1/* needs the public-API key (X-N8N-API-KEY header).
#   - Owner setup: POST /rest/owner/setup with email/firstName/lastName/
#     password → 200 + Set-Cookie: n8n-auth=<JWT>. 400 if already set up.
#   - API key issuance: POST /rest/api-keys (cookie-authed). Response
#     body: `{ data: { id, userId, label, apiKey } }` — `apiKey` is the
#     value to use in `X-N8N-API-KEY`.
#   - Public API surface: GET /api/v1/workflows (read-only-ish — does
#     NOT expose synchronous /execute or /run endpoints in 1.65).

set -eu

HOST="${BOOTSTRAP_HOST:-http://localhost:5678}"
EMAIL="${BOOTSTRAP_EMAIL:-ci@n8n-demo.local}"
FIRST="${BOOTSTRAP_FIRST_NAME:-CI}"
LAST="${BOOTSTRAP_LAST_NAME:-Smoke}"
PASSWORD="${BOOTSTRAP_PASSWORD:-CISmoke123!}"
LABEL="${BOOTSTRAP_API_KEY_LABEL:-ci-smoke-key}"

COOKIE_FILE="$(mktemp /tmp/n8n-cookie.XXXXXX)"
trap 'rm -f "${COOKIE_FILE}"' EXIT

log() { echo "[bootstrap] $*" >&2; }

# 1. Owner setup (idempotent: 200 first time, 400 thereafter).
log "POST /rest/owner/setup as ${EMAIL}"
setup_status="$(curl -sS -o /dev/null -w '%{http_code}' \
                  -c "${COOKIE_FILE}" \
                  -X POST -H 'content-type: application/json' \
                  -d "$(jq -n --arg e "${EMAIL}" --arg f "${FIRST}" \
                              --arg l "${LAST}"  --arg p "${PASSWORD}" \
                            '{email:$e,firstName:$f,lastName:$l,password:$p}')" \
                  "${HOST}/rest/owner/setup")"

case "${setup_status}" in
  200)
    log "owner created"
    ;;
  400)
    # Already set up; log in to get a fresh cookie.
    log "owner already exists; POST /rest/login"
    login_status="$(curl -sS -o /dev/null -w '%{http_code}' \
                      -c "${COOKIE_FILE}" \
                      -X POST -H 'content-type: application/json' \
                      -d "$(jq -n --arg e "${EMAIL}" --arg p "${PASSWORD}" \
                                '{email:$e,password:$p}')" \
                      "${HOST}/rest/login")"
    [ "${login_status}" = "200" ] || {
      log "ERROR: /rest/login returned HTTP ${login_status}"
      exit 1
    }
    ;;
  *)
    log "ERROR: /rest/owner/setup returned HTTP ${setup_status}"
    exit 1
    ;;
esac

# 2. API-key issuance (cookie-authed). Idempotent on label collision.
#
# n8n 2.x changed the schema: `scopes` is now a required array of
# permission strings. We fetch the available scopes from
# /rest/api-keys/scopes and pass them all so the bootstrapped key has
# the same broad access the 1.x key had. (n8n 1.x treated keys as
# all-access by default.)
log "GET  /rest/api-keys/scopes"
scopes_response="$(curl -sS -b "${COOKIE_FILE}" "${HOST}/rest/api-keys/scopes" \
                   -H 'content-type: application/json')"
scopes_arg="$(printf '%s' "${scopes_response}" \
               | jq -c 'if type=="array" then . elif (.data|type=="array") then .data else [] end')"
if [ -z "${scopes_arg}" ] || [ "${scopes_arg}" = "[]" ]; then
  # Endpoint missing or empty (older 2.x?) — fall back to a hand-rolled
  # superset that covers everything the bundled workflows need.
  scopes_arg='["workflow:create","workflow:read","workflow:update","workflow:delete","workflow:list","workflow:execute","workflow:move","credential:create","credential:read","credential:update","credential:delete","credential:list","credential:move","credential:share","execution:read","execution:list","execution:delete","tag:create","tag:read","tag:update","tag:delete","tag:list","user:create","user:read","user:update","user:delete","user:list","user:changeRole","variable:create","variable:read","variable:update","variable:delete","variable:list","project:create","project:read","project:update","project:delete","project:list","sourceControl:pull","securityAudit:generate"]'
fi

log "POST /rest/api-keys"
key_response="$(curl -sS \
                  -b "${COOKIE_FILE}" \
                  -X POST -H 'content-type: application/json' \
                  -d "$(jq -n --arg lab "${LABEL}" --argjson scopes "${scopes_arg}" \
                          '{label:$lab, scopes:$scopes, expiresAt:null}')" \
                  "${HOST}/rest/api-keys")"

# n8n 2.x splits the response into .data.apiKey (masked preview, 10 chars
# like "******xyz") and .data.rawApiKey (the full JWT, only present at
# creation time). 1.x only had .data.apiKey with the raw value.
api_key="$(printf '%s' "${key_response}" \
            | jq -r '.data.rawApiKey // .data.apiKey // empty')"

if [ -z "${api_key}" ]; then
  # Note: n8n only returns the full API key at creation time; subsequent
  # GET /rest/api-keys returns only a masked preview. On label collision
  # we fail loudly rather than hand back an unusable preview value. Caller
  # should wipe the n8n volume (`docker volume rm <vol>`) to re-bootstrap.
  log "ERROR: could not issue API key"
  log "response: ${key_response}"
  log "hint: a key with label '${LABEL}' may already exist; wipe the n8n"
  log "      data volume to start fresh (the full key is only returned"
  log "      at creation time)."
  exit 1
fi

log "API key issued (length=${#api_key})"
printf '%s\n' "${api_key}"
