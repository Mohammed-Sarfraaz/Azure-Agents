#!/bin/bash
set -e

# Variables
ACR_LOGIN_SERVER=$1
ACR_USERNAME=$2
ACR_PASSWORD=$3
IMAGE_NAME="devops-agent"
IMAGE_TAG="latest"

if [ -z "$ACR_LOGIN_SERVER" ] || [ -z "$ACR_USERNAME" ] || [ -z "$ACR_PASSWORD" ]; then
    echo "Usage: ./build-and-push.sh <acr-login-server> <acr-username> <acr-password>"
    exit 1
fi

# Build Docker image
echo "Building Docker image..."
docker build -t $IMAGE_NAME:$IMAGE_TAG ./docker

# Tag image for ACR
echo "Tagging image for ACR..."
docker tag $IMAGE_NAME:$IMAGE_TAG $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG

# Login to ACR
echo "Logging in to ACR..."
echo $ACR_PASSWORD | docker login -u $ACR_USERNAME --password-stdin $ACR_LOGIN_SERVER

# Push image to ACR
echo "Pushing image to ACR..."
docker push $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG

echo "Image pushed successfully to $ACR_LOGIN_SERVER/$IMAGE_NAME:$IMAGE_TAG"
