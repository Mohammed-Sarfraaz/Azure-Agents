FROM ubuntu:24.04

# Define the target architecture environment variables
ENV TARGETARCH="linux-arm64"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies for the Azure Pipelines agent and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg \
    iputils-ping \
    jq \
    libcurl4 \
    libicu-dev \
    libunwind8 \
    netcache \
    software-properties-common \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x ./start.sh

ENTRYPOINT [ "./start.sh" ]