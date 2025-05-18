# Makefile for InstructLab

# Variables
IMAGE_NAME = instructlab-gpu-amd # Name of the Docker image
DATA_DIR = $(HOME)/.local/share/instructlab
WORKSPACE_DIR = $(shell pwd)

# Default target
.PHONY: all
all: build

# Build the Docker image
.PHONY: build
build:
	docker build -t $(IMAGE_NAME) .

# Build with plain progress output for better debugging
.PHONY: build-verbose
build-verbose:
	docker build --progress=plain -t $(IMAGE_NAME) .

# Run the container interactively with GPU support
.PHONY: run
run: build
	docker run --gpus all -it --rm \
		-v $(DATA_DIR):/root/.local/share/instructlab \
		-v $(WORKSPACE_DIR):/workspace \
		$(IMAGE_NAME)

# Launch the InstructLab shell directly
.PHONY: shell
shell: build
	docker run --gpus all -it --rm \
		-v $(DATA_DIR):/root/.local/share/instructlab \
		-v $(WORKSPACE_DIR):/workspace \
		$(IMAGE_NAME) bash

# Clean up (remove the image)
.PHONY: clean
clean:
	docker rmi $(IMAGE_NAME)

# Help information
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all (default): Build the Docker image"
	@echo "  build: Build the Docker image"
	@echo "  build-verbose: Build with detailed output (--progress=plain)"
	@echo "  run: Run the container with ilab command"
	@echo "  shell: Run the container with bash shell"
	@echo "  clean: Remove the Docker image"
