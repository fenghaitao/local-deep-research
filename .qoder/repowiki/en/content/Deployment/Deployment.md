# Deployment

<cite>
**Referenced Files in This Document**   
- [Dockerfile](file://Dockerfile)
- [unraid-templates/local-deep-research.xml](file://unraid-templates/local-deep-research.xml)
- [cookiecutter-docker/cookiecutter.json](file://cookiecutter-docker/cookiecutter.json)
- [cookiecutter-docker/hooks/pre_prompt.py](file://cookiecutter-docker/hooks/pre_prompt.py)
- [cookiecutter-docker/hooks/post_gen_project.py](file://cookiecutter-docker/hooks/post_gen_project.py)
- [cookiecutter-docker/{{cookiecutter.config_name}}/docker-compose.{{cookiecutter.config_name}}.yml](file://cookiecutter-docker/{{cookiecutter.config_name}}/docker-compose.{{cookiecutter.config_name}}.yml)
- [docker-compose.yml](file://docker-compose.yml)
- [docker-compose.unraid.yml](file://docker-compose.unraid.yml)
- [docker-compose.gpu.override.yml](file://docker-compose.gpu.override.yml)
- [scripts/ldr_entrypoint.sh](file://scripts/ldr_entrypoint.sh)
- [scripts/ollama_entrypoint.sh](file://scripts/ollama_entrypoint.sh)
- [docs/deployment/unraid.md](file://docs/deployment/unraid.md)
</cite>

## Table of Contents
1. [Docker Deployment](#docker-deployment)
2. [Unraid Server Deployment](#unraid-server-deployment)
3. [Cookiecutter-Docker Template System](#cookiecutter-docker-template-system)
4. [Production Configuration Requirements](#production-configuration-requirements)
5. [Scaling Considerations](#scaling-considerations)
6. [Monitoring and Log Management](#monitoring-and-log-management)
7. [Entry Point Scripts](#entry-point-scripts)
8. [Maintenance and Updates](#maintenance-and-updates)

## Docker Deployment

The local-deep-research system provides comprehensive Docker support for deployment across various environments. The Docker implementation is defined in the Dockerfile, which follows a multi-stage build process to optimize image size and security.

The Docker build process consists of three main stages:
1. **Builder-base**: Establishes the base environment with Python, Node.js, and system dependencies
2. **Builder**: Builds the application dependencies and frontend assets
3. **LDR**: Creates the final production image with minimal runtime dependencies

The production container runs as a non-root user (ldruser) for security, with proper directory permissions and volume configurations. Key Docker features include:

- **Volume Mounting**: The container exposes `/app/.config/local_deep_research` for persistent configuration and `/scripts/` for startup scripts
- **Network Setup**: Configured to expose port 5000 with health checks for container orchestration
- **Security Hardening**: Uses a non-root user (UID 1000) and minimal base image
- **Health Checks**: Implements HTTP-based health checks for container orchestration systems

The Docker image can be built and run using standard Docker commands:
```bash
docker build -t local-deep-research .
docker run -d -p 5000:5000 --name local-deep-research local-deep-research
```

For production deployments, the system provides docker-compose configurations that orchestrate multiple services including the main application, Ollama for local LLM processing, and SearXNG for private search capabilities.

**Section sources**
- [Dockerfile](file://Dockerfile#L171-L244)
- [docker-compose.yml](file://docker-compose.yml#L19-L184)

## Unraid Server Deployment

The local-deep-research system includes dedicated support for Unraid server deployment through a comprehensive XML template. The Unraid template provides a user-friendly interface for configuring the container with sensible defaults optimized for the Unraid environment.

Key features of the Unraid deployment include:

- **Template Integration**: The `local-deep-research.xml` template can be added to Unraid's Docker repositories for one-click installation
- **Volume Configuration**: Pre-configured data directories at `/mnt/user/appdata/local-deep-research/` following Unraid best practices
- **Service Integration**: Automatic configuration for companion containers (Ollama and SearXNG) with proper network settings
- **GPU Support**: Optional NVIDIA GPU passthrough for accelerated local LLM processing

The Unraid template exposes several configurable parameters:
- **WebUI Port**: Host port mapping for accessing the web interface (default: 5000)
- **Data Directory**: Primary data storage location for databases, research outputs, and logs
- **Scripts Directory**: Location for startup scripts, required for Ollama integration
- **Document Collections**: Optional read-only mounts for personal notes, project documents, and research papers
- **LLM Configuration**: Environment variables for configuring Ollama URL, SearXNG URL, and API keys

For GPU acceleration on Unraid, users must:
1. Install the Nvidia-Driver plugin
2. Configure Docker daemon with NVIDIA runtime support
3. Enable GPU in the Ollama container with appropriate runtime and environment variables

The deployment documentation also provides guidance for backup strategies using Unraid's CA Appdata Backup plugin and troubleshooting common issues like port conflicts and network configuration.

**Section sources**
- [unraid-templates/local-deep-research.xml](file://unraid-templates/local-deep-research.xml#L1-L54)
- [docs/deployment/unraid.md](file://docs/deployment/unraid.md#L1-L457)

## Cookiecutter-Docker Template System

The local-deep-research system includes a Cookiecutter template system for generating customized Docker configurations. This template system allows users to create tailored docker-compose files based on their specific deployment requirements.

The cookiecutter-docker template is configured through `cookiecutter.json`, which defines default parameters:
- `config_name`: Configuration profile name
- `build`: Flag to build from source or use pre-built image
- `host_port`: Web interface port (default: 5000)
- `host_ip`: Web server binding (default: 0.0.0.0)
- `host_network`: Network mode selection
- `enable_gpu`: GPU acceleration flag
- `enable_searxng`: SearXNG integration flag

The template system includes two hook scripts:
- **pre_prompt.py**: Runs before user input to detect system capabilities (GPU detection) and prompt for Ollama-specific configuration
- **post_gen_project.py**: Runs after template generation to move the generated docker-compose file to the correct location and clean up temporary directories

The template generates a docker-compose configuration file (`docker-compose.[config_name].yml`) with the following features:
- Conditional service inclusion based on user choices
- Proper network configuration (host mode or custom network)
- Environment variable setup for LLM providers and search engines
- Volume mounting for data persistence
- GPU resource allocation when enabled

Users can generate a custom configuration by running:
```bash
cookiecutter cookiecutter-docker/
```

This interactive process guides users through configuration options and generates a docker-compose file optimized for their specific environment and requirements.

**Section sources**
- [cookiecutter-docker/cookiecutter.json](file://cookiecutter-docker/cookiecutter.json#L1-L10)
- [cookiecutter-docker/hooks/pre_prompt.py](file://cookiecutter-docker/hooks/pre_prompt.py#L1-L78)
- [cookiecutter-docker/hooks/post_gen_project.py](file://cookiecutter-docker/hooks/post_gen_project.py#L1-L23)
- [cookiecutter-docker/{{cookiecutter.config_name}}/docker-compose.{{cookiecutter.config_name}}.yml](file://cookiecutter-docker/{{cookiecutter.config_name}}/docker-compose.{{cookiecutter.config_name}}.yml#L1-L116)

## Production Configuration Requirements

For production deployments, the local-deep-research system requires careful configuration to ensure security, performance, and reliability.

### Security Hardening
The system implements multiple security measures:
- **Data Encryption**: Uses SQLCipher with AES-256 encryption for all user databases
- **Isolated User Databases**: Each user has their own encrypted database with complete data isolation
- **Non-root Execution**: The application runs as a non-root user (ldruser) in containers
- **Environment Variables**: Sensitive configuration is managed through environment variables
- **Network Security**: Proper container networking with service isolation

Key security configuration parameters include:
- `LDR_DATA_DIR`: Must point to a persistent volume for data storage
- API key environment variables (OpenAI, Anthropic, Google) should be set only if locking configuration
- Proper volume permissions to ensure the ldruser can access required directories

### Performance Tuning
Optimal performance requires configuration based on available hardware:
- **CPU/RAM**: The base configuration works on all platforms, but more resources allow for larger models and faster processing
- **GPU Acceleration**: For NVIDIA GPUs, configure the docker-compose.gpu.override.yml to enable GPU passthrough
- **Model Selection**: Choose appropriate LLM models based on available VRAM and performance requirements
- **Context Length**: Configure Ollama context length based on available memory

### Backup Strategies
Essential backup considerations:
- **Critical Data**: `/data` volume containing user databases, research outputs, and encrypted databases
- **Configuration**: Scripts directory and any custom configuration files
- **Backup Frequency**: Regular backups based on research activity level
- **Backup Methods**: Use Unraid's CA Appdata Backup plugin or manual tar backups

**Section sources**
- [Dockerfile](file://Dockerfile#L171-L244)
- [docker-compose.yml](file://docker-compose.yml#L19-L184)
- [docker-compose.gpu.override.yml](file://docker-compose.gpu.override.yml#L1-L32)

## Scaling Considerations

The local-deep-research system can be scaled to handle multiple concurrent users and resource-intensive research tasks through several strategies.

### Horizontal Scaling
For high-concurrency scenarios:
- Deploy multiple application instances behind a load balancer
- Ensure shared storage for consistent user data access
- Use external database solutions for better performance under load

### Resource Management
For resource-intensive research tasks:
- **GPU Utilization**: Enable GPU acceleration for faster LLM processing
- **Memory Configuration**: Adjust Ollama keep-alive settings and context length based on available RAM
- **Parallel Processing**: The system naturally handles multiple research tasks in parallel

### Container Orchestration
For production environments:
- Use Docker Compose for multi-container deployments
- Implement health checks and auto-restart policies
- Monitor resource usage and scale accordingly
- Consider Kubernetes for large-scale deployments with advanced scaling requirements

The system's architecture supports scaling through:
- Stateless application design (state stored in databases)
- Modular service architecture (separate services for LLM, search, and application)
- Persistent storage for user data and research outputs

**Section sources**
- [docker-compose.yml](file://docker-compose.yml#L19-L184)
- [Dockerfile](file://Dockerfile#L171-L244)

## Monitoring and Log Management

Effective monitoring and log management are essential for maintaining deployed instances of the local-deep-research system.

### Built-in Monitoring Features
The system includes:
- **Health Checks**: HTTP-based health checks for container orchestration
- **Analytics Dashboard**: Built-in dashboard for tracking costs, performance, and usage metrics
- **WebSocket Support**: Real-time updates for research progress monitoring

### Log Management
The container is configured to:
- Store logs in `/data/logs` directory (persisted through volume mounting)
- Create structured log directories for different components
- Set appropriate permissions (700) for security

Log rotation and retention should be configured based on storage capacity and compliance requirements. The entrypoint script ensures proper directory creation and permissions for log storage.

### External Monitoring
For production environments:
- Integrate with existing monitoring solutions (Prometheus, Grafana, etc.)
- Set up alerts for container health and resource utilization
- Monitor database performance and query patterns
- Track API usage and error rates

**Section sources**
- [scripts/ldr_entrypoint.sh](file://scripts/ldr_entrypoint.sh#L1-L36)
- [Dockerfile](file://Dockerfile#L232-L234)

## Entry Point Scripts

The local-deep-research system uses two entry point scripts to manage container initialization and service startup.

### LDR Entrypoint Script
The `ldr_entrypoint.sh` script handles:
- **Volume Permission Setup**: Creates required subdirectories under `/data` and sets proper ownership for the ldruser
- **Directory Creation**: Ensures existence of logs, cache, research outputs, and encrypted databases directories
- **Permission Configuration**: Sets secure permissions (700) for sensitive directories
- **User Switching**: Uses gosu to switch from root to the ldruser for application execution

The script follows the pattern of performing root-level operations (directory creation and permission setting) before dropping privileges to run the application as a non-privileged user.

### Ollama Entrypoint Script
The `ollama_entrypoint.sh` script manages:
- **Service Initialization**: Starts the Ollama service in the background
- **Service Readiness**: Waits for the Ollama service to be ready before proceeding
- **Model Management**: Pulls the specified LLM model using `ollama pull`
- **Process Management**: Keeps the container running indefinitely to maintain the Ollama service

The script accepts a model name as a command-line argument and ensures the specified model is available before the container completes initialization.

These entry point scripts are critical for proper container operation, ensuring that volumes have correct permissions and that dependent services are properly initialized.

**Section sources**
- [scripts/ldr_entrypoint.sh](file://scripts/ldr_entrypoint.sh#L1-L36)
- [scripts/ollama_entrypoint.sh](file://scripts/ollama_entrypoint.sh#L1-L40)

## Maintenance and Updates

Maintaining deployed instances of the local-deep-research system requires a structured approach to updates and maintenance.

### Update Strategies
For template-based deployments:
- Use Unraid's "Force Update" feature to update container images
- Verify compatibility with existing data and configuration

For Docker Compose deployments:
- Use `docker compose pull` followed by `docker compose up -d` to update services
- Consider using Watchtower for automated container updates

### Best Practices
- **Regular Backups**: Perform regular backups of the data directory before updates
- **Update Testing**: Test updates in a staging environment when possible
- **Monitoring**: Monitor system performance and error logs after updates
- **Documentation**: Keep deployment documentation updated with configuration changes

### Minimizing Downtime
To reduce downtime during updates:
- Use rolling updates when running multiple instances
- Schedule updates during low-usage periods
- Implement health checks to ensure service availability
- Maintain version compatibility between components

The system's containerized architecture facilitates easy updates and rollbacks, allowing administrators to maintain system availability while keeping the deployment current.

**Section sources**
- [docs/deployment/unraid.md](file://docs/deployment/unraid.md#L378-L406)
- [docker-compose.yml](file://docker-compose.yml#L19-L184)