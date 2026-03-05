# MediaWorks - Pre-built media processing environment for MCP servers
# https://hub.docker.com/r/sagacient/mediaworks

FROM ubuntu:24.04

LABEL org.opencontainers.image.title="MediaWorks"
LABEL org.opencontainers.image.description="Pre-built media processing environment with ffmpeg, LibreOffice, and python-pptx for MCP servers"
LABEL org.opencontainers.image.source="https://github.com/sagacient/mediaworks"
LABEL org.opencontainers.image.licenses="MPL-2.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # FFmpeg for audio/video processing
    ffmpeg \
    # LibreOffice Impress for PPT slide rendering
    libreoffice-impress \
    libreoffice-common \
    # Python runtime
    python3 \
    python3-pip \
    python3-venv \
    # Fonts for LibreOffice rendering
    fonts-liberation \
    fonts-dejavu-core \
    fonts-noto-core \
    # Utilities
    bash \
    coreutils \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages for PPT media extraction
RUN pip3 install --no-cache-dir --break-system-packages \
    'python-pptx>=1.0.0' \
    'Pillow>=11.0.0'

# Create non-root user for security
RUN useradd -m -s /bin/bash -u 1000 mediaworks

# Create directories
RUN mkdir -p /data /output /scripts && \
    chown -R mediaworks:mediaworks /data /output

# Copy helper scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh && \
    chown -R mediaworks:mediaworks /scripts

# Switch to non-root user
USER mediaworks

# Set working directory
WORKDIR /home/mediaworks

# Default entrypoint
ENTRYPOINT ["bash"]
