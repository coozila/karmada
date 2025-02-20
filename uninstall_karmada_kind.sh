#!/bin/bash

set -e

# 1. Stop and clean up Karmada
echo "# Step 1: Stop and clean up Karmada"

## 1.1 Stop Karmada locally
echo "## Sub-step 1.1: Stopping Karmada locally..."
./hack/local-down-karmada.sh

if [ $? -eq 0 ]; then
    echo "Karmada stopped locally successfully!"
else
    echo "Error: Failed to stop Karmada locally!" >&2
    exit 1
fi

## 1.2 Delete the cluster locally
echo "## Sub-step 1.2: Deleting cluster locally..."
./hack/delete-cluster.sh host $HOME/.kube/host.config

if [ $? -eq 0 ]; then
    echo "Cluster deleted successfully!"
else
    echo "Error: Failed to delete cluster!" >&2
    exit 1
fi

## 1.3 Clean up residual Karmada files
echo "## Sub-step 1.3: Cleaning up residual Karmada files..."
KARMADA_CONFIG_PATHS=(
    "$HOME/.kube/karmada-host.config"
    "$HOME/.kube/karmada-member*.config"
    "$HOME/.kube/karmada*"
)

for path in "${KARMADA_CONFIG_PATHS[@]}"; do
    if [ -e $path ]; then
        rm -rf $path
        echo "Removed: $path"
    fi
done

KARMADA_DIRECTORIES=(
    "/var/lib/karmada"
    "/etc/karmada"
)

for dir in "${KARMADA_DIRECTORIES[@]}"; do
    if [ -d $dir ]; then
        sudo rm -rf $dir
        echo "Removed directory: $dir"
    fi
done

echo "Residual Karmada files removed successfully."

# 2. Remove Kind
echo "# Step 2: Remove Kind"

## 2.1 Remove Kind binary
echo "## Sub-step 2.1: Removing Kind binary..."
if command -v kind &>/dev/null; then
    KIND_PATH=$(command -v kind)
    sudo rm -f "$KIND_PATH"
    echo "Kind binary removed successfully."
else
    echo "Kind binary is not installed."
fi

# 3. Remove Karmada plugin
echo "# Step 3: Remove Karmada plugin"

## 3.1 Remove the Karmada plugin if installed via Krew
echo "## Sub-step 3.1: Checking and removing Karmada plugin..."
if command -v kubectl &> /dev/null && kubectl krew list | grep -q "karmada"; then
    kubectl krew uninstall karmada
    echo "Karmada plugin removed successfully."
else
    echo "Karmada plugin is not installed."
fi

# 4. Remove Krew
echo "# Step 4: Remove Krew"

## 4.1 Remove Krew manually
echo "## Sub-step 4.1: Removing Krew manually..."
if [ -d "$HOME/.krew" ]; then
    rm -rf "$HOME/.krew"
    echo "Krew files removed successfully."
else
    echo "Krew is not installed."
fi

## 4.2 Remove Krew PATH entry from .bashrc
echo "## Sub-step 4.2: Cleaning up .bashrc..."
sed -i '/export PATH="${KREW_ROOT:-\$HOME\/.krew}\/bin:\$PATH"/d' ~/.bashrc
echo ".bashrc cleaned up successfully."

# 5. Remove kubectl and clean up kubeconfig
echo "# Step 5: Remove kubectl and clean up kubeconfig"

## 5.1 Remove 'host' context from kubeconfig
echo "## Sub-step 5.1: Removing 'host' context..."
if kubectl config get-contexts | grep -q "host"; then
    kubectl config delete-context host
    echo "Context 'host' deleted."
else
    echo "Context 'host' not found in kubeconfig."
fi

## 5.2 Remove kubeconfig file for 'host'
echo "## Sub-step 5.2: Removing kubeconfig file..."
if [ -f ~/.kube/host.config ]; then
    rm -f ~/.kube/host.config
    echo "Kubeconfig file 'host.config' removed."
else
    echo "No kubeconfig file found to remove."
fi

## 5.3 Remove kubectl binary
echo "## Sub-step 5.3: Removing kubectl binary..."
if command -v kubectl &>/dev/null; then
    KUBECTL_PATH=$(command -v kubectl)
    sudo rm -f "$KUBECTL_PATH"
    echo "kubectl binary removed successfully."
else
    echo "kubectl binary is not installed."
fi

## 5.4 Remove residual kubeconfig files
echo "## Sub-step 5.4: Removing residual kubeconfig files..."
if [ -d ~/.kube ]; then
    rm -rf ~/.kube
    echo "All residual kubeconfig files removed successfully."
else
    echo "No residual kubeconfig files found."
fi

echo "All steps completed successfully!"

# Final Step: Remove leftover configuration files and directories
echo "# Final Step: Clean up leftover configuration files and directories"

rm -rf ~/.karmada

if [ $? -eq 0 ]; then
    echo "All leftover configuration files and directories removed successfully."
else
    echo "Error: Failed to remove leftover configuration files and directories!" >&2
    exit 1
fi

echo "All steps completed successfully!"