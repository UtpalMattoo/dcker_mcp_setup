#!/bin/bash

set -e

echo "🔧 Running Dev Container setup..."

# Step 1: Base system packages
apt-get update && apt-get install -y curl git gnupg ca-certificates apt-transport-https build-essential pkg-config


# Not using Google Cloud CLI and Node
# Can still use containerized Google Cloud services or Node services
# Step 2: Node.js 20
# curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs

# Step 3: Google Cloud SDK repo setup
# echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' > /etc/apt/sources.list.d/google-cloud-sdk.list
# curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg


# Step 4: Install Google Cloud CLI
#apt-get update && apt-get install -y google-cloud-cli

# Step 5: Python dependencies
pip install --upgrade pip
if [ -f .devcontainer/requirements.txt ]; then pip install -r .devcontainer/requirements.txt; fi

# Step 6: Create shared Docker network (if missing)
NETWORK_NAME="mcp-net"

if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "✔ Docker network '$NETWORK_NAME' already exists"
else
    echo "➕ Creating Docker network '$NETWORK_NAME'..."
    docker network create "$NETWORK_NAME"
    echo "✔ Network created"
fi

echo "🎉 Setup complete!"