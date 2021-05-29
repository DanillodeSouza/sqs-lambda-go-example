.PHONY: usage lint get-linter build zip update-lambda start unit-tests coverage

OK_COLOR=\033[32;01m
NO_COLOR=\033[0m

GO := go
GO_LINTER := golint
GOFLAGS ?=
ROOT_DIR := $(realpath .)

DOCKER_COMPOSE := docker-compose

PKGS = $(shell $(GO) list ./...)

## usage: show available actions
usage: Makefile
	@echo "to use make call:"
	@echo "make <action>"
	@echo ""
	@echo "list of available actions:"
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'

## build: build all
build: unit-tests
	@echo "$(OK_COLOR)==> Building binary (linux/amd64/lambda-processor)...$(NO_COLOR)"
	@echo GOOS=linux GOARCH=amd64 $(GO) build -v -o bin/linux_amd64/lambda-processor ./cmd/lambda-processor
	@GOOS=linux GOARCH=amd64 $(GO) build -v $(BUILDFLAGS) -o bin/linux_amd64/lambda-processor ./cmd/lambda-processor

## up: start services
up: build
	@echo "$(OK_COLOR)==> Starting services...$(NO_COLOR)"
	$(DOCKER_COMPOSE) up

## down: stop services
down: build
	@echo "$(OK_COLOR)==> Stopping services...$(NO_COLOR)"
	$(DOCKER_COMPOSE) down

# lint: linter in code
lint:
	@echo "$(OK_COLOR)==> Running linter...$(NO_COLOR)"
	@$(GO_LINTER) -set_exit_status $(PKGS)

## get-linter: install linter
get-linter:
	@echo "$(OK_COLOR)==> Getting linter...$(NO_COLOR)"
	@go get -v -u golang.org/x/lint/golint

zip:
	@echo "$(OK_COLOR)==> Zipping binary (linux/amd64/lambda-processor)...$(NO_COLOR)"
	cd bin/linux_amd64 && zip lambda-processor.zip lambda-processor

## update-lambda: Update lambda code
update-lambda: build zip
	@echo "$(OK_COLOR)==> Updating lambda code...$(NO_COLOR)"
	./scripts/update-lambda.sh
	@echo "$(OK_COLOR)==> Lambda updated...$(NO_COLOR)"

## start: Start lambda
start: build zip
	@echo "$(OK_COLOR)==> Starting lambda...$(NO_COLOR)"
	docker-compose up

## unit-test: run unit tests
unit-tests:
	@echo "$(OK_COLOR)==> Running unit tests[...]:$(NO_COLOR)"
	@go test $(GOFLAGS) $(PKGS)

## coverage: run unit test and generate code coverage reports
coverage:
	@echo "$(OK_COLOR)==> Running tests coverage...$(NO_COLOR)"
	@$(GO) test -coverprofile=coverage.out $(GOFLAGS) $(PKGS)
	@$(GO) tool cover -html=coverage.out -o=coverage.html
	@echo "$(OK_COLOR)coverage reports created at coverage.html$(NO_COLOR)"
