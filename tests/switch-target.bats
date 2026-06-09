#!/usr/bin/env bats
# switch-target.bats — Mock/Real Umschaltung

load helpers/setup

setup_file() {
  wait_for_all_healthy 180
}

@test "Default: BCONNECT_BASE_URL zeigt auf Mock" {
  run docker exec c2g-gateway printenv BCONNECT_BASE_URL
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "bconnect-mock"
}

@test "n8n: BCONNECT_BASE_URL zeigt auf Mock" {
  run docker exec c2g-n8n printenv BCONNECT_BASE_URL
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "bconnect-mock"
}

@test ".env.example enthaelt BCONNECT_BASE_URL" {
  grep -q '^BCONNECT_BASE_URL=' .env.example
}

@test ".env.example enthaelt BCONNECT_API_KEY" {
  grep -q '^BCONNECT_API_KEY=' .env.example
}

@test ".env.example enthaelt ANTHROPIC_API_KEY" {
  grep -q '^ANTHROPIC_API_KEY=' .env.example
}
