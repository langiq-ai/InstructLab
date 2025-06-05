# Complete InstructLab Setup and Usage Guide

## Overview
InstructLab is an open-source project that allows you to enhance Large Language Models (LLMs) with custom knowledge and skills. This guide will walk you through the entire process from installation to training your first model.

## Prerequisites Check

### System Requirements
- **Operating System**: Apple M1/M2/M3 Mac or Linux system (tested on Fedora)
- **Python**: Version 3.10 or 3.11 (Python 3.12 is not supported yet)
- **Disk Space**: Approximately 60GB for the entire process
- **C++ Compiler**: Required for compilation
- **Memory**: At least 16GB RAM recommended

### Pre-Installation Commands
```bash
# Check Python version
python3 --version

# On macOS, install Xcode command line tools if needed
xcode-select --install

# On Linux, ensure you have build essentials
sudo apt-get update && sudo apt-get install build-essential  # Ubuntu/Debian
# OR
sudo dnf groupinstall "Development Tools"  # Fedora/RHEL
```

## Step 1: Environment Setup

### Create Python Virtual Environment
```bash
# Create a new directory for InstructLab
mkdir ~/instructlab-workspace
cd ~/instructlab-workspace

# Create Python virtual environment
python3 -m venv venv

# Activate the virtual environment
source venv/bin/activate  # Linux/Mac
# OR for Windows (if supported in future)
# venv\Scripts\activate

# Upgrade pip
pip install --upgrade pip
```

## Step 2: Install InstructLab

### Install the Core Package
```bash
# Install InstructLab
pip install instructlab

# Verify installation
ilab --help
```

### Alternative: Install from Source (Development)
```bash
# Clone the repository
git clone https://github.com/instructlab/instructlab.git
cd instructlab

# Install in development mode
pip install -e .
```

## Step 3: Initialize InstructLab

### Initialize the Configuration
```bash
# Initialize InstructLab (creates config and directories)
ilab config init

# This creates:
# - ~/.config/instructlab/config.yaml
# - ~/.local/share/instructlab/ (data directory)
# - ~/.cache/instructlab/ (cache directory)
```

### Configure Settings (Optional)
```bash
# View current configuration
ilab config show

# Edit configuration if needed
# The config file is at ~/.config/instructlab/config.yaml
```

## Step 4: Download a Base Model

### Download Pre-trained Model
```bash
# Download the default model (Mixtral-8x7B-Instruct)
ilab model download

# Or specify a specific model
ilab model download --repository instructlab/merlinite-7b-lab-GGUF

# List available models
ilab model list
```

### Verify Model Download
```bash
# Check downloaded models
ls ~/.cache/instructlab/models/

# The model file should be something like:
# mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf
```

## Step 5: Initialize Taxonomy

### Download the Taxonomy Repository
```bash
# Clone the taxonomy repository
ilab taxonomy download

# This downloads the community taxonomy to:
# ~/.local/share/instructlab/taxonomy/
```

### Explore the Taxonomy Structure
```bash
# Navigate to taxonomy directory
cd ~/.local/share/instructlab/taxonomy/

# View the structure
tree -L 3 .
# OR
find . -type d -maxdepth 3
```

## Step 6: Test Your Setup

### Start a Chat Session
```bash
# Start chatting with the base model
ilab model chat

# Test with a simple question
# Example: "What is the capital of Canada?"
# Type 'exit' or Ctrl+C to quit the chat
```

### Alternative: Chat with Specific Model
```bash
# Chat with a specific model file
ilab model chat --model ~/.cache/instructlab/models/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf
```

## Step 7: Add Custom Knowledge/Skills

### Create Knowledge Contribution
```bash
# Navigate to taxonomy directory
cd ~/.local/share/instructlab/taxonomy/

# Create a new knowledge area (example: company_info)
mkdir -p knowledge/company_info

# Create the qna.yaml file
cat > knowledge/company_info/qna.yaml << 'EOF'
version: 2
task_description: "Information about Acme Corporation"
created_by: your_name
domain: company
seed_examples:
  - question: "What does Acme Corporation do?"
    answer: "Acme Corporation is a leading provider of innovative software solutions for enterprise clients, specializing in cloud-based productivity tools and AI-powered analytics platforms."
  - question: "When was Acme Corporation founded?"
    answer: "Acme Corporation was founded in 2015 by Jane Smith and John Doe in San Francisco, California."
  - question: "What are Acme Corporation's main products?"
    answer: "Acme Corporation's main products include CloudSync Pro (a cloud synchronization platform), DataMind Analytics (an AI-powered business intelligence tool), and TeamHub (a collaborative workspace platform)."
document:
  repo: https://github.com/your-username/acme-docs
  commit: main
  patterns:
    - "*.md"
    - "*.txt"
EOF
```

### Create Skills Contribution (Example: Email Writing)
```bash
# Create a new skill area
mkdir -p skills/writing/email_assistant

# Create the qna.yaml file for skills
cat > skills/writing/email_assistant/qna.yaml << 'EOF'
version: 2
task_description: "Help users write professional emails"
created_by: your_name
seed_examples:
  - question: "Write a professional email to schedule a meeting with a client."
    answer: |
      Subject: Meeting Request - [Your Company] Partnership Discussion
      
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
      
      Thank you for taking the time to interview me for the [Position Title] role today. I enjoyed our conversation about [specific topic discussed] and learning more about the team's projects.
      
      Our discussion reinforced my enthusiasm for this opportunity and my belief that my experience in [relevant experience] would be valuable to your team.
      
      Please don't hesitate to reach out if you need any additional information. I look forward to hearing about the next steps.
      
      Thank you again for your time and consideration.
      
      Best regards,
      [Your Name]
EOF
```

## Step 8: Validate Your Contributions

### Check Taxonomy Validity
```bash
# Validate your taxonomy contributions
ilab taxonomy diff

# This shows what changes you've made to the taxonomy
```

### Generate Synthetic Data
```bash
# Generate training data from your taxonomy
ilab data generate

# This creates synthetic question-answer pairs
# Output goes to ~/.local/share/instructlab/datasets/
```

## Step 9: Train the Model

### Start Training Process
```bash
# Train the model with your new data
ilab model train

# This process can take several hours depending on:
# - Your hardware capabilities
# - Amount of new data
# - Model size
```

### Monitor Training Progress
```bash
# Training logs are typically saved to:
# ~/.local/share/instructlab/checkpoints/

# You can monitor progress with:
tail -f ~/.local/share/instructlab/checkpoints/latest/training.log
```

## Step 10: Test Your Enhanced Model

### Chat with Your Trained Model
```bash
# Start a chat session with your newly trained model
ilab model chat --model ~/.local/share/instructlab/checkpoints/latest/

# Test your custom knowledge/skills
# Example questions:
# - "What does Acme Corporation do?" (if you added company info)
# - "Write a professional email to schedule a meeting" (if you added email skills)
```

### Compare Performance
```bash
# Chat with original model
ilab model chat --model ~/.cache/instructlab/models/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf

# Chat with your enhanced model
ilab model chat --model ~/.local/share/instructlab/checkpoints/latest/model.gguf
```

## Step 11: Serve Your Model

### Start Model Server
```bash
# Start a model server for API access
ilab model serve --model ~/.local/share/instructlab/checkpoints/latest/model.gguf

# Default server runs on http://localhost:8000
# Access the API documentation at http://localhost:8000/docs
```

### Test API Endpoints
```bash
# Test the API with curl
curl -X POST "http://localhost:8000/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "instructlab",
    "messages": [
      {"role": "user", "content": "What does Acme Corporation do?"}
    ]
  }'
```

## Step 12: Contribute Back to Community

### Prepare Your Contribution
```bash
# Navigate to taxonomy directory
cd ~/.local/share/instructlab/taxonomy/

# Check your changes
git status
git diff

# Add your changes
git add knowledge/company_info/qna.yaml  # or your specific files
git commit -m "Add knowledge about Acme Corporation"
```

### Submit Pull Request
```bash
# Fork the taxonomy repository on GitHub first
# Then add your fork as a remote
git remote add fork https://github.com/YOUR_USERNAME/taxonomy.git

# Push your changes
git push fork main

# Create a Pull Request on GitHub to contribute back to the community
```

## Advanced Usage

### Batch Processing
```bash
# Process multiple taxonomy files at once
ilab data generate --taxonomy-path ~/.local/share/instructlab/taxonomy/knowledge/
ilab data generate --taxonomy-path ~/.local/share/instructlab/taxonomy/skills/
```

### Custom Model Parameters
```bash
# Train with custom parameters
ilab model train --num-epochs 3 --learning-rate 0.0001 --batch-size 8
```

### Export Models
```bash
# Export your trained model
ilab model export --model ~/.local/share/instructlab/checkpoints/latest/ --format gguf
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Python Version Issues
```bash
# Check Python version
python3 --version

# If using wrong version, create venv with specific Python
python3.11 -m venv venv
```

#### 2. Memory Issues During Training
```bash
# Monitor memory usage
htop
# OR
free -h

# Reduce batch size if running out of memory
ilab model train --batch-size 4
```

#### 3. Model Download Failures
```bash
# Clear cache and retry
rm -rf ~/.cache/instructlab/models/
ilab model download
```

#### 4. Taxonomy Validation Errors
```bash
# Check YAML syntax
python3 -c "import yaml; yaml.safe_load(open('knowledge/your_area/qna.yaml'))"

# Validate taxonomy structure
ilab taxonomy diff --taxonomy-path ~/.local/share/instructlab/taxonomy/
```

### Log Locations
- **Configuration**: `~/.config/instructlab/config.yaml`
- **Training Logs**: `~/.local/share/instructlab/checkpoints/*/training.log`
- **Data Generation Logs**: `~/.local/share/instructlab/datasets/*/generation.log`
- **Model Cache**: `~/.cache/instructlab/models/`

## Best Practices

### 1. Data Quality
- Provide diverse, high-quality examples in your taxonomy
- Use clear, specific questions and comprehensive answers
- Include edge cases and variations in your examples

### 2. Organization
- Keep your taxonomy contributions well-organized
- Use descriptive names for your knowledge/skill areas
- Document your contributions clearly

### 3. Testing
- Always test your base model before training
- Test your enhanced model thoroughly after training
- Compare performance between original and enhanced models

### 4. Resource Management
- Monitor disk space during training
- Use appropriate batch sizes for your hardware
- Clean up old checkpoints periodically

## Maintenance Commands

### Regular Cleanup
```bash
# Clean old checkpoints (keep only latest 3)
find ~/.local/share/instructlab/checkpoints/ -maxdepth 1 -type d | sort | head -n -3 | xargs rm -rf

# Clear model cache
rm -rf ~/.cache/instructlab/models/*

# Update InstructLab
pip install --upgrade instructlab
```

### Backup Important Data
```bash
# Backup your custom taxonomy
tar -czf taxonomy_backup_$(date +%Y%m%d).tar.gz ~/.local/share/instructlab/taxonomy/

# Backup your trained models
tar -czf models_backup_$(date +%Y%m%d).tar.gz ~/.local/share/instructlab/checkpoints/
```

## Next Steps

1. **Join the Community**: Visit the [InstructLab GitHub](https://github.com/instructlab) and community forums
2. **Explore Examples**: Check out existing taxonomy contributions for inspiration
3. **Contribute**: Submit your own knowledge and skills to help improve community models
4. **Experiment**: Try different types of contributions and training parameters
5. **Share**: Share your enhanced models with the community (following licensing requirements)

This completes the comprehensive InstructLab setup and usage guide. You now have everything needed to install, configure, use, and contribute to InstructLab!