# Docker Deployment

<cite>
**Referenced Files in This Document**   
- [Dockerfile](file://Dockerfile)
- [docker-compose.yml](file://docker-compose.yml)
- [docker-compose.gpu.override.yml](file://docker-compose.gpu.override.yml)
- [docker-compose.unraid.yml](file://docker-compose.unraid.yml)
- [scripts/ldr_entrypoint.sh](file://scripts/ldr_entrypoint.sh)
- [scripts/ollama_entrypoint.sh](file://scripts/ollama_entrypoint.sh)
- [cookiecutter-docker/{{cookiecutter.config_name}}/docker-compose.{{cookiecutter.config_name}}.yml](file://cookiecutter-docker/{{cookiecutter.config_name}}/docker-compose.{{cookiecutter.config_name}}.yml)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Dockerfile Structure](#dockerfile-structure)
3. [Multi-Stage Build Process](#multi-stage-build-process)
4. [docker-compose Configuration](#docker-compose-configuration)
5. [Entry Point Scripts](#entry-point-scripts)
6. [Image Building and Container Runtime](#image-building-and-container-runtime)
7. [Security Best Practices](#security-best-practices)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Production Considerations](#production-considerations)

## Introduction

The Local Deep Research (LDR) system provides a comprehensive Docker-based deployment solution for AI-powered research assistant capabilities. This documentation details the complete Docker deployment architecture, including the multi-stage Dockerfile, docker-compose configurations, entry point scripts, and production deployment considerations.

The Docker deployment enables users to run LDR with various configuration options, from CPU-only operation to GPU-accelerated inference, with support for multiple deployment environments including standard Docker, Unraid, and custom configurations through Cookiecutter templates.

**Section sources**
- [README.md](file://README.md#L1-L513)

## Dockerfile Structure

The Dockerfile implements a multi-stage build process designed for security, reproducibility, and optimal performance. The build process is divided into distinct stages that separate build dependencies from runtime requirements.

### Base Image Selection

The Dockerfile uses `python:3.13.9-slim` as the base image, which provides a minimal Python environment with a small attack surface. The image is pinned to a specific digest for supply chain security:

```dockerfile
FROM python:3.13.9-slim@sha256:326df678c20c78d465db501563f3492d17c42a4afe33a1f2bf5406a1d56b0e86 AS builder-base
```

This approach ensures reproducible builds and protects against supply chain attacks by verifying the exact image version.

### Build Dependencies

The builder stage installs essential system dependencies for both the Python backend and frontend components:

- **SQLCipher**: For encrypted database storage with AES-256 encryption
- **Node.js 22.x LTS**: For building the frontend assets
- **Build tools**: Required for compiling Python packages
- **GPG verification**: For secure package repository validation

The Dockerfile implements strict security practices by verifying the GPG fingerprint of the NodeSource repository before adding it to ensure the integrity of downloaded packages.

### Runtime Dependencies

The production stage (`ldr`) includes only the necessary runtime dependencies:

- **SQLCipher runtime libraries**: For database operations
- **gosu**: For safe user switching in the entrypoint script
- **WeasyPrint dependencies**: For PDF generation capabilities
- **GLib and GObject libraries**: For system-level operations

This minimal approach reduces the container's attack surface and improves security posture.

**Section sources**
- [Dockerfile](file://Dockerfile#L1-L244)

## Multi-Stage Build Process

The Dockerfile implements a sophisticated multi-stage build process that optimizes for both development and production use cases.

### Builder Stage

The `builder` stage inherits from `builder-base` and performs the following operations:

1. **Install npm dependencies** using `npm ci` for reproducible builds
2. **Build frontend assets** using the Vite build system
3. **Install Python dependencies** using PDM with production-only packages

```dockerfile
FROM builder-base AS builder
RUN npm ci \
    && npm run build \
    && pdm install --prod --no-editable
```

This separation ensures that build tools and development dependencies are not included in the final production image.

### Test Stage

The `ldr-test` stage extends the builder-base with additional dependencies required for testing:

- **Xvfb and xauth**: For headless browser testing
- **Chromium dependencies**: Required for Puppeteer and Playwright
- **Additional system libraries**: For comprehensive test coverage

The test container is configured to use Playwright's Chromium installation, with environment variables set to ensure Puppeteer uses the same Chrome binary, avoiding redundant downloads and ensuring consistency.

### Production Stage

The production stage (`ldr`) implements several security best practices:

- **Non-root user**: Creates a dedicated `ldruser` with UID 1000
- **Volume configuration**: Sets up persistent storage for configuration and data
- **Health checks**: Implements container health monitoring
- **Proper permissions**: Ensures correct ownership and access controls

The production image copies only the compiled Python virtual environment from the builder stage, resulting in a minimal runtime image that excludes build tools and development dependencies.

**Section sources**
- [Dockerfile](file://Dockerfile#L1-L244)

## docker-compose Configuration

The LDR system provides multiple docker-compose configuration files to support different deployment scenarios and requirements.

### Base Configuration

The base `docker-compose.yml` file defines a complete stack with three primary services:

```yaml
services:
  local-deep-research:
    image: localdeepresearch/local-deep-research:latest
    ports:
      - "5000:5000"
    environment:
      - LDR_WEB_HOST=0.0.0.0
      - LDR_WEB_PORT=5000
      - LDR_DATA_DIR=/data
      - LDR_LLM_OLLAMA_URL=http://ollama:11434
      - LDR_SEARCH_ENGINE_WEB_SEARXNG_DEFAULT_PARAMS_INSTANCE_URL=http://searxng:8080
    volumes:
      - ldr_data:/data
      - ldr_scripts:/scripts
      - ./local_collections/personal_notes:/local_collections/personal_notes/
      - ./local_collections/project_docs:/local_collections/project_docs/
      - ./local_collections/research_papers:/local_collections/research_papers/
    restart: unless-stopped
    depends_on:
      ollama:
        condition: service_healthy
      searxng:
        condition: service_started

  ollama:
    image: ollama/ollama:latest@sha256:8850b8b33936b9fb246e7b3e02849941f1151ea847e5fb15511f17de9589aea1
    entrypoint: "/scripts/ollama_entrypoint.sh ${MODEL:-gemma3:12b}"
    healthcheck:
      test: [ "CMD", "ollama", "show", "${MODEL:-gemma3:12b}" ]
      interval: 10s
      timeout: 5s
      start_period: 10m
      retries: 2
    environment:
      OLLAMA_KEEP_ALIVE: '30m'
    volumes:
      - ollama_data:/root/.ollama
      - ldr_scripts:/scripts

  searxng:
    image: searxng/searxng:latest@sha256:6dd0dffc05a75d92bbacd858953b4e93b8f709403c3fb1fb8a33ca8fd02e40a4
    volumes:
      - searxng_data:/etc/searxng
```

Key features of the base configuration:

- **Named volumes**: For persistent data storage across container restarts
- **Service dependencies**: Ensures proper startup order with health checks
- **Environment variables**: Configures critical application settings
- **Document collections**: Mount points for local document search

### GPU Override Configuration

The `docker-compose.gpu.override.yml` file provides NVIDIA GPU acceleration capabilities:

```yaml
services:
  ollama:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [ gpu ]
```

This override file follows Docker's recommended pattern for GPU support, allowing users to combine it with the base configuration for GPU-accelerated inference.

### Unraid Configuration

The `docker-compose.unraid.yml` file adapts the deployment for Unraid systems by replacing named volumes with host paths:

```yaml
services:
  local-deep-research:
    volumes:
      - /mnt/user/appdata/local-deep-research/data:/data
      - /mnt/user/appdata/local-deep-research/scripts:/scripts
  ollama:
    volumes:
      - /mnt/user/appdata/local-deep-research/ollama:/root/.ollama
  searxng:
    volumes:
      - /mnt/user/appdata/local-deep-research/searxng:/etc/searxng
```

This configuration follows Unraid best practices by using the appdata share for persistent storage.

### Cookiecutter Template

The Cookiecutter template provides an interactive way to generate custom docker-compose configurations:

```yaml
services:
  local-deep-research:
    {% if cookiecutter.build %}
    build:
      context: .
      dockerfile: Dockerfile
      target: ldr
    {% else %}
    image: localdeepresearch/local-deep-research
    {% endif %}
```

The template supports various configuration options including:
- Building from source vs. using pre-built images
- Host network mode vs. bridge networking
- GPU acceleration (NVIDIA or AMD)
- Custom port and IP configurations

**Section sources**
- [docker-compose.yml](file://docker-compose.yml#L1-L184)
- [docker-compose.gpu.override.yml](file://docker-compose.gpu.override.yml#L1-L32)
- [docker-compose.unraid.yml](file://docker-compose.unraid.yml#L1-L40)
- [cookiecutter-docker/{{cookiecutter.config_name}}/docker-compose.{{cookiecutter.config_name}}.yml](file://cookiecutter-docker/{{cookiecutter.config_name}}/docker-compose.{{cookiecutter.config_name}}.yml#L1-L116)

## Entry Point Scripts

The LDR system includes two specialized entry point scripts that handle container initialization and service orchestration.

### LDR Entry Point Script

The `ldr_entrypoint.sh` script performs critical initialization tasks:

```bash
#!/bin/bash
set -e

echo "Setting up /data directory permissions..."

# Create required subdirectories
mkdir -p /data/logs
mkdir -p /data/cache
mkdir -p /data/research_outputs
mkdir -p /data/encrypted_databases

# Set permissions to 700 (owner-only access)
chmod 700 /data/logs
chmod 700 /data/cache
chmod 700 /data/research_outputs
chmod 700 /data/encrypted_databases

# Fix ownership
chown -R ldruser:ldruser /data

# Create matplotlib cache directory
mkdir -p /home/ldruser/.config/matplotlib
chown -R ldruser:ldruser /home/ldruser/.config
chmod -R 700 /home/ldruser/.config

echo "Starting LDR application as ldruser..."
exec gosu ldruser "$@"
```

Key responsibilities:
- **Directory creation**: Ensures all required data directories exist
- **Permission management**: Sets secure permissions (700) for sensitive data
- **Ownership fixing**: Changes ownership to the non-root `ldruser`
- **User switching**: Uses `gosu` to drop privileges before starting the application

This script addresses the common Docker issue where volumes are created with root ownership but need to be accessible by a non-root application user.

### Ollama Entry Point Script

The `ollama_entrypoint.sh` script orchestrates Ollama service startup and model management:

```bash
#!/bin/bash
set -e

usage() {
  echo "Usage: $0 <model_name>"
  exit 1
}

# Check if a model name is provided
if [ "$#" -ne 1 ]; then
  usage
fi

MODEL_NAME=$1

# Start the main Ollama application
ollama serve &

# Wait for the Ollama application to be ready
while ! ollama ls; do
  echo "Waiting for Ollama service to be ready..."
  sleep 10
done
echo "Ollama service is ready."

# Pull the model
echo "Pulling the $MODEL_NAME with ollama pull..."
if ollama pull "$MODEL_NAME"; then
  echo "Model pulled successfully."
else
  echo "Failed to pull model."
  exit 1
fi

# Run ollama forever
sleep infinity
```

Key features:
- **Service orchestration**: Starts the Ollama service in the background
- **Readiness checking**: Waits for the service to be fully available
- **Model management**: Automatically pulls the specified model
- **Error handling**: Validates model download success
- **Process management**: Uses `sleep infinity` to keep the container running

The script uses the `MODEL` environment variable (with `gemma3:12b` as default) to determine which model to download, allowing users to customize the model via Docker environment variables.

**Section sources**
- [scripts/ldr_entrypoint.sh](file://scripts/ldr_entrypoint.sh#L1-L36)
- [scripts/ollama_entrypoint.sh](file://scripts/ollama_entrypoint.sh#L1-L40)

## Image Building and Container Runtime

### Image Building Process

The LDR Docker image can be built using the standard Docker build command:

```bash
docker build -t localdeepresearch/local-deep-research:latest .
```

For development builds, you can specify the target stage:

```bash
# Build the test image
docker build -t ldr-test --target ldr-test .

# Build the production image
docker build -t ldr-prod --target ldr .
```

The build process automatically handles dependency installation, frontend compilation, and package optimization.

### Container Runtime Configuration

When running the container, several configuration options are available:

#### Environment Variables

Key environment variables for configuration:

| Variable | Purpose | Default |
|--------|--------|--------|
| `LDR_WEB_HOST` | Web server bind address | `0.0.0.0` |
| `LDR_WEB_PORT` | Web server port | `5000` |
| `LDR_DATA_DIR` | Data directory path | `/data` |
| `MODEL` | Ollama model to download | `gemma3:12b` |
| `OLLAMA_KEEP_ALIVE` | Model keep-alive duration | `30m` |

#### Volume Mounts

Essential volume mounts for persistent data:

```bash
-v ldr_data:/data \
-v ldr_scripts:/scripts \
-v ldr_rag_cache:/root/.cache/local_deep_research/rag_indices
```

For local document search, additional mounts can be added:

```bash
-v ./local_collections/personal_notes:/local_collections/personal_notes/
-v ./local_collections/project_docs:/local_collections/project_docs/
-v ./local_collections/research_papers:/local_collections/research_papers/
```

#### Resource Allocation

For optimal performance, consider resource allocation:

```bash
# CPU and memory limits
--cpus=4 \
--memory=8g \

# For GPU acceleration
--gpus=all \
--runtime=nvidia
```

The specific requirements depend on the chosen LLM model and workload characteristics.

**Section sources**
- [Dockerfile](file://Dockerfile#L1-L244)
- [docker-compose.yml](file://docker-compose.yml#L1-L184)

## Security Best Practices

The LDR Docker deployment implements multiple security best practices to protect user data and system integrity.

### User Permissions

The production container runs as a non-root user (`ldruser` with UID 1000), following the principle of least privilege:

```dockerfile
RUN groupadd -r ldruser && useradd -r -g ldruser -u 1000 -m -d /home/ldruser ldruser
```

This prevents potential privilege escalation attacks and limits the impact of any security vulnerabilities.

### Read-Only Filesystems

While not explicitly configured as read-only, the container design minimizes writable areas. Only the `/data` volume and user home directory are writable, reducing the attack surface.

### Secret Management

The system handles secrets through environment variables, with recommendations to use Docker secrets or external secret management systems in production:

```yaml
# In production, use Docker secrets instead of environment variables
secrets:
  - openai_api_key
  - anthropic_api_key

environment:
  - LDR_LLM_OPENAI_API_KEY=/run/secrets/openai_api_key
```

### Network Security

The docker-compose configuration implements proper network isolation:

```yaml
networks:
  ldr-network:
```

Services communicate through this dedicated network using service names as hostnames, avoiding the use of localhost which doesn't work between containers.

### Data Encryption

All user data is protected with SQLCipher encryption using AES-256, providing signal-level security for stored information. The encryption keys are derived using PBKDF2-SHA512 with 256,000 iterations to prevent brute-force attacks.

### Additional Security Measures

- **GPG verification**: NodeSource repository GPG key is verified during build
- **Minimal base image**: Reduces attack surface
- **Regular updates**: Base images and dependencies are kept current
- **Security scanning**: Integrated with CodeQL, Semgrep, and OpenSSF Scorecard

**Section sources**
- [Dockerfile](file://Dockerfile#L1-L244)
- [docker-compose.yml](file://docker-compose.yml#L1-L184)
- [docs/security/CODEQL_GUIDE.md](file://docs/security/CODEQL_GUIDE.md#L1-L194)

## Troubleshooting Guide

This section addresses common Docker deployment issues and their solutions.

### Volume Mounting Problems

**Issue**: Permission errors when accessing mounted volumes.

**Solution**: Ensure the entry point script has proper permissions and the `ldruser` has ownership of the mounted directories. The `ldr_entrypoint.sh` script automatically handles this, but if issues persist:

```bash
# Manually fix permissions
docker exec -it local-deep-research chown -R ldruser:ldruser /data
```

**Issue**: Data not persisting across container restarts.

**Solution**: Verify that named volumes or host paths are correctly configured in docker-compose.yml:

```yaml
volumes:
  - ldr_data:/data  # Named volume
  # OR
  - /host/path/data:/data  # Host path
```

### Network Connectivity Issues

**Issue**: Services cannot communicate with each other.

**Solution**: Ensure all services are on the same network and use the correct service names:

```yaml
services:
  local-deep-research:
    networks:
      - ldr-network
    environment:
      - LDR_LLM_OLLAMA_URL=http://ollama:11434  # Use service name, not localhost
```

**Issue**: Cannot access the web interface.

**Solution**: Verify port mapping and firewall settings:

```yaml
ports:
  - "5000:5000"  # Host:Container port mapping
```

Test connectivity from within the container:
```bash
docker exec -it local-deep-research wget -O- http://localhost:5000
```

### Permission Errors

**Issue**: "Permission denied" errors when writing to volumes.

**Solution**: The `ldr_entrypoint.sh` script should handle permission fixing, but if issues occur:

1. Verify the script is executable:
```bash
chmod +x scripts/ldr_entrypoint.sh
```

2. Check the container user:
```bash
docker exec -it local-deep-research id
```

3. Manually fix permissions if needed:
```bash
docker exec -it local-deep-research chown -R ldruser:ldruser /data
```

### Ollama-Specific Issues

**Issue**: Ollama service not starting or model not downloading.

**Solution**: Check the Ollama container logs:
```bash
docker logs ollama_service
```

Verify the model name is correct and available:
```bash
docker exec -it ollama_service ollama list
```

Ensure sufficient disk space is available for model downloads (5-15GB per model).

**Issue**: GPU not being utilized.

**Solution**: Verify NVIDIA Container Toolkit is installed and configured:
```bash
nvidia-smi  # Should show GPU information
docker inspect ollama_service | grep -i runtime  # Should show "nvidia"
```

### General Troubleshooting Commands

```bash
# Check container status
docker ps -a

# View container logs
docker logs local-deep-research
docker logs ollama_service
docker logs searxng

# Execute commands in running container
docker exec -it local-deep-research bash

# Check disk space
docker system df

# Clean up unused resources
docker system prune
```

**Section sources**
- [docker-compose.yml](file://docker-compose.yml#L1-L184)
- [scripts/ldr_entrypoint.sh](file://scripts/ldr_entrypoint.sh#L1-L36)
- [scripts/ollama_entrypoint.sh](file://scripts/ollama_entrypoint.sh#L1-L40)
- [docs/deployment/unraid.md](file://docs/deployment/unraid.md#L1-L457)

## Production Considerations

### Logging Strategies

The LDR system supports multiple logging approaches for production deployments:

#### File Logging

Enable file logging through environment variables or web interface settings:

```yaml
environment:
  - LDR_ENABLE_FILE_LOGGING=true
```

Logs are stored in the `/data/logs` directory, which should be backed up regularly.

#### Centralized Logging

For container orchestration platforms, integrate with centralized logging solutions:

```yaml
# Example with Fluentd
logging:
  driver: "fluentd"
  options:
    fluentd-address: "fluentd-host:24224"
    tag: "local-deep-research"
```

#### Log Rotation

Implement log rotation to prevent disk space issues:

```bash
# Add logrotate configuration
/var/lib/docker/volumes/ldr_data/_data/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

### Health Checks

The production container includes a comprehensive health check:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/api/v1/health')" || exit 1
```

This allows container orchestration systems to monitor container health and perform automatic restarts if needed.

### Backup Procedures

Implement regular backup procedures for critical data:

#### Automated Backups

```bash
#!/bin/bash
# backup-ldr.sh
BACKUP_DIR="/backups/ldr"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/ldr_backup_${DATE}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p ${BACKUP_DIR}

# Create compressed backup of data directory
tar -czf ${BACKUP_FILE} /data

# Remove backups older than 30 days
find ${BACKUP_DIR} -name "ldr_backup_*.tar.gz" -mtime +30 -delete
```

#### Backup Content

Critical data to include in backups:
- `/data` directory: Contains user databases, research outputs, cache, and logs
- Configuration files: Custom settings and preferences
- Document collections: If stored within the container

#### Backup Schedule

Recommended backup schedule:
- **Daily**: Incremental backups of data changes
- **Weekly**: Full backups with compression
- **Monthly**: Offsite backups for disaster recovery

### Monitoring and Alerting

Implement monitoring for production deployments:

#### Resource Monitoring

Monitor CPU, memory, and disk usage:
```bash
# Use Docker stats
docker stats local-deep-research ollama_service searxng
```

Set up alerts for:
- High CPU usage (>80% for extended periods)
- Memory pressure (approaching container limits)
- Disk space utilization (>80%)

#### Application Performance

Monitor key performance metrics:
- Research completion times
- API response latencies
- Error rates
- Cache hit ratios

#### Alerting

Configure alerts for:
- Service downtime
- Health check failures
- High error rates
- Resource exhaustion

### High Availability

For mission-critical deployments, consider high availability configurations:

#### Load Balancing

Use a reverse proxy (e.g., Nginx, Traefik) to distribute traffic across multiple LDR instances.

#### Database Replication

For large-scale deployments, consider external database solutions with replication capabilities.

#### Auto-Scaling

In cloud environments, configure auto-scaling based on load metrics to handle variable workloads.

**Section sources**
- [Dockerfile](file://Dockerfile#L1-L244)
- [docker-compose.yml](file://docker-compose.yml#L1-L184)
- [scripts/ldr_entrypoint.sh](file://scripts/ldr_entrypoint.sh#L1-L36)