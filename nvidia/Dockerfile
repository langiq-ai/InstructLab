# Base image with CUDA (choose one compatible with your driver, e.g. CUDA 12.1 + Python 3.11)
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

# Add NVIDIA runtime labels
LABEL com.nvidia.volumes.needed="nvidia_driver"
LABEL com.nvidia.cuda.version="12.1.1"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    VIRTUAL_ENV=/opt/venv \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility

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
    nvidia-container-toolkit-base \
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
    LDFLAGS="-L/usr/local/cuda/lib64" \
    CUDA_HOME=/usr/local/cuda

# Add GPU detection script
RUN echo '#!/bin/bash\n\
    if nvidia-smi &> /dev/null; then\n\
    echo "GPU detected, using CUDA"\n\
    export CUDA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-0}\n\
    else\n\
    echo "No GPU detected, falling back to CPU"\n\
    export CUDA_VISIBLE_DEVICES=""\n\
    fi\n\
    exec "$@"' > /usr/local/bin/gpu-entrypoint.sh && \
    chmod +x /usr/local/bin/gpu-entrypoint.sh

RUN pip install vllm@git+https://github.com/opendatahub-io/vllm@2024.08.01

# Create user sandesh
RUN useradd -m -s /bin/bash sandesh && \
    usermod -aG sudo sandesh && \
    mkdir -p /home/sandesh/.local/share/instructlab && \
    chown -R sandesh:sandesh /home/sandesh

# Optional: Set InstructLab model/data dir as volume
VOLUME ["/home/sandesh/.local/share/instructlab"]

# Set working directory
WORKDIR /workspace

# Change ownership of workspace to sandesh user
RUN chown -R sandesh:sandesh /workspace

# Switch to sandesh user
USER sandesh

# Set entrypoint to handle GPU detection
ENTRYPOINT ["/usr/local/bin/gpu-entrypoint.sh"]

# Default command (can be overridden)
CMD [ "ilab" ]
