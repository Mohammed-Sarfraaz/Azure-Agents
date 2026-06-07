#!/bin/bash
set -e

AGENT_VERSION=${AGENT_VERSION:-3.227.2}
AZURE_DEVOPS_URL=${AZURE_DEVOPS_URL}
AZURE_DEVOPS_TOKEN=${AZURE_DEVOPS_TOKEN}
AGENT_NAME=${AGENT_NAME:-"aks-agent-$(hostname)"}
AGENT_POOL=${AGENT_POOL:-"Default"}

if [ -z "$AZURE_DEVOPS_URL" ] || [ -z "$AZURE_DEVOPS_TOKEN" ]; then
    echo "Error: AZURE_DEVOPS_URL and AZURE_DEVOPS_TOKEN environment variables are required"
    exit 1
fi

# Download agent
echo "Downloading Azure DevOps agent version $AGENT_VERSION..."
wget https://vstsagentpackage.azureedge.net/agent/$AGENT_VERSION/vsts-agent-linux-x64-$AGENT_VERSION.tar.gz -O agent.tar.gz

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
