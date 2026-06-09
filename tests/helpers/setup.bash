#!/usr/bin/env bash
# setup.bash — Gemeinsame BATS-Hilfsfunktionen

# n8n API Key (wird beim Seeding erzeugt)
export N8N_API_KEY="${N8N_API_KEY:-}"
export N8N_URL="http://localhost:5678"
export MOCK_URL="http://localhost:3433"
export GATEWAY_URL="http://localhost:3001"

# Wartet bis ein Container healthy ist (max $2 Sekunden)
wait_for_healthy() {
  local container="$1"
  local timeout="${2:-60}"
  local elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    local health
    health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "missing")
    if [ "$health" = "healthy" ]; then
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  echo "Timeout: $container not healthy after ${timeout}s (status: $health)"
  return 1
}

# Wartet bis alle 3 Challenge-Container healthy sind
wait_for_all_healthy() {
  local timeout="${1:-120}"
  wait_for_healthy c2g-mock "$timeout"
  wait_for_healthy c2g-gateway "$timeout"
  wait_for_healthy c2g-n8n "$timeout"
}

# Bootstrapt den n8n API Key (liest ihn aus dem Container)
bootstrap_n8n_api_key() {
  if [ -n "$N8N_API_KEY" ]; then
    return 0
  fi
  # Der n8n-demo Entrypoint schreibt den Key in /tmp/n8n-api-key
  N8N_API_KEY=$(docker exec c2g-n8n cat /tmp/n8n-api-key 2>/dev/null || echo "")
  export N8N_API_KEY
}

# Holt die Workflow-ID anhand des Namens
get_workflow_id() {
  local name="$1"
  bootstrap_n8n_api_key
  curl -fsS "${N8N_URL}/api/v1/workflows" \
    -H "X-N8N-API-KEY: ${N8N_API_KEY}" 2>/dev/null \
    | jq -r ".data[] | select(.name | contains(\"$name\")) | .id" \
    | head -1
}

# Fuehrt einen Workflow aus und wartet auf das Ergebnis
execute_and_wait() {
  local wf_id="$1"
  local timeout="${2:-60}"
  bootstrap_n8n_api_key

  local result
  result=$(curl -fsS -X POST \
    "${N8N_URL}/api/v1/workflows/${wf_id}/run" \
    -H "X-N8N-API-KEY: ${N8N_API_KEY}" \
    -H "Content-Type: application/json" \
    -d '{}' 2>/dev/null)

  local exec_id
  exec_id=$(echo "$result" | jq -r '.data.executionId // empty')
  if [ -z "$exec_id" ]; then
    echo "Failed to start workflow: $result"
    return 1
  fi

  # Auf Abschluss warten
  local elapsed=0
  while [ "$elapsed" -lt "$timeout" ]; do
    local status
    status=$(curl -fsS "${N8N_URL}/api/v1/executions/${exec_id}" \
      -H "X-N8N-API-KEY: ${N8N_API_KEY}" 2>/dev/null \
      | jq -r '.data.status // .status // "running"')
    if [ "$status" = "success" ] || [ "$status" = "error" ]; then
      echo "$status"
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  echo "timeout"
  return 1
}

# MCP-Aufruf ueber den Gateway
mcp_call() {
  local domain="$1"
  local method="$2"
  local params="${3:-{}}"

  # Initialize session
  local init_response
  init_response=$(curl -fsS -X POST "${GATEWAY_URL}/${domain}/mcp" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-03-26\",\"capabilities\":{},\"clientInfo\":{\"name\":\"test\",\"version\":\"1.0\"}}}" 2>/dev/null)

  # Eigentlicher Aufruf
  curl -fsS -X POST "${GATEWAY_URL}/${domain}/mcp" \
    -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"${method}\",\"params\":${params}}"
}
