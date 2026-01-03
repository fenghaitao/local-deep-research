# Configuration and Settings

<cite>
**Referenced Files in This Document**   
- [NOTIFICATIONS.md](file://docs/NOTIFICATIONS.md)
- [NOTIFICATION_FLOW.md](file://docs/NOTIFICATION_FLOW.md)
- [manager.py](file://src/local_deep_research/notifications/manager.py)
- [service.py](file://src/local_deep_research/notifications/service.py)
- [notification_validator.py](file://src/local_deep_research/security/notification_validator.py)
- [settings_manager.py](file://src/local_deep_research/settings/manager.py)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json)
</cite>

## Table of Contents
1. [Notification Configuration](#notification-configuration)
2. [Service URL Configuration](#service-url-configuration)
3. [Rate Limiting Configuration](#rate-limiting-configuration)
4. [Security Settings](#security-settings)
5. [Settings Access and Thread Safety](#settings-access-and-thread-safety)
6. [Configuration Examples](#configuration-examples)
7. [Best Practices](#best-practices)

## Notification Configuration

The notification system in Local Deep Research (LDR) is built on the Apprise framework, enabling integration with over 100 notification services. The system is designed with security, scalability, and user isolation in mind, supporting per-user configuration and rate limiting.

Notification settings are managed through the application's settings system, with all sensitive data encrypted at rest using SQLCipher (AES-256). The encryption key is derived from the user's login password via PBKDF2-SHA512, ensuring zero-knowledge security where even administrators cannot access notification credentials without the user's password.

The system supports multiple event types that can trigger notifications:
- Research completion and failure
- Research queuing
- Subscription updates and errors
- API quota warnings
- Authentication issues

Each event type can be individually enabled or disabled through user-specific settings, allowing users to customize their notification preferences. By default, research completion and failure notifications are enabled, while other event types are disabled to prevent notification overload.

**Section sources**
- [NOTIFICATIONS.md](file://docs/NOTIFICATIONS.md#L3-L41)
- [NOTIFICATION_FLOW.md](file://docs/NOTIFICATION_FLOW.md#L7-L14)

## Service URL Configuration

### notifications.service_url

The `notifications.service_url` setting is the primary configuration for notification delivery. It accepts a comma-separated list of Apprise-compatible URLs, enabling users to send notifications to multiple services simultaneously.

```json
"notifications.service_url": {
    "category": "notifications",
    "description": "Comma-separated list of Apprise notification service URLs",
    "editable": true,
    "name": "Notification Service URLs",
    "options": null,
    "type": "APP",
    "ui_element": "text",
    "value": "",
    "visible": true
}
```

**Key Features:**
- **Multiple Services**: Users can configure multiple notification services by separating URLs with commas
- **Apprise Compatibility**: Supports all services available in the Apprise ecosystem including Discord, Slack, Telegram, email (SMTP), Pushover, and Gotify
- **Credential Support**: Service URLs can include authentication credentials (e.g., tokens, passwords) which are securely encrypted
- **Dynamic Configuration**: URLs are fetched from user settings when needed rather than maintaining persistent connections

**Example Configuration:**
```
discord://webhook_id/webhook_token,slack://token1/token2/token3,mailto://user:password@smtp.gmail.com
```

When multiple service URLs are configured, notifications are sent to all specified services simultaneously. This allows users to receive critical alerts on multiple platforms, ensuring they don't miss important events.

The system automatically masks service URLs in logs to prevent credential exposure, displaying them in the format `discord://webhook_id/***` instead of revealing the full token.

**Section sources**
- [NOTIFICATIONS.md](file://docs/NOTIFICATIONS.md#L27-L30)
- [NOTIFICATION_FLOW.md](file://docs/NOTIFICATION_FLOW.md#L425-L426)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L1-L5819)

## Rate Limiting Configuration

### Per-User Rate Limiting

The notification system implements per-user rate limiting to prevent abuse and ensure fair resource allocation in multi-user deployments. Each user can configure their own rate limits independently, and limits are enforced separately for each user.

```mermaid
classDiagram
class NotificationManager {
+settings_snapshot Dict[str, Any]
+user_id str
+service NotificationService
+_rate_limiter RateLimiter
+send_notification(event_type, context, force) bool
+test_service(url) Dict[str, Any]
}
class RateLimiter {
-_user_limits Dict[str, tuple[int, int]]
-_hourly_counts Dict[str, deque]
-_daily_counts Dict[str, deque]
+set_user_limits(user_id, max_per_hour, max_per_day) None
+is_allowed(user_id) bool
+reset(user_id) None
}
NotificationManager --> RateLimiter : "uses"
NotificationManager --> NotificationService : "delegates"
```

**Diagram sources**
- [manager.py](file://src/local_deep_research/notifications/manager.py#L17-L572)

### notifications.rate_limit_per_hour and notifications.rate_limit_per_day

These settings control the maximum number of notifications a user can send within specific time windows:

```json
"notifications.rate_limit_per_hour": {
    "category": "notifications",
    "description": "Max notifications per hour (per user)",
    "editable": true,
    "max_value": 100,
    "min_value": 1,
    "name": "Hourly Rate Limit",
    "options": null,
    "step": 1,
    "type": "APP",
    "ui_element": "number",
    "value": 10,
    "visible": true
},
"notifications.rate_limit_per_day": {
    "category": "notifications",
    "description": "Max notifications per day (per user)",
    "editable": true,
    "max_value": 1000,
    "min_value": 1,
    "name": "Daily Rate Limit",
    "options": null,
    "step": 1,
    "type": "APP",
    "ui_element": "number",
    "value": 50,
    "visible": true
}
```

**Key Implementation Details:**
- **Shared Singleton with Per-User Limits**: The system uses a shared `RateLimiter` instance across all `NotificationManager` instances, but maintains separate limits and counters for each user
- **Memory Efficiency**: The implementation uses approximately 24 bytes per user for limit storage
- **Thread Safety**: All operations are protected by threading locks to ensure safe concurrent access
- **Automatic Cleanup**: Inactive users (no activity for 7+ days) are periodically cleaned from memory to prevent memory leaks

**Default Values:**
- `notifications.rate_limit_per_hour`: 10 notifications per hour
- `notifications.rate_limit_per_day`: 50 notifications per day

When a user exceeds their rate limit, a `RateLimitError` is raised, which can be caught and handled gracefully by the calling code. The rate limiter automatically tracks notification counts and removes entries older than one hour (for hourly limits) or one day (for daily limits).

**Multi-Worker Deployment Consideration:** In multi-worker deployments (e.g., gunicorn with multiple workers), each worker maintains its own rate limit counters. This means a user could potentially send up to N × max_per_hour notifications (where N = number of workers) by distributing requests across different workers. For production multi-worker deployments, consider implementing Redis-based rate limiting.

**Section sources**
- [NOTIFICATIONS.md](file://docs/NOTIFICATIONS.md#L42-L48)
- [NOTIFICATION_FLOW.md](file://docs/NOTIFICATION_FLOW.md#L437-L439)
- [manager.py](file://src/local_deep_research/notifications/manager.py#L312-L572)

## Security Settings

### notifications.allow_private_ips

This security setting controls whether notification service URLs can target private or internal IP addresses, providing protection against Server-Side Request Forgery (SSRF) attacks.

```json
"notifications.allow_private_ips": {
    "category": "security",
    "description": "Allow notifications to private/internal IP addresses (development only)",
    "editable": true,
    "name": "Allow Private IPs",
    "options": null,
    "type": "APP",
    "ui_element": "checkbox",
    "value": false,
    "visible": true
}
```

**Security Implications:**
- **Default Setting**: Disabled (False) for security reasons
- **Private IP Ranges Blocked**: The validator blocks RFC 1918 addresses (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16), loopback addresses (127.0.0.0/8, ::1/128), link-local addresses (169.254.0.0/16, fe80::/10), and unique local IPv6 addresses (fc00::/7)
- **Development Use Only**: Should only be enabled in development or testing environments

When `allow_private_ips` is set to `False` (the default), the system validates all notification URLs to prevent SSRF attacks. The validation process includes:

1. **Protocol Validation**: Only allows safe protocols (http, https, mailto, discord, slack, telegram, etc.)
2. **Blocked Protocols**: Prevents use of dangerous protocols like file://, ftp://, javascript://, and data://
3. **Hostname Validation**: Checks if the hostname resolves to a private IP address
4. **No DNS Rebinding**: For security, hostnames are not resolved to prevent DNS rebinding attacks

```mermaid
flowchart TD
A[Notification URL] --> B{Protocol Valid?}
B --> |No| C[Reject: Blocked Protocol]
B --> |Yes| D{Private IP?}
D --> |Yes| E[Reject: Private IP Address]
D --> |No| F[Allow: Valid URL]
G[allow_private_ips=True] --> D
H[allow_private_ips=False] --> D
```

**Diagram sources**
- [notification_validator.py](file://src/local_deep_research/security/notification_validator.py#L1-L252)

**When to Enable:**
- **Development Environments**: When testing with local notification services
- **Internal Deployments**: When using internal notification servers accessible only within a trusted network
- **Testing Scenarios**: When validating integration with services running on private IPs

**Security Best Practice:** Never enable this setting in production environments. The risk of SSRF attacks outweighs any convenience benefits. If internal notification services are required, use public DNS names that resolve to internal IPs rather than direct IP addresses.

**Section sources**
- [manager.py](file://src/local_deep_research/notifications/manager.py#L87-L91)
- [service.py](file://src/local_deep_research/notifications/service.py#L45-L53)
- [notification_validator.py](file://src/local_deep_research/security/notification_validator.py#L1-L252)

## Settings Access and Thread Safety

### Settings Snapshot Pattern

The notification system employs a "settings snapshot" pattern to ensure thread-safe access to user settings, particularly when sending notifications from background threads like research queue processors.

```mermaid
sequenceDiagram
participant MainThread as "Main Thread"
participant BackgroundThread as "Background Thread"
participant DB as "Encrypted Database"
MainThread->>DB : Open session with user password
DB-->>MainThread : Database session
MainThread->>MainThread : SettingsManager(session)
MainThread->>MainThread : get_settings_snapshot()
MainThread->>BackgroundThread : Pass snapshot and user_id
BackgroundThread->>BackgroundThread : NotificationManager(snapshot, user_id)
BackgroundThread->>BackgroundThread : send_notification()
```

**Diagram sources**
- [NOTIFICATION_FLOW.md](file://docs/NOTIFICATION_FLOW.md#L511-L550)

The pattern works as follows:
1. In the main thread, capture settings using `SettingsManager.get_settings_snapshot()`
2. Pass the resulting dictionary (not the database session) to the `NotificationManager`
3. The `NotificationManager` uses the snapshot for all setting lookups

This approach avoids thread-safety issues with database sessions and Flask's `g` context, which are not safe to use in background threads.

**Key Benefits:**
- ✅ Thread-safe (no database access in background threads)
- ✅ Consistent settings (captured at notification time)
- ✅ No Flask `g` context needed
- ✅ Works from queue processors, schedulers, and other background tasks

```python
# Correct implementation
with get_user_db_session(username, password) as session:
    settings_manager = SettingsManager(session)
    settings_snapshot = settings_manager.get_settings_snapshot()

# Pass snapshot to background thread
notification_manager = NotificationManager(
    settings_snapshot=settings_snapshot,
    user_id=username
)
```

The `user_id` parameter is required when creating a `NotificationManager` to enable per-user rate limiting and ensure proper user isolation.

**Section sources**
- [NOTIFICATIONS.md](file://docs/NOTIFICATIONS.md#L159-L168)
- [NOTIFICATION_FLOW.md](file://docs/NOTIFICATION_FLOW.md#L315-L345)
- [manager.py](file://src/local_deep_research/notifications/manager.py#L57-L80)

## Configuration Examples

### settings.json Configuration

```json
{
    "notifications.service_url": "discord://webhook_id/webhook_token,mailto://user:password@smtp.gmail.com",
    "notifications.rate_limit_per_hour": 15,
    "notifications.rate_limit_per_day": 100,
    "notifications.allow_private_ips": false,
    "notifications.on_research_completed": true,
    "notifications.on_research_failed": true,
    "notifications.on_research_queued": false,
    "app.external_url": "https://ldr.example.com"
}
```

### Environment Variable Equivalents

Environment variables follow the pattern `LDR_{SETTING_KEY_IN_UPPERCASE_WITH_UNDERSCORES}`:

```bash
# Notification service URLs
LDR_NOTIFICATIONS_SERVICE_URL="discord://webhook_id/webhook_token,slack://token1/token2/token3"

# Rate limiting
LDR_NOTIFICATIONS_RATE_LIMIT_PER_HOUR=15
LDR_NOTIFICATIONS_RATE_LIMIT_PER_DAY=100

# Security
LDR_NOTIFICATIONS_ALLOW_PRIVATE_IPS=false

# Event toggles
LDR_NOTIFICATIONS_ON_RESEARCH_COMPLETED=true
LDR_NOTIFICATIONS_ON_RESEARCH_FAILED=true
LDR_NOTIFICATIONS_ON_RESEARCH_QUEUED=false

# Application URL
LDR_APP_EXTERNAL_URL="https://ldr.example.com"
```

### Programmatic Configuration

```python
from local_deep_research.settings.manager import SettingsManager
from local_deep_research.notifications.manager import NotificationManager
from local_deep_research.database.session_context import get_user_db_session

# Configure settings
with get_user_db_session(username, password) as session:
    settings_manager = SettingsManager(session)
    
    # Set notification service URLs
    settings_manager.set_setting(
        "notifications.service_url", 
        "discord://webhook_id/webhook_token"
    )
    
    # Configure rate limits
    settings_manager.set_setting("notifications.rate_limit_per_hour", 20)
    settings_manager.set_setting("notifications.rate_limit_per_day", 75)
    
    # Enable specific events
    settings_manager.set_setting("notifications.on_research_completed", True)
    settings_manager.set_setting("notifications.on_api_quota_warning", True)

# Send notification from background thread
settings_snapshot = settings_manager.get_settings_snapshot()
notification_manager = NotificationManager(
    settings_snapshot=settings_snapshot,
    user_id=username
)

try:
    notification_manager.send_notification(
        event_type=EventType.RESEARCH_COMPLETED,
        context={"query": "AI research trends", "summary": "Recent developments...", "url": "/research/123"}
    )
except RateLimitError:
    logger.warning("Rate limit exceeded")
```

**Section sources**
- [NOTIFICATIONS.md](file://docs/NOTIFICATIONS.md#L79-L94)
- [NOTIFICATION_FLOW.md](file://docs/NOTIFICATION_FLOW.md#L448-L462)
- [manager.py](file://src/local_deep_research/notifications/manager.py#L249-L260)

## Best Practices

### Securing Notification Service URLs

1. **Avoid Hardcoding Credentials**: Use environment variables or secure credential stores instead of embedding credentials directly in configuration files
2. **Use App-Specific Tokens**: When available, use service-specific tokens with limited permissions rather than primary account credentials
3. **Regular Rotation**: Periodically rotate notification service tokens and credentials
4. **Least Privilege**: Configure notification services with the minimum permissions necessary
5. **Monitor Usage**: Regularly review notification logs for unexpected activity

### Configuration Recommendations

- **Production Deployments**: Keep `notifications.allow_private_ips` disabled to prevent SSRF attacks
- **Rate Limit Tuning**: Adjust rate limits based on user needs and notification service constraints
- **Multiple Services**: Configure at least two notification services for redundancy
- **Testing**: Regularly test notification configurations using the built-in test function
- **Monitoring**: Implement monitoring for failed notification attempts

### Troubleshooting Common Issues

**Issue**: "No notification service URLs configured"
- **Cause**: The `notifications.service_url` setting is empty
- **Solution**: Configure service URLs in the settings dashboard or via API

**Issue**: "Rate limit exceeded"
- **Cause**: User has exceeded their configured hourly or daily limit
- **Solution**: Wait for the rate limit window to expire, adjust rate limit settings, or use `force=True` for critical notifications

**Issue**: "Failed to send notification after 3 attempts"
- **Cause**: Service is unreachable or credentials are invalid
- **Solution**: Verify service URL, test with `test_service()`, check network connectivity

**Issue**: Notifications work in main thread but fail in background thread
- **Cause**: Using database session in background thread (not thread-safe)
- **Solution**: Use settings snapshot pattern as documented

**Section sources**
- [NOTIFICATIONS.md](file://docs/NOTIFICATIONS.md#L235-L261)
- [NOTIFICATION_FLOW.md](file://docs/NOTIFICATION_FLOW.md#L464-L508)
- [service.py](file://src/local_deep_research/notifications/service.py#L236-L297)