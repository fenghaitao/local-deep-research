# Configuration

<cite>
**Referenced Files in This Document**   
- [env_settings.py](file://src/local_deep_research/settings/env_settings.py)
- [manager.py](file://src/local_deep_research/settings/manager.py)
- [llm_config.py](file://src/local_deep_research/config/llm_config.py)
- [search_config.py](file://src/local_deep_research/config/search_config.py)
- [thread_settings.py](file://src/local_deep_research/config/thread_settings.py)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json)
- [bootstrap.py](file://src/local_deep_research/settings/env_definitions/bootstrap.py)
- [db_config.py](file://src/local_deep_research/settings/env_definitions/db_config.py)
- [security.py](file://src/local_deep_research/settings/env_definitions/security.py)
- [testing.py](file://src/local_deep_research/settings/env_definitions/testing.py)
- [search_engines_config.py](file://src/local_deep_research/web_search_engines/search_engines_config.py)
</cite>

## Table of Contents
1. [Configuration System Overview](#configuration-system-overview)
2. [Environment Variables and Bootstrap Settings](#environment-variables-and-bootstrap-settings)
3. [Database Configuration](#database-configuration)
4. [LLM Provider Configuration](#llm-provider-configuration)
5. [Search Engine Configuration](#search-engine-configuration)
6. [Security Settings](#security-settings)
7. [Performance and Thread Settings](#performance-and-thread-settings)
8. [Default Settings Structure](#default-settings-structure)
9. [Configuration Management System](#configuration-management-system)
10. [Best Practices for Production](#best-practices-for-production)

## Configuration System Overview

The system implements a hierarchical configuration management system that combines environment variables, database-stored settings, and default values. The configuration system is designed to handle the bootstrapping requirements of the application, where certain settings must be available before the database connection is established. This dual-layer approach ensures flexibility for both development and production environments while maintaining security and reliability.

The configuration system prioritizes settings in the following order: environment variables take precedence over database settings, which in turn override default values. This allows administrators to override specific settings without modifying the database, while ensuring that the application has sensible defaults when no explicit configuration is provided. The system also includes a settings locking mechanism that prevents configuration changes when enabled, providing stability in production environments.

**Section sources**
- [env_settings.py](file://src/local_deep_research/settings/env_settings.py#L1-L348)
- [manager.py](file://src/local_deep_research/settings/manager.py#L1-L800)

## Environment Variables and Bootstrap Settings

The application uses environment variables prefixed with `LDR_` for critical bootstrap settings that must be available before database initialization. These environment-only settings are essential for the application's bootstrapping process and cannot be stored in the database since they are prerequisites for accessing it. The environment variable names are automatically generated from the setting keys by converting to uppercase and replacing dots with underscores (e.g., `bootstrap.encryption_key` becomes `LDR_BOOTSTRAP_ENCRYPTION_KEY`).

Key bootstrap environment variables include:
- `LDR_BOOTSTRAP_ENCRYPTION_KEY`: Database encryption key for securing stored data
- `LDR_BOOTSTRAP_SECRET_KEY`: Application secret key for session encryption and security
- `LDR_BOOTSTRAP_DATABASE_URL`: Database connection URL specifying the database location and credentials
- `LDR_BOOTSTRAP_ALLOW_UNENCRYPTED`: Boolean flag to allow unencrypted database storage (intended for development only)
- `LDR_BOOTSTRAP_DATA_DIR`: Path to the data directory where application data is stored
- `LDR_BOOTSTRAP_CONFIG_DIR`: Path to the configuration directory for configuration files
- `LDR_BOOTSTRAP_LOG_DIR`: Path to the log directory for log files
- `LDR_BOOTSTRAP_ENABLE_FILE_LOGGING`: Boolean flag to enable logging to files

These bootstrap settings are defined in the `BOOTSTRAP_SETTINGS` list in the bootstrap.py module and are implemented using specific setting classes that handle type conversion and validation. For example, `SecretSetting` is used for sensitive values like encryption keys, while `PathSetting` validates and normalizes file paths. The system also supports boolean parsing with HTML checkbox semantics, where any non-empty string value is considered true, except for explicit false values like "off", "false", "0", or "no".

**Section sources**
- [bootstrap.py](file://src/local_deep_research/settings/env_definitions/bootstrap.py#L1-L61)
- [env_settings.py](file://src/local_deep_research/settings/env_settings.py#L1-L348)

## Database Configuration

Database configuration settings control SQLite and SQLCipher database parameters that must be set before establishing a database connection. These settings are critical for database performance, security, and compatibility, and are therefore managed as environment variables rather than database-stored values. The database configuration settings are defined in the `DB_CONFIG_SETTINGS` list in the db_config.py module.

Key database configuration parameters include:
- `LDR_DB_CONFIG_CACHE_SIZE_MB`: SQLite cache size in megabytes (default: 100MB, range: 1-10000MB)
- `LDR_DB_CONFIG_JOURNAL_MODE`: SQLite journal mode with options including DELETE, TRUNCATE, PERSIST, MEMORY, WAL, and OFF (default: WAL)
- `LDR_DB_CONFIG_SYNCHRONOUS`: SQLite synchronous mode with options OFF, NORMAL, FULL, and EXTRA (default: NORMAL)
- `LDR_DB_CONFIG_PAGE_SIZE`: SQLite page size in bytes (must be a power of 2, default: 4096, range: 512-65536)
- `LDR_DB_CONFIG_KDF_ITERATIONS`: Number of key derivation function iterations for encryption (default: 256000, range: 1000-1000000)
- `LDR_DB_CONFIG_KDF_ALGORITHM`: Key derivation function algorithm (default: PBKDF2_HMAC_SHA512)
- `LDR_DB_CONFIG_HMAC_ALGORITHM`: HMAC algorithm for database integrity verification (default: HMAC_SHA512)

The recommended production configuration uses WAL (Write-Ahead Logging) journal mode for better concurrency and performance, with synchronous mode set to NORMAL for a balance between data safety and performance. The cache size should be adjusted based on available system memory, with larger values improving performance for read-heavy workloads. For security-sensitive deployments, increasing the KDF iterations enhances protection against brute-force attacks on the encryption key.

**Section sources**
- [db_config.py](file://src/local_deep_research/settings/env_definitions/db_config.py#L1-L73)
- [env_settings.py](file://src/local_deep_research/settings/env_settings.py#L1-L348)

## LLM Provider Configuration

The system supports multiple LLM providers with comprehensive configuration options for each service. LLM configuration is managed through both environment variables and database settings, with environment variables taking precedence. The available providers include OpenAI, Anthropic, Google Gemini, Ollama, LM Studio, vLLM, OpenRouter, and custom OpenAI-compatible endpoints.

### Provider Selection and Configuration

The primary LLM provider is configured using the `llm.provider` setting, which accepts values from the VALID_PROVIDERS list:
- `openai`: OpenAI API
- `anthropic`: Anthropic API
- `google`: Google Gemini API
- `ollama`: Ollama (local models)
- `lmstudio`: LM Studio (local models)
- `vllm`: vLLM (local models)
- `openai_endpoint`: Custom OpenAI-compatible endpoint
- `openrouter`: OpenRouter API

Each provider has specific configuration requirements:
- **OpenAI**: Requires `llm.openai.api_key` and optionally `llm.openai.api_base` and `llm.openai.organization`
- **Anthropic**: Requires `llm.anthropic.api_key`
- **Google**: Configuration handled through the GoogleProvider class
- **Ollama**: Configured with `llm.ollama.url` (default: http://localhost:11434)
- **LM Studio**: Configured with `llm.lmstudio.url` (default: http://localhost:1234)
- **Custom OpenAI-compatible**: Requires `llm.openai_endpoint.api_key` and `llm.openai_endpoint.url`

### Advanced LLM Settings

The system provides extensive configuration options for fine-tuning LLM behavior:
- `llm.model`: Specifies the model name (e.g., "gpt-4o", "claude-3-5-sonnet-latest", "gemma3:12b")
- `llm.temperature`: Controls randomness in model outputs (range: 0.0-1.0, default: 0.7)
- `llm.max_tokens`: Maximum number of tokens in model responses (default: 30000)
- `llm.context_window_unrestricted`: Boolean flag to let cloud providers handle context sizing automatically (default: true)
- `llm.context_window_size`: Context window size for cloud LLMs when unrestricted mode is disabled (default: 128000)
- `llm.local_context_window_size`: Context window size for local LLMs to prevent memory issues (default: 4096)

Specialized settings are available for local LLM providers:
- **Ollama**: `llm.ollama.enable_thinking` controls whether models perform internal reasoning (default: true)
- **LlamaCpp**: `llm.llamacpp_model_path` specifies the model file path, with additional parameters for GPU layers and batch size
- **vLLM**: Automatically detected when dependencies are available

The system includes availability checks for each provider, ensuring that configured providers are actually accessible before attempting to use them. For example, the Ollama provider checks connectivity to the specified URL and verifies that the requested model exists in the Ollama registry.

**Section sources**
- [llm_config.py](file://src/local_deep_research/config/llm_config.py#L1-L800)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L1-L800)

## Search Engine Configuration

The search engine configuration system provides flexible options for integrating various search services and custom endpoints. Search engines are configured through a combination of database settings and dynamic registration, allowing for both predefined and user-defined search capabilities.

### Default Search Engines

The system includes several default search engines that can be configured through the database:
- **Elasticsearch**: Configured with `search.engine.web.elasticsearch` settings including hosts, index name, and search fields
- **SearXNG**: Privacy-focused metasearch engine with configurable instance URL
- **Google Programmable Search Engine**: Requires API key and search engine ID
- **Tavily**: AI-native search with research capabilities
- **Brave Search**: Privacy-respecting search engine
- **DuckDuckGo**: Community-powered search engine

### Custom Search Engine Configuration

Custom search engines can be defined through the database settings under the `search.engine.web` namespace. Each search engine configuration includes:
- `module_path`: Python module path for the search engine implementation
- `class_name`: Class name of the search engine
- `requires_llm`: Boolean indicating if the search engine requires an LLM for processing
- `default_params`: Dictionary of default parameters for the search engine
- `description`: Brief description of the search engine's purpose
- `strengths`: List of the search engine's strengths
- `weaknesses`: List of the search engine's limitations
- `reliability`: Reliability assessment of the search engine

### Local Document Collections

The system supports searching local document collections through several mechanisms:
- **Local File Search**: Configured through `search.engine.local` settings with specified paths
- **Library RAG**: Semantic search across all document collections, enabled by `search.engine.library.enabled`
- **Individual Collections**: Each document collection is registered as a separate search engine with its own configuration

The search configuration is dynamically loaded by the `search_config()` function, which aggregates settings from the database, registered retrievers, and local collections. The function also handles the registration of LangChain retrievers as available search engines, expanding the system's search capabilities.

**Section sources**
- [search_engines_config.py](file://src/local_deep_research/web_search_engines/search_engines_config.py#L1-L367)
- [search_config.py](file://src/local_deep_research/config/search_config.py#L1-L153)

## Security Settings

The configuration system includes comprehensive security settings to protect the application and its data. These settings are divided into environment variables for critical security parameters and database-stored settings for operational security controls.

### Environment Security Settings

The primary environment security setting is:
- `LDR_SECURITY_SSRF_DISABLE_VALIDATION`: Boolean flag to disable SSRF (Server-Side Request Forgery) validation (default: false)

This setting should only be enabled in trusted development environments, as disabling SSRF validation exposes the application to potential security vulnerabilities. The system includes extensive SSRF protection that validates all URLs before making external requests, preventing access to internal network resources.

### Database Security Settings

Security-related settings stored in the database include:
- `security.rate_limit_default`: Default rate limit for all HTTP endpoints (default: "5000 per hour;50000 per day")
- `security.rate_limit_login`: Rate limit for login attempts to prevent brute force attacks (default: "5 per 15 minutes")
- `security.rate_limit_registration`: Rate limit for registration attempts to prevent spam (default: "3 per hour")

These rate limiting settings use a flexible format that supports multiple limits separated by semicolons, with each limit specified as "N per hour/minute/day". The system implements rate limiting at the HTTP endpoint level to protect against abuse and denial-of-service attacks.

### Application Security Settings

Additional security-related settings include:
- `app.lock_settings`: When enabled, prevents all configuration changes through the UI
- `app.enable_file_logging`: Warning that log files are unencrypted and may contain sensitive data
- Database encryption: Controlled by the bootstrap encryption key and SQLCipher configuration

The system also includes security headers, input validation, and path validation to prevent common web vulnerabilities such as XSS, SQL injection, and path traversal attacks.

**Section sources**
- [security.py](file://src/local_deep_research/settings/env_definitions/security.py#L1-L24)
- [settings_security.json](file://src/local_deep_research/defaults/settings_security.json#L1-L39)
- [env_settings.py](file://src/local_deep_research/settings/env_settings.py#L1-L348)

## Performance and Thread Settings

The system includes various performance tuning parameters and thread management settings to optimize resource utilization and responsiveness.

### Performance Tuning Parameters

Key performance settings include:
- `app.max_concurrent_researches`: Maximum number of concurrent research processes allowed per user (default: 3, range: 1-10)
- `app.queue_mode`: Queue processing mode with options for 'direct' (immediate execution) or 'queue' (background processing)
- `llm.max_tokens`: Maximum tokens in model responses, affecting both performance and cost
- `search.max_results`: Maximum number of search results to retrieve (default: 50)
- `search.max_filtered_results`: Maximum results after relevance filtering (default: 20)
- `report.searches_per_section`: Number of searches per report section (default: 2)

### Thread Management

The system implements thread-safe settings management through the `SettingsManager` class, which includes thread safety checks to prevent cross-thread access to database sessions. Each thread maintains its own settings context through thread-local storage, ensuring that settings are properly isolated between concurrent operations.

The `thread_settings.py` module provides utilities for managing settings in threaded contexts:
- `set_settings_context()`: Sets the settings context for the current thread
- `get_settings_context()`: Retrieves the settings context for the current thread
- `get_setting_from_snapshot()`: Retrieves settings from a snapshot without database access, essential for background threads

The system also includes a settings locking mechanism that prevents configuration changes when enabled, ensuring stability during critical operations.

**Section sources**
- [manager.py](file://src/local_deep_research/settings/manager.py#L1-L800)
- [thread_settings.py](file://src/local_deep_research/config/thread_settings.py#L1-L127)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L1-L800)

## Default Settings Structure

The system's default settings are defined in JSON files within the `src/local_deep_research/defaults` directory. The primary configuration file, `default_settings.json`, contains all default settings with their metadata, including category, description, editability, value constraints, and UI presentation details.

Each setting in the defaults file includes the following properties:
- `category`: Organizational category for grouping related settings
- `description`: Detailed explanation of the setting's purpose
- `editable`: Boolean indicating if the setting can be modified
- `max_value` and `min_value`: Value constraints for numeric settings
- `name`: User-friendly name for the setting
- `options`: Available options for select and multiselect UI elements
- `step`: Increment step for numeric inputs
- `type`: Setting type (APP, LLM, SEARCH, REPORT, DATABASE)
- `ui_element`: UI component type (text, checkbox, select, number, range, password, multiselect)
- `value`: Default value
- `visible`: Boolean indicating if the setting should be visible in the UI

Additional default setting files include:
- `settings_security.json`: Security-related default settings
- `settings_search_config.json`: Search engine configuration defaults
- `settings_nasa_ads.json`: NASA ADS search engine defaults
- `settings_openalex.json`: OpenAlex search engine defaults
- `settings_semantic_scholar.json`: Semantic Scholar search engine defaults
- `settings_ollama_embeddings.json`: Ollama embeddings configuration

The system automatically loads these default settings into the database during initialization, ensuring that all settings are available even if not explicitly configured. Custom settings not present in the defaults file are preserved when importing settings, allowing for extension of the configuration system.

**Section sources**
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L1-L800)
- [manager.py](file://src/local_deep_research/settings/manager.py#L1-L800)

## Configuration Management System

The configuration management system is implemented through the `SettingsManager` class, which provides a unified interface for accessing and modifying application settings. The system follows a hierarchical approach with multiple layers of configuration sources.

### Settings Hierarchy and Resolution

The system resolves settings in the following priority order:
1. Environment variables (highest priority)
2. Database-stored settings
3. Default values from JSON files (lowest priority)

When retrieving a setting, the system first checks if it's an environment-only setting (defined in the bootstrap or database configuration categories). If not, it checks the environment variables, then the database, and finally returns the default value if no other value is found.

### Settings Manager Interface

The `SettingsManager` implements the `ISettingsManager` interface with the following key methods:
- `get_setting(key, default, check_env)`: Retrieves a setting value with type conversion
- `set_setting(key, value, commit)`: Updates a setting value in the database
- `get_all_settings(bypass_cache)`: Returns all settings with metadata
- `get_settings_snapshot()`: Provides a simplified key-value snapshot for thread contexts
- `create_or_update_setting(setting, commit)`: Creates or updates a setting with validation
- `delete_setting(key, commit)`: Removes a setting from the database
- `import_settings(settings_data, commit, overwrite, delete_extra)`: Imports settings from a dictionary
- `load_from_defaults_file(commit, **kwargs)`: Loads settings from the defaults file

### Type Conversion and Validation

The system performs automatic type conversion based on the setting's UI element type:
- `text`: String values
- `checkbox`: Boolean values with HTML form semantics
- `number` and `range`: Numeric values (integer if whole number, otherwise float)
- `select` and `multiselect`: String or array values
- `password`: String values for sensitive data
- `json`: Preserved as-is for JSON parsing

The system includes validation for numeric values, ensuring they fall within specified minimum and maximum constraints. Boolean values are parsed according to HTML checkbox semantics, where any non-empty string value is considered true, except for explicit false values.

### Thread Safety and Context Management

The settings system implements thread safety by associating each `SettingsManager` instance with the thread in which it was created. Attempts to use a manager instance from a different thread raise a `RuntimeError` to prevent potential database session conflicts. For background threads, settings are passed via snapshots using the `get_settings_snapshot()` method, avoiding database access in threaded contexts.

**Section sources**
- [manager.py](file://src/local_deep_research/settings/manager.py#L1-L800)
- [base.py](file://src/local_deep_research/settings/base.py#L1-L118)
- [env_settings.py](file://src/local_deep_research/settings/env_settings.py#L1-L348)

## Best Practices for Production

### Security Configuration

For production deployments, follow these security best practices:
1. Always provide a strong `LDR_BOOTSTRAP_ENCRYPTION_KEY` to encrypt the database
2. Set a secure `LDR_BOOTSTRAP_SECRET_KEY` for session management
3. Never disable SSRF validation in production (`LDR_SECURITY_SSRF_DISABLE_VALIDATION=false`)
4. Enable rate limiting to protect against abuse
5. Disable debug mode to prevent information disclosure
6. Use HTTPS for all external communications
7. Regularly rotate API keys for LLM providers

### Database Configuration

Optimize database performance with these settings:
```env
LDR_DB_CONFIG_CACHE_SIZE_MB=512
LDR_DB_CONFIG_JOURNAL_MODE=WAL
LDR_DB_CONFIG_SYNCHRONOUS=NORMAL
LDR_DB_CONFIG_PAGE_SIZE=4096
LDR_DB_CONFIG_KDF_ITERATIONS=500000
```

### LLM Provider Configuration

For reliable LLM integration:
1. Configure multiple providers as fallback options
2. Set appropriate context window sizes based on your use case
3. Monitor token usage and adjust `llm.max_tokens` accordingly
4. Use environment variables for API keys to avoid storing them in the database
5. Implement proper error handling for API rate limits and timeouts

### Performance Optimization

Optimize system performance by:
1. Adjusting `app.max_concurrent_researches` based on available system resources
2. Using 'queue' mode for background processing in high-traffic environments
3. Configuring appropriate search result limits to balance comprehensiveness and performance
4. Monitoring system resources and adjusting local LLM settings accordingly

### Monitoring and Maintenance

Implement regular monitoring and maintenance:
1. Enable file logging for troubleshooting (with proper log rotation)
2. Regularly backup the database and configuration
3. Monitor rate limiting statistics to detect potential abuse
4. Update the application regularly to receive security patches and improvements

By following these best practices, you can ensure a secure, reliable, and high-performing deployment of the system in production environments.

**Section sources**
- [manager.py](file://src/local_deep_research/settings/manager.py#L1-L800)
- [env_settings.py](file://src/local_deep_research/settings/env_settings.py#L1-L348)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L1-L800)