#!/usr/bin/env bats
# workflow-01.bats — Workflow 1: Endpoint-Uebersicht
# Wird in Phase 2 mit konkreten Tests gefuellt.

load helpers/setup

setup_file() {
  wait_for_all_healthy 180
  bootstrap_n8n_api_key
}

@test "Workflow 1: JSON ist valide" {
  run jq empty workflows/01-endpoint-overview.json
  [ "$status" -eq 0 ]
}

@test "Workflow 1: hat name, nodes, connections" {
  run jq -e '.name and .nodes and .connections' workflows/01-endpoint-overview.json
  [ "$status" -eq 0 ]
}
