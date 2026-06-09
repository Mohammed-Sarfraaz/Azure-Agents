FROM ubuntu:24.04

# Define the target architecture environment variables
ENV TARGETARCH="linux-arm64"

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies for the Azure Pipelines agent and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    iputils-ping \
    jq \
    libcurl4 \
    libicu-dev \
    libunwind8 \
    software-properties-common \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /azp
RUN chown -R 1000:1000 /azp

COPY ./start.sh .
RUN chmod +x ./start.sh && chown 1000:1000 ./start.sh

ENTRYPOINT [ "./start.sh" ]