#!/usr/bin/env bats
# workflow-02.bats — Workflow 2: Software-Compliance
# Wird in Phase 2 mit konkreten Tests gefuellt.

load helpers/setup

setup_file() {
  wait_for_all_healthy 180
  bootstrap_n8n_api_key
}

@test "Workflow 2: JSON ist valide" {
  run jq empty workflows/02-software-compliance.json
  [ "$status" -eq 0 ]
}

@test "Workflow 2: hat name, nodes, connections" {
  run jq -e '.name and .nodes and .connections' workflows/02-software-compliance.json
  [ "$status" -eq 0 ]
}
