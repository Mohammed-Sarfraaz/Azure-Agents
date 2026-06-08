FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
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
    && rm -rf /var/lib/apt/lists/*

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
