# Copyright 2025 The MathWorks, Inc.
ARG BASE_IMAGE=padv:latest

FROM ${BASE_IMAGE}

RUN export DEBIAN_FRONTEND=noninteractive \
    && sudo apt-get update \
    && sudo apt-get install --no-install-recommends --yes \
    python3 3.12 \
    python3-pip \
    git \
    curl \
    && sudo apt-get clean \
    && sudo apt-get autoremove \
    && sudo rm -rf /var/lib/apt/lists/*

RUN pip install colorlog

# Installing jfrog cli, azure cli and aws cli
RUN curl -fL https://getcli.jfrog.io/setup | sh
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo /bin/bash
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
        sudo unzip awscliv2.zip && \
        sudo ./aws/install && \
        sudo rm -rf awscliv2.zip aws

###############################################
#      Support Azure DevOps container job
##############################################
# Install Node.js LTS and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo /bin/bash - \
    && sudo apt-get install -y nodejs \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

RUN sudo chmod u+s /usr/sbin/groupadd /usr/sbin/usermod && \
    sudo touch /etc/sudoers && \
    sudo chmod u+w /etc/sudoers && \
    sudo rm -f /bin/su && \
    sudo bash -c "echo '#!/usr/bin/env bash' > /bin/su" && \
    sudo bash -c "echo \"echo 'su has been disabled in this container'\" >> /bin/su"  && \
    sudo chmod +x /bin/su

ENTRYPOINT [""]