#!/bin/bash
# ============================================================================
# setup-runner.sh — Setup GitHub Actions Self-Hosted Runner on Ubuntu VM
# ============================================================================
# Run this INSIDE your VirtualBox Ubuntu VM (via SSH or VM terminal).
#
# What it does:
#   1. Installs Docker & Docker Compose
#   2. Downloads and configures GitHub Actions runner
#   3. Installs runner as a system service (auto-starts on boot)
#
# Prerequisites:
#   - Ubuntu VM with internet access
#   - GitHub Personal Access Token (or repo runner token)
#
# Usage:
#   chmod +x setup-runner.sh
#   ./setup-runner.sh <GITHUB_RUNNER_TOKEN>
#
# Get your token from:
#   https://github.com/ankitbelbase17/Simple_Realstate_Buyerportal/settings/actions/runners/new
# ============================================================================

set -e

# ── Config ──────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/ankitbelbase17/Simple_Realstate_Buyerportal"
RUNNER_NAME="buyer-portal-vm"
RUNNER_LABELS="self-hosted,linux,x64"
RUNNER_DIR="$HOME/actions-runner"

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

banner() { echo -e "\n${CYAN}$(printf '=%.0s' {1..60})\n  $1\n$(printf '=%.0s' {1..60})${NC}\n"; }
ok()     { echo -e "  ${GREEN}[OK]  $1${NC}"; }
step()   { echo -e "  ${YELLOW}[>>]  $1${NC}"; }
fail()   { echo -e "  ${RED}[FAIL]  $1${NC}"; exit 1; }

# ── Check token argument ───────────────────────────────────────────────────
if [ -z "$1" ]; then
    echo ""
    echo -e "${RED}ERROR: Runner token required!${NC}"
    echo ""
    echo "Usage: ./setup-runner.sh <GITHUB_RUNNER_TOKEN>"
    echo ""
    echo "Get your token from:"
    echo "  1. Go to: ${REPO_URL}/settings/actions/runners/new"
    echo "  2. Select 'Linux' as the OS"
    echo "  3. Copy the token from the './config.sh' command"
    echo "     (it looks like: AXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX)"
    echo ""
    exit 1
fi

RUNNER_TOKEN="$1"

banner "STEP 1: Install Docker"

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    ok "Docker already installed: $(docker --version)"
else
    step "Installing Docker..."
    
    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Install prerequisites
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add current user to docker group (so runner can use docker without sudo)
    sudo usermod -aG docker $USER

    ok "Docker installed: $(docker --version)"
fi

# Ensure docker group is active for current session
if ! groups | grep -q docker; then
    step "Adding $USER to docker group..."
    sudo usermod -aG docker $USER
    ok "User added to docker group"
    echo -e "  ${YELLOW}NOTE: You may need to log out and back in for group changes.${NC}"
    echo -e "  ${YELLOW}      Or run: newgrp docker${NC}"
fi

# Start Docker service
sudo systemctl enable docker
sudo systemctl start docker
ok "Docker service running"

banner "STEP 2: Install GitHub Actions Runner"

# Create runner directory
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# Download latest runner
step "Downloading GitHub Actions runner..."
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
if [ -z "$RUNNER_VERSION" ]; then
    RUNNER_VERSION="2.321.0"
    echo "  Using fallback version: $RUNNER_VERSION"
fi

RUNNER_FILE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_FILE}"

if [ ! -f "$RUNNER_FILE" ]; then
    curl -o "$RUNNER_FILE" -L "$RUNNER_URL"
fi
tar xzf "$RUNNER_FILE"
ok "Runner v${RUNNER_VERSION} downloaded"

banner "STEP 3: Configure Runner"

step "Configuring runner for repo..."
./config.sh \
    --url "$REPO_URL" \
    --token "$RUNNER_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABELS" \
    --unattended \
    --replace

ok "Runner configured"

banner "STEP 4: Install as System Service"

step "Installing runner service..."
sudo ./svc.sh install
sudo ./svc.sh start
ok "Runner service installed and started"

# Verify service status
step "Verifying service..."
sudo ./svc.sh status

banner "SETUP COMPLETE"

echo -e "  ${GREEN}Runner Name:    $RUNNER_NAME${NC}"
echo -e "  ${GREEN}Repository:     $REPO_URL${NC}"
echo -e "  ${GREEN}Runner Dir:     $RUNNER_DIR${NC}"
echo ""
echo -e "  ${CYAN}The runner is now listening for jobs from GitHub Actions.${NC}"
echo -e "  ${CYAN}When you push code to GitHub, the deploy stage will run HERE.${NC}"
echo ""
echo -e "  Useful commands:"
echo -e "    Check status:  cd $RUNNER_DIR && sudo ./svc.sh status"
echo -e "    View logs:     cd $RUNNER_DIR && sudo ./svc.sh log"
echo -e "    Stop runner:   cd $RUNNER_DIR && sudo ./svc.sh stop"
echo -e "    Start runner:  cd $RUNNER_DIR && sudo ./svc.sh start"
echo -e "    Uninstall:     cd $RUNNER_DIR && sudo ./svc.sh uninstall"
echo ""
