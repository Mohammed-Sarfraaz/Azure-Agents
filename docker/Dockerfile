FROM ubuntu:22.04


ENV DEBIAN_FRONTEND=noninteractive

# Make apt more resilient and verbose on failure to aid debugging under buildx/qemu
RUN apt-get update -o Acquire::Retries=3 || (echo "apt update failed" && cat /etc/apt/sources.list && ls -la /etc/apt/sources.list.d && exit 1)

RUN apt-get install -y --no-install-recommends \
    ca-certificates \
    apt-transport-https \
    gnupg \
    curl \
    git \
    iputils-ping \
    jq \
    libssl-dev \
    liblttng-ust0 \
    libkrb5-3 \
    zlib1g \
    libicu-dev \
    libcurl4 \
    libffi-dev \
    python3 \
    python3-dev \
    python3-pip \
    unzip \
    wget \
    zip \
    || (echo "apt install failed" && tail -n +1 /var/log/apt/term.log || true) && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/agentuser agentuser

WORKDIR /home/agentuser

ENV AGENT_ALLOW_RUNASROOT=true

# Create agent directory and ensure agentuser owns it so downloads succeed
RUN mkdir -p /home/agentuser/myagent && chown -R agentuser:agentuser /home/agentuser/myagent

COPY start.sh /home/agentuser/start.sh
RUN chmod +x /home/agentuser/start.sh && chown agentuser:agentuser /home/agentuser/start.sh

USER agentuser
WORKDIR /home/agentuser/myagent

ENTRYPOINT ["/home/agentuser/start.sh"]
