#!/usr/bin/env bats
# workflow-03.bats — Workflow 3: KI-Agent
# Laufzeit-Tests werden uebersprungen wenn kein ANTHROPIC_API_KEY gesetzt ist.

load helpers/setup

setup_file() {
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
  run jq -r '.. | .value? // empty' workflows/03-ai-infra-advisor.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi "claude"
}

@test "Workflow 3: hat AI Agent Node" {
  run jq -r '.nodes[].type' workflows/03-ai-infra-advisor.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "langchain.agent"
}

@test "Workflow 3: hat 3 MCP Client Tool Nodes" {
  local count
  count=$(jq '[.nodes[] | select(.type | contains("mcpClientTool"))] | length' workflows/03-ai-infra-advisor.json)
  [ "$count" -eq 3 ]
}

@test "Workflow 3: MCP Endpoints URL korrekt" {
  run jq -r '.. | .endpointUrl? // empty' workflows/03-ai-infra-advisor.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mcp-gateway:3001/endpoints/mcp"
}

@test "Workflow 3: MCP Jobs URL korrekt" {
  run jq -r '.. | .endpointUrl? // empty' workflows/03-ai-infra-advisor.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mcp-gateway:3001/jobs/mcp"
}

@test "Workflow 3: MCP Compliance URL korrekt" {
  run jq -r '.. | .endpointUrl? // empty' workflows/03-ai-infra-advisor.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "mcp-gateway:3001/compliance/mcp"
}

@test "Workflow 3: hat HTML-Formatter Node" {
  run jq -r '.nodes[].type' workflows/03-ai-infra-advisor.json
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "n8n-nodes-base.code"
}
