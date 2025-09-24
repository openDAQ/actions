# Dockerfile for act with GitHub CLI support
FROM ghcr.io/catthehacker/ubuntu:act-latest

# Install GitHub CLI
RUN apt-get update && \
    apt-get install -y curl gpg && \
    # Add GitHub CLI repository key
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    # Add repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    # Update package list and install gh
    apt-get update && \
    apt-get install -y gh && \
    # Clean apt cache to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Verify installation
RUN gh --version

# Set working directory
WORKDIR /github/workspace

# Image metadata
LABEL org.opencontainers.image.title="Act Ubuntu with GitHub CLI"
LABEL org.opencontainers.image.description="Ubuntu image for act with GitHub CLI pre-installed"
LABEL org.opencontainers.image.source="https://github.com/openDAQ/openDAQ"

