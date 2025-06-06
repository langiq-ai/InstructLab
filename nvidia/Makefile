# Makefile for InstructLab

# Variables
IMAGE_NAME = instructlab-gpu-nvidia
DATA_DIR = $(HOME)/.local/share/instructlab
WORKSPACE_DIR = $(shell pwd)
CONTAINER_DATA_DIR = /home/sandesh/.local/share/instructlab

# Default target
.PHONY: all
all: build

# Build the Docker image using Docker Compose
.PHONY: build
build:
	docker compose build

# Build with plain progress output for better debugging
.PHONY: build-verbose
build-verbose:
	docker compose build --progress=plain

# Run the container interactively with GPU support using Docker Compose
.PHONY: run
run: build
	docker compose run --rm instructlab

# Launch the InstructLab shell directly using Docker Compose
.PHONY: shell
shell: build
	docker compose run --rm instructlab bash

# Clean up (remove the image and containers)
.PHONY: clean
clean:
	docker compose down --rmi all --volumes --remove-orphans

# Start services in the background
.PHONY: up
up: build
	docker compose up -d

# Stop running services
.PHONY: down
down:
	docker compose down

# View logs from the service
.PHONY: logs
logs:
	docker compose logs -f instructlab

# Restart the service
.PHONY: restart
restart:
	docker compose restart

# Check status of services
.PHONY: status
status:
	docker compose ps

# Execute commands in running container
.PHONY: exec
exec:
	docker compose exec instructlab bash

# Help information
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all (default): Build the Docker image using Docker Compose"
	@echo "  build: Build the Docker image using Docker Compose"
	@echo "  build-verbose: Build with detailed output (--progress=plain)"
	@echo "  run: Run the container with ilab command using Docker Compose"
	@echo "  shell: Run the container with bash shell using Docker Compose"
	@echo "  up: Start services in the background"
	@echo "  down: Stop running services"
	@echo "  logs: View logs from the service"
	@echo "  restart: Restart the service"
	@echo "  status: Check status of services"
	@echo "  exec: Execute bash in running container"
	@echo "  clean: Remove the Docker image, containers, and volumes using Docker Compose"
	@echo "  up: Start services in the background using Docker Compose"
	@echo "  down: Stop running services using Docker Compose"
	@echo "  logs: View logs from the service"
	@echo "  restart: Restart the service"
	@echo "  status: Check status of services"
