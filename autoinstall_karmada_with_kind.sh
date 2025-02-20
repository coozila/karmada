#!/bin/bash

set -e

source ~/.bashrc
# Define the absolute path to the install directory
INSTALL_DIR="$(dirname "$(realpath "$0")")"

# Step 1: Install or verify asdf version manager
echo "Step 1: Verifying asdf installation..."
if ! command -v asdf &>/dev/null; then
    echo "asdf not found! Installing asdf..."
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.0
    echo "asdf installed successfully!"
    source ~/.bashrc
fi

# Step 2: Install Go plugin for asdf if not installed
echo "Step 2: Verifying Go plugin for asdf..."
if ! asdf plugin-list | grep -q "golang"; then
    echo "Go plugin not found! Installing Go plugin for asdf..."
    asdf plugin-add golang https://github.com/kennyp/asdf-golang.git
    echo "Go plugin installed successfully!"
fi

# Step 3: Install Golang version 1.23.5 using asdf
echo "Step 3: Installing Golang version 1.23.5..."
asdf install golang 1.23.5
asdf local golang 1.23.5
echo "Golang 1.23.5 installed successfully!"

# Step 4: Install kubectl
echo "Step: Installing kubectl..."

# Download kubectl binary
curl -LO https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl

# Download sha256 checksum file for kubectl
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/linux/amd64/kubectl.sha256"

# Verify the checksum
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Make kubectl executable
chmod +x kubectl

# Create directory for user-specific binaries if it doesn't exist
mkdir -p ~/.local/bin

# Move kubectl to ~/.local/bin
mv kubectl ~/.local/bin/kubectl

# Add ~/.local/bin to PATH if it's not already included
if ! grep -q "$HOME/.local/bin" ~/.bashrc; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
fi

# Reload bashrc to apply changes (this applies only for future shell sessions)
source ~/.bashrc

# Directly check if kubectl is now available in PATH
if ! command -v kubectl &>/dev/null; then
    echo "kubectl is not available in PATH, trying again with direct path"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Verify kubectl installation
kubectl version --client


# Step 5: Install Kind
echo "Step: Installing Kind..."
go install sigs.k8s.io/kind@v0.26.0

# Add GOPATH/bin to PATH
echo "Step: Adding GOPATH/bin to PATH..."
export PATH=$PATH:$(go env GOPATH)/bin

# Verify Kind installation
echo "Step: Verifying Kind installation..."
if ! command -v kind &>/dev/null; then
    echo "Kind is not installed correctly! Please check the installation."
    exit 1
fi

# Verify Kind version
kind_version=$(kind version)
echo "Kind installed successfully! Version: $kind_version"

# Add GOPATH/bin to shell PATH permanently (for future sessions)
if ! grep -q "$(go env GOPATH)/bin" ~/.bashrc; then
    echo "Adding GOPATH/bin to ~/.bashrc..."
    echo "export PATH=\$PATH:$(go env GOPATH)/bin" >> ~/.bashrc
    source ~/.bashrc
    echo "GOPATH/bin added to ~/.bashrc for future sessions."
fi

# Step 6: Install Krew
# Check system architecture
echo "Step: Installing Krew..."
OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
[ "$ARCH" == "x86_64" ] && ARCH="amd64" || true

# Define Krew name based on the system architecture
KREW="krew-${OS}_${ARCH}"

# Download and install Krew
curl -fsSL "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" | tar zx
./${KREW} install krew

# Step 7: Add Krew to PATH
echo "Step: Adding Krew to PATH..."
if ! grep -q 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' ~/.bashrc; then
    echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
fi
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
source ~/.bashrc

# Step 8: Verify Krew installation
echo "Step: Verifying Krew installation..."
kubectl krew version

# Step 9: Create Kind cluster
echo "Step: Creating Kind cluster named 'host'..."
./hack/create-cluster.sh host $HOME/.kube/host.config

# Step 9.1: Verify the Kind cluster is running (with retries)
echo "Step: Verifying Kind cluster is running..."
max_retries=10
retry_count=0
while ! kubectl cluster-info --kubeconfig=$HOME/.kube/host.config &>/dev/null; do
    if [ $retry_count -ge $max_retries ]; then
        echo "Kind cluster is not running after $max_retries attempts. Exiting..."
        exit 1
    fi
    echo "Kind cluster is not running, retrying in 10 seconds... Attempt $((retry_count + 1))/$max_retries"
    ((retry_count++))
    sleep 10
done

# Add a small delay to ensure that the cluster is fully initialized
echo "Waiting an additional 10 seconds for cluster to stabilize..."
sleep 10
echo "Kind cluster is running correctly!"

# Step 10: Install Karmada plugin via Krew
echo "Step: Installing Karmada plugin via Krew..."
kubectl krew install karmada

# Step 11: Verify Karmada plugin installation
echo "Step: Verifying Karmada plugin installation..."
if ! command -v kubectl-karmada &>/dev/null; then
    echo "Karmada plugin is not installed correctly!"
    exit 1
fi
echo "Karmada plugin installed successfully!"

# Step 12: Initialize Karmada
echo "Step: Initializing Karmada..."
kubectl karmada init --crds https://github.com/karmada-io/karmada/releases/download/v1.2.0/crds.tar.gz --kubeconfig=$HOME/.kube/host.config --karmada-data=${HOME}/.karmada --karmada-pki=${HOME}/.karmada/pki
echo "Karmada plugin installed and initialized successfully!"
