#!/usr/bin/env bats
# smoke.bats — Container-Startup + Healthchecks

load helpers/setup

setup_file() {
  # Stelle sicher, dass Container laufen
  docker compose up -d 2>/dev/null || true
  wait_for_all_healthy 180
  bootstrap_n8n_api_key
}

@test "bconnect-mock ist healthy" {
  run curl -fsS "${MOCK_URL}/health"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"status"'
}

@test "bconnect-mock: BMS Version ist 26r1" {
  run curl -fsS "${MOCK_URL}/health"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi '26r1'
}

@test "bconnect-mock: Profil ist standard-readwrite" {
  run curl -fsS "${MOCK_URL}/health"
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi 'standard-readwrite'
}

@test "mcp-gateway ist healthy" {
  run curl -fsS "${GATEWAY_URL}/health"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"endpoints"'
}

@test "mcp-gateway: endpoints Domain registriert" {
  run curl -fsS "${GATEWAY_URL}/health"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"endpoints"'
}

@test "mcp-gateway: jobs Domain registriert" {
  run curl -fsS "${GATEWAY_URL}/health"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"jobs"'
}

@test "mcp-gateway: compliance Domain registriert" {
  run curl -fsS "${GATEWAY_URL}/health"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"compliance"'
}

@test "n8n ist healthy" {
  run curl -fsS "${N8N_URL}/healthz"
  [ "$status" -eq 0 ]
}

@test "bconnect-mock: WindowsEndpoints liefert Daten" {
  run curl -fsS "${MOCK_URL}/bconnect/v2.0/WindowsEndpoints"
  [ "$status" -eq 0 ]
  local count
  count=$(echo "$output" | jq '.data | length')
  [ "$count" -ge 5 ]
}

@test "bconnect-mock: Software liefert Daten" {
  run curl -fsS "${MOCK_URL}/bconnect/v2.0/Software"
  [ "$status" -eq 0 ]
  local count
  count=$(echo "$output" | jq '.data | length')
  [ "$count" -ge 1 ]
}

@test "kein Container hat Status exited" {
  run docker compose ps --format '{{.State}}'
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "exited"
}
