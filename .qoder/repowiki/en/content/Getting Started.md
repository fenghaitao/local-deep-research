# Getting Started

<cite>
**Referenced Files in This Document**   
- [README.md](file://README.md)
- [env_configuration.md](file://docs/env_configuration.md)
- [unraid.md](file://docs/deployment/unraid.md)
- [api-quickstart.md](file://docs/api-quickstart.md)
- [troubleshooting-openai-api-key.md](file://docs/troubleshooting-openai-api-key.md)
- [Dockerfile](file://Dockerfile)
- [docker-compose.yml](file://docker-compose.yml)
- [pyproject.toml](file://pyproject.toml)
- [developing.md](file://docs/developing.md)
- [simple_working_example.py](file://examples/api_usage/http/simple_working_example.py)
- [simple_client_example.py](file://examples/api_usage/simple_client_example.py)
- [minimal_working_example.py](file://examples/api_usage/programmatic/minimal_working_example.py)
</cite>

## Table of Contents
1. [Installation Options](#installation-options)
2. [Setup Instructions](#setup-instructions)
3. [Configuration Requirements](#configuration-requirements)
4. [Executing Your First Research Query](#executing-your-first-research-query)
5. [Code Examples](#code-examples)
6. [Common Pitfalls and Troubleshooting](#common-pitfalls-and-troubleshooting)

## Installation Options

Local Deep Research (LDR) offers multiple installation methods to accommodate different technical preferences and environments. Users can choose between Docker for containerized deployment, direct Python setup for development and customization, or Unraid deployment for home server environments.

### Docker Installation

Docker provides the most straightforward method for deploying LDR, ensuring consistent behavior across different platforms. The recommended approach uses Docker Compose, which bundles the web application with its dependencies.

For CPU-only operation (compatible with all platforms including macOS, Windows, and Linux):
```bash
curl -O https://raw.githubusercontent.com/LearningCircuit/local-deep-research/main/docker-compose.yml && docker compose up -d
```

For NVIDIA GPU acceleration on Linux systems:
```bash
curl -O https://raw.githubusercontent.com/LearningCircuit/local-deep-research/main/docker-compose.yml && \
curl -O https://raw.githubusercontent.com/LearningCircuit/local-deep-research/main/docker-compose.gpu.override.yml && \
docker compose -f docker-compose.yml -f docker-compose.gpu.override.yml up -d
```

The Docker deployment includes three main services:
- **local-deep-research**: The main web application service
- **ollama**: For running local LLMs with GPU acceleration support
- **searxng**: A privacy-focused metasearch engine for comprehensive web searches

After deployment, access the web interface at `http://localhost:5000`.

**Section sources**
- [README.md](file://README.md#L129-L238)
- [docker-compose.yml](file://docker-compose.yml#L1-L184)

### Direct Python Setup

For developers and users who prefer direct control over the installation, LDR can be installed as a Python package using PDM (Python Development Master), a modern Python package manager.

First, install the package:
```bash
pip install local-deep-research
```

Then set up the required dependencies:
```bash
# Install SearXNG for optimal search results
docker pull searxng/searxng
docker run -d -p 8080:8080 --name searxng searxng/searxng

# Install Ollama from https://ollama.ai
# Download a model
ollama pull gemma3:12b
```

Finally, start the web interface:
```bash
python -m local_deep_research.web.app
```

Optional dependencies can be installed for extended functionality:
```bash
# For VLLM support (advanced local model hosting)
pip install "local-deep-research[vllm]"
```

This installation method is ideal for development and customization, allowing direct access to the codebase and easier debugging.

**Section sources**
- [README.md](file://README.md#L313-L342)
- [developing.md](file://docs/developing.md#L1-L63)

### Unraid Deployment

For Unraid server users, LDR provides a fully compatible deployment option with a pre-configured template for easy installation.

Using the template method:
1. Navigate to the Docker tab in Unraid WebUI
2. Add the template repository: `https://github.com/LearningCircuit/local-deep-research`
3. Click "Add Container" and select "LocalDeepResearch" from the template dropdown
4. Configure volume paths (default: `/mnt/user/appdata/local-deep-research/`)
5. Click "Apply" to deploy

Alternatively, use the Docker Compose Manager plugin:
1. Install "Docker Compose Manager" from Community Applications
2. Create a new stack using the repository URL
3. Update volume paths to Unraid format

The Unraid deployment supports NVIDIA GPU passthrough, automatic SearXNG and Ollama integration, and integration with Unraid shares for document search. Backup integration with the CA Appdata Backup plugin is also supported.

**Section sources**
- [README.md](file://README.md#L279-L311)
- [unraid.md](file://docs/deployment/unraid.md#L1-L457)

## Setup Instructions

### Dependency Installation via PDM

When installing LDR via Python package, PDM is used for dependency management. After installing the base package, configure the environment:

```bash
# Install dependencies
pdm install --no-self

# Set up pre-commit hooks for code quality
pdm run pre-commit install
pdm run pre-commit install-hooks
```

To run the application in the PDM-managed environment:
```bash
# Activate the virtual environment
pdm venv activate

# Run the web interface
python -m local_deep_research.web.app
```

For development purposes, you may need to build frontend assets:
```bash
npm install
npm run build
```

This compiles the Vite frontend into the appropriate directory for the web interface.

**Section sources**
- [developing.md](file://docs/developing.md#L1-L63)
- [pyproject.toml](file://pyproject.toml#L1-L272)

### Environment Configuration

LDR uses environment variables for configuration, following the Dynaconf pattern with the format `LDR_SECTION__SETTING=value`. Configuration can be managed through a `.env` file in the config directory or directly through environment variables.

Key configuration locations:
- **Windows**: `%USERPROFILE%\Documents\LearningCircuit\local-deep-research\config\.env`
- **Linux/Mac**: `~/.config/local_deep_research/config/.env`

Common operations include:
```bash
# Change web port
export LDR_WEB__PORT=8080

# Change search engine
export LDR_SEARCH__TOOL=wikipedia

# Set data directory location
export LDR_DATA_DIR=/path/to/your/data/directory
```

For Docker deployments, pass environment variables during container startup:
```bash
docker run -p 8080:8080 \
  -e LDR_WEB__PORT=8080 \
  -e LDR_SEARCH__TOOL=wikipedia \
  local-deep-research
```

**Section sources**
- [env_configuration.md](file://docs/env_configuration.md#L1-L202)

## Configuration Requirements

### Setting API Keys for LLM Providers

Proper configuration of LLM provider API keys is essential for LDR functionality. Due to a current limitation, API keys must be set with both prefixed and non-prefixed versions:

```bash
# You need BOTH of these for each API key
export OPENAI_API_KEY=your-key-here
export LDR_OPENAI_API_KEY=your-key-here

export ANTHROPIC_API_KEY=your-key-here
export LDR_ANTHROPIC_API_KEY=your-key-here

export SERP_API_KEY=your-key-here
export LDR_SERP_API_KEY=your-key-here
```

This applies to all search-related API keys including OpenAI, Anthropic, SerpAPI, Brave, Google PSE, and Guardian API keys.

For OpenRouter integration (access to 100+ models):
```bash
export LDR_LLM_PROVIDER=openai_endpoint
export LDR_LLM_OPENAI_ENDPOINT_URL=https://openrouter.ai/api/v1
export LDR_LLM_OPENAI_ENDPOINT_API_KEY="your-api-key"
export LDR_LLM_MODEL=anthropic/claude-3.5-sonnet
```

The same pattern works for any OpenAI-compatible API service by changing the endpoint URL and API key.

**Section sources**
- [env_configuration.md](file://docs/env_configuration.md#L43-L143)
- [troubleshooting-openai-api-key.md](file://docs/troubleshooting-openai-api-key.md#L1-L250)

## Executing Your First Research Query

### Using the Web Interface

After successful installation and configuration, access the web interface at `http://localhost:5000`. The interface provides a user-friendly way to execute research queries:

1. Create a user account through the registration form
2. Log in with your credentials
3. Navigate to the research interface
4. Enter your research question in the query field
5. Select your preferred LLM provider and settings
6. Click "Start Research" to initiate the query

The system will display progress indicators as it performs iterative research, verifies information across sources, and compiles a comprehensive report with proper citations.

### Using the Programmatic API

For programmatic access, LDR provides both HTTP REST API and Python client interfaces. The simplest usage pattern uses the built-in client that handles authentication complexity:

```python
from local_deep_research.api import LDRClient, quick_query

# One-liner for quick research
summary = quick_query("username", "password", "What is DNA?")
print(summary)

# Or use the client for multiple operations
client = LDRClient()
client.login("username", "password")
result = client.quick_research("What is machine learning?")
print(result["summary"])
```

For more complex scenarios, use the context manager pattern:
```python
with LDRClient() as client:
    if client.login("username", "password"):
        # Start research without waiting
        result = client.quick_research("What is quantum computing?", wait_for_result=False)
        print(f"Research started with ID: {result['research_id']}")
        
        # Later, get the results
        final_result = client.wait_for_research(result["research_id"])
        print(f"Research complete: {final_result['summary'][:100]}...")
```

**Section sources**
- [README.md](file://README.md#L344-L390)
- [api-quickstart.md](file://docs/api-quickstart.md#L1-L232)
- [simple_client_example.py](file://examples/api_usage/simple_client_example.py#L1-L132)

## Code Examples

### Minimal Working Configuration

For programmatic access without database dependencies, a minimal working example demonstrates the core functionality:

```python
from langchain_ollama import ChatOllama
from local_deep_research.search_system import AdvancedSearchSystem

class MinimalSearchEngine:
    """Minimal search engine that returns hardcoded results."""
    def __init__(self, settings_snapshot=None):
        self.settings_snapshot = settings_snapshot or {}

    def run(self, query, research_context=None):
        """Return some fake search results."""
        return [
            {
                "title": "Introduction to AI",
                "link": "https://example.com/ai-intro",
                "snippet": "Artificial Intelligence (AI) is the simulation of human intelligence...",
                "full_content": "Full article about AI basics...",
                "rank": 1,
            },
            {
                "title": "Machine Learning Explained",
                "link": "https://example.com/ml-explained",
                "snippet": "Machine learning is a subset of AI that enables systems to learn...",
                "full_content": "Detailed explanation of machine learning...",
                "rank": 2,
            },
        ]

# Create LLM
llm = ChatOllama(model="gemma3:12b")

# Create minimal search engine
search = MinimalSearchEngine()

# Create search system with programmatic_mode=True to avoid database dependencies
system = AdvancedSearchSystem(
    llm=llm,
    search=search,
    settings_snapshot={"search.iterations": 1, "search.strategy": "direct"},
    programmatic_mode=True,
)

# Run a search
result = system.analyze_topic("What is artificial intelligence?")
print(f"Found {len(result['findings'])} findings")
print(f"Summary:\n{result['current_knowledge']}")
```

**Section sources**
- [minimal_working_example.py](file://examples/api_usage/programmatic/minimal_working_example.py#L1-L89)

### HTTP API Access Pattern

For language-agnostic access, the HTTP API provides a robust interface. The following example demonstrates the complete authentication and research flow:

```python
import requests
from bs4 import BeautifulSoup

# Create session for cookie persistence
session = requests.Session()

# Login - get CSRF token first
login_page = session.get("http://localhost:5000/auth/login")
soup = BeautifulSoup(login_page.text, 'html.parser')
csrf_input = soup.find('input', {'name': 'csrf_token'})
login_csrf = csrf_input.get('value')

# Login with form data
session.post(
    "http://localhost:5000/auth/login",
    data={
        "username": "your_username",
        "password": "your_password",
        "csrf_token": login_csrf
    }
)

# Get CSRF token for API requests
csrf_token = session.get("http://localhost:5000/auth/csrf-token").json()["csrf_token"]

# Make API request
headers = {"X-CSRF-Token": csrf_token}
response = session.post(
    "http://localhost:5000/api/start_research",
    json={"query": "What is quantum computing?"},
    headers=headers
)
print(response.json())
```

**Section sources**
- [api-quickstart.md](file://docs/api-quickstart.md#L52-L96)
- [simple_working_example.py](file://examples/api_usage/http/simple_working_example.py#L1-L266)

## Common Pitfalls and Troubleshooting

### Missing Environment Variables

A common issue during setup is missing environment variables, particularly API keys. Ensure that all required API keys are set with both prefixed and non-prefixed versions:

```bash
# Required for proper operation
export OPENAI_API_KEY=your-key-here
export LDR_OPENAI_API_KEY=your-key-here
```

Verify the configuration by checking if the variables are properly set:
```bash
echo $OPENAI_API_KEY
echo $LDR_OPENAI_API_KEY
```

### Incorrect LLM Provider Configuration

Issues with LLM provider configuration often stem from incorrect endpoint URLs or API keys. For OpenAI-compatible services like OpenRouter:

```bash
# Correct configuration for OpenRouter
export LDR_LLM_PROVIDER=openai_endpoint
export LDR_LLM_OPENAI_ENDPOINT_URL=https://openrouter.ai/api/v1
export LDR_LLM_OPENAI_ENDPOINT_API_KEY="your-api-key"
export LDR_LLM_MODEL=anthropic/claude-3.5-sonnet
```

Test the configuration with a simple API call to verify connectivity.

### Initial Startup Issues

Common startup issues include port conflicts and dependency problems. For port conflicts, change the host port mapping:

```bash
# Map host port 5050 to container port 5000
docker run -p 5050:5000 local-deep-research
```

For dependency issues, ensure all required services are running:
```bash
# Verify SearXNG is accessible
curl http://localhost:8080

# Verify Ollama is accessible
ollama list
```

### Connectivity Problems

Connectivity problems often occur when accessing the API from non-localhost addresses. The API is configured to require HTTPS for non-localhost connections to prevent session hijacking:

**Solutions for non-localhost access:**
1. Use HTTPS with a reverse proxy (recommended for production)
2. SSH tunnel: `ssh -L 5000:localhost:5000 user@server`, then use localhost:5000
3. Set `TESTING=1` when starting the server (insecure - development only)

```bash
# Insecure option for development
TESTING=1 python -m local_deep_research.web.app
```

**Warning**: The `TESTING=1` option disables secure cookie protection. Session cookies can be intercepted by network attackers. Never use in production or on public networks.

**Section sources**
- [troubleshooting-openai-api-key.md](file://docs/troubleshooting-openai-api-key.md#L1-L250)
- [unraid.md](file://docs/deployment/unraid.md#L298-L377)
- [simple_working_example.py](file://examples/api_usage/http/simple_working_example.py#L1-L36)