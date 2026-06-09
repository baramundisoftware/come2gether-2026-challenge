#!/usr/bin/env bash
# lint.sh — Statische Analyse (kein Docker noetig)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
errors=0

echo "=== Compose-Syntax ==="
COMPOSE_CMD="${COMPOSE_CMD:-$(command -v docker-compose 2>/dev/null || echo 'docker compose')}"
$COMPOSE_CMD config >/dev/null 2>&1 && echo "PASS" || { echo "FAIL"; errors=$((errors+1)); }

echo ""
echo "=== Workflow-JSON-Validierung ==="
for f in workflows/*.json; do
  [ -f "$f" ] || continue
  if ! jq empty "$f" 2>/dev/null; then
    echo "FAIL: $f ist kein valides JSON"
    errors=$((errors+1))
    continue
  fi
  if ! jq -e '.name and .nodes and .connections' "$f" >/dev/null 2>&1; then
    echo "FAIL: $f fehlen Pflichtfelder (name, nodes, connections)"
    errors=$((errors+1))
    continue
  fi
  echo "  OK: $f"
done

echo ""
echo "=== Keine Secrets im Repo ==="
if grep -rE '(sk-ant-[a-zA-Z0-9_-]{20,}|baramundi-2008|ANTHROPIC_API_KEY=sk-)' \
     --include='*.yml' --include='*.yaml' --include='*.json' \
     --include='*.sh' --include='*.md' --include='*.env*' \
     . 2>/dev/null | grep -v '.gitignore' | grep -v 'lint.sh' | grep -v '.env.example'; then
  echo "FAIL: Secrets gefunden!"
  errors=$((errors+1))
else
  echo "  OK: Keine Secrets"
fi

echo ""
echo "=== Keine Credentials in Workflow-JSONs ==="
for f in workflows/*.json; do
  [ -f "$f" ] || continue
  if jq -r '.. | strings' "$f" 2>/dev/null | grep -qiE '(sk-ant-|baramundi-2008)'; then
    echo "FAIL: $f enthaelt moeglicherweise Credentials"
    errors=$((errors+1))
  else
    echo "  OK: $f"
  fi
done

echo ""
echo "=== .env.example vollstaendig ==="
# Alle Variablen in docker-compose.yml muessen in .env.example vorkommen
missing=0
for var in BCONNECT_BASE_URL BCONNECT_API_KEY ANTHROPIC_API_KEY; do
  if ! grep -q "^${var}=" .env.example 2>/dev/null; then
    echo "FAIL: $var fehlt in .env.example"
    missing=$((missing+1))
  fi
done
if [ "$missing" -eq 0 ]; then
  echo "  OK: Alle Variablen vorhanden"
else
  errors=$((errors+missing))
fi

echo ""
echo "=== Keine internen Referenzen ==="
if grep -rEi '(bms-win22srv|/home/ansible/|\.mshome\.net)' \
     --include='*.yml' --include='*.yaml' --include='*.json' \
     --include='*.sh' --include='*.md' \
     . 2>/dev/null | grep -v '.git/' | grep -v 'node_modules/' | grep -v 'lint.sh'; then
  echo "FAIL: Interne Referenzen gefunden!"
  errors=$((errors+1))
else
  echo "  OK: Keine internen Referenzen"
fi

echo ""
if [ "$errors" -gt 0 ]; then
  echo "=== FAILED: $errors Fehler ==="
  exit 1
else
  echo "=== ALL PASSED ==="
fi
