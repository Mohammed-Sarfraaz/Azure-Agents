#!/bin/bash
set -e

AGENT_VERSION=${AGENT_VERSION:-4.274.1}
AZURE_DEVOPS_URL=${AZURE_DEVOPS_URL}
AZURE_DEVOPS_TOKEN=${AZURE_DEVOPS_TOKEN}
AGENT_NAME=${AGENT_NAME:-"aks-agent-$(hostname)"}
AGENT_POOL=${AGENT_POOL:-"Default"}
AGENT_ARCH=${AGENT_ARCH:-$(uname -m)}

if [ -z "$AZURE_DEVOPS_URL" ] || [ -z "$AZURE_DEVOPS_TOKEN" ]; then
    echo "Error: AZURE_DEVOPS_URL and AZURE_DEVOPS_TOKEN environment variables are required"
    exit 1
fi

case "$AGENT_ARCH" in
  x86_64|amd64)
    AGENT_ARCH="x64"
    ;;
  aarch64|arm64)
    AGENT_ARCH="arm64"
    ;;
  *)
    echo "Error: unsupported architecture '$AGENT_ARCH'"
    exit 1
    ;;
esac

AGENT_URL="https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/vsts-agent-linux-${AGENT_ARCH}-${AGENT_VERSION}.tar.gz"

# Download agent
echo "Downloading Azure DevOps agent version $AGENT_VERSION for architecture $AGENT_ARCH..."
wget -q "$AGENT_URL" -O agent.tar.gz

# Extract agent
echo "Extracting agent..."
tar zxf agent.tar.gz
rm agent.tar.gz

# Configure agent
echo "Configuring agent..."
./config.sh \
    --unattended \
    --url "$AZURE_DEVOPS_URL" \
    --auth pat \
    --token "$AZURE_DEVOPS_TOKEN" \
    --agent "$AGENT_NAME" \
    --pool "$AGENT_POOL" \
    --acceptTeeEula

# Run agent
echo "Starting agent..."
./run.sh
