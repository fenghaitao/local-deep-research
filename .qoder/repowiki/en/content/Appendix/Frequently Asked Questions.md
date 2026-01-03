# Frequently Asked Questions

<cite>
**Referenced Files in This Document**   
- [README.md](file://README.md)
- [docs/faq.md](file://docs/faq.md)
- [docs/env_configuration.md](file://docs/env_configuration.md)
- [docs/troubleshooting-openai-api-key.md](file://docs/troubleshooting-openai-api-key.md)
- [docs/search-engines.md](file://docs/search-engines.md)
- [docs/CUSTOM_LLM_INTEGRATION.md](file://docs/CUSTOM_LLM_INTEGRATION.md)
- [src/local_deep_research/database/encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py)
- [src/local_deep_research/web_search_engines/search_engines_config.py](file://src/local_deep_research/web_search_engines/search_engines_config.py)
- [src/local_deep_research/llm/llm_registry.py](file://src/local_deep_research/llm/llm_registry.py)
- [src/local_deep_research/settings/env_settings.py](file://src/local_deep_research/settings/env_settings.py)
- [src/local_deep_research/error_handling/error_reporter.py](file://src/local_deep_research/error_handling/error_reporter.py)
</cite>

## Table of Contents
1. [Installation Issues](#installation-issues)
2. [API Key Configuration](#api-key-configuration)
3. [Search Engine Setup](#search-engine-setup)
4. [LLM Provider Integration](#llm-provider-integration)
5. [Performance Optimization](#performance-optimization)
6. [Research Strategy Selection](#research-strategy-selection)
7. [Citation Accuracy and Result Verification](#citation-accuracy-and-result-verification)
8. [Common Errors and Solutions](#common-errors-and-solutions)
9. [Environment Variables Configuration](#environment-variables-configuration)
10. [Encrypted Databases Setup](#encrypted-databases-setup)
11. [WebSocket Connections Troubleshooting](#websocket-connections-troubleshooting)
12. [Extending the System](#extending-the-system)

## Installation Issues

### What are the system requirements for running Local Deep Research?

Local Deep Research requires the following system specifications:
- **Python**: 3.10 or newer
- **RAM**: 8GB minimum (16GB recommended for larger models)
- **GPU VRAM** (for Ollama):
  - 7B models: 4GB VRAM minimum
  - 13B models: 8GB VRAM minimum
  - 30B models: 16GB VRAM minimum
  - 70B models: 48GB VRAM minimum
- **Disk Space**:
  - 100MB for LDR
  - 1-2GB for SearXNG
  - 5-15GB per Ollama model
- **OS**: Windows, macOS, Linux

**Section sources**
- [README.md](file://README.md#L53-L66)

### Do I need Docker to run Local Deep Research?

Docker is recommended but not required. You have three installation options:
- **Docker Compose**: Best for production use
- **Docker**: Good for quick testing
- **Pip package**: Best for development or Python integration

The Docker Compose method is recommended as it bundles the web app and all dependencies for easy setup.

**Section sources**
- [README.md](file://README.md#L68-L79)

### How do I set up SearXNG for optimal search results?

SearXNG is a privacy-respecting metasearch engine that aggregates results from multiple sources. To set it up:

```bash
docker pull searxng/searxng
docker run -d -p 8080:8080 --name searxng searxng/searxng
```

Then set the URL to `http://localhost:8080` in LDR settings. For Docker Compose deployments, use `http://searxng:8080` as the URL since containers communicate through the Docker network.

**Section sources**
- [README.md](file://README.md#L81-L90)
- [docs/search-engines.md](file://docs/search-engines.md#L57-L67)

### Why am I getting filename errors on Windows?

This issue (#339) occurs when LDR generates invalid filenames according to Windows filesystem rules. The problem has been fixed in recent versions. To resolve it, update to the latest version of Local Deep Research.

**Section sources**
- [docs/faq.md](file://docs/faq.md#L443-L446)

## API Key Configuration

### How do I configure OpenAI API keys?

You can configure OpenAI API keys through multiple methods:

**Via Web Interface:**
1. Login to LDR web interface
2. Go to Settings
3. Select "OpenAI" as LLM Provider
4. Enter your API key in the "OpenAI API Key" field
5. Click Save

**Via Environment Variables:**
```bash
export OPENAI_API_KEY=sk-your-api-key
python -m local_deep_research.web.app
```

**Programmatically:**
```python
from local_deep_research.settings import CachedSettingsManager
from local_deep_research.database.session_context import get_user_db_session

with get_user_db_session(username="user", password="pass") as session:
    settings_manager = CachedSettingsManager(session, "user")
    settings_manager.set_setting("llm.provider", "openai")
    settings_manager.set_setting("llm.openai.api_key", "sk-your-api-key")
```

**Section sources**
- [docs/troubleshooting-openai-api-key.md](file://docs/troubleshooting-openai-api-key.md#L33-L55)

### Why do I need to set API keys with and without the LDR_ prefix?

Due to a known bug, API keys must be set both with and without the `LDR_` prefix for search engines to work properly:

```bash
# You need BOTH of these for each API key
export OPENAI_API_KEY=your-key-here
export LDR_OPENAI_API_KEY=your-key-here
```

This applies to all search-related API keys including:
- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `SERP_API_KEY`
- `BRAVE_API_KEY`
- `GOOGLE_PSE_API_KEY`
- `GOOGLE_PSE_ENGINE_ID`
- `GUARDIAN_API_KEY`

This issue will be fixed in a future update.

**Section sources**
- [docs/env_configuration.md](file://docs/env_configuration.md#L44-L62)

### What should I do if I get "No API key found" error?

If you encounter a "No API key found" error, try these solutions:

1. **Via Web Interface:**
   - Login to LDR web interface
   - Go to Settings
   - Select "OpenAI" as LLM Provider
   - Enter your API key in the "OpenAI API Key" field
   - Click Save

2. **Via Environment Variable:**
   ```bash
   export OPENAI_API_KEY=sk-your-api-key
   python -m local_deep_research.web.app
   ```

3. **Programmatically:**
   ```python
   from local_deep_research.settings import CachedSettingsManager
   from local_deep_research.database.session_context import get_user_db_session

   with get_user_db_session(username="user", password="pass") as session:
       settings_manager = CachedSettingsManager(session, "user")
       settings_manager.set_setting("llm.provider", "openai")
       settings_manager.set_setting("llm.openai.api_key", "sk-your-api-key")
   ```

**Section sources**
- [docs/troubleshooting-openai-api-key.md](file://docs/troubleshooting-openai-api-key.md#L25-L55)

### How do I troubleshoot "Invalid API key" errors?

If you receive "Invalid API key" errors, follow these steps:

1. **Verify API Key Format:**
   - OpenAI keys start with `sk-`
   - Should be around 51 characters long
   - No extra spaces or quotes

2. **Check API Key Validity:**
   ```bash
   # Test directly with curl
   curl https://api.openai.com/v1/models \
     -H "Authorization: Bearer YOUR_API_KEY"
   ```

3. **Regenerate API Key:**
   - Go to https://platform.openai.com/api-keys
   - Create a new API key
   - Update in LDR settings

**Section sources**
- [docs/troubleshooting-openai-api-key.md](file://docs/troubleshooting-openai-api-key.md#L57-L81)

## Search Engine Setup

### How do I configure search engines in Local Deep Research?

Search engines can be configured through environment variables using the Dynaconf format:

```bash
# Example configuration
LDR_SEARCH__TOOL=wikipedia
LDR_SEARCH_ENGINE_TAVILY_API_KEY=your-key-here
LDR_SEARCH_ENGINE_WEB_SERPAPI_API_KEY=your-key-here
LDR_SEARCH_ENGINE_WEB_GOOGLE_PSE_API_KEY=your-key-here
LDR_SEARCH_ENGINE_WEB_GOOGLE_PSE_ENGINE_ID=your-engine-id
LDR_SEARCH_ENGINE_WEB_BRAVE_API_KEY=your-key-here
```

You can also configure search engines through the web UI in the Settings section.

**Section sources**
- [docs/env_configuration.md](file://docs/env_configuration.md#L14-L18)
- [docs/search-engines.md](file://docs/search-engines.md#L109-L147)

### What should I do if I encounter SearXNG connection errors?

If you experience SearXNG connection errors, follow these troubleshooting steps:

1. **Verify SearXNG is running**:
   ```bash
   docker ps | grep searxng
   curl http://localhost:8080
   ```

2. **For Docker networking issues**:
   - Use `http://searxng:8080` (container name) not `localhost`
   - Or use `--network host` mode

3. **Check browser access**: Navigate to `http://localhost:8080`

4. **Verify URL in settings**: Ensure the URL is correctly set to `http://localhost:8080` or `http://searxng:8080` depending on your deployment method.

**Section sources**
- [docs/faq.md](file://docs/faq.md#L198-L211)
- [docs/search-engines.md](file://docs/search-engines.md#L213-L217)

### How do I resolve rate limit errors with search engines?

To resolve rate limit errors:

1. Check status: `python -m local_deep_research.web_search_engines.rate_limiting status`
2. Reset limits: `python -m local_deep_research.web_search_engines.rate_limiting reset`
3. Use `auto` search tool for automatic fallbacks
4. Add premium search engines (Tavily, SerpAPI, etc.)
5. Enable adaptive rate limiting in Settings → Rate Limiting

The system includes intelligent adaptive rate limiting that learns optimal wait times for each engine and automatically retries failed requests.

**Section sources**
- [docs/faq.md](file://docs/faq.md#L212-L219)
- [docs/search-engines.md](file://docs/search-engines.md#L179-L184)

### Why am I getting "Invalid value" errors from SearXNG?

Ensure "Search snippets only" is enabled in settings. This option is required for SearXNG to function properly. Without this setting enabled, SearXNG may return invalid responses that the system cannot parse correctly.

**Section sources**
- [docs/faq.md](file://docs/faq.md#L220-L223)

## LLM Provider Integration

### How do I integrate OpenRouter with Local Deep Research?

OpenRouter provides access to 100+ models through a single API with an OpenAI-compatible format. To integrate:

**Via Web UI (Recommended):**
1. Navigate to Settings → LLM Provider
2. Select "Custom OpenAI Endpoint" 
3. Set Endpoint URL: `https://openrouter.ai/api/v1`
4. Enter your OpenRouter API key
5. Select a model from the dropdown

**Via Environment Variables:**
```bash
export LDR_LLM_PROVIDER=openai_endpoint
export LDR_LLM_OPENAI_ENDPOINT_URL=https://openrouter.ai/api/v1
export LDR_LLM_OPENAI_ENDPOINT_API_KEY="<your-api-key>"
export LDR_LLM_MODEL=anthropic/claude-3.5-sonnet
```

**Docker Compose Example:**
```yaml
services:
  local-deep-research:
    environment:
      - LDR_LLM_PROVIDER=openai_endpoint
      - LDR_LLM_OPENAI_ENDPOINT_URL=https://openrouter.ai/api/v1
      - LDR_LLM_OPENAI_ENDPOINT_API_KEY=<your-api-key>
      - LDR_LLM_MODEL=anthropic/claude-3.5-sonnet
```

**Section sources**
- [docs/faq.md](file://docs/faq.md#L281-L313)
- [docs/env_configuration.md](file://docs/env_configuration.md#L89-L130)

### How do I connect to LM Studio from Docker?

LM Studio runs on your host machine, but Docker containers can't reach `localhost` (it refers to the container itself). If you see "Model 1" / "Model 2" instead of actual models, this is why.

**Mac/Windows (Docker Desktop):**
- Use `http://host.docker.internal:1234` instead of `localhost:1234`

**Linux:**
Option A - Use your host's actual IP address:
1. Find your IP: `hostname -I | awk '{print $1}'`
2. Set LM Studio URL to: `http://192.168.1.xxx:1234`
3. Ensure LM Studio is listening on `0.0.0.0` (not just localhost)

Option B - Enable `host.docker.internal` on Linux:
Add to your docker-compose.yml:
```yaml
services:
  local-deep-research:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```
Then use `http://host.docker.internal:1234`

**Section sources**
- [docs/faq.md](file://docs/faq.md#L245-L267)

### How do I use custom LLM providers?

Local Deep Research supports seamless integration with custom LangChain LLMs. You can register any LangChain-compatible LLM and use it throughout the system.

**Quick Start:**
```python
from local_deep_research.api import quick_summary

# Option 1: Pass an LLM instance
result = quick_summary(
    query="Your research question",
    llms={"my_model": your_llm_instance},
    provider="my_model"
)

# Option 2: Pass a factory function
def create_llm(model_name=None, temperature=0.7, **kwargs):
    return YourCustomLLM(model=model_name, temp=temperature)

result = quick_summary(
    query="Your research question",
    llms={"custom": create_llm},
    provider="custom",
    model_name="gpt-turbo",
    temperature=0.5
)
```

Your custom LLM must inherit from `langchain_core.language_models.BaseChatModel` and implement the required methods.

**Section sources**
- [docs/CUSTOM_LLM_INTEGRATION.md](file://docs/CUSTOM_LLM_INTEGRATION.md#L15-L38)

### Why is my model not appearing in the dropdown list?

This is a current limitation (#179). As a workaround, you can:
1. Type the exact model name in the dropdown field
2. Edit the database directly
3. Use environment variables to specify the model

**Section sources**
- [docs/faq.md](file://docs/faq.md#L274-L280)

## Performance Optimization

### How can I improve research speed?

To improve research speed:

1. **Reduce complexity**:
   - Use Settings to reduce iterations and questions per iteration
   - Via API:
   ```python
   quick_summary(
       query="your query",
       iterations=1,
       questions_per_iteration=2
   )
   ```

2. **Use faster models**:
   - Local: `mistral:7b`
   - Cloud: `gpt-3.5-turbo`

3. **Enable "Search snippets only"** (required for SearXNG)

4. **Limit the number of search engines** used simultaneously

**Section sources**
- [docs/faq.md](file://docs/faq.md#L354-L373)

### How do I reduce high memory usage?

To reduce high memory usage:

- Use smaller models (7B instead of 70B)
- Limit document collection size
- Use quantized models (GGUF format)
- Reduce the number of parallel searches
- Lower the context length setting for your LLM

**Section sources**
- [docs/faq.md](file://docs/faq.md#L374-L379)

### How do I optimize context length for Ollama models?

There is a known issue with Ollama (#500) where context length is not always respected. Workaround:
- Set context length when pulling model: `ollama pull llama3:8b --context-length 8192`

You can also configure context length through environment variables or the web UI settings.

**Section sources**
- [docs/faq.md](file://docs/faq.md#L269-L273)

## Research Strategy Selection

### What research strategies are available?

Local Deep Research supports multiple research strategies:

- **source-based**: Single query, fast results
- **focused_iteration**: Iterative refinement for accuracy (recommended)
- **adaptive_explorer**: Dynamically adjusts exploration based on findings
- **constraint_guided_explorer**: Follows specific constraints during research
- **diversity_explorer**: Maximizes diversity of sources and perspectives

The `focused_iteration` strategy is recommended for most use cases as it provides the best balance of accuracy and comprehensiveness.

**Section sources**
- [docs/search-engines.md](file://docs/search-engines.md#L198-L202)
- [src/local_deep_research/advanced_search_system/strategies](file://src/local_deep_research/advanced_search_system/strategies)

### How do I select the best research strategy for my needs?

Choose your research strategy based on your requirements:

- **Quick Summary**: Use `source-based` strategy for answers in 30 seconds to 3 minutes
- **Detailed Research**: Use `focused_iteration` for comprehensive analysis with structured findings
- **Report Generation**: Use `focused_iteration` with multiple iterations for professional reports
- **Document Analysis**: Use `source-based` for searching private documents with AI
- **Complex Research**: Use `adaptive_explorer` or `constraint_guided_explorer` for specialized research needs

You can configure the strategy through the web UI or via API parameters.

**Section sources**
- [README.md](file://README.md#L83-L87)
- [docs/search-engines.md](file://docs/search-engines.md#L198-L202)

## Citation Accuracy and Result Verification

### How does Local Deep Research ensure citation accuracy?

Local Deep Research uses multiple citation handlers to ensure accuracy:

- **Standard Citation Handler**: Extracts citations from model responses
- **Forced Answer Citation Handler**: Ensures every claim has a supporting citation
- **Precision Extraction Handler**: Uses advanced techniques to extract precise citations

The system verifies information across multiple sources and provides proper citations for all claims in the research report.

**Section sources**
- [src/local_deep_research/citation_handlers](file://src/local_deep_research/citation_handlers)

### How can I verify the accuracy of research results?

To verify research results:

1. Check the citations provided in the report
2. Cross-reference information across multiple sources
3. Review the search results that support each claim
4. Use the "Report Generation" mode for more comprehensive analysis
5. Enable fact-checking in settings for additional verification

The system is designed to be transparent about sources, allowing you to verify the accuracy of any claim by examining the underlying evidence.

**Section sources**
- [README.md](file://README.md#L44-L45)
- [src/local_deep_research/constraint_checking](file://src/local_deep_research/constraint_checking)

## Common Errors and Solutions

### How do I fix "Error: max_workers must be greater than 0"?

This error indicates LDR cannot connect to your LLM. Check:

1. Ollama is running: `ollama list`
2. You have models downloaded: `ollama pull llama3:8b`
3. Correct model name in settings
4. For Docker: Ensure containers can communicate
5. Verify the LLM service is running and accessible

This error typically indicates a connection issue between LDR and the LLM service.

**Section sources**
- [docs/faq.md](file://docs/faq.md#L151-L158)

### What should I do about "404 Error" when viewing results?

This issue should be resolved in versions 0.5.2 and later. If you're still experiencing it:

1. Refresh the page
2. Check if research actually completed in logs
3. Update to the latest version
4. Restart the application
5. Check database integrity

This error often occurs when there's a temporary issue with result retrieval.

**Section sources**
- [docs/faq.md](file://docs/faq.md#L168-L173)

### How do I resolve research getting stuck or showing empty headings?

Common causes and solutions:

**Causes:**
- "Search snippets only" disabled (must be enabled for SearXNG)
- Rate limiting from search engines
- LLM connection issues

**Solutions:**
1. Reset settings to defaults
2. Use fewer iterations (2-3)
3. Limit questions per iteration (3-4)
4. Enable rate limiting in settings
5. Try a different search engine

**Section sources**
- [docs/faq.md](file://docs/faq.md#L175-L186)

### How do I handle "Database is locked" errors?

To resolve "Database is locked" errors:

```bash
docker-compose down
docker-compose up -d
```

This stops all containers and restarts them, which typically resolves database locking issues. If the problem persists, check file permissions and ensure only one instance is accessing the database.

**Section sources**
- [docs/faq.md](file://docs/faq.md#L402-L408)

## Environment Variables Configuration

### What is the format for environment variables in Local Deep Research?

Local Deep Research uses Dynaconf to manage configuration. The format for environment variables is:

```
LDR_SECTION__SETTING=value
```

Note the **double underscore** (`__`) between the section and setting name.

For example:
- `LDR_WEB__PORT=8080`
- `LDR_SEARCH__TOOL=wikipedia`
- `LDR_GENERAL__ENABLE_FACT_CHECKING=true`

**Section sources**
- [docs/env_configuration.md](file://docs/env_configuration.md#L14-L17)

### How do I change the web port?

To change the web port:

```bash
# Linux/Mac
export LDR_WEB__PORT=8080

# Windows
set LDR_WEB__PORT=8080
```

You can also set this in a `.env` file in your config directory or through the web UI settings.

**Section sources**
- [docs/env_configuration.md](file://docs/env_configuration.md#L159-L164)

### How do I set the data directory location?

By default, Local Deep Research stores all data in platform-specific user directories. You can override this location using the `LDR_DATA_DIR` environment variable:

```bash
# Linux/Mac
export LDR_DATA_DIR=/path/to/your/data/directory

# Windows
set LDR_DATA_DIR=C:\path\to\your\data\directory
```

All application data will be organized under this directory:
- `$LDR_DATA_DIR/ldr.db` - Application database
- `$LDR_DATA_DIR/research_outputs/` - Research reports
- `$LDR_DATA_DIR/cache/` - Cached data
- `$LDR_DATA_DIR/logs/` - Application logs

**Section sources**
- [docs/env_configuration.md](file://docs/env_configuration.md#L185-L202)

## Encrypted Databases Setup

### How does database encryption work in Local Deep Research?

Local Deep Research uses SQLCipher with AES-256 encryption (same technology used by Signal messenger) to protect all user data at rest. Each user has their own encrypted database with complete data isolation.

Key features:
- **Signal-level encryption**: SQLCipher with AES-256
- **Per-user isolated databases**: Each user has their own encrypted database
- **Zero-knowledge architecture**: No password recovery mechanism ensures true privacy
- **Advanced key derivation**: PBKDF2-SHA512 with 256,000 iterations prevents brute-force attacks
- **Data integrity**: HMAC-SHA512 verification prevents tampering

**Section sources**
- [README.md](file://README.md#L57-L71)
- [src/local_deep_research/database/encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py)

### What should I do if SQLCipher is not available?

If SQLCipher is not installed, you'll see a security error. To resolve:

1. Install SQLCipher: `sudo apt install sqlcipher libsqlcipher-dev`
2. Reinstall the project: `pdm install`
3. Or use Docker with SQLCipher pre-installed

Alternatively, you can explicitly allow unencrypted databases (NOT RECOMMENDED):
```bash
export LDR_ALLOW_UNENCRYPTED=true
```

This is not recommended as it stores passwords and API keys in plain text.

**Section sources**
- [src/local_deep_research/database/encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py#L113-L140)

### How do I change my database password?

To change the encryption password for a user's database:

```python
db_manager.change_password(username, old_password, new_password)
```

This rekeys the database with the new password. Note that this only works when SQLCipher is available.

**Section sources**
- [src/local_deep_research/database/encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py#L480-L518)

## WebSocket Connections Troubleshooting

### How does WebSocket support work in Local Deep Research?

Local Deep Research provides real-time updates through WebSocket support for live research progress. The system uses WebSockets to push updates to the client as research progresses, allowing for live progress monitoring.

WebSockets are used for:
- Real-time research progress updates
- Live status notifications
- Interactive research monitoring
- Progress tracking without page refreshes

**Section sources**
- [README.md](file://README.md#L94)

### What should I do if WebSocket connections are failing?

If WebSocket connections are failing:

1. Check if the server supports WebSockets
2. Verify network connectivity
3. Check firewall settings that might block WebSocket connections
4. Ensure the server is configured to handle WebSocket connections
5. Try refreshing the page or restarting the application

WebSocket issues are often related to network configuration or server settings.

**Section sources**
- [README.md](file://README.md#L94)

## Extending the System

### How can I extend Local Deep Research with custom search engines?

You can extend the system with custom search engines by registering them through the search engine configuration. The system supports:

- **LangChain Retrievers**: Any vector store or database (FAISS, Chroma, Pinecone, Weaviate, Elasticsearch)
- **Custom Sources**: Your own documents and databases
- **Meta Search**: Combine multiple engines intelligently

To integrate a custom search engine, implement the appropriate interface and register it with the system.

**Section sources**
- [README.md](file://README.md#L122-L125)
- [docs/search-engines.md](file://docs/search-engines.md#L148-L164)

### How do I integrate custom LLM providers?

To integrate custom LLM providers:

1. Create a class that inherits from `langchain_core.language_models.BaseChatModel`
2. Implement the required methods (`_generate`, `_llm_type`)
3. Register your custom LLM using the LLM registry

```python
from local_deep_research.llm.llm_registry import register_llm

register_llm("my_custom_model", my_llm_instance)
```

Your custom LLM can then be used throughout the system by specifying "my_custom_model" as the provider.

**Section sources**
- [docs/CUSTOM_LLM_INTEGRATION.md](file://docs/CUSTOM_LLM_INTEGRATION.md#L40-L46)
- [src/local_deep_research/llm/llm_registry.py](file://src/local_deep_research/llm/llm_registry.py)

### What are the requirements for custom LLM implementations?

Your custom LLM must:
1. Inherit from `langchain_core.language_models.BaseChatModel`
2. Implement the required methods (`_generate`, `_llm_type`)
3. Handle the standard LangChain message formats
4. Return proper `ChatResult` objects
5. Be thread-safe if used in multi-threaded applications

The system will wrap all LLMs (custom and built-in) with think-tag removal and token counting.

**Section sources**
- [docs/CUSTOM_LLM_INTEGRATION.md](file://docs/CUSTOM_LLM_INTEGRATION.md#L42-L46)
- [src/local_deep_research/llm/llm_registry.py](file://src/local_deep_research/llm/llm_registry.py)