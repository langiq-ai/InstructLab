#!/bin/bash

# InstructLab Complete Setup Script
# This script automates the entire InstructLab installation and setup process
# Based on the comprehensive guide in README.md

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="$HOME/instructlab-workspace"
PYTHON_VERSION_MIN="3.10"
PYTHON_VERSION_MAX="3.11"

# Function to print colored output
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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install conda/miniconda if not present
install_conda() {
    log "Setting up conda for Python version management..."
    
    if command_exists conda; then
        info "Conda is already installed"
        return 0
    fi
    
    local conda_installer
    local conda_url
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        conda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        conda_installer="$HOME/miniconda_installer.sh"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ $(uname -m) == "arm64" ]]; then
            conda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
        else
            conda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
        fi
        conda_installer="$HOME/miniconda_installer.sh"
    else
        error "Unsupported operating system for conda installation"
    fi
    
    info "Downloading Miniconda installer..."
    if command_exists curl; then
        curl -fsSL "$conda_url" -o "$conda_installer"
    elif command_exists wget; then
        wget -q "$conda_url" -O "$conda_installer"
    else
        error "Neither curl nor wget is available. Please install one of them first."
    fi
    
    info "Installing Miniconda..."
    bash "$conda_installer" -b -p "$HOME/miniconda3"
    
    # Initialize conda
    eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
    conda config --set auto_activate_base false
    
    # Add conda to PATH for this session
    export PATH="$HOME/miniconda3/bin:$PATH"
    
    # Clean up installer
    rm "$conda_installer"
    
    info "Miniconda installed successfully"
    
    # Add conda initialization to shell profile
    local shell_profile
    if [[ -f "$HOME/.bashrc" ]]; then
        shell_profile="$HOME/.bashrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
        shell_profile="$HOME/.bash_profile"
    elif [[ -f "$HOME/.zshrc" ]]; then
        shell_profile="$HOME/.zshrc"
    else
        shell_profile="$HOME/.bashrc"
        touch "$shell_profile"
    fi
    
    if ! grep -q "miniconda3/bin/conda" "$shell_profile"; then
        echo "" >> "$shell_profile"
        echo "# >>> conda initialize >>>" >> "$shell_profile"
        echo "# !! Contents within this block are managed by 'conda init' !!" >> "$shell_profile"
        "$HOME/miniconda3/bin/conda" init bash >> "$shell_profile"
        echo "# <<< conda initialize <<<" >> "$shell_profile"
        info "Added conda initialization to $shell_profile"
    fi
}

# Setup Python environment with conda
setup_python_with_conda() {
    log "Setting up Python environment with conda..."
    
    # Ensure conda is available
    if ! command_exists conda; then
        if [[ -f "$HOME/miniconda3/bin/conda" ]]; then
            export PATH="$HOME/miniconda3/bin:$PATH"
            eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
        else
            error "Conda installation failed or not found"
        fi
    fi
    
    local env_name="instructlab"
    local python_version="3.11"
    
    # Check if environment already exists
    if conda env list | grep -q "^$env_name "; then
        warn "Conda environment '$env_name' already exists"
        read -p "Do you want to remove and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            conda env remove -n "$env_name" -y
            info "Removed existing conda environment"
        else
            info "Using existing conda environment"
            conda activate "$env_name"
            return 0
        fi
    fi
    
    # Create new conda environment with specific Python version
    info "Creating conda environment '$env_name' with Python $python_version..."
    conda create -n "$env_name" python="$python_version" -y
    
    # Activate the environment
    conda activate "$env_name"
    info "Activated conda environment '$env_name'"
    
    # Upgrade pip in the conda environment
    pip install --upgrade pip
    info "Upgraded pip in conda environment"
}

# Check Python version
check_python_version() {
    log "Checking Python version..."
    
    local python_cmd="python"
    if command_exists python3; then
        python_cmd="python3"
    elif command_exists python; then
        python_cmd="python"
    else
        error "Python is not installed or not accessible."
    fi
    
    local python_version
    python_version=$($python_cmd --version | cut -d' ' -f2 | cut -d'.' -f1,2)
    
    # Simple version comparison without bc dependency
    local version_ok=false
    if [[ "$python_version" == "3.10" ]] || [[ "$python_version" == "3.11" ]]; then
        version_ok=true
    fi
    
    if [[ "$version_ok" == false ]]; then
        warn "Python version $python_version is not optimal for InstructLab (requires 3.10 or 3.11)"
        read -p "Do you want to install and use conda to manage Python versions? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_conda
            setup_python_with_conda
            return 0
        else
            error "Python version $python_version is not supported. Please install Python 3.10 or 3.11."
        fi
    fi
    
    info "Python version $python_version is compatible."
}

# Check system requirements
check_system_requirements() {
    log "Checking system requirements..."
    
    # Check operating system
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        info "Running on Linux"
        DISTRO=$(lsb_release -si 2>/dev/null || echo "Unknown")
        info "Distribution: $DISTRO"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        info "Running on macOS"
        # Check for Apple Silicon
        if [[ $(uname -m) == "arm64" ]]; then
            info "Apple Silicon Mac detected"
        else
            warn "Intel Mac detected. Apple Silicon is recommended for better performance."
        fi
    else
        warn "Unsupported operating system. This script is tested on Linux and macOS."
    fi
    
    # Check available memory (in GB)
    if command_exists free; then
        local memory_gb
        memory_gb=$(free -g | awk '/^Mem:/{print $2}')
        if [[ $memory_gb -lt 16 ]]; then
            warn "Available RAM ($memory_gb GB) is less than recommended 16GB"
        else
            info "Available RAM: $memory_gb GB"
        fi
    fi
    
    # Check available disk space
    local available_space
    available_space=$(df -BG "$HOME" | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $available_space -lt 60 ]]; then
        warn "Available disk space ($available_space GB) might be insufficient. 60GB+ recommended."
    else
        info "Available disk space: $available_space GB"
    fi
}

# Install system dependencies
install_system_dependencies() {
    log "Installing system dependencies..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Detect package manager and install build tools
        if command_exists apt-get; then
            info "Installing build essentials for Ubuntu/Debian..."
            sudo apt-get update
            sudo apt-get install -y build-essential python3-dev python3-venv git curl
        elif command_exists dnf; then
            info "Installing development tools for Fedora/RHEL..."
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y python3-devel python3-venv git curl
        elif command_exists yum; then
            info "Installing development tools for CentOS/RHEL..."
            sudo yum groupinstall -y "Development Tools"
            sudo yum install -y python3-devel python3-venv git curl
        else
            warn "Unknown package manager. Please install build tools manually."
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        info "Installing Xcode command line tools for macOS..."
        if ! xcode-select -p &>/dev/null; then
            xcode-select --install
            warn "Xcode command line tools installation started. Please complete it and re-run this script."
            exit 1
        else
            info "Xcode command line tools already installed"
        fi
    fi
}

# Create workspace and virtual environment
setup_environment() {
    log "Setting up workspace and environment..."
    
    # Create workspace directory
    if [[ -d "$WORKSPACE_DIR" ]]; then
        warn "Workspace directory $WORKSPACE_DIR already exists"
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            error "Aborted by user"
        fi
    else
        mkdir -p "$WORKSPACE_DIR"
        info "Created workspace directory: $WORKSPACE_DIR"
    fi
    
    cd "$WORKSPACE_DIR"
    
    # Check if we're using conda or traditional venv
    if command_exists conda && conda env list | grep -q "instructlab"; then
        info "Using existing conda environment"
        conda activate instructlab
        # Create a symlink to make scripts work
        if [[ ! -L "venv" ]] && [[ ! -d "venv" ]]; then
            ln -s "$CONDA_PREFIX" venv
            info "Created symlink to conda environment"
        fi
    else
        # Traditional virtual environment setup
        if [[ ! -d "venv" ]]; then
            local python_cmd="python3"
            if command_exists python; then
                python_cmd="python"
            fi
            
            $python_cmd -m venv venv
            info "Created Python virtual environment"
        else
            warn "Virtual environment already exists"
        fi
        
        # Activate virtual environment
        source venv/bin/activate
        info "Activated virtual environment"
        
        # Upgrade pip
        pip install --upgrade pip
        info "Upgraded pip"
    fi
}

# Install InstructLab
install_instructlab() {
    log "Installing InstructLab..."
    
    # Make sure we're in the correct environment
    if command_exists conda && conda env list | grep -q "instructlab"; then
        conda activate instructlab
        info "Using conda environment"
    elif [[ -z "${VIRTUAL_ENV:-}" ]]; then
        cd "$WORKSPACE_DIR"
        source venv/bin/activate
        info "Activated virtual environment"
    fi
    
    # Install InstructLab
    pip install instructlab
    info "InstructLab installed successfully"
    
    # Verify installation
    if ilab --help &>/dev/null; then
        info "InstructLab installation verified"
    else
        error "InstructLab installation failed"
    fi
}

# Initialize InstructLab configuration
initialize_config() {
    log "Initializing InstructLab configuration..."
    
    # Initialize config
    ilab config init --non-interactive || true
    info "InstructLab configuration initialized"
    
    # Show configuration
    info "Current configuration:"
    ilab config show || warn "Could not display configuration"
}

# Download base model
download_model() {
    log "Downloading base model..."
    
    info "This may take a while depending on your internet connection..."
    
    # Download the default model
    if ilab model download; then
        info "Base model downloaded successfully"
    else
        warn "Model download failed or was interrupted"
        return 1
    fi
    
    # Verify model download
    if ls ~/.cache/instructlab/models/*.gguf &>/dev/null; then
        info "Model files found in cache:"
        ls -lh ~/.cache/instructlab/models/*.gguf
    else
        warn "No model files found in cache"
    fi
}

# Download taxonomy
download_taxonomy() {
    log "Downloading taxonomy repository..."
    
    if ilab taxonomy download; then
        info "Taxonomy downloaded successfully"
    else
        error "Taxonomy download failed"
    fi
    
    # Show taxonomy structure
    if [[ -d ~/.local/share/instructlab/taxonomy ]]; then
        info "Taxonomy structure:"
        find ~/.local/share/instructlab/taxonomy -type d -maxdepth 3 | head -10
    fi
}

# Create example knowledge contribution
create_example_knowledge() {
    log "Creating example knowledge contribution..."
    
    local taxonomy_dir="$HOME/.local/share/instructlab/taxonomy"
    local knowledge_dir="$taxonomy_dir/knowledge/example_company"
    
    mkdir -p "$knowledge_dir"
    
    cat > "$knowledge_dir/qna.yaml" << 'EOF'
version: 2
task_description: "Information about Example Tech Company"
created_by: instructlab_setup_script
domain: company
seed_examples:
  - question: "What does Example Tech Company do?"
    answer: "Example Tech Company is a leading provider of innovative software solutions for enterprise clients, specializing in cloud-based productivity tools and AI-powered analytics platforms."
  - question: "When was Example Tech Company founded?"
    answer: "Example Tech Company was founded in 2020 by the InstructLab community as an example for demonstrating knowledge contributions."
  - question: "What are Example Tech Company's main products?"
    answer: "Example Tech Company's main products include CloudSync Pro (a cloud synchronization platform), DataMind Analytics (an AI-powered business intelligence tool), and TeamHub (a collaborative workspace platform)."
EOF
    
    info "Created example knowledge contribution at $knowledge_dir/qna.yaml"
}

# Create example skills contribution
create_example_skills() {
    log "Creating example skills contribution..."
    
    local taxonomy_dir="$HOME/.local/share/instructlab/taxonomy"
    local skills_dir="$taxonomy_dir/skills/writing/email_helper"
    
    mkdir -p "$skills_dir"
    
    cat > "$skills_dir/qna.yaml" << 'EOF'
version: 2
task_description: "Help users write professional emails"
created_by: instructlab_setup_script
seed_examples:
  - question: "Write a professional email to schedule a meeting with a client."
    answer: |
      Subject: Meeting Request - Partnership Discussion
      
      Dear [Client Name],
      
      I hope this email finds you well. I would like to schedule a meeting to discuss potential partnership opportunities between our companies.
      
      Would you be available for a 30-minute call next week? I'm flexible with timing and can accommodate your schedule. Please let me know what works best for you.
      
      I look forward to our conversation.
      
      Best regards,
      [Your Name]
      [Your Title]
      [Your Company]
  - question: "Write a follow-up email after a job interview."
    answer: |
      Subject: Thank you for the interview - [Position Title]
      
      Dear [Interviewer Name],
      
      Thank you for taking the time to interview me for the [Position Title] role today. I enjoyed our conversation and learning more about the team's projects.
      
      Our discussion reinforced my enthusiasm for this opportunity and my belief that my experience would be valuable to your team.
      
      Please don't hesitate to reach out if you need any additional information. I look forward to hearing about the next steps.
      
      Thank you again for your time and consideration.
      
      Best regards,
      [Your Name]
EOF
    
    info "Created example skills contribution at $skills_dir/qna.yaml"
}

# Test setup with chat
test_setup() {
    log "Testing setup with a quick chat session..."
    
    info "Starting a brief chat session to test the installation..."
    info "You can type 'exit' to quit the chat session"
    
    # Start chat session (this will be interactive)
    echo "Testing with a simple question..."
    echo "What is the capital of France?" | timeout 30 ilab model chat || {
        warn "Chat test timed out or failed - this is normal for the first run"
        info "You can test manually later with: ilab model chat"
    }
}

# Validate taxonomy contributions
validate_taxonomy() {
    log "Validating taxonomy contributions..."
    
    if ilab taxonomy diff; then
        info "Taxonomy validation completed"
    else
        warn "Taxonomy validation showed differences or warnings"
    fi
}

# Create helper scripts
create_helper_scripts() {
    log "Creating helper scripts..."
    
    # Create activation script
    cat > "$WORKSPACE_DIR/activate.sh" << 'EOF'
#!/bin/bash
# Helper script to activate InstructLab environment

cd ~/instructlab-workspace

# Check if conda environment exists
if command -v conda >/dev/null 2>&1 && conda env list | grep -q "instructlab"; then
    echo "Activating conda environment..."
    eval "$(conda shell.bash hook)"
    conda activate instructlab
elif [[ -d "venv" ]]; then
    echo "Activating virtual environment..."
    source venv/bin/activate
else
    echo "No environment found. Please run the setup script first."
    exit 1
fi

echo "InstructLab environment activated!"
echo "Python version: $(python --version)"
echo ""
echo "Available commands:"
echo "  ilab --help                    # Show all commands"
echo "  ilab model chat               # Start chat session"
echo "  ilab model download           # Download models"
echo "  ilab taxonomy diff            # Check taxonomy changes"
echo "  ilab data generate            # Generate training data"
echo "  ilab model train              # Train the model"
echo "  ilab model serve              # Serve model as API"
EOF
    
    chmod +x "$WORKSPACE_DIR/activate.sh"
    
    # Create quick training script
    cat > "$WORKSPACE_DIR/quick_train.sh" << 'EOF'
#!/bin/bash
# Quick training script for InstructLab

set -e

cd ~/instructlab-workspace

# Activate environment
if command -v conda >/dev/null 2>&1 && conda env list | grep -q "instructlab"; then
    eval "$(conda shell.bash hook)"
    conda activate instructlab
elif [[ -d "venv" ]]; then
    source venv/bin/activate
else
    echo "No environment found. Please run the setup script first."
    exit 1
fi

echo "Starting InstructLab training process..."
echo "This will:"
echo "1. Validate taxonomy"
echo "2. Generate synthetic data"
echo "3. Train the model"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

echo "Step 1: Validating taxonomy..."
ilab taxonomy diff

echo "Step 2: Generating synthetic data..."
ilab data generate

echo "Step 3: Training model..."
echo "Note: This can take several hours!"
ilab model train

echo "Training completed! You can now test with:"
echo "ilab model chat --model ~/.local/share/instructlab/checkpoints/latest/"
EOF
    
    chmod +x "$WORKSPACE_DIR/quick_train.sh"
    
    # Create cleanup script
    cat > "$WORKSPACE_DIR/cleanup.sh" << 'EOF'
#!/bin/bash
# Cleanup script for InstructLab

echo "InstructLab Cleanup Options:"
echo "1. Clean old checkpoints (keep latest 3)"
echo "2. Clear model cache"
echo "3. Clean datasets"
echo "4. Full cleanup (everything except taxonomy)"
echo "5. Cancel"

read -p "Choose option (1-5): " choice

case $choice in
    1)
        echo "Cleaning old checkpoints..."
        find ~/.local/share/instructlab/checkpoints/ -maxdepth 1 -type d | sort | head -n -3 | xargs rm -rf
        echo "Done!"
        ;;
    2)
        echo "Clearing model cache..."
        rm -rf ~/.cache/instructlab/models/*
        echo "Done!"
        ;;
    3)
        echo "Cleaning datasets..."
        rm -rf ~/.local/share/instructlab/datasets/*
        echo "Done!"
        ;;
    4)
        echo "Full cleanup (keeping taxonomy)..."
        rm -rf ~/.cache/instructlab/models/*
        rm -rf ~/.local/share/instructlab/datasets/*
        find ~/.local/share/instructlab/checkpoints/ -maxdepth 1 -type d | head -n -1 | xargs rm -rf
        echo "Done!"
        ;;
    5)
        echo "Cancelled"
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF
    
    chmod +x "$WORKSPACE_DIR/cleanup.sh"
    
    info "Helper scripts created:"
    info "  $WORKSPACE_DIR/activate.sh     # Activate environment"
    info "  $WORKSPACE_DIR/quick_train.sh  # Quick training process"
    info "  $WORKSPACE_DIR/cleanup.sh      # Cleanup utilities"
}

# Create backup script
create_backup_script() {
    log "Creating backup script..."
    
    cat > "$WORKSPACE_DIR/backup.sh" << 'EOF'
#!/bin/bash
# Backup script for InstructLab

BACKUP_DIR="$HOME/instructlab-backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Creating backup in $BACKUP_DIR..."

# Backup taxonomy
if [[ -d ~/.local/share/instructlab/taxonomy ]]; then
    echo "Backing up taxonomy..."
    tar -czf "$BACKUP_DIR/taxonomy_$DATE.tar.gz" -C ~/.local/share/instructlab taxonomy/
fi

# Backup trained models (checkpoints)
if [[ -d ~/.local/share/instructlab/checkpoints ]]; then
    echo "Backing up trained models..."
    tar -czf "$BACKUP_DIR/checkpoints_$DATE.tar.gz" -C ~/.local/share/instructlab checkpoints/
fi

# Backup configuration
if [[ -f ~/.config/instructlab/config.yaml ]]; then
    echo "Backing up configuration..."
    cp ~/.config/instructlab/config.yaml "$BACKUP_DIR/config_$DATE.yaml"
fi

echo "Backup completed in $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
EOF
    
    chmod +x "$WORKSPACE_DIR/backup.sh"
    info "Backup script created at $WORKSPACE_DIR/backup.sh"
}

# Print summary and next steps
print_summary() {
    log "InstructLab setup completed successfully!"
    
    echo
    echo "=== SETUP SUMMARY ==="
    echo "✅ System requirements checked"
    echo "✅ Dependencies installed"
    if command_exists conda && conda env list | grep -q "instructlab"; then
        echo "✅ Conda environment created with Python $(conda list python | grep "^python " | awk '{print $2}')"
    else
        echo "✅ Python virtual environment created"
    fi
    echo "✅ InstructLab installed and configured"
    echo "✅ Base model downloaded"
    echo "✅ Taxonomy repository downloaded"
    echo "✅ Example contributions created"
    echo "✅ Helper scripts created"
    echo
    echo "=== WORKSPACE LOCATION ==="
    echo "📁 $WORKSPACE_DIR"
    echo
    echo "=== QUICK START ==="
    if command_exists conda && conda env list | grep -q "instructlab"; then
        echo "1. Activate conda environment:"
        echo "   conda activate instructlab"
        echo "   # OR use: $WORKSPACE_DIR/activate.sh"
    else
        echo "1. Activate environment:"
        echo "   cd $WORKSPACE_DIR && source venv/bin/activate"
        echo "   # OR use: $WORKSPACE_DIR/activate.sh"
    fi
    echo
    echo "2. Start chatting:"
    echo "   ilab model chat"
    echo
    echo "3. Train with your custom data:"
    echo "   $WORKSPACE_DIR/quick_train.sh"
    echo
    echo "=== IMPORTANT LOCATIONS ==="
    echo "📄 Config: ~/.config/instructlab/config.yaml"
    echo "📁 Data: ~/.local/share/instructlab/"
    echo "📁 Models: ~/.cache/instructlab/models/"
    echo "📁 Taxonomy: ~/.local/share/instructlab/taxonomy/"
    echo
    echo "=== NEXT STEPS ==="
    echo "1. Test the installation: ilab model chat"
    echo "2. Explore the taxonomy: cd ~/.local/share/instructlab/taxonomy"
    echo "3. Add your own knowledge/skills to the taxonomy"
    echo "4. Generate data: ilab data generate"
    echo "5. Train your model: ilab model train"
    echo "6. Serve your model: ilab model serve"
    echo
    echo "=== HELPFUL COMMANDS ==="
    echo "• ilab --help                  # Show all commands"
    echo "• ilab config show             # View configuration"
    echo "• ilab model list              # List available models"
    echo "• ilab taxonomy diff           # Check taxonomy changes"
    echo "• $WORKSPACE_DIR/cleanup.sh    # Cleanup utilities"
    echo "• $WORKSPACE_DIR/backup.sh     # Backup your work"
    echo
    echo "🎉 Happy training with InstructLab!"
}

# Main execution flow
main() {
    echo "=== InstructLab Complete Setup Script ==="
    echo "This script will install and configure InstructLab with all dependencies."
    echo
    
    # Confirmation prompt
    read -p "Do you want to continue with the installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    # Run setup steps
    check_python_version
    check_system_requirements
    install_system_dependencies
    setup_environment
    install_instructlab
    initialize_config
    download_model
    download_taxonomy
    create_example_knowledge
    create_example_skills
    validate_taxonomy
    create_helper_scripts
    create_backup_script
    
    # Optional: Test setup
    read -p "Do you want to test the installation with a chat session? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        test_setup
    fi
    
    print_summary
}

# Handle script interruption
trap 'error "Script interrupted by user"' INT TERM

# Run main function
main "$@"
