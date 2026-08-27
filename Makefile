.DEFAULT_GOAL := help
.PHONY: proxy up up-build up-d up-d-build down reset reseed nuke logs url open fleet keycloak doctor help demo-test

PORT ?= 4000
RELYRA_HOST ?= relyra.localhost
DEMO_PROXY_NETWORK ?= proxy
export PORT
export RELYRA_HOST
export DEMO_PROXY_NETWORK

SOLO_COMPOSE := docker compose
FLEET_COMPOSE := docker compose -f docker-compose.yml -f docker-compose.proxy.yml
KEYCLOAK_COMPOSE := $(FLEET_COMPOSE) --profile keycloak
PROXY_COMPOSE := docker compose -f docker/traefik/compose.yml
KEYCLOAK_ROUTE_ATTEMPTS ?= 30
KEYCLOAK_ROUTE_SLEEP ?= 1

## help: discover the Relyra demo launcher commands and their topology
help:
	@echo "Relyra demo launcher"
	@echo ""
	@awk '/^## [a-zA-Z0-9_-]+:/ { line = substr($$0, 4); i = index(line, ":"); printf "  %-14s %s\n", substr(line, 1, i - 1), substr(line, i + 2) }' $(MAKEFILE_LIST)

## proxy: start the shared Traefik proxy and its external network
proxy:
	docker network inspect "$${DEMO_PROXY_NETWORK}" >/dev/null 2>&1 || docker network create "$${DEMO_PROXY_NETWORK}"
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
	@set -eu; \
	echo "The next boot is a cold rebuild."; \
	if [ "$${NUKE:-}" = "1" ]; then \
		echo "NUKE will permanently delete this Relyra demo's database, build, dependency, Hex, and Mix volumes. Continue? [y/N] y (NUKE=1)"; \
		answer=y; \
	else \
		printf "%s" "NUKE will permanently delete this Relyra demo's database, build, dependency, Hex, and Mix volumes. Continue? [y/N] "; \
		IFS= read -r answer || answer=""; \
	fi; \
	case "$$answer" in \
		y|Y) $(SOLO_COMPOSE) down -v ;; \
		*) echo "Nuke cancelled; no volumes or caches were removed." ;; \
	esac

## logs: follow the Relyra demo service logs
logs:
	$(SOLO_COMPOSE) logs -f

## url: print browser origins, routes, walkthrough, and topology notes
url:
	@echo "==> Browser origins"
	@echo "  Proxy: http://$${RELYRA_HOST}"
	@echo "  Loopback: http://localhost:$${PORT}"
	@echo ""
	@echo "==> Route map"
	@echo "  Home: http://$${RELYRA_HOST}/"
	@echo "  Admin: http://$${RELYRA_HOST}/relyra/admin"
	@echo "  Login test: http://$${RELYRA_HOST}/login/test"
	@echo "  Support scenario: http://$${RELYRA_HOST}/support/scenario"
	@echo "  Health: http://$${RELYRA_HOST}/healthz"
	@echo "  OPTIONAL — fleet + keycloak profile: http://keycloak.$${RELYRA_HOST}/admin"
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

## open: open the primary browser origin or print a portable fallback
open:
	@url="http://$${RELYRA_HOST}"; \
	if command -v open >/dev/null 2>&1; then \
		if ! open "$$url"; then \
			printf "ERROR browser opener failed — %s. Next: open the URL manually\n" "$$url"; exit 1; \
		fi; \
	elif command -v xdg-open >/dev/null 2>&1; then \
		if ! xdg-open "$$url"; then \
			printf "ERROR browser opener failed — %s. Next: open the URL manually\n" "$$url"; exit 1; \
		fi; \
	else \
		printf "WARN browser opener unavailable — %s. Next: open the URL manually or install xdg-utils\n" "$$url"; \
	fi

## fleet: list all Traefik-routed local demo containers
fleet:
	@output=$$(docker ps --filter label=traefik.enable=true --format '{{.Label "com.docker.compose.project"}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}' 2>&1); \
	status=$$?; \
	if [ "$$status" -ne 0 ]; then \
		printf "ERROR fleet query — %s. Next: docker info\n" "$$output"; \
		exit "$$status"; \
	fi; \
	if [ -z "$$output" ]; then \
		printf "%s\n" "No Traefik-routed demo containers running." "Next: make proxy"; \
	else \
		printf "Project  Name  Status  Ports\n"; \
		printf "%s\n" "$$output" | \
			awk -F '\t' 'BEGIN { OFS="\t" } { for (i=1; i<=4; i++) if ($$i == "") $$i="(missing)"; print $$1, $$2, $$3, $$4 }' | \
			LC_ALL=C sort -t "$$(printf '\t')" -k1,1 -k2,2 | \
			awk -F '\t' '{ printf "%s  %s  %s  %s\n", $$1, $$2, $$3, $$4 }'; \
	fi

## keycloak: start the optional Fleet Keycloak proof and validate its public descriptor
keycloak:
	@$(MAKE) --no-print-directory proxy
	$(KEYCLOAK_COMPOSE) up --build -d
	$(KEYCLOAK_COMPOSE) wait keycloak_provisioner
	@set -eu; \
		host="$${RELYRA_HOST}"; \
		descriptor_url="http://keycloak.$$host/realms/demo-app/protocol/saml/descriptor"; \
		expected_entity_id="entityID=\"http://keycloak.$$host/realms/demo-app\""; \
		attempt=1; \
		while [ "$$attempt" -le "$(KEYCLOAK_ROUTE_ATTEMPTS)" ]; do \
			descriptor="$$(curl --fail --silent --show-error --noproxy "*" --resolve "keycloak.$$host:80:127.0.0.1" "$$descriptor_url")" && \
				case "$$descriptor" in *"$$expected_entity_id"*) $(MAKE) --no-print-directory url; exit 0 ;; esac; \
			attempt=$$((attempt + 1)); \
			if [ "$$attempt" -le "$(KEYCLOAK_ROUTE_ATTEMPTS)" ]; then sleep "$(KEYCLOAK_ROUTE_SLEEP)"; fi; \
		done; \
		printf '%s\n' "ERROR Keycloak public descriptor validation failed — expected $$expected_entity_id at $$descriptor_url" >&2; \
		exit 1

## doctor: inspect the Relyra browser route map and shared proxy network
doctor:
	@failures=0; \
	printf "==> Dependencies\n"; \
	if command -v docker >/dev/null 2>&1; then \
		docker_output=$$(docker version 2>&1); docker_status=$$?; \
		if [ "$$docker_status" -eq 0 ]; then \
			printf "OK docker — Docker CLI and daemon are available.\n"; \
		else \
			printf "ERROR docker — %s. Next: start Docker and run docker info\n" "$$docker_output"; failures=1; \
		fi; \
		compose_output=$$(docker compose version 2>&1); compose_status=$$?; \
		if [ "$$compose_status" -eq 0 ]; then \
			printf "OK docker compose — Docker Compose is available.\n"; \
		else \
			printf "ERROR docker compose — %s. Next: install the Docker Compose plugin\n" "$$compose_output"; failures=1; \
		fi; \
	else \
		printf "ERROR docker — command not found. Next: install Docker Desktop or Docker Engine\n"; \
		printf "ERROR docker compose — Docker CLI unavailable. Next: install the Docker Compose plugin\n"; \
		failures=1; \
	fi; \
	printf "\n==> Host ports\n"; \
	check_port() { \
		port="$$1"; probe=""; probe_output=""; probe_status=127; \
		if command -v lsof >/dev/null 2>&1; then \
			probe="lsof"; probe_output=$$(lsof -nP -iTCP:"$$port" -sTCP:LISTEN 2>&1); probe_status=$$?; \
		elif command -v nc >/dev/null 2>&1; then \
			probe="nc"; probe_output=$$(nc -z localhost "$$port" 2>&1); probe_status=$$?; \
		fi; \
		if [ -z "$$probe" ]; then \
			if [ "$$port" = "5432" ]; then \
				printf "WARN port 5432 probe unavailable — Relyra does not publish Postgres; this listener is diagnostic only. Next: inspect host ports manually or install lsof/netcat\n"; \
			else \
				printf "WARN port %s probe unavailable — neither lsof nor nc is installed. Next: inspect host ports manually or install lsof/netcat\n" "$$port"; failures=1; \
			fi; \
		elif [ "$$probe_status" -eq 0 ]; then \
			if [ "$$port" = "5432" ]; then \
				if [ "$$probe" = "nc" ]; then probe_output="detected by nc"; fi; \
				printf "INFO port 5432 occupied — %s. Relyra does not publish Postgres; this listener is diagnostic only.\n" "$$probe_output"; \
			elif [ "$$port" = "4000" ]; then \
				if [ "$$probe" = "nc" ]; then probe_output="detected by nc"; fi; \
				printf "WARN port 4000 occupied — %s. Next: stop the listener or set PORT=<free-port>\n" "$$probe_output"; failures=1; \
			else \
				if [ "$$probe" = "nc" ]; then probe_output="detected by nc"; fi; \
				printf "WARN port 8080 occupied — %s. Next: stop the listener or reconfigure the shared proxy\n" "$$probe_output"; failures=1; \
			fi; \
		elif [ "$$probe_status" -eq 1 ]; then \
			if [ "$$port" = "5432" ]; then \
				printf "OK port 5432 free — Relyra does not publish Postgres; this listener is diagnostic only.\n"; \
			else \
				printf "OK port %s free.\n" "$$port"; \
			fi; \
		else \
			if [ "$$port" = "5432" ]; then \
				printf "WARN port 5432 probe failed — %s. Relyra does not publish Postgres; this listener is diagnostic only. Next: inspect port 5432 manually\n" "$$probe_output"; \
			else \
				printf "ERROR port %s probe failed — %s. Next: inspect port %s manually\n" "$$port" "$$probe_output" "$$port"; failures=1; \
			fi; \
		fi; \
	}; \
	check_port 4000; \
	check_port 5432; \
	check_port 8080; \
	printf "\n==> Shared proxy network\n"; \
	if docker network inspect "$${DEMO_PROXY_NETWORK}" >/dev/null 2>&1; then \
		printf "OK proxy network exists — %s.\n" "$${DEMO_PROXY_NETWORK}"; \
	else \
		printf "WARN proxy network missing. Next: make proxy\n"; failures=1; \
	fi; \
	printf "\n==> Next steps\n"; \
	if [ "$$failures" -eq 0 ]; then \
		printf "OK doctor — no blocking launcher issues detected.\n"; \
	else \
		printf "Review the exact Next: commands above.\n"; \
	fi; \
	exit "$$failures"

demo-test:
	$(SOLO_COMPOSE) --profile keycloak --profile browser run --rm playwright
