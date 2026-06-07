FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    git \
    iputils-ping \
    jq \
    libssl-dev \
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

RUN mkdir -p /home/agentuser/myagent && cd /home/agentuser/myagent

COPY start.sh /home/agentuser/start.sh
RUN chmod +x /home/agentuser/start.sh

USER agentuser
WORKDIR /home/agentuser/myagent

ENTRYPOINT ["/home/agentuser/start.sh"]
