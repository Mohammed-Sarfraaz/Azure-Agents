# Azure DevOps Agent Deployment on AKS

This guide explains how to deploy an Azure DevOps agent as a pod on your AKS cluster.

## Prerequisites

- AKS cluster deployed (using this Terraform infrastructure)
- Docker installed locally
- `kubectl` configured to access your AKS cluster
- Azure DevOps organization and a Personal Access Token (PAT)
- Access to Azure Container Registry (ACR)

## Step 1: Build and Push Docker Image to ACR

### 1.1 Get ACR Credentials

```bash
# Get ACR login server name
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)

### 1.2 Build and Push Image

```bash
cd <your-terraform-directory>
chmod +x scripts/build-and-push.sh
./scripts/build-and-push.sh $ACR_LOGIN_SERVER $ACR_USERNAME $ACR_PASSWORD
```

Alternatively, use Docker manually:

```bash
# Build image
docker build -t devops-agent:latest ./docker

# Tag for ACR
docker tag devops-agent:latest $ACR_LOGIN_SERVER/devops-agent:latest

# Login to ACR
az acr login --name $ACR_LOGIN_SERVER

# Push to ACR
docker push $ACR_LOGIN_SERVER/devops-agent:latest
```

## Step 2: Create Azure DevOps PAT Token

1. Go to your Azure DevOps organization: `https://dev.azure.com/YOUR_ORG`
2. Click on User Settings → Personal access tokens
3. Click "New Token"
4. Name: `DevOps-Agent-AKS`
5. Organization: Select your organization
6. Scopes: Agent Pools (Read & Manage), Deployment group (Read & Manage)
7. Expiration: Set as needed
8. Click "Create" and copy the token

## Step 3: Deploy Agent to AKS

### 3.1 Update the Secret

Edit `k8s/devops-agent-secret.yaml`:

```yaml
stringData:
  org-url: "https://dev.azure.com/YOUR_ORG"
  pat-token: "YOUR_PAT_TOKEN_HERE"
```

Or apply directly:

```bash
kubectl create secret generic devops-agent-secret \
  --from-literal=org-url="https://dev.azure.com/YOUR_ORG" \
  --from-literal=pat-token="YOUR_PAT_TOKEN" \
  -n azure-devops-agents
```

### 3.2 Update the Deployment

Edit `k8s/devops-agent-deployment.yaml` and replace `<ACR_LOGIN_SERVER>` with your actual ACR login server:

```bash
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
sed -i "s/<ACR_LOGIN_SERVER>/$ACR_LOGIN_SERVER/g" k8s/devops-agent-deployment.yaml
```

### 3.3 Get AKS Credentials

```bash
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_name)
```

### 3.4 Deploy to AKS

```bash
# Create namespace and apply secret
kubectl apply -f k8s/devops-agent-secret.yaml

# Deploy the agent
kubectl apply -f k8s/devops-agent-deployment.yaml

# Verify deployment
kubectl get deployment -n azure-devops-agents
kubectl logs -n azure-devops-agents -f deployment/azure-devops-agent
```

## Step 4: Verify Agent Registration

1. Go to your Azure DevOps organization
2. Organization Settings → Agent pools
3. Your agent should appear in the pool with a green "Online" status

## Troubleshooting

### Check Pod Logs

```bash
kubectl logs -n azure-devops-agents -f deployment/azure-devops-agent
```

### Describe Pod

```bash
kubectl describe pod -n azure-devops-agents -l app=azure-devops-agent
```

### Common Issues

**Image Pull Error:**
- Ensure ACR credentials are correct
- Verify image exists in ACR: `az acr repository list --name <acr-name>`

**Agent Connection Error:**
- Check org URL format: `https://dev.azure.com/YOUR_ORG`
- Verify PAT token is valid and has correct scopes
- Check agent pool name exists in Azure DevOps

**Pod Crashes:**
- Check resource limits in deployment
- Verify agent script permissions: `chmod +x docker/start.sh`

## Scaling

To run multiple agents:

```bash
kubectl scale deployment azure-devops-agent --replicas=3 -n azure-devops-agents
```

## Cleanup

```bash
kubectl delete namespace azure-devops-agents
```
