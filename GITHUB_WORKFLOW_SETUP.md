# GitHub Workflow Setup Guide

This guide explains how to set up GitHub Actions to automatically build and deploy the Azure DevOps agent to AKS.

## Prerequisites

- GitHub repository with this code
- Azure subscription with AKS and ACR already deployed
- Azure DevOps organization with a Personal Access Token (PAT)
- Service Principal with permissions to ACR and AKS (recommended for security)

## Step 1: Create Azure Service Principal

Create a service principal for GitHub Actions to authenticate with Azure:

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az ad sp create-for-rbac \
  --name "github-actions-devops-agent" \
  --role "Contributor" \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --json-auth > ~/github-sp.json

cat ~/github-sp.json
```

Save the output JSON for the next step.

## Step 2: Configure GitHub Repository Secrets

In your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Create the following secrets:

### Azure Secrets

| Secret Name | Value | Source |
|-------------|-------|--------|
| `AZURE_CLIENT_ID` | `clientId` from SP JSON | Service Principal |
| `AZURE_TENANT_ID` | `tenantId` from SP JSON | Service Principal |
| `AZURE_SUBSCRIPTION_ID` | `subscriptionId` from SP JSON | Service Principal |
| `AZURE_RESOURCE_GROUP` | Your resource group name | Terraform output |
| `AKS_CLUSTER_NAME` | Your AKS cluster name | Terraform output |
| `ACR_LOGIN_SERVER` | Your ACR login server (e.g., `myacr.azurecr.io`) | Terraform output |

### Azure DevOps Secrets

| Secret Name | Value | Notes |
|-------------|-------|-------|
| `AZURE_DEVOPS_ORG_URL` | `https://dev.azure.com/YOUR_ORG` | Your DevOps org URL |
| `AZURE_DEVOPS_PAT_TOKEN` | Your Personal Access Token | [Create PAT](#creating-azure-devops-pat) |

## Step 3: Creating Azure DevOps PAT

1. Navigate to your Azure DevOps organization: `https://dev.azure.com/YOUR_ORG`
2. Click your **User Settings** (top-right avatar)
3. Select **Personal access tokens**
4. Click **New Token**
5. Configure:
   - **Name:** `GitHub-DevOps-Agent`
   - **Organization:** Select your organization
   - **Expiration:** Set as needed (e.g., 1 year)
   - **Scopes:** 
     - ✅ Agent Pools (Read & manage)
     - ✅ Deployment group (Read & manage)
6. Click **Create**
7. Copy the token and save it as `AZURE_DEVOPS_PAT_TOKEN` secret in GitHub

## Step 4: Get Terraform Outputs

Run these commands to get the values needed for GitHub secrets:

```bash
# Get outputs from your Terraform deployment
terraform output -raw resource_group_name
terraform output -raw aks_name
terraform output -raw acr_login_server
```

## Step 5: Verify Workflow Setup

1. Go to **Actions** tab in your GitHub repository
2. You should see the "Build and Deploy DevOps Agent to AKS" workflow
3. The workflow will run automatically on:
   - Push to `main` branch affecting `docker/**`, `k8s/**`, or `.github/workflows/deploy-devops-agent.yml`
   - Manual trigger via **Run workflow** button

## Workflow Variables Configuration

Create a `.github/variables.yml` file in your repository for environment configuration:

```yaml
# .github/variables.yml (optional - for organization consistency)
agent:
  image_name: devops-agent
  namespace: azure-devops-agents
  pool_name: Default
  replicas: 1
  resources:
    requests:
      memory: "256Mi"
      cpu: "500m"
    limits:
      memory: "512Mi"
      cpu: "1000m"
```

## Triggering the Workflow

### Automatic Trigger
The workflow automatically triggers when:
- Code is pushed to `main` branch affecting:
  - `docker/` directory
  - `k8s/` directory
  - `.github/workflows/deploy-devops-agent.yml`

### Manual Trigger
1. Go to **Actions** tab
2. Click "Build and Deploy DevOps Agent to AKS"
3. Click **Run workflow**
4. (Optional) Enter number of replicas
5. Click **Run workflow**

## Workflow Steps Explained

### Build and Push Phase
1. **Checkout code** - Gets the latest code from your repo
2. **Setup Docker Buildx** - Prepares Docker for multi-platform builds
3. **Azure CLI login** - Authenticates with Azure using Service Principal
4. **Login to ACR** - Logs in to Azure Container Registry via Azure CLI
5. **Build and push Docker image** - Builds image with two tags:
   - `latest` - Always points to latest build
   - `<commit-sha>` - Points to specific commit

> Note: AKS image pulls are expected to be handled by the cluster-managed identity with the `AcrPull` role.

### Deploy Phase
1. **Checkout code** - Gets the latest code
2. **Azure CLI login** - Authenticates with Azure
3. **Get AKS credentials** - Configures kubectl to access AKS
4. **Create namespace** - Creates `azure-devops-agents` namespace if it doesn't exist
5. **Create DevOps Agent Secret** - Creates Kubernetes secret with DevOps credentials
6. **Update deployment image** - Updates K8s manifests with correct image URL
7. **Deploy to AKS** - Applies the deployment to AKS
8. **Verify deployment** - Waits for rollout to complete
9. **Check pod status** - Shows pod logs for debugging

## Troubleshooting

### Workflow Fails at Azure Login
- Verify Service Principal credentials in GitHub secrets
- Check Service Principal has required permissions
- Ensure tenant ID and subscription ID are correct

### Docker Build Fails
- Check `docker/Dockerfile` syntax
- Ensure `docker/start.sh` file exists and is executable
- Verify Docker context path is correct (`./docker`)

### AKS Deployment Fails
- Verify AKS cluster name and resource group are correct
- Check AKS cluster is running: `az aks list --output table`
- Check deployment spec: `kubectl describe deployment -n azure-devops-agents`

### Pod Crashes
- Check pod logs: `kubectl logs -n azure-devops-agents -l app=azure-devops-agent`
- Verify DevOps org URL and PAT token are correct
- Ensure PAT token has correct scopes and hasn't expired

### Permission Denied Errors
- Verify Service Principal has `Contributor` role
- Check RBAC permissions on ACR and AKS
- Ensure resource group permissions are correct

## Security Best Practices

1. **Service Principal:**
   - Use least privilege principle (specific roles instead of Contributor)
   - Rotate credentials regularly
   - Store credentials securely in GitHub

2. **PAT Token:**
   - Set expiration dates
   - Limit scopes to required permissions only
   - Rotate tokens periodically
   - Never commit tokens to repository

3. **Docker Image:**
   - Use image digest for deployment (not just `latest`)
   - Scan images for vulnerabilities: `az acr scan --registry $ACR_NAME`
   - Keep base image updated

4. **AKS Security:**
   - Use RBAC for pod access control
   - Implement network policies
   - Use managed identities where possible

## Scaling Multiple Agents

To deploy multiple agent replicas, either:

### Option 1: Modify workflow input
When manually triggering the workflow, specify the number of replicas in the workflow input.

### Option 2: Edit deployment manifest
In `k8s/devops-agent-deployment.yaml`, change the `replicas` field:

```yaml
spec:
  replicas: 3  # Deploy 3 agents
```

Then push the change to main to trigger the workflow.

## Cleanup

To remove the deployed agent:

```bash
kubectl delete namespace azure-devops-agents
```

Or add a manual workflow step to destroy resources if needed.
