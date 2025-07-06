#!/bin/bash

set -euo pipefail

# Colors for output (disable if NO_COLOR is set or not a terminal)
if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly CYAN=''
    readonly NC=''
else
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly NC='\033[0m'
fi

# Configuration file
readonly CONFIG_FILE="$HOME/.backup-config"

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}         Backup System Download${NC}"
    echo -e "${BLUE}================================================${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Prompt for user input with default
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"
    local value
    
    if [[ -n "$default" ]]; then
        echo -n "$prompt [$default]: "
    else
        echo -n "$prompt: "
    fi
    
    read -r value
    if [[ -z "$value" ]]; then
        value="$default"
    fi
    
    eval "$var_name=\\\"$value\\\""
}

# Load existing configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
        print_info "Using existing configuration from ~/.backup-config"
    fi
}

# Save configuration
save_config() {
    local pat="$1"
    local repo_url="$2"
    
    # Create or update config file
    if [[ -f "$CONFIG_FILE" ]]; then
        # Update existing config file
        if grep -q "^GITHUB_PAT=" "$CONFIG_FILE"; then
            sed -i "s|^GITHUB_PAT=.*|GITHUB_PAT=\"$pat\"|" "$CONFIG_FILE"
        else
            echo "GITHUB_PAT=\"$pat\"" >> "$CONFIG_FILE"
        fi
        
        if grep -q "^BACKUP_REPO_URL=" "$CONFIG_FILE"; then
            sed -i "s|^BACKUP_REPO_URL=.*|BACKUP_REPO_URL=\"$repo_url\"|" "$CONFIG_FILE"
        else
            echo "BACKUP_REPO_URL=\"$repo_url\"" >> "$CONFIG_FILE"
        fi
    else
        # Create new config file
        cat > "$CONFIG_FILE" << EOF
# Backup system configuration - $(date)
GITHUB_PAT="$pat"
BACKUP_REPO_URL="$repo_url"
EOF
    fi
    
    chmod 600 "$CONFIG_FILE"
}

main() {
    print_header
    
    echo "This script will download the backup system to your machine."
    echo
    echo "What it does:"
    echo "• Downloads backup scripts to ~/backup-jobs"
    echo "• Sets proper executable permissions"
    echo "• Stores configuration for future use"
    echo
    echo "After completion, you can run: cd ~/backup-jobs && ./setup-backup.sh"
    echo
    
    # Load existing configuration
    load_config
    
    # Get repository URL
    if [[ -n "${BACKUP_REPO_URL:-}" ]]; then
        echo "Using existing repository URL: $BACKUP_REPO_URL"
        repo_url="$BACKUP_REPO_URL"
    else
        echo -n "Backup repository URL: "
        read -r repo_url
        
        if [[ -z "$repo_url" ]]; then
            print_error "Repository URL is required"
            exit 1
        fi
    fi
    
    # Get GitHub PAT
    if [[ -n "${GITHUB_PAT:-}" ]]; then
        echo "Using existing GitHub PAT from configuration."
        pat_token="$GITHUB_PAT"
    else
        echo
        echo "You need a GitHub Personal Access Token (PAT) for private repository access."
        echo "Get one from: https://github.com/settings/tokens"
        echo "Required scope: 'repo' (for private repository access)"
        echo
        echo -n "Enter your GitHub PAT: "
        read -rs pat_token
        echo
        
        if [[ -z "$pat_token" ]]; then
            print_error "GitHub PAT is required for private repository access"
            exit 1
        fi
    fi
    
    # Save configuration for future use
    save_config "$pat_token" "$repo_url"
    
    # Check if directory already exists
    if [[ -d "$HOME/backup-jobs" ]]; then
        echo -e "${YELLOW}Warning: ~/backup-jobs directory already exists.${NC}"
        echo -n "Remove existing directory and continue? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Download cancelled."
            exit 0
        fi
        echo "Removing existing directory..."
        rm -rf "$HOME/backup-jobs"
    fi
    
    # Construct clone URL
    clone_url="https://${pat_token}@${repo_url}"
    
    # Clone repository
    echo "Downloading backup system..."
    if git clone "$clone_url" "$HOME/backup-jobs"; then
        print_success "Repository downloaded successfully"
    else
        print_error "Failed to download repository"
        echo "Please check your PAT and repository URL."
        exit 1
    fi
    
    # Set executable permissions
    echo "Setting executable permissions..."
    cd "$HOME/backup-jobs"
    if chmod +x *.sh jobs/*.sh; then
        print_success "Executable permissions set"
    else
        print_error "Failed to set permissions"
        exit 1
    fi
    
    echo
    print_success "Backup system download completed!"
    echo
    echo "Configuration saved to ~/.backup-config for future downloads."
    echo
    echo "Next steps:"
    echo "1. cd ~/backup-jobs"
    echo "2. ./setup-backup.sh"
    echo
    echo "The setup wizard will guide you through configuration in 5-10 minutes."
}

if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main "$@"
fi