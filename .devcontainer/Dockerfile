FROM python:3.10

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Install pip and setuptools
RUN pip install --upgrade pip setuptools wheel

# Create a non-root user (optional but recommended)
RUN useradd -m -s /bin/bash devuser

# Switch to non-root user (optional)
# USER devuser
