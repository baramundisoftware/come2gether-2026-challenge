#!/usr/bin/env bats
# workflow-03.bats — Workflow 3: KI-Agent
# Wird in Phase 2 mit konkreten Tests gefuellt.
# Tests werden uebersprungen wenn kein ANTHROPIC_API_KEY gesetzt ist.

load helpers/setup

setup_file() {
  if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
    skip "ANTHROPIC_API_KEY nicht gesetzt — KI-Tests uebersprungen"
  fi
  wait_for_all_healthy 180
  bootstrap_n8n_api_key
}

@test "Workflow 3: JSON ist valide" {
  run jq empty workflows/03-ai-infra-advisor.json
  [ "$status" -eq 0 ]
}

@test "Workflow 3: hat name, nodes, connections" {
  run jq -e '.name and .nodes and .connections' workflows/03-ai-infra-advisor.json
  [ "$status" -eq 0 ]
}

@test "Workflow 3: verwendet Claude als Model" {
  run jq -r '.. | .model? // empty' workflows/03-ai-infra-advisor.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "claude"
}
