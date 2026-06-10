#!/usr/bin/env bats
# workflow-02.bats — Workflow 2: Software-Compliance

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

@test "Workflow 2: verwendet baramundi Endpoint Node" {
  run jq -r '.nodes[].type' workflows/02-software-compliance.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "CUSTOM.baramundiEndpoint"
}

@test "Workflow 2: verwendet baramundi Software Node" {
  run jq -r '.nodes[].type' workflows/02-software-compliance.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "CUSTOM.baramundiSoftware"
}

@test "Workflow 2: hat Manual Trigger" {
  run jq -r '.nodes[].type' workflows/02-software-compliance.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "manualTrigger"
}

@test "Workflow 2: hat IF-Verzweigung" {
  run jq -r '.nodes[].type' workflows/02-software-compliance.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "n8n-nodes-base.if"
}

@test "Workflow 2: Credential referenziert bconnectdefault0" {
  run jq -r '.. | .bconnectApi? // empty | .id' workflows/02-software-compliance.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "bconnectdefault0"
}

@test "Workflow 2: bmsVersion ist 26R1" {
  run jq -r '.. | .bmsVersion? // empty' workflows/02-software-compliance.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "26R1"
}
