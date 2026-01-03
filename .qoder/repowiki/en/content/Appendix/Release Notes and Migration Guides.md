# Release Notes and Migration Guides

<cite>
**Referenced Files in This Document**   
- [0.2.0.md](file://docs/release_notes/0.2.0.md)
- [0.4.0.md](file://docs/release_notes/0.4.0.md)
- [MIGRATION_GUIDE_v1.md](file://docs/MIGRATION_GUIDE_v1.md)
- [RELEASE_GUIDE.md](file://docs/RELEASE_GUIDE.md)
- [__version__.py](file://src/local_deep_research/__version__.py)
- [initialize.py](file://src/local_deep_research/database/initialize.py)
- [encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py)
- [env_settings.py](file://src/local_deep_research/settings/env_settings.py)
- [UPGRADE_NOTICE.md](file://examples/api_usage/UPGRADE_NOTICE.md)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Version 0.2.0 Release Notes](#version-020-release-notes)
3. [Version 0.4.0 Release Notes](#version-040-release-notes)
4. [Migration Guide v1.0](#migration-guide-v10)
5. [Release Process](#release-process)
6. [Database Migration and Compatibility](#database-migration-and-compatibility)
7. [Configuration Changes](#configuration-changes)
8. [Troubleshooting Common Upgrade Issues](#troubleshooting-common-upgrade-issues)
9. [Conclusion](#conclusion)

## Introduction
This document provides comprehensive information about version management in the local-deep-research project. It includes detailed release notes for significant versions (0.2.0, 0.4.0), step-by-step migration guides for upgrading between major versions, and documentation of the release process. The information reflects actual changes documented in the release notes and migration guide, ensuring accuracy for users managing their installations and upgrades.

**Section sources**
- [0.2.0.md](file://docs/release_notes/0.2.0.md)
- [0.4.0.md](file://docs/release_notes/0.4.0.md)
- [MIGRATION_GUIDE_v1.md](file://docs/MIGRATION_GUIDE_v1.md)
- [RELEASE_GUIDE.md](file://docs/RELEASE_GUIDE.md)

## Version 0.2.0 Release Notes
Local Deep Research v0.2.0 represents a major update that significantly enhances research capabilities, performance, and user experience. This release introduces new search strategies, improved search integrations, and important technical improvements that lay the foundation for future development.

### Major Enhancements
The v0.2.0 release delivers several key enhancements that expand the research capabilities of the system:

- **New Search Strategies**: Implementation of parallel search for lightning-fast research, iterative deep search for enhanced exploration of complex topics, and cross-engine filtering for smarter result ranking across multiple search engines.
- **Improved Search Integrations**: Enhanced support for self-hosted SearxNG instances, better integration with GitHub for more effective code repository analysis, and refined logic for selecting the most appropriate search engines per query.
- **Technical Improvements**: Introduction of a unified database (`ldr.db`) consolidating all settings and history, improved Ollama integration with better reliability and error handling, and enhanced error recovery for connectivity issues and API errors.
- **User Experience**: Enhanced logging panel with duplicate detection and better filtering, streamlined settings UI with improved organization, and more detailed real-time research progress tracking.

### Development Improvements
This release also includes important development improvements that enhance code quality and security:

- **PDM Support**: Transition to PDM for dependency management, providing a more modern and efficient package management experience.
- **Pre-commit Hooks**: Implementation of linting and code quality checks to maintain code standards.
- **Code Security**: Integration of CodeQL with analysis scripts to identify potential security vulnerabilities.
- **Improved Documentation**: Enhanced development guides and setup instructions to support contributors and users.

### Migration Notes
Users upgrading from v0.1.x should be aware of the following migration considerations:

- The application now uses a unified database (`ldr.db`) that automatically migrates data from older databases.
- Settings and research history are automatically migrated on first run when upgrading from v0.1.x.
- The `llm_config.py` file has been deprecated in favor of direct environment variable configuration.

**Section sources**
- [0.2.0.md](file://docs/release_notes/0.2.0.md)

## Version 0.4.0 Release Notes
Local Deep Research v0.4.0 delivers significant improvements to search capabilities, model integrations, and overall system performance. This release focuses on enhancing LLM functionality, expanding search capabilities, and improving the user experience.

### Major Enhancements
The v0.4.0 release introduces several important enhancements:

- **LLM Improvements**: Added support for custom OpenAI-compatible endpoints, improved model discovery for both OpenAI and Anthropic using their official packages, and increased default context window size with higher maximum limits.
- **Search Enhancements**: Implementation of journal quality assessment to estimate journal reputation and quality for academic sources, fixed API key handling and prioritized SearXNG in auto search, and added English translations to Chinese content in Elasticsearch files.
- **User Experience**: Added display of selected search engine during research, improved handling of search engine API keys from database settings, and introduced user-configurable context window size for LLMs.
- **System Improvements**: Migration to `loguru` for enhanced logging capabilities, memory optimizations to fix high usage when journal quality filtering is enabled, and support for resuming interrupted benchmark runs.

### Bug Fixes
This release addresses several important issues:

- Fixed broken SearXNG API key setting
- Resolved memory usage issues with journal quality filtering
- Cleaned up OpenAI endpoint model loading features
- Fixed various evaluation scripts
- Improved settings manager reliability

**Section sources**
- [0.4.0.md](file://docs/release_notes/0.4.0.md)

## Migration Guide v1.0
The migration from Local Deep Research v0.x to v1.0 represents a significant architectural shift that introduces enhanced security, multi-user support, and improved system reliability. This guide provides comprehensive instructions for upgrading applications and services to the new version.

### Breaking Changes
The v1.0 release introduces several breaking changes that require attention during migration:

#### Authentication Required
The most significant change is the introduction of user authentication for all access:

**v0.x**: Open access without authentication
```python
# Direct API access
from local_deep_research.api import quick_summary
result = quick_summary("query")
```

**v1.0**: Authentication required
```python
from local_deep_research.api import quick_summary
from local_deep_research.settings import CachedSettingsManager
from local_deep_research.database.session_context import get_user_db_session

# Must authenticate first
with get_user_db_session(username="user", password="pass") as session:
    settings_manager = CachedSettingsManager(session, "user")
    settings_snapshot = settings_manager.get_all_settings()

    result = quick_summary(
        "query",
        settings_snapshot=settings_snapshot  # Required parameter
    )
```

#### HTTP API Changes
The HTTP API structure has been reorganized with new endpoint prefixes and authentication requirements:

- **v0.x**: `/api/v1/quick_summary`
- **v1.0**: `/api/start_research`

Authentication now requires a session-based flow with CSRF token protection:

```python
import requests

# v1.0 requires session-based authentication
session = requests.Session()

# 1. Login
session.post(
    "http://localhost:5000/auth/login",
    json={"username": "user", "password": "pass"}
)

# 2. Get CSRF token for state-changing operations
csrf = session.get("http://localhost:5000/auth/csrf-token").json()["csrf_token"]

# 3. Make API requests with CSRF token
response = session.post(
    "http://localhost:5000/api/start_research",
    json={"query": "test"},
    headers={"X-CSRF-Token": csrf}
)
```

#### Database Changes
The database architecture has been completely redesigned:

**v0.x**:
- Single shared database: `ldr.db`
- No encryption
- Direct database access from any thread

**v1.0**:
- Per-user databases: `encrypted_databases/{username}.db`
- SQLCipher encryption with user passwords
- Thread-local session management
- In-memory queue tracking (no more service_db)

#### Settings Management
Settings management has been updated to require context:

**v0.x**:
```python
# Direct settings access
from local_deep_research.config import get_db_setting
value = get_db_setting("llm.provider")
```

**v1.0**:
```python
# Settings require context
from local_deep_research.settings import CachedSettingsManager

# Within authenticated session
settings_manager = CachedSettingsManager(session, username)
value = settings_manager.get_setting("llm.provider")

# Or use settings snapshot for thread safety
settings_snapshot = settings_manager.get_all_settings()
```

### Migration Steps
Follow these steps to successfully migrate from v0.x to v1.0:

#### 1. Update Dependencies
```bash
pip install --upgrade local-deep-research
```

#### 2. Create User Accounts
Users must create accounts through the web interface:
1. Start the server: `python -m local_deep_research.web.app`
2. Open http://localhost:5000
3. Click "Register" and create an account
4. Configure LLM providers and API keys in Settings

#### 3. Update Programmatic Code
Update your code to use the new authentication and settings context:

```python
from local_deep_research.api import quick_summary
from local_deep_research.settings import CachedSettingsManager
from local_deep_research.database.session_context import get_user_db_session

def run_research(username, password, query):
    with get_user_db_session(username, password) as session:
        settings_manager = CachedSettingsManager(session, username)
        settings_snapshot = settings_manager.get_all_settings()

        return quick_summary(
            query=query,
            settings_snapshot=settings_snapshot,
            iterations=2,
            questions_per_iteration=3
        )
```

#### 4. Update HTTP API Calls
Create a wrapper for authenticated requests:

```python
class LDRClient:
    def __init__(self, base_url="http://localhost:5000"):
        self.base_url = base_url
        self.session = requests.Session()
        self.csrf_token = None

    def login(self, username, password):
        response = self.session.post(
            f"{self.base_url}/auth/login",
            json={"username": username, "password": password}
        )
        if response.status_code == 200:
            self.csrf_token = self.session.get(
                f"{self.base_url}/auth/csrf-token"
            ).json()["csrf_token"]
        return response

    def start_research(self, query, **kwargs):
        return self.session.post(
            f"{self.base_url}/api/start_research",
            json={"query": query, **kwargs},
            headers={"X-CSRF-Token": self.csrf_token}
        )
```

#### 5. Update Configuration
API keys are now stored encrypted in per-user databases. Users must:
1. Login to the web interface
2. Go to Settings
3. Re-enter API keys for LLM providers

Custom LLM registrations now require settings context:

```python
def create_custom_llm(model_name=None, temperature=None, settings_snapshot=None):
    # Access settings from snapshot if needed
    api_key = settings_snapshot.get("llm.custom.api_key", {}).get("value")
    return CustomLLM(api_key=api_key, model=model_name, temperature=temperature)
```

### Common Issues and Solutions
Address these common issues during migration:

- **"No settings context available in thread"**: Pass `settings_snapshot` parameter to all API calls
- **"Encrypted database requires password"**: Ensure you're using `get_user_db_session()` with credentials
- **CSRF token errors**: Get fresh CSRF token before state-changing requests
- **Old endpoints return 404**: Update to new endpoint structure
- **Rate limiting not working**: Rate limits are now per-user; ensure proper authentication

**Section sources**
- [MIGRATION_GUIDE_v1.md](file://docs/MIGRATION_GUIDE_v1.md)
- [UPGRADE_NOTICE.md](file://examples/api_usage/UPGRADE_NOTICE.md)

## Release Process
The local-deep-research project follows a well-defined release process that ensures consistent, reliable, and secure releases. This process is documented in the RELEASE_GUIDE.md file and implemented through automated workflows.

### Automated Release Process
Releases are fully automated when pull requests are merged to the `main` branch. The process includes:

- **Automatic Release Creation**: Triggered by any merge to the `main` branch, using the version from `src/local_deep_research/__version__.py`
- **Changelog Generation**: Auto-generated from commit history since the last release
- **Duplicate Prevention**: Skips release creation if a release already exists for that version
- **Automatic Publishing**: After release creation, triggers PyPI and Docker publishing (requires approval)

### Release Workflow
The release workflow differs slightly for regular releases and hotfixes:

#### For Regular Releases:
1. Create PR with your changes
2. Update version in `src/local_deep_research/__version__.py`
3. Get approval from code owners
4. Merge to main → Release automatically created
5. Approve publishing in GitHub Actions (PyPI/Docker)

#### For Hotfixes:
1. Create hotfix branch from main
2. Make minimal fix
3. Bump patch version (e.g., 0.4.3 → 0.4.4)
4. Fast-track review by code owners
5. Merge to main → Automatic release

### Manual Release Options
In specific circumstances, manual release options are available:

- **Manual Trigger**: Use GitHub Actions to run the "Create Release" workflow with specified version and prerelease flag
- **Version Tags**: Push a git tag (e.g., `git tag v0.4.3 && git push origin v0.4.3`) to automatically create a release

### Branch Protection
The main branch is protected with the following requirements:
- Required reviews from code owners
- No direct pushes - only via approved PRs
- Status checks must pass (CI tests)

### Version Numbering
The project follows Semantic Versioning:
- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features, backward compatible
- **Patch** (0.0.X): Bug fixes, backward compatible

**Section sources**
- [RELEASE_GUIDE.md](file://docs/RELEASE_GUIDE.md)
- [__version__.py](file://src/local_deep_research/__version__.py)

## Database Migration and Compatibility
The database system in local-deep-research has evolved significantly across versions, with important changes to ensure data integrity, security, and compatibility.

### Database Initialization
The database initialization process is handled by the `initialize_database` function in `initialize.py`. This function:
- Creates all tables defined in the models if they don't exist
- Runs migrations for existing tables to add missing columns
- Initializes default settings if a database session is provided
- Ensures idempotent initialization (can be run multiple times safely)

```python
def initialize_database(
    engine: Engine,
    db_session: Optional[Session] = None,
) -> None:
    """
    Initialize database tables if they don't exist.
    
    This is a temporary solution until Alembic migrations are implemented.
    Currently creates all tables defined in the models if they don't exist.
    """
    inspector = inspect(engine)
    existing_tables = inspector.get_table_names()
    
    # Create all tables (including news tables) - let SQLAlchemy handle dependencies
    Base.metadata.create_all(engine, checkfirst=True)
    
    # Run migrations for existing tables
    _run_migrations(engine)
```

### Per-User Encrypted Databases
Starting with v1.0, the system uses per-user encrypted databases for enhanced security:

- Each user has their own encrypted SQLCipher database in `encrypted_databases/{username}.db`
- Databases are encrypted with user passwords using SQLCipher
- The system checks for SQLCipher availability and warns if running without encryption
- If SQLCipher is not available, users can set `LDR_ALLOW_UNENCRYPTED=true` to proceed (not recommended)

### Migration Warnings
When changing encryption settings, users should be aware that:
- Changing encryption settings requires deleting existing databases and creating new ones
- There is no migration path for encryption setting changes
- Users will lose existing data when recreating databases

**Section sources**
- [initialize.py](file://src/local_deep_research/database/initialize.py)
- [encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py)

## Configuration Changes
The configuration system in local-deep-research has undergone significant changes to improve security, flexibility, and ease of use.

### Environment-Only Settings
Certain settings must be environment-only because they are required before database initialization or for testing/CI configuration:

- **Bootstrap settings** (paths, encryption keys) needed to initialize the database
- **Database configuration settings** required before connecting to the database
- **Testing flags** that need to be checked before any database operations
- **CI/CD variables** controlling build-time behavior

These settings are accessed through the SettingsManager but always read from environment variables. The environment variable naming convention is `LDR_<SETTING_KEY_IN_UPPERCASE_WITH_UNDERSCORES>`.

### Settings Migration
When upgrading from v0.x to v1.0, configuration changes include:

- **Deprecated files**: The `llm_config.py` file has been deprecated in favor of direct environment variable configuration
- **API key storage**: API keys are now stored encrypted in per-user databases rather than in configuration files
- **Context requirements**: Settings access now requires a context (session) rather than direct access

### Environment Variables
Key environment variables include:
- `LDR_ALLOW_UNENCRYPTED`: Allows running without database encryption (not recommended)
- `LDR_USE_SHARED_DB`: Enables compatibility mode with shared database (not recommended)
- `LDR_DB_CACHE_SIZE_MB`: Database cache size in MB
- `LDR_DB_JOURNAL_MODE`: Database journal mode (WAL, DELETE, etc.)
- `LDR_DB_SYNCHRONOUS`: Database synchronous mode (NORMAL, FULL, OFF)

**Section sources**
- [env_settings.py](file://src/local_deep_research/settings/env_settings.py)
- [MIGRATION_GUIDE_v1.md](file://docs/MIGRATION_GUIDE_v1.md)

## Troubleshooting Common Upgrade Issues
This section addresses common issues encountered during upgrades and provides solutions to resolve them.

### Authentication Issues
**Issue**: "No settings context available in thread"
**Solution**: Pass the `settings_snapshot` parameter to all API calls. The settings snapshot must be obtained from a `CachedSettingsManager` within an authenticated session.

**Issue**: "Encrypted database requires password"
**Solution**: Ensure you're using `get_user_db_session()` with valid username and password credentials. The session context is required for accessing the encrypted database.

**Issue**: CSRF token errors
**Solution**: Get a fresh CSRF token before making state-changing requests (POST, PUT, DELETE). The token can be obtained from the `/auth/csrf-token` endpoint.

### Database Issues
**Issue**: Old endpoints return 404
**Solution**: Update to the new endpoint structure. For example, `/api/v1/quick_summary` has been replaced with `/api/start_research`.

**Issue**: Rate limiting not working
**Solution**: Rate limits are now per-user. Ensure proper authentication is in place, as unauthenticated requests may not be subject to rate limiting.

**Issue**: Database migration fails
**Solution**: Check application logs for detailed error messages, ensure write permissions to the data directory, verify SQLite functionality, or start with a fresh database by removing `ldr.db`.

### Configuration Issues
**Issue**: Missing API keys after upgrade
**Solution**: Re-enter API keys in the Settings interface after logging in. API keys are now stored encrypted in per-user databases rather than in configuration files.

**Issue**: Custom LLM configurations not working
**Solution**: Update custom LLM code to accept and use the `settings_snapshot` parameter, which contains the necessary configuration values.

### Compatibility Mode
For temporary backward compatibility, you can:
1. Set environment variable: `LDR_USE_SHARED_DB=1` (not recommended)
2. Create a compatibility wrapper for existing code

```python
# compatibility.py
import os
os.environ["LDR_USE_SHARED_DB"] = "1"  # Use at your own risk

def quick_summary_compat(query, **kwargs):
    # Minimal compatibility wrapper
    # Note: This bypasses security features!
    from local_deep_research.api import quick_summary
    return quick_summary(query, settings_snapshot={}, **kwargs)
```

**Warning**: Compatibility mode bypasses security features and is not recommended for production use.

**Section sources**
- [MIGRATION_GUIDE_v1.md](file://docs/MIGRATION_GUIDE_v1.md)
- [UPGRADE_NOTICE.md](file://examples/api_usage/UPGRADE_NOTICE.md)

## Conclusion
The local-deep-research project has undergone significant evolution from version 0.2.0 to the current v1.3.22, with major improvements in security, functionality, and user experience. The transition to v1.0 introduced critical architectural changes including per-user encrypted databases, mandatory authentication, and improved settings management.

When upgrading between versions, pay particular attention to:
- The requirement for authentication in v1.0+
- The migration from shared to per-user encrypted databases
- The changes to API endpoints and request patterns
- The deprecation of configuration files in favor of environment variables and database-stored settings

The automated release process ensures consistent and reliable releases, while the comprehensive migration guide provides clear instructions for upgrading applications. By following the documented procedures and addressing the common issues outlined in this guide, users can successfully manage their local-deep-research installations and take advantage of the latest features and improvements.

**Section sources**
- [0.2.0.md](file://docs/release_notes/0.2.0.md)
- [0.4.0.md](file://docs/release_notes/0.4.0.md)
- [MIGRATION_GUIDE_v1.md](file://docs/MIGRATION_GUIDE_v1.md)
- [RELEASE_GUIDE.md](file://docs/RELEASE_GUIDE.md)