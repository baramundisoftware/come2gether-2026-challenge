# come2gether-2026-challenge — Makefile
#
# Selbstständig: das n8n-Image wird lokal aus diesem Repo gebaut
# (docker/Dockerfile + vendor/-Connector). Mock und MCP-Gateway kommen
# als fertige Images aus der GHCR (siehe docker-compose.yml).

# ── Compose-Kommando (V1 oder V2) ─────────────────────────
# Bewusst OHNE -p: sonst arbeiten `make ...` und die `docker compose ...`
# Befehle aus der README auf zwei verschiedenen Compose-Projekten — `make down`
# wuerde einen per `docker compose up` gestarteten Stack nicht finden.
COMPOSE := $(shell command -v docker-compose 2>/dev/null || echo "docker compose")

# Ziel-Tag des lokal gebauten n8n-Images. Muss dem image: in der
# docker-compose.yml entsprechen, damit `up` das lokale Image nutzt.
N8N_IMAGE ?= ghcr.io/baramundisoftware/come2gether-2026-challenge:latest

.PHONY: build pull \
        up down clean \
        test test-lint test-smoke test-workflows test-mcp test-switch test-ai test-all

# ── Build ──────────────────────────────────────────────────

build:  ## n8n-Image lokal aus diesem Repo bauen (optional; Default ist make pull)
	docker build -f docker/Dockerfile -t $(N8N_IMAGE) .

pull:  ## Mock + Gateway + n8n Images aus der GHCR ziehen
	$(COMPOSE) pull

# ── Run ────────────────────────────────────────────────────

up: ## Container starten + Credentials seeden + Model patchen
	$(COMPOSE) up -d
	@echo "Warte auf n8n healthy ..."
	@for i in $$(seq 1 30); do \
	  docker inspect --format='{{.State.Health.Status}}' c2g-n8n 2>/dev/null | grep -q healthy && break; \
	  sleep 3; \
	done
	@sleep 8
	@docker exec c2g-n8n sh /seed-anthropic-credential.sh 2>/dev/null || true
	@bash scripts/patch-claude-model.sh 2>/dev/null || true

down: ## Container stoppen
	$(COMPOSE) down

clean: ## Container + Volumes entfernen
	$(COMPOSE) down -v --remove-orphans

# ── Tests ──────────────────────────────────────────────────

test-lint:  ## Statische Analyse (kein Docker noetig)
	bash tests/lint.sh

test-smoke: ## Container-Startup + Healthchecks
	$(COMPOSE) up -d
	bats tests/smoke.bats

test-workflows: ## Workflow 1+2 ausfuehren und pruefen
	bats tests/workflow-01.bats
	bats tests/workflow-02.bats

test-mcp: ## MCP Gateway Erreichbarkeit + Tools
	bats tests/mcp-gateway.bats

test-switch: ## Mock/Real Umschaltung pruefen
	bats tests/switch-target.bats

test-ai: ## Workflow 3 (KI) — nur mit ANTHROPIC_API_KEY
	@if [ -z "$$ANTHROPIC_API_KEY" ]; then \
	  echo "SKIP: ANTHROPIC_API_KEY not set"; \
	else \
	  bats tests/workflow-03.bats; \
	fi

test: test-lint test-smoke test-workflows test-mcp test-switch  ## Alle Tests (ohne KI)

test-all: test test-ai  ## Alle Tests inkl. KI

help: ## Targets anzeigen
	@grep -E '^[a-z_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
