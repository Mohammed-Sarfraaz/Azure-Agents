<!-- GitHub Secrets Configuration Template -->
# GitHub Secrets Quick Reference

Copy and paste this checklist to ensure all required secrets are configured:

## Required GitHub Repository Secrets

### Azure Service Principal Secrets
- [ ] `AZURE_CLIENT_ID` - Client ID from Service Principal JSON
- [ ] `AZURE_TENANT_ID` - Tenant ID from Service Principal JSON  
- [ ] `AZURE_SUBSCRIPTION_ID` - Subscription ID from Service Principal JSON

### Azure Infrastructure Secrets
- [ ] `AZURE_RESOURCE_GROUP` - Resource group name (e.g., `rg-aksdemo-dev-canadacentral`)
- [ ] `AKS_CLUSTER_NAME` - AKS cluster name (e.g., `aks-aksdemo-dev`)
- [ ] `ACR_LOGIN_SERVER` - ACR login server (e.g., `myacr.azurecr.io`)

### Azure DevOps Secrets
- [ ] `AZURE_DEVOPS_ORG_URL` - Organization URL (e.g., `https://dev.azure.com/myorg`)
- [ ] `AZURE_DEVOPS_PAT_TOKEN` - Personal Access Token with Agent Pools and Deployment group scopes

## How to Add Secrets in GitHub

1. Go to your repository on GitHub
2. Click **Settings** (top navigation)
3. In left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Enter the secret name and value
6. Click **Add secret**

Repeat for each secret above.

## Getting Secret Values

### Terraform Outputs
```bash
# Run these in your Terraform directory
terraform output -raw resource_group_name
terraform output -raw aks_name
terraform output -raw acr_login_server
```

### Service Principal (One-time setup)
```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az ad sp create-for-rbac \
  --name "github-actions-devops-agent" \
  --role "Contributor" \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --json-auth
```

Copy the JSON output and extract:
- `clientId` → AZURE_CLIENT_ID
- `tenantId` → AZURE_TENANT_ID
- `subscriptionId` → AZURE_SUBSCRIPTION_ID

### Azure DevOps PAT
1. Go to https://dev.azure.com/YOUR_ORG
2. Click User Settings (top-right avatar)
3. Select "Personal access tokens"
4. Click "New Token"
5. Create with scopes: Agent Pools (Read & manage), Deployment group (Read & manage)
6. Copy token → AZURE_DEVOPS_PAT_TOKEN

## Verification

After adding all secrets, you can verify them in GitHub:

```bash
# Secrets are masked in logs - GitHub will show "***" in workflow logs
# You cannot view secret values after creation (by design)
# You can only update or delete them
```

## Workflow File Location
`.github/workflows/deploy-devops-agent.yml`

## Next Steps
1. Add all secrets to your GitHub repository
2. Push code to `main` branch (or use manual workflow trigger)
3. Go to **Actions** tab to monitor the workflow
4. Check Azure DevOps agent pool for registered agent
