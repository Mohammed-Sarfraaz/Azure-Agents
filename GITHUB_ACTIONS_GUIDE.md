# GitHub Actions Workflow - DevOps Agent Deployment

## Overview

This GitHub Actions workflow automates the process of building a Docker image for the Azure DevOps agent, pushing it to Azure Container Registry (ACR), and deploying it to your AKS cluster.

## Key Features

✅ **Automated Builds** - Build Docker image on push to main branch  
✅ **ACR Integration** - Push image to Azure Container Registry  
✅ **Auto-deployment** - Deploy directly to AKS after successful build  
✅ **Secure Credentials** - Uses GitHub Secrets and Service Principal for authentication  
✅ **Image Versioning** - Tags images with both `latest` and commit SHA  
✅ **Build Caching** - Leverages ACR caching for faster builds  
✅ **Manual Triggers** - Can be triggered manually from GitHub Actions tab  

## Quick Setup (3 Steps)

### Step 1: Create Azure Service Principal

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az ad sp create-for-rbac \
  --name "github-actions-devops-agent" \
  --role "Contributor" \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --json-auth
```

**Save the output JSON** - you'll need the values in the next step.

### Step 2: Add GitHub Repository Secrets

In your GitHub repo → **Settings** → **Secrets and variables** → **Actions**, create these secrets:

#### From Service Principal JSON:
- `AZURE_CLIENT_ID` = `clientId`
- `AZURE_TENANT_ID` = `tenantId`  
- `AZURE_SUBSCRIPTION_ID` = `subscriptionId`

#### From Terraform outputs:
```bash
terraform output -raw resource_group_name      # → AZURE_RESOURCE_GROUP
terraform output -raw aks_name                 # → AKS_CLUSTER_NAME
terraform output -raw acr_login_server         # → ACR_LOGIN_SERVER
```

#### From Azure DevOps:
1. Go to https://dev.azure.com/YOUR_ORG
2. User Settings → Personal access tokens → New Token
3. Scopes: Agent Pools (Read & manage), Deployment group (Read & manage)
4. `AZURE_DEVOPS_ORG_URL` = `https://dev.azure.com/YOUR_ORG`
5. `AZURE_DEVOPS_PAT_TOKEN` = your generated token

### Step 3: Deploy!

Push to `main` branch or manually trigger from **Actions** tab:

```bash
git add docker/ k8s/ .github/
git commit -m "Add DevOps agent deployment"
git push origin main
```

The workflow will automatically:
1. Build the Docker image
2. Push it to ACR
3. Deploy to AKS
4. Register the agent in DevOps

## Workflow Details

### Workflow File
`.github/workflows/deploy-devops-agent.yml`

### Triggers
- **Push to main** - When changes affect:
  - `docker/**`
  - `k8s/**`
  - `.github/workflows/deploy-devops-agent.yml`
- **Manual trigger** - Via GitHub Actions UI

### Jobs

#### 1. `build-and-push` (Runs on ubuntu-latest)
Builds and pushes Docker image to ACR

Steps:
- Checkout code
- Setup Docker Buildx
- Authenticate with Azure
- Login to ACR via Azure CLI
- Build and push image with tags:
  - `<registry>/devops-agent:latest`
  - `<registry>/devops-agent:<commit-sha>`
- Get AKS credentials for next job

> Note: AKS image pulls are expected to use the cluster-managed identity with the `AcrPull` role.

#### 2. `deploy` (Depends on build-and-push)
Deploys agent to AKS

Steps:
- Checkout code
- Authenticate with Azure
- Get AKS credentials
- Create `azure-devops-agents` namespace
- Create Kubernetes secret with DevOps credentials
- Update K8s deployment with correct image URI
- Apply deployment to AKS
- Verify rollout status
- Display pod logs

## Workflow Variables

### Environment Variables (in workflow)
```yaml
AGENT_IMAGE_NAME: devops-agent
REGISTRY_URL: ${{ secrets.ACR_LOGIN_SERVER }}
AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
RESOURCE_GROUP: ${{ secrets.AZURE_RESOURCE_GROUP }}
AKS_CLUSTER_NAME: ${{ secrets.AKS_CLUSTER_NAME }}
```

### GitHub Secrets (Required)

| Secret | Purpose | How to Get |
|--------|---------|-----------|
| `AZURE_CLIENT_ID` | Service Principal auth | Service Principal JSON |
| `AZURE_TENANT_ID` | Service Principal auth | Service Principal JSON |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription | `az account show --query id` |
| `AZURE_RESOURCE_GROUP` | Resource group name | `terraform output resource_group_name` |
| `AKS_CLUSTER_NAME` | AKS cluster name | `terraform output aks_name` |
| `ACR_LOGIN_SERVER` | ACR registry URL | `terraform output acr_login_server` |
| `AZURE_DEVOPS_ORG_URL` | DevOps org URL | Azure DevOps settings |
| `AZURE_DEVOPS_PAT_TOKEN` | DevOps auth token | Azure DevOps PAT |

## Monitoring Workflow Execution

### View Workflow Runs
1. Go to your GitHub repo
2. Click **Actions** tab
3. Select "Build and Deploy DevOps Agent to AKS" workflow
4. Click on a workflow run to see details

### Check Logs
- Click a job to see detailed logs
- Sensitive data (passwords, tokens) are masked as `***`

### Verify Deployment

```bash
# Check deployment status
kubectl get deployment -n azure-devops-agents
kubectl get pods -n azure-devops-agents

# Check pod logs
kubectl logs -n azure-devops-agents -f deployment/azure-devops-agent

# Check Azure DevOps
# Go to Organization Settings → Agent pools
# Agent should appear with "Online" status
```

## Troubleshooting

### Workflow Fails - Azure Login
**Error:** `Error: Unable to get the OIDC token`

**Solution:**
- Verify Service Principal credentials are correct
- Check Service Principal has Contributor role
- Ensure secrets are correctly named and valued

### Workflow Fails - Docker Build
**Error:** `failed to solve with frontend dockerfile.v0`

**Solution:**
- Check `docker/Dockerfile` and `docker/start.sh` exist
- Verify Dockerfile syntax
- Ensure file permissions are correct

### Pod Crashes - Agent Won't Connect
**Error:** Pod crashes or agent shows as offline

**Solution:**
```bash
kubectl logs -n azure-devops-agents -l app=azure-devops-agent

# Check if issue is with credentials
# Verify AZURE_DEVOPS_ORG_URL and AZURE_DEVOPS_PAT_TOKEN are correct
# Ensure PAT token has correct scopes and hasn't expired
```

### Deployment Timeout
**Error:** `error waiting for rollout status`

**Solution:**
- Check pod logs for crashes: `kubectl describe pod <pod-name>`
- Verify image was pushed to ACR: `az acr repository show-tags --repository devops-agent`
- Check resource constraints: `kubectl top nodes`

## Advanced Configuration

### Scale Agents
Modify `k8s/devops-agent-deployment.yaml`:

```yaml
spec:
  replicas: 3  # Deploy 3 agents instead of 1
```

Then push to main to trigger workflow.

### Custom Agent Pool
Update the deployment environment variable:

```yaml
- name: AGENT_POOL
  value: "Custom-Pool-Name"  # Change from "Default"
```

### Image Retention
ACR automatically cleans up images based on retention policy. Configure via Azure portal or CLI:

```bash
az acr config retention update --registry <acr-name> --status enabled --days 30
```

### Build Cache
The workflow uses ACR's buildcache for faster builds:

```yaml
cache-from: type=registry,ref=${{ env.REGISTRY_URL }}/devops-agent:buildcache
cache-to: type=registry,ref=${{ env.REGISTRY_URL }}/devops-agent:buildcache,mode=max
```

## Security Considerations

1. **Service Principal Rotation** - Rotate credentials periodically
2. **PAT Token Expiration** - Set PAT to expire in 1 year max
3. **Secret Scope** - PAT token should only have Agent Pools and Deployment group scopes
4. **Network Policy** - Consider adding Kubernetes network policies
5. **RBAC** - Limit Service Principal to required roles only

## Rollback

To rollback to a previous image version:

```bash
# Get image SHA from previous deployment
kubectl set image deployment/azure-devops-agent \
  agent=<acr>/devops-agent:<old-sha> \
  -n azure-devops-agents
```

## Documentation Files

- `GITHUB_WORKFLOW_SETUP.md` - Detailed setup instructions
- `GITHUB_SECRETS_SETUP.md` - GitHub secrets configuration checklist
- `DEVOPS_AGENT_SETUP.md` - Manual deployment guide (for reference)
- `docker/Dockerfile` - Agent Docker image
- `docker/start.sh` - Agent startup script
- `k8s/devops-agent-deployment.yaml` - Kubernetes deployment manifest
- `k8s/devops-agent-secret.yaml` - Secret template (for reference)

## Support

For issues or questions:
1. Check workflow logs in GitHub Actions
2. Review pod logs: `kubectl logs -n azure-devops-agents ...`
3. Check Azure DevOps agent pool status
4. See troubleshooting section above
