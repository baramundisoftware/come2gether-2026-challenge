#!/usr/bin/env bats
# workflow-01.bats — Workflow 1: Endpoint-Uebersicht

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

@test "Workflow 1: verwendet baramundi Endpoint Node" {
  run jq -r '.nodes[].type' workflows/01-endpoint-overview.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "CUSTOM.baramundiEndpoint"
}

@test "Workflow 1: hat Manual Trigger" {
  run jq -r '.nodes[].type' workflows/01-endpoint-overview.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "manualTrigger"
}

@test "Workflow 1: hat HTML-Output Node" {
  run jq -r '.nodes[].type' workflows/01-endpoint-overview.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "n8n-nodes-base.html"
}

@test "Workflow 1: hat Code Node fuer HTML-Generierung" {
  run jq -r '.nodes[].type' workflows/01-endpoint-overview.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "n8n-nodes-base.code"
}

@test "Workflow 1: Credential referenziert bconnectdefault0" {
  run jq -r '.. | .bconnectApi? // empty | .id' workflows/01-endpoint-overview.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "bconnectdefault0"
}

@test "Workflow 1: bmsVersion ist 26R1" {
  run jq -r '.. | .bmsVersion? // empty' workflows/01-endpoint-overview.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "26R1"
}
