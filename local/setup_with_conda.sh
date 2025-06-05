#!/bin/bash

# InstructLab Setup Script with Conda (Forced)
# This script specifically uses conda for Python environment management

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
WORKSPACE_DIR="$HOME/instructlab-workspace"
CONDA_ENV_NAME="instructlab"
PYTHON_VERSION="3.11"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install miniconda
install_miniconda() {
    log "Installing Miniconda..."
    
    if command_exists conda; then
        info "Conda is already installed"
        return 0
    fi
    
    local conda_installer="$HOME/miniconda_installer.sh"
    local conda_url
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        conda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ $(uname -m) == "arm64" ]]; then
            conda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
        else
            conda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
        fi
    else
        error "Unsupported operating system"
    fi
    
    info "Downloading Miniconda..."
    if command_exists curl; then
        curl -fsSL "$conda_url" -o "$conda_installer"
    elif command_exists wget; then
        wget -q "$conda_url" -O "$conda_installer"
    else
        error "Neither curl nor wget is available"
    fi
    
    bash "$conda_installer" -b -p "$HOME/miniconda3"
    
    # Initialize conda for this session
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
    export PATH="$HOME/miniconda3/bin:$PATH"
    
    # Configure conda
    conda config --set auto_activate_base false
    conda config --set channel_priority strict
    
    rm "$conda_installer"
    info "Miniconda installed successfully"
    
    # Add to shell profile
    local shell_profile="$HOME/.bashrc"
    if [[ "$SHELL" == *"zsh"* ]]; then
        shell_profile="$HOME/.zshrc"
    fi
    
    if ! grep -q "miniconda3/bin/conda" "$shell_profile" 2>/dev/null; then
        echo "" >> "$shell_profile"
        echo "# >>> conda initialize >>>" >> "$shell_profile"
        "$HOME/miniconda3/bin/conda" init bash >> "$shell_profile" 2>/dev/null || true
        echo "# <<< conda initialize <<<" >> "$shell_profile"
        info "Added conda initialization to $shell_profile"
    fi
}

# Setup conda environment
setup_conda_environment() {
    log "Setting up conda environment for InstructLab..."
    
    # Ensure conda is available
    if ! command_exists conda; then
        if [[ -f "$HOME/miniconda3/bin/conda" ]]; then
            eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
            export PATH="$HOME/miniconda3/bin:$PATH"
        else
            error "Conda not found"
        fi
    fi
    
    # Remove existing environment if it exists
    if conda env list | grep -q "^$CONDA_ENV_NAME "; then
        warn "Environment '$CONDA_ENV_NAME' already exists"
        read -p "Remove and recreate? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            conda env remove -n "$CONDA_ENV_NAME" -y
        else
            info "Using existing environment"
            conda activate "$CONDA_ENV_NAME"
            return 0
        fi
    fi
    
    # Create environment
    info "Creating conda environment with Python $PYTHON_VERSION..."
    conda create -n "$CONDA_ENV_NAME" python="$PYTHON_VERSION" pip -y
    
    # Activate environment
    conda activate "$CONDA_ENV_NAME"
    info "Activated conda environment '$CONDA_ENV_NAME'"
    
    # Install additional packages that might be needed
    conda install -n "$CONDA_ENV_NAME" -c conda-forge git curl -y
    pip install --upgrade pip
}

# Install system dependencies
install_system_deps() {
    log "Installing system dependencies..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y build-essential curl wget
        elif command_exists dnf; then
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y curl wget
        elif command_exists yum; then
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y curl wget
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! xcode-select -p &>/dev/null; then
            xcode-select --install
            warn "Please complete Xcode installation and re-run this script"
            exit 1
        fi
    fi
}

# Create workspace
create_workspace() {
    log "Creating workspace..."
    
    mkdir -p "$WORKSPACE_DIR"
    cd "$WORKSPACE_DIR"
    info "Workspace created at $WORKSPACE_DIR"
}

# Install InstructLab
install_instructlab() {
    log "Installing InstructLab..."
    
    conda activate "$CONDA_ENV_NAME"
    pip install instructlab
    
    if ilab --help &>/dev/null; then
        info "InstructLab installed successfully"
    else
        error "InstructLab installation failed"
    fi
}

# Setup InstructLab
setup_instructlab() {
    log "Setting up InstructLab..."
    
    conda activate "$CONDA_ENV_NAME"
    
    # Initialize config
    ilab config init --non-interactive || true
    
    # Download model
    info "Downloading base model (this may take a while)..."
    ilab model download
    
    # Download taxonomy
    info "Downloading taxonomy..."
    ilab taxonomy download
    
    info "InstructLab setup completed"
}

# Create helper scripts
create_helpers() {
    log "Creating helper scripts..."
    
    # Environment activation script
    cat > "$WORKSPACE_DIR/activate_conda.sh" << EOF
#!/bin/bash
eval "\$(conda shell.bash hook)"
conda activate $CONDA_ENV_NAME
echo "InstructLab conda environment activated!"
echo "Python: \$(python --version)"
echo "InstructLab: \$(ilab --version)"
EOF
    chmod +x "$WORKSPACE_DIR/activate_conda.sh"
    
    # Quick start script
    cat > "$WORKSPACE_DIR/quick_start.sh" << EOF
#!/bin/bash
eval "\$(conda shell.bash hook)"
conda activate $CONDA_ENV_NAME
echo "Starting InstructLab chat..."
ilab model chat
EOF
    chmod +x "$WORKSPACE_DIR/quick_start.sh"
    
    info "Helper scripts created"
}

# Print summary
print_summary() {
    log "Setup completed successfully!"
    
    echo
    echo "=== CONDA SETUP SUMMARY ==="
    echo "✅ Miniconda installed"
    echo "✅ Conda environment '$CONDA_ENV_NAME' created with Python $PYTHON_VERSION"
    echo "✅ InstructLab installed"
    echo "✅ Base model downloaded"
    echo "✅ Taxonomy downloaded"
    echo "✅ Helper scripts created"
    echo
    echo "=== QUICK START ==="
    echo "1. Activate environment:"
    echo "   conda activate $CONDA_ENV_NAME"
    echo "   # OR: $WORKSPACE_DIR/activate_conda.sh"
    echo
    echo "2. Start chatting:"
    echo "   ilab model chat"
    echo "   # OR: $WORKSPACE_DIR/quick_start.sh"
    echo
    echo "=== USEFUL COMMANDS ==="
    echo "• conda activate $CONDA_ENV_NAME  # Activate environment"
    echo "• conda deactivate               # Deactivate environment"
    echo "• conda env list                 # List all environments"
    echo "• conda list                     # List packages in current env"
    echo
    echo "🎉 InstructLab is ready with conda!"
}

# Main function
main() {
    echo "=== InstructLab Setup with Conda ==="
    echo "This will install Miniconda and set up InstructLab in a conda environment."
    echo
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled"
        exit 0
    fi
    
    install_system_deps
    install_miniconda
    setup_conda_environment
    create_workspace
    install_instructlab
    setup_instructlab
    create_helpers
    print_summary
}

# Handle interruption
trap 'error "Setup interrupted"' INT TERM

# Run
main "$@"
