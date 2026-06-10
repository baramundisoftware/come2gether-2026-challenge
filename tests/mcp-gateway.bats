#!/usr/bin/env bats
# mcp-gateway.bats — MCP Gateway Erreichbarkeit + Tools

load helpers/setup

setup_file() {
  wait_for_all_healthy 180
}

MCP_ACCEPT="Accept: application/json, text/event-stream"
MCP_CT="Content-Type: application/json"
MCP_INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'

@test "MCP: /endpoints/mcp antwortet auf initialize" {
  run curl -fsS -X POST "${GATEWAY_URL}/endpoints/mcp" \
    -H "$MCP_CT" -H "$MCP_ACCEPT" -d "$MCP_INIT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"serverInfo"'
}

@test "MCP: /jobs/mcp antwortet auf initialize" {
  run curl -fsS -X POST "${GATEWAY_URL}/jobs/mcp" \
    -H "$MCP_CT" -H "$MCP_ACCEPT" -d "$MCP_INIT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"serverInfo"'
}

@test "MCP: /compliance/mcp antwortet auf initialize" {
  run curl -fsS -X POST "${GATEWAY_URL}/compliance/mcp" \
    -H "$MCP_CT" -H "$MCP_ACCEPT" -d "$MCP_INIT"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"serverInfo"'
}
