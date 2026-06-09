#!/usr/bin/env bats
# mcp-gateway.bats — MCP Gateway Erreichbarkeit + Tools

load helpers/setup

setup_file() {
  wait_for_all_healthy 180
}

@test "MCP: /endpoints/mcp antwortet auf initialize" {
  run curl -fsS -X POST "${GATEWAY_URL}/endpoints/mcp" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"serverInfo"'
}

@test "MCP: /jobs/mcp antwortet auf initialize" {
  run curl -fsS -X POST "${GATEWAY_URL}/jobs/mcp" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"serverInfo"'
}

@test "MCP: /compliance/mcp antwortet auf initialize" {
  run curl -fsS -X POST "${GATEWAY_URL}/compliance/mcp" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"serverInfo"'
}
