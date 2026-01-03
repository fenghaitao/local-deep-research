# Unraid Server Deployment

<cite>
**Referenced Files in This Document**   
- [local-deep-research.xml](file://unraid-templates/local-deep-research.xml)
- [unraid.md](file://docs/deployment/unraid.md)
- [docker-compose.yml](file://docker-compose.yml)
- [docker-compose.unraid.yml](file://docker-compose.unraid.yml)
- [docker-compose.gpu.override.yml](file://docker-compose.gpu.override.yml)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Unraid Template Structure](#unraid-template-structure)
3. [Installation Methods](#installation-methods)
4. [Container Configuration](#container-configuration)
5. [Storage and Data Management](#storage-and-data-management)
6. [Performance Tuning](#performance-tuning)
7. [Backup and Restore Procedures](#backup-and-restore-procedures)
8. [Monitoring and Maintenance](#monitoring-and-maintenance)
9. [Troubleshooting Guide](#troubleshooting-guide)
10. [Conclusion](#conclusion)

## Introduction

Local Deep Research (LDR) is an AI-powered research assistant designed for systematic, deep research with proper citation tracking. This documentation provides comprehensive guidance for deploying LDR on Unraid servers, covering template configuration, container settings, storage considerations, performance optimization, and maintenance procedures.

The system supports multiple deployment methods on Unraid, including template installation, Docker Compose Manager, and manual configuration. LDR can run entirely locally with Ollama and SearXNG for privacy-focused research or integrate with cloud LLM providers like OpenAI, Anthropic, and Google.

**Section sources**
- [unraid.md](file://docs/deployment/unraid.md#L1-L50)
- [README.md](file://README.md#L38-L56)

## Unraid Template Structure

The Unraid template file (local-deep-research.xml) defines the container configuration for LDR deployment. The template includes essential settings for container operation, network configuration, and environment variables.

```xml
<Container version="2">
  <Name>LocalDeepResearch</Name>
  <Repository>localdeepresearch/local-deep-research</Repository>
  <Registry>https://hub.docker.com/r/localdeepresearch/local-deep-research</Registry>
  <Network>bridge</Network>
  <Shell>sh</Shell>
  <Privileged>false</Privileged>
  <Support>https://github.com/LearningCircuit/local-deep-research/issues</Support>
  <Project>https://github.com/LearningCircuit/local-deep-research</Project>
  <Overview>Local Deep Research (LDR) is an AI-powered research assistant that performs systematic research by breaking down complex questions, searching multiple sources in parallel, verifying information across sources, and creating comprehensive reports with proper citations.</Overview>
  <Category>Tools: Productivity: Network:Web</Category>
  <WebUI>http://[IP]:[PORT:5000]</WebUI>
  <TemplateURL>https://raw.githubusercontent.com/LearningCircuit/local-deep-research/main/unraid-templates/local-deep-research.xml</TemplateURL>
  <Icon>https://raw.githubusercontent.com/LearningCircuit/local-deep-research/main/docs/assets/logo.png</Icon>
```

The template includes comprehensive configuration options for web interface access, data directories, and environment variables that control LLM and search engine integration.

**Diagram sources**
- [local-deep-research.xml](file://unraid-templates/local-deep-research.xml#L1-L34)

**Section sources**
- [local-deep-research.xml](file://unraid-templates/local-deep-research.xml#L1-L34)

## Installation Methods

### Method 1: Template Installation (Recommended)

The template method provides the simplest deployment process:

1. Navigate to **Docker** tab → **Docker Repositories**
2. Add template repository: `https://github.com/LearningCircuit/local-deep-research`
3. Click **Add Container** → Select **LocalDeepResearch** from template
4. Configure paths (default: `/mnt/user/appdata/local-deep-research/`)
5. Click **Apply**

This method automatically configures the container with sensible defaults and proper volume mappings.

### Method 2: Docker Compose Manager Plugin

For users preferring Docker Compose:

1. Install "Docker Compose Manager" from Community Applications
2. Create a new stack with repository URL: `https://github.com/LearningCircuit/local-deep-research.git`
3. Set compose file to: `docker-compose.yml:docker-compose.unraid.yml`
4. For GPU support, add `docker-compose.gpu.override.yml` to the compose file list

The Docker Compose Manager approach allows for more complex configurations and easier management of multi-container setups.

### Method 3: Manual Docker Template

For advanced users requiring custom configurations:

1. Download the template:
```bash
wget -O /boot/config/plugins/dockerMan/templates-user/local-deep-research.xml \
  https://raw.githubusercontent.com/LearningCircuit/local-deep-research/main/unraid-templates/local-deep-research.xml
```

2. Go to **Docker** tab → **Add Container**
3. Select **LocalDeepResearch** from template dropdown
4. Customize configuration as needed
5. Click **Apply**

**Section sources**
- [unraid.md](file://docs/deployment/unraid.md#L13-L107)

## Container Configuration

### Volume Mappings

Proper volume configuration ensures data persistence and optimal performance:

| Container Path | Host Path (Recommended) | Purpose | Required |
|----------------|-------------------------|---------|----------|
| `/data` | `/mnt/user/appdata/local-deep-research/data` | User databases, research outputs, cache, logs | Yes |
| `/scripts` | `/mnt/user/appdata/local-deep-research/scripts` | Startup scripts for Ollama integration | Yes |
| `/root/.ollama` | `/mnt/user/appdata/local-deep-research/ollama` | Downloaded LLM models (5-15GB each) | If using Ollama |
| `/etc/searxng` | `/mnt/user/appdata/local-deep-research/searxng` | SearXNG configuration | If using SearXNG |
| `/local_collections/*` | `/mnt/user/documents/*` | Document directories for AI search | Optional |

**Performance Tip**: If your appdata share is set to "cache-only", use `/mnt/cache/appdata/local-deep-research/` instead for better performance by bypassing FUSE overhead.

### Port Configuration

The default web interface port is 5000. If this port is already in use:

1. In the template, change the **Host Port** (left side): `5050:5000`
2. Do **NOT** change the Container Port (right side) or `LDR_WEB_PORT` variable
3. Access WebUI at: `http://[unraid-ip]:5050`

### Environment Variables

#### Required Variables (Do Not Change)

These variables are pre-configured and essential for proper container operation:

| Variable | Value | Purpose |
|----------|-------|---------|
| `LDR_WEB_HOST` | `0.0.0.0` | Binds to all interfaces for Docker networking |
| `LDR_WEB_PORT` | `5000` | Internal container port |
| `LDR_DATA_DIR` | `/data` | Internal data directory path |

#### Service Connection Variables

Configure based on your deployment setup:

| Variable | Default | Description |
|----------|---------|-------------|
| `LDR_LLM_OLLAMA_URL` | `http://ollama:11434` | Use when Ollama is on custom network; use `http://[IP]:11434` for external instances |
| `LDR_SEARCH_ENGINE_WEB_SEARXNG_DEFAULT_PARAMS_INSTANCE_URL` | `http://searxng:8080` | Use when SearXNG is on custom network; configure external search in WebUI otherwise |

#### Optional LLM Configuration

Leave these empty unless you want to lock the configuration (prevents WebUI changes):

| Variable | Purpose |
|----------|---------|
| `LDR_LLM_PROVIDER` | Force LLM provider (ollama, openai, anthropic, google) |
| `LDR_LLM_MODEL` | Force specific model name |
| `LDR_LLM_OPENAI_API_KEY` | Lock OpenAI API key |
| `LDR_LLM_ANTHROPIC_API_KEY` | Lock Anthropic API key |
| `LDR_LLM_GOOGLE_API_KEY` | Lock Google API key |

**Recommendation**: Configure these via the WebUI Settings page instead of environment variables for easier management.

### Network Configuration

**Recommended**: Bridge Mode with Custom Network

For multi-container setups (LDR + Ollama + SearXNG):
- All containers should be on the same network: `ldr-network`
- Add `--network=ldr-network` to Extra Parameters for each container
- Containers can communicate using service names (e.g., `http://ollama:11434`)

**Alternative**: Individual Containers
- Use bridge network (default)
- Point to external services by IP: `http://192.168.1.100:11434`

**Section sources**
- [unraid.md](file://docs/deployment/unraid.md#L108-L169)
- [local-deep-research.xml](file://unraid-templates/local-deep-research.xml#L35-L53)

## Storage and Data Management

### Persistent Data Storage

LDR stores all user data in the configured data directory. The primary storage locations include:

- **User databases**: Encrypted SQLite databases with AES-256 encryption (SQLCipher)
- **Research outputs**: Generated reports and research findings
- **Cache**: Temporary files and search results
- **Logs**: Application and system logs

The data directory structure follows Unraid best practices with all data stored under `/mnt/user/appdata/local-deep-research/`.

### Cache Drive Usage

For optimal performance, consider using the cache drive for frequently accessed data:

1. Create a cache-only share for LDR data
2. Configure the container to use `/mnt/cache/appdata/local-deep-research/` as the host path
3. This bypasses FUSE overhead and improves I/O performance

### Array Integration

For long-term data storage and redundancy:

1. Ensure the appdata share is configured to use the array
2. Set appropriate mover settings to transfer data from cache to array
3. Monitor disk usage to ensure sufficient space for LLM models (5-15GB each)

**Section sources**
- [unraid.md](file://docs/deployment/unraid.md#L110-L123)
- [paths.py](file://src/local_deep_research/config/paths.py#L14-L40)

## Performance Tuning

### CPU Pinning

To optimize CPU utilization:

1. Identify available CPU cores on your Unraid system
2. In the container settings, use CPU pinning to dedicate specific cores to LDR
3. Reserve additional cores for Ollama when using local LLMs
4. Avoid pinning all CPU cores to maintain system responsiveness

### Memory Allocation

For optimal memory performance:

1. Allocate sufficient RAM based on your usage patterns:
   - Basic usage: 4-8GB
   - Local LLM processing: 16-32GB+
2. Monitor memory usage through the Unraid dashboard
3. Adjust allocation based on observed usage patterns

### GPU Passthrough for LLM Processing

To enable GPU acceleration for enhanced LLM processing:

#### Step 1: Install NVIDIA Driver Plugin

1. Go to **Apps** tab
2. Search for "Nvidia-Driver"
3. Install the plugin
4. Select appropriate driver version
5. Reboot Unraid

#### Step 2: Configure Docker for NVIDIA Runtime

Edit `/etc/docker/daemon.json`:
```json
{
  "registry-mirrors": [],
  "insecure-registries": [],
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
}
```

Restart Docker:
```bash
/etc/rc.d/rc.docker restart
```

#### Step 3: Enable GPU in Ollama Container

For Template Installation:
1. Edit Ollama container
2. In **Extra Parameters**, add: `--runtime=nvidia`
3. Add environment variables:
   - `NVIDIA_DRIVER_CAPABILITIES=all`
   - `NVIDIA_VISIBLE_DEVICES=all`
4. Apply

Verify GPU is working:
```bash
docker exec -it ollama_service nvidia-smi
```

**Section sources**
- [unraid.md](file://docs/deployment/unraid.md#L207-L269)
- [docker-compose.gpu.override.yml](file://docker-compose.gpu.override.yml#L1-L32)

## Backup and Restore Procedures

### Using Unraid's Appdata Backup Plugin

1. Install "CA Appdata Backup / Restore" from Community Applications
2. Add to backup paths:
```
/mnt/user/appdata/local-deep-research/
```
3. Schedule regular backups

### Manual Backup

```bash
# Backup data
tar -czf ldr_backup_$(date +%Y%m%d).tar.gz \
  /mnt/user/appdata/local-deep-research/data

# Restore data
tar -xzf ldr_backup_20250120.tar.gz -C /
```

### Backup Recommendations

**Critical**: `/mnt/user/appdata/local-deep-research/data` (user databases, research outputs)

**Optional**: 
- `/mnt/user/appdata/local-deep-research/ollama` (models can be re-downloaded)
- `/mnt/user/appdata/local-deep-research/searxng` (minimal config)

**Section sources**
- [unraid.md](file://docs/deployment/unraid.md#L271-L297)

## Monitoring and Maintenance

### Dashboard Monitoring

Monitor system performance through the Unraid dashboard:

1. **CPU Usage**: Watch for sustained high utilization
2. **Memory Usage**: Monitor for memory pressure
3. **Disk Usage**: Track storage consumption, especially for LLM models
4. **Network Activity**: Monitor container communication

### Regular Maintenance Tasks

1. **Update Management**: 
   - For Template Installation: Use Docker tab → Force Update
   - For Docker Compose: Use Compose section → Update Stack

2. **Log Monitoring**: Regularly check container logs for errors:
```bash
docker logs local-deep-research
docker logs ollama_service
docker logs searxng
```

3. **Storage Management**: Clean up unused LLM models and old research data

4. **Security Updates**: Keep Unraid and all plugins up to date

**Section sources**
- [unraid.md](file://docs/deployment/unraid.md#L378-L405)

## Troubleshooting Guide

### Common Issues and Solutions

#### Settings Don't Persist

**Symptom**: Settings reset after container restart

**Solution**:
1. Verify volume mapping: `/mnt/user/appdata/local-deep-research/data:/data`
2. Ensure `LDR_DATA_DIR=/data` is set
3. Check that `/mnt/user/appdata/local-deep-research/data` exists and has write permissions
4. Review Unraid logs: **Tools** → **System Log**

#### Container Won't Start

**Check dependencies**:
1. Verify network configuration (ensure `ldr-network` exists if used)
2. Confirm Ollama and SearXNG are running if referenced
3. Check logs: `docker logs local-deep-research`

**Common issues**:
- Port 5000 conflict → Change host port mapping
- Network not found → Create network: `docker network create ldr-network`
- Volume permission errors → Ensure paths exist and are writable

#### Can't Access WebUI

**Verify network settings**:
1. Confirm container is running
2. Check port mapping: Should show `5000:5000` or custom mapping
3. Access via: `http://[unraid-ip]:5000`
4. Check Unraid firewall settings

#### GPU Not Detected

**Verify driver installation**:
```bash
nvidia-smi
```

**Check container runtime**:
```bash
docker inspect ollama_service | grep -i runtime
```

**Common issues**:
- Wrong driver version → Try older driver
- Runtime not configured → Check `/etc/docker/daemon.json`
- GPU in use by VM → Stop VMs using GPU passthrough

#### Models Download Slowly or Fail

**For Ollama**:
1. Check disk space (models are 5-15GB each)
2. Download manually: `docker exec -it ollama_service ollama pull gemma3:12b`
3. Monitor progress: `docker logs -f ollama_service`

**Section sources**
- [unraid.md](file://docs/deployment/unraid.md#L298-L369)
- [faq.md](file://docs/faq.md#L410-L432)

## Conclusion

Deploying Local Deep Research on Unraid provides a powerful, privacy-focused AI research solution. By following the template structure and configuration guidelines outlined in this documentation, users can successfully deploy and maintain the system for systematic research tasks.

The deployment options range from simple template installation to more complex Docker Compose configurations, accommodating various user expertise levels and requirements. Performance can be optimized through proper resource allocation, GPU passthrough, and storage configuration.

Regular maintenance, monitoring, and backup procedures ensure system reliability and data protection. The troubleshooting guide provides solutions to common issues, enabling quick resolution of deployment problems.

For additional support and community resources, refer to the project's Discord server, GitHub repository, and documentation.

**Section sources**
- [unraid.md](file://docs/deployment/unraid.md#L428-L457)
- [README.md](file://README.md#L497-L501)