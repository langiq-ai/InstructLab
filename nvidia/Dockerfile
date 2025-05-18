# Base image with CUDA (choose one compatible with your driver, e.g. CUDA 12.1 + Python 3.11)
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    unzip \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip \
    ca-certificates \
    software-properties-common \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    python --version

# Create virtual environment and activate
RUN python -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Split installation into multiple steps for easier debugging

# Step 1: Upgrade pip, setuptools and wheel
RUN pip install --upgrade pip setuptools wheel

# Step 2: Install PyTorch with CUDA support
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Step 3: Install instructlab with CUDA support
RUN pip install 'instructlab[cuda]' \
    -C cmake.args="-DLLAMA_CUDA=on" \
    -C cmake.args="-DLLAMA_NATIVE=off"

# Step 4: Install vllm from GitHub with specified CUDA architectures and compiler flags
ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0" \
    NVCC_FLAGS="-diag-suppress 179,39" \
    CFLAGS="-I/usr/local/cuda/include" \
    LDFLAGS="-L/usr/local/cuda/lib64"
RUN pip install vllm@git+https://github.com/opendatahub-io/vllm@2024.08.01

# Optional: Set InstructLab model/data dir as volume
VOLUME ["/root/.local/share/instructlab"]

# Set working directory
WORKDIR /workspace

# Default command (can be overridden)
CMD [ "ilab" ]
