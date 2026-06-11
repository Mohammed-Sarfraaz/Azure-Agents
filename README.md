# Azure DevOps Agent on AKS

This repository contains everything needed to build, publish, and deploy a self-hosted Azure DevOps agent into an AKS cluster using Docker, Kubernetes manifests, and GitHub Actions.

## Project Overview

The project delivers an Azure DevOps agent as a containerized workload running in Azure Kubernetes Service (AKS). The agent image is built from the `docker/` folder, pushed to Azure Container Registry (ACR), and deployed using Kubernetes manifests in the `k8s/` folder.

The `GitHub Actions` workflow automates the build, push, and deployment process so that changes to the repository can be deployed reliably and repeatably.

## Repository Structure

- `DEVOPS_AGENT_SETUP.md` - detailed deployment guide for AKS
- `GITHUB_ACTIONS_GUIDE.md` - instructions for GitHub Actions setup and use
- `GITHUB_SECRETS_SETUP.md` - GitHub Secrets configuration checklist
- `GITHUB_WORKFLOW_SETUP.md` - workflow configuration and setup details
- `docker/` - Docker image assets for the Azure DevOps agent
  - `Dockerfile` - image build instructions
  - `start.sh` - startup script for the agent container
- `k8s/` - Kubernetes manifests for deployment uisng Kubectl or Argocd
  - `devops-agent-deployment.yaml` - deployment manifest for the agent pod
  - `devops-agent-secret.yaml` - secret manifest for Azure DevOps credentials
- `scripts/` - helper scripts
  - `build-and-push.sh` - builds and pushes the container image to ACR
- `.github/workflows/deploy-devops-agent.yml` - GitHub Actions workflow for CI/CD

## Key Features

- Containerized Azure DevOps self-hosted agent
- AKS deployment with namespace, service account, secret, and deployment manifest
- ACR-based container registry integration
- GitHub Actions workflow to build, tag, push, and deploy the image
- Secure credential storage using Kubernetes secrets and GitHub repository secrets

## Prerequisites

- Azure subscription with AKS and ACR deployed
- Azure DevOps organization with a Personal Access Token (PAT)
- GitHub repository access to configure Actions secrets
- Docker installed locally (for local image build/push)
- `kubectl` configured for your AKS cluster
- Azure CLI installed for authentication and cluster access

In Azure DevOps, verify the agent appears under Organization Settings → Agent pools.

## GitHub Actions Integration

The repository includes a CI/CD workflow at:

- `.github/workflows/deploy-devops-agent.yml`

This workflow does the following:

- builds the Docker image
- tags and pushes it to ACR
- authenticates to Azure using GitHub Secrets
- connects to AKS
- creates the Kubernetes namespace and secret
- deploys the Azure DevOps agent to AKS
- validates rollout status

### Required GitHub Secrets

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `AZURE_RESOURCE_GROUP`
- `AKS_CLUSTER_NAME`
- `ACR_LOGIN_SERVER`
- `AZURE_DEVOPS_ORG_URL`
- `AZURE_DEVOPS_PAT_TOKEN`

Use `GITHUB_SECRETS_SETUP.md` for secret creation guidance.

## Troubleshooting

Common issues and remediation:

- Image pull failures: verify ACR login server and registry access
- Secret or PAT problems: confirm `AZURE_DEVOPS_ORG_URL` and `AZURE_DEVOPS_PAT_TOKEN`
- Pod crashes: inspect logs with `kubectl logs -n azure-devops-agents -f deployment/azure-devops-agent`
- Deployment rollouts: use `kubectl describe deployment -n azure-devops-agents`

## Notes

- The deployment currently uses `imagePullPolicy: Always` to ensure AKS grabs the latest image.
- The container runs as user `1000` and does not allow privilege escalation.
- The default agent name is `aks-devops-agent` and the agent pool is set to `Default`.

## Reference Documentation

- `DEVOPS_AGENT_SETUP.md` - AKS deployment guide
- `GITHUB_ACTIONS_GUIDE.md` - GitHub Actions workflow guide
- `GITHUB_WORKFLOW_SETUP.md` - workflow setup instructions
- `GITHUB_SECRETS_SETUP.md` - GitHub Secrets checklist

## License

This repository does not include a license file. Add a `LICENSE` if you want to define reuse permissions.
