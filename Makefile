.DEFAULT_GOAL := help
.PHONY: proxy up up-build up-d up-d-build down reset reseed nuke logs url open fleet doctor help demo-test

PORT ?= 4000
RELYRA_HOST ?= relyra.localhost
DEMO_PROXY_NETWORK ?= proxy

SOLO_COMPOSE := docker compose
FLEET_COMPOSE := docker compose -f docker-compose.yml -f docker-compose.proxy.yml
PROXY_COMPOSE := docker compose -f docker/traefik/compose.yml

## help: discover the Relyra demo launcher commands and their topology
help:
	@echo "Relyra demo launcher"
	@echo ""
	@awk '/^## [a-zA-Z0-9_-]+:/ { line = substr($$0, 4); i = index(line, ":"); printf "  %-14s %s\n", substr(line, 1, i - 1), substr(line, i + 2) }' $(MAKEFILE_LIST)

## proxy: start the shared Traefik proxy and its external network
proxy:
	-docker network create "$(DEMO_PROXY_NETWORK)"
	$(PROXY_COMPOSE) up -d

## up: start the loopback solo demo without rebuilding
up:
	$(SOLO_COMPOSE) up --no-build

## up-build: build and start the loopback solo demo in the foreground
up-build:
	$(SOLO_COMPOSE) up --build

## up-d: start the loopback solo demo detached, then print its routes
up-d:
	$(SOLO_COMPOSE) up --no-build -d
	@$(MAKE) --no-print-directory url

## up-d-build: build and start the loopback solo demo detached, then print its routes
up-d-build:
	$(SOLO_COMPOSE) up --build -d
	@$(MAKE) --no-print-directory url

## down: stop the Relyra demo while preserving named volumes and caches
down:
	$(SOLO_COMPOSE) down

## reset: refresh demo data by dropping and setting up the database
reset:
	$(SOLO_COMPOSE) exec demo_app mix do ecto.drop, ecto.setup

## reseed: alias the complete demo-data refresh
reseed: reset

## nuke: permanently remove Relyra demo volumes after explicit confirmation
nuke:
	@echo "NUKE is configured in the launcher safety contract."
	@exit 1

## logs: follow the Relyra demo service logs
logs:
	$(SOLO_COMPOSE) logs -f

## url: print browser origins, routes, walkthrough, and topology notes
url:
	@echo "==> Browser origins"
	@echo "  Proxy: http://$(RELYRA_HOST)"
	@echo "  Loopback: http://localhost:$(PORT)"
	@echo ""
	@echo "==> Route map"
	@echo "  Home: http://$(RELYRA_HOST)/"
	@echo "  Admin: http://$(RELYRA_HOST)/relyra/admin"
	@echo "  Login test: http://$(RELYRA_HOST)/login/test"
	@echo "  Support scenario: http://$(RELYRA_HOST)/support/scenario"
	@echo "  Health: http://$(RELYRA_HOST)/healthz"
	@echo "  OPTIONAL — fleet + keycloak profile: http://keycloak.$(RELYRA_HOST)/admin"
	@echo "  OPTIONAL — shared fleet proxy: http://localhost:8080/dashboard/"
	@echo ""
	@echo "==> Walkthrough"
	@echo "  1. Open Login test"
	@echo "  2. Choose FakeIdP"
	@echo "  3. Complete the sign-in"
	@echo "  4. Inspect the operator trace"
	@echo ""
	@echo "==> Topology notes"
	@echo "  *.localhost is browser-facing; Docker health checks and internal probes use service DNS."

## open: open the primary Relyra browser origin on macOS
open:
	open "http://$(RELYRA_HOST)"

## fleet: list all Traefik-routed local demo containers
fleet:
	@ids=$$(docker ps --filter label=traefik.enable=true -q); \
	if [ -z "$$ids" ]; then \
		echo "No Traefik-routed demo containers running."; \
	else \
		echo "Traefik-routed demo containers:"; \
		docker ps --filter label=traefik.enable=true --format 'table {{.Label "com.docker.compose.project"}}\\t{{.Names}}\\t{{.Status}}\\t{{.Ports}}'; \
	fi

## doctor: inspect the Relyra browser route map and shared proxy network
doctor:
	@$(MAKE) --no-print-directory url
	@docker network inspect "$(DEMO_PROXY_NETWORK)" --format 'proxy network exists ({{.Name}})' 2>/dev/null || echo "WARN proxy network missing. Next: make proxy"
	@$(MAKE) --no-print-directory fleet

demo-test:
	$(SOLO_COMPOSE) --profile keycloak --profile browser run --rm playwright
