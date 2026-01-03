# Notification System

<cite>
**Referenced Files in This Document**   
- [manager.py](file://src/local_deep_research/notifications/manager.py)
- [service.py](file://src/local_deep_research/notifications/service.py)
- [templates.py](file://src/local_deep_research/notifications/templates.py)
- [url_builder.py](file://src/local_deep_research/notifications/url_builder.py)
- [queue_helpers.py](file://src/local_deep_research/notifications/queue_helpers.py)
- [exceptions.py](file://src/local_deep_research/notifications/exceptions.py)
- [notification_validator.py](file://src/local_deep_research/security/notification_validator.py)
- [research_completed.jinja2](file://src/local_deep_research/notifications/templates/research_completed.jinja2)
- [api_quota_warning.jinja2](file://src/local_deep_research/notifications/templates/api_quota_warning.jinja2)
- [auth_issue.jinja2](file://src/local_deep_research/notifications/templates/auth_issue.jinja2)
- [subscription_update.jinja2](file://src/local_deep_research/notifications/templates/subscription_update.jinja2)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Three-Tier Architecture](#three-tier-architecture)
3. [Event Types](#event-types)
4. [Notification Services Configuration](#notification-services-configuration)
5. [Security Model](#security-model)
6. [Template System](#template-system)
7. [Setup Examples](#setup-examples)
8. [Troubleshooting Guide](#troubleshooting-guide)

## Introduction
The notification system in Local Deep Research provides a robust framework for delivering timely updates to users through various channels. This document details the architecture, configuration, and operational aspects of the notification system, focusing on its three-tier design, event triggers, service integration, security model, and customization capabilities.

## Three-Tier Architecture

The notification system follows a three-tier architecture consisting of NotificationManager, NotificationService, and Settings Integration components. This design ensures separation of concerns, scalability, and maintainability.

```mermaid
classDiagram
class NotificationManager {
+settings_snapshot Dict[str, Any]
+user_id str
+service NotificationService
+_rate_limiter RateLimiter
+send_notification(event_type, context, force) bool
+test_service(url) Dict[str, Any]
+_should_notify(event_type) bool
+_log_notification(event_type, context) None
}
class NotificationService {
+apprise Apprise
+allow_private_ips bool
+SERVICE_PATTERNS Dict[str, str]
+send(title, body, service_urls, tag, attach) bool
+send_event(event_type, context, service_urls, tag, custom_template) bool
+test_service(url) Dict[str, Any]
+get_service_type(url) Optional[str]
+_send_with_retry(title, body, apprise_instance, tag, attach) bool
+_validate_url(url) None
}
class RateLimiter {
+max_per_hour int
+max_per_day int
+cleanup_interval_hours int
+_user_limits Dict[str, tuple[int, int]]
+_hourly_counts Dict[str, deque]
+_daily_counts Dict[str, deque]
+_last_cleanup datetime
+_lock threading.Lock
+set_user_limits(user_id, max_per_hour, max_per_day) None
+get_user_limits(user_id) tuple[int, int]
+is_allowed(user_id) bool
+_clean_old_entries(user_id, now) None
+reset(user_id) None
+_cleanup_inactive_users_if_needed(now) None
}
class NotificationTemplate {
+TEMPLATE_FILES Dict[EventType, str]
+_jinja_env Optional[Environment]
+format(event_type, context, custom_template) Dict[str, str]
+_get_jinja_env() Environment
+_get_fallback_template(event_type, context) Dict[str, str]
+get_required_context(event_type) list[str]
}
class EventType {
+RESEARCH_COMPLETED str
+RESEARCH_FAILED str
+RESEARCH_QUEUED str
+SUBSCRIPTION_UPDATE str
+SUBSCRIPTION_ERROR str
+RATE_LIMIT_WARNING str
+API_QUOTA_WARNING str
+AUTH_ISSUE str
+TEST str
}
NotificationManager --> NotificationService : "uses"
NotificationManager --> RateLimiter : "uses"
NotificationManager --> NotificationTemplate : "uses"
NotificationService --> Apprise : "wraps"
NotificationTemplate --> Jinja2 : "uses"
NotificationManager --> SettingsManager : "integrates with"
```

**Diagram sources**
- [manager.py](file://src/local_deep_research/notifications/manager.py#L17-L572)
- [service.py](file://src/local_deep_research/notifications/service.py#L31-L341)
- [templates.py](file://src/local_deep_research/notifications/templates.py#L13-L231)

**Section sources**
- [manager.py](file://src/local_deep_research/notifications/manager.py#L1-L572)
- [service.py](file://src/local_deep_research/notifications/service.py#L1-L341)
- [templates.py](file://src/local_deep_research/notifications/templates.py#L1-L231)

### NotificationManager (Rate Limiting and Settings)
The NotificationManager serves as the high-level interface for the notification system, handling rate limiting and user settings integration. It uses a shared RateLimiter instance across all instances to enforce per-user rate limits while maintaining thread safety through locking mechanisms.

Key features:
- Thread-safe access to user settings via settings snapshots
- Per-user rate limiting with configurable hourly and daily limits
- Integration with the application's settings system
- Automatic logging of sent notifications
- Support for force-sending notifications to bypass rate limits

The manager validates notification preferences based on user settings before sending, ensuring users only receive notifications they've explicitly enabled.

### NotificationService (Apprise Integration)
The NotificationService provides the low-level interface to the Apprise library, which supports over 100 notification services. This component handles the actual delivery of notifications with built-in retry logic and security validation.

Key features:
- Integration with Apprise for multi-service support
- Automatic retry with exponential backoff for failed deliveries
- Security validation of service URLs to prevent SSRF attacks
- Support for attachments in notifications
- Service type detection from URLs
- Comprehensive error handling and logging

The service creates temporary Apprise instances for each send operation, ensuring proper resource management and isolation between different notification requests.

### Settings Integration (User Preferences)
The notification system integrates with the application's settings framework to store and retrieve user preferences. Settings are captured as snapshots for thread-safe access from background processes.

Key configuration options:
- `notifications.service_url`: Comma-separated list of Apprise URLs for notification services
- `notifications.rate_limit_per_hour`: Maximum notifications per hour per user
- `notifications.rate_limit_per_day`: Maximum notifications per day per user
- `notifications.on_research_completed`: Enable notifications for research completion
- `notifications.on_research_failed`: Enable notifications for research failures
- `notifications.on_subscription_update`: Enable notifications for subscription updates
- `notifications.on_api_quota_warning`: Enable notifications for API quota warnings
- `notifications.on_auth_issue`: Enable notifications for authentication issues
- `notifications.allow_private_ips`: Allow notifications to private/internal IPs (development only)

## Event Types

The system supports multiple event types that trigger notifications, each with specific context data and template formatting.

```mermaid
stateDiagram-v2
[*] --> ResearchEvents
[*] --> SubscriptionEvents
[*] --> SystemEvents
ResearchEvents --> RESEARCH_COMPLETED : "research completes"
ResearchEvents --> RESEARCH_FAILED : "research fails"
ResearchEvents --> RESEARCH_QUEUED : "research queued"
SubscriptionEvents --> SUBSCRIPTION_UPDATE : "new content available"
SubscriptionEvents --> SUBSCRIPTION_ERROR : "subscription error"
SystemEvents --> RATE_LIMIT_WARNING : "approaching rate limit"
SystemEvents --> API_QUOTA_WARNING : "approaching API quota"
SystemEvents --> AUTH_ISSUE : "authentication failure"
RESEARCH_COMPLETED --> [*]
RESEARCH_FAILED --> [*]
RESEARCH_QUEUED --> [*]
SUBSCRIPTION_UPDATE --> [*]
SUBSCRIPTION_ERROR --> [*]
RATE_LIMIT_WARNING --> [*]
API_QUOTA_WARNING --> [*]
AUTH_ISSUE --> [*]
```

**Diagram sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L13-L32)

**Section sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L1-L231)

### Research Completion
Triggered when a research task completes successfully. The notification includes:
- Research query
- Summary of findings (truncated to 200 characters)
- Direct link to view the full research results
- Research ID for reference

This notification helps users quickly access their completed research without needing to navigate through the application interface.

### API Quota Warnings
Sent when a user approaches their API quota limits for external services. The notification includes:
- Service name that is nearing quota limits
- Current usage and maximum limit
- Reset time for the quota period

This proactive warning allows users to manage their API usage and avoid service interruptions.

### Authentication Issues
Triggered when authentication fails for external services. The notification includes:
- Service name that experienced authentication failure
- Generic error message (to prevent information leakage)
- Instruction to check credentials

These notifications help users identify and resolve credential issues promptly.

### Subscription Updates
Sent when new content is available for user subscriptions. The notification includes:
- Subscription name
- Number of new items found
- Direct link to view the updates

This keeps users informed about new developments in topics they're following without requiring constant manual checking.

## Notification Services Configuration

The system supports various notification services through Apprise URLs, with security validation to prevent abuse.

```mermaid
flowchart TD
A["User Configuration"] --> B["Service URL Input"]
B --> C{"URL Validation"}
C --> |Valid| D["Store Encrypted"]
C --> |Invalid| E["Reject with Error"]
D --> F["Notification Delivery"]
F --> G{"Delivery Success?"}
G --> |Yes| H["Log Success"]
G --> |No| I["Retry with Backoff"]
I --> J{"Max Attempts?"}
J --> |No| F
J --> |Yes| K["Log Failure"]
style C fill:#f9f,stroke:#333
style D fill:#bbf,stroke:#333
style F fill:#f96,stroke:#333
```

**Diagram sources**
- [service.py](file://src/local_deep_research/notifications/service.py#L31-L341)
- [notification_validator.py](file://src/local_deep_research/security/notification_validator.py#L20-L252)

**Section sources**
- [service.py](file://src/local_deep_research/notifications/service.py#L1-L341)
- [notification_validator.py](file://src/local_deep_research/security/notification_validator.py#L1-L252)

### Discord Configuration
To configure Discord notifications, use the webhook URL format:
```
discord://webhook_id/webhook_token
```

The system validates that the URL uses the correct scheme and doesn't target private IP addresses. Multiple Discord webhooks can be configured by separating URLs with commas.

### Email Configuration
Email notifications support various providers through different URL schemes:
- Generic SMTP: `smtp://user:password@smtp.example.com:port`
- Gmail: `mailto://username:password@gmail.com`
- Office365: `office365://user:pass@domain.com`

The system validates that email URLs don't use blocked schemes like `file://` or `javascript://` and checks for proper formatting.

### Push Notifications
Push notifications are supported through services like Pushover, Gotify, and ntfy:
- Pushover: `pushover://user_key@token`
- Gotify: `gotify://hostname:port/token`
- ntfy: `ntfy://hostname/topic`

These services provide mobile push notifications, ensuring users receive timely updates even when away from their computers.

## Security Model

The notification system implements a zero-knowledge security architecture with encrypted storage of service URLs.

```mermaid
sequenceDiagram
participant User
participant WebInterface
participant EncryptionService
participant Database
participant NotificationService
User->>WebInterface : Enter service URL
WebInterface->>EncryptionService : Encrypt with user-derived key
EncryptionService->>Database : Store encrypted URL
Database-->>WebInterface : Confirmation
WebInterface-->>User : Success message
loop Notification Process
User->>System : Trigger event
System->>Database : Retrieve encrypted URL
Database-->>System : Encrypted URL
System->>EncryptionService : Decrypt with user key
EncryptionService-->>NotificationService : Decrypted URL
NotificationService->>ExternalService : Send notification
end
```

**Diagram sources**
- [database/encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py)
- [security/notification_validator.py](file://src/local_deep_research/security/notification_validator.py#L20-L252)

**Section sources**
- [security/notification_validator.py](file://src/local_deep_research/security/notification_validator.py#L1-L252)

### Encrypted Storage
Service URLs are encrypted using AES-256 encryption before storage in the database. The encryption key is derived from the user's password using a key derivation function, implementing a zero-knowledge architecture where the system cannot access plaintext service URLs.

This approach ensures that even if the database is compromised, attackers cannot extract notification service credentials without knowing individual user passwords.

### Zero-Knowledge Architecture
The system follows a zero-knowledge principle where sensitive information is encrypted client-side or with keys derived from user credentials. Key aspects include:
- Encryption keys are derived from user passwords using PBKDF2
- Service URLs are encrypted before storage and decrypted only when needed
- The application server never has access to plaintext service URLs
- Password changes automatically invalidate old encryption keys

This architecture protects user credentials even in the event of a server compromise.

### SSRF Prevention
The system implements comprehensive Server-Side Request Forgery (SSRF) prevention measures:
- Blocked dangerous protocols (file://, ftp://, javascript://, etc.)
- Validation of HTTP/HTTPS URLs to prevent access to private IP ranges
- Allowlist of approved notification service protocols
- Hostname validation without DNS resolution to prevent DNS rebinding attacks

These measures ensure that notification services cannot be abused to access internal network resources.

## Template System

The notification system uses Jinja2 templates for customizable notification content, allowing users to personalize message formats.

```mermaid
classDiagram
class NotificationTemplate {
+TEMPLATE_FILES Dict[EventType, str]
+_jinja_env Optional[Environment]
+format(event_type, context, custom_template) Dict[str, str]
+_get_jinja_env() Environment
+_get_fallback_template(event_type, context) Dict[str, str]
+get_required_context(event_type) list[str]
}
class Jinja2Environment {
+loader FileSystemLoader
+autoescape select_autoescape
+trim_blocks True
+lstrip_blocks True
}
NotificationTemplate --> Jinja2Environment : "uses"
Jinja2Environment --> "templates/" : "loads from"
```

**Diagram sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L34-L231)

**Section sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L1-L231)

### Template Structure
Templates are stored in the `notifications/templates/` directory with the `.jinja2` extension. Each event type has a corresponding template file that defines the notification format.

The template structure separates the title and body, with the first line becoming the title and subsequent lines forming the body. This allows for consistent formatting across different notification services.

### Context Variables
Each event type supports specific context variables that can be used in templates:
- `query`: Research query text
- `research_id`: UUID of the research task
- `summary`: Brief summary of research findings
- `url`: Direct link to view results
- `service`: External service name
- `current`: Current API usage
- `limit`: API usage limit
- `reset_time`: Quota reset time
- `subscription_name`: Name of the subscription
- `item_count`: Number of new items

These variables are automatically populated based on the event context and can be referenced in templates using Jinja2 syntax.

### Customization
Users can customize notification templates by modifying the Jinja2 files in the templates directory. The system automatically reloads templates when changes are detected, allowing for dynamic customization without requiring application restarts.

For advanced customization, users can also provide custom templates programmatically through the API, enabling dynamic message formatting based on specific conditions.

## Setup Examples

### Web Interface Configuration
Configuring notifications through the web interface involves several steps:

1. Navigate to Settings → Notifications
2. Enter Apprise URLs for desired services (comma-separated)
3. Configure rate limits for hourly and daily notifications
4. Enable or disable specific notification types
5. Test configuration with the test button
6. Save settings

The interface provides real-time validation of service URLs and displays the detected service type (Discord, Email, etc.) for confirmation.

### API Configuration
Notifications can also be configured programmatically through the API:

```python
import requests

# Update notification settings
response = requests.post(
    "http://localhost:5000/api/settings",
    json={
        "notifications.service_url": "discord://webhook_id/token,mailto://user:pass@gmail.com",
        "notifications.rate_limit_per_hour": 10,
        "notifications.rate_limit_per_day": 50,
        "notifications.on_research_completed": True,
        "notifications.on_api_quota_warning": True
    },
    headers={"Authorization": "Bearer your-api-token"}
)

# Test notification service
test_response = requests.post(
    "http://localhost:5000/api/notifications/test",
    json={"url": "discord://webhook_id/token"},
    headers={"Authorization": "Bearer your-api-token"}
)
```

This allows for automated configuration and integration with external management systems.

## Troubleshooting Guide

### Common Delivery Issues
When notifications fail to deliver, consider the following troubleshooting steps:

1. **Verify Service URL Format**: Ensure the URL follows the correct Apprise format for the service
2. **Check Encryption Status**: Confirm that the database encryption is properly configured
3. **Validate Network Access**: Ensure the server can reach external notification services
4. **Review Rate Limits**: Check if the user has exceeded their notification rate limits
5. **Examine Logs**: Review application logs for specific error messages

### Testing Configuration
Use the built-in test functionality to verify notification configuration:

```python
from local_deep_research.notifications import NotificationManager

# Create notification manager with user settings
manager = NotificationManager(settings_snapshot, user_id="user123")

# Test a service URL
result = manager.test_service("discord://webhook_id/token")
if result["success"]:
    print("Service configuration is valid")
else:
    print(f"Configuration error: {result['error']}")
```

This test sends a sample notification to verify that the service is properly configured and accessible.

### Log Analysis
When troubleshooting notification issues, examine the application logs for relevant entries:

- Look for "Failed to send notification" messages
- Check for rate limit warnings
- Verify that notification preferences are enabled
- Confirm that service URLs pass validation checks

The logs provide detailed information about the notification delivery process, including any errors encountered during sending.

**Section sources**
- [manager.py](file://src/local_deep_research/notifications/manager.py#L1-L572)
- [service.py](file://src/local_deep_research/notifications/service.py#L1-L341)
- [queue_helpers.py](file://src/local_deep_research/notifications/queue_helpers.py#L1-L413)