# Template System

<cite>
**Referenced Files in This Document**   
- [templates.py](file://src/local_deep_research/notifications/templates.py)
- [research_completed.jinja2](file://src/local_deep_research/notifications/templates/research_completed.jinja2)
- [research_failed.jinja2](file://src/local_deep_research/notifications/templates/research_failed.jinja2)
- [research_queued.jinja2](file://src/local_deep_research/notifications/templates/research_queued.jinja2)
- [subscription_update.jinja2](file://src/local_deep_research/notifications/templates/subscription_update.jinja2)
- [subscription_error.jinja2](file://src/local_deep_research/notifications/templates/subscription_error.jinja2)
- [api_quota_warning.jinja2](file://src/local_deep_research/notifications/templates/api_quota_warning.jinja2)
- [auth_issue.jinja2](file://src/local_deep_research/notifications/templates/auth_issue.jinja2)
- [test.jinja2](file://src/local_deep_research/notifications/templates/test.jinja2)
- [service.py](file://src/local_deep_research/notifications/service.py)
- [manager.py](file://src/local_deep_research/notifications/manager.py)
- [queue_helpers.py](file://src/local_deep_research/notifications/queue_helpers.py)
</cite>

## Table of Contents
1. [Template Storage and Event Mapping](#template-storage-and-event-mapping)
2. [Template Rendering Process](#template-rendering-process)
3. [Available Template Variables by Event Type](#available-template-variables-by-event-type)
4. [Template Customization Guidelines](#template-customization-guidelines)
5. [Variable Detection and Missing Variables](#variable-detection-and-missing-variables)
6. [Security Considerations](#security-considerations)
7. [Testing Custom Templates](#testing-custom-templates)

## Template Storage and Event Mapping

The Jinja2-based template system stores all notification templates in the `notifications/templates/` directory. Each template file follows the `.jinja2` extension and corresponds to a specific event type through the `TEMPLATE_FILES` dictionary in the `NotificationTemplate` class.

The `TEMPLATE_FILES` dictionary maps `EventType` enum values to their respective template filenames. This mapping ensures that when a notification is triggered for a specific event, the correct template is automatically selected for rendering. The system supports the following event types and their corresponding template files:

- `RESEARCH_COMPLETED` → `research_completed.jinja2`
- `RESEARCH_FAILED` → `research_failed.jinja2`
- `RESEARCH_QUEUED` → `research_queued.jinja2`
- `SUBSCRIPTION_UPDATE` → `subscription_update.jinja2`
- `SUBSCRIPTION_ERROR` → `subscription_error.jinja2`
- `API_QUOTA_WARNING` → `api_quota_warning.jinja2`
- `AUTH_ISSUE` → `auth_issue.jinja2`
- `TEST` → `test.jinja2`

This structure allows for easy extension of the notification system by simply adding new template files and updating the `TEMPLATE_FILES` dictionary.

**Section sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L43-L52)

## Template Rendering Process

The template rendering process begins when a notification is triggered through the `NotificationManager.send_notification()` method. The process follows these steps:

1. The `NotificationManager` receives an event type and context data
2. It calls `NotificationTemplate.format()` with the event type and context
3. The template system retrieves the appropriate template file using the `TEMPLATE_FILES` mapping
4. A Jinja2 environment is initialized with the templates directory as the loader
5. The template is rendered with the provided context data
6. The rendered content is parsed into title (first line) and body (subsequent lines)

If Jinja2 fails to initialize (e.g., templates directory not found), the system automatically falls back to a simple string formatting approach using the `_get_fallback_template()` method. This fallback mechanism ensures that notifications are still delivered even if the template system encounters issues.

The rendering process also includes error handling for template rendering failures. If an exception occurs during Jinja2 rendering, the system logs the error and uses the fallback template format to ensure notification delivery.

**Section sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L93-L154)
- [manager.py](file://src/local_deep_research/notifications/manager.py#L149-L238)

## Available Template Variables by Event Type

Each event type has specific template variables that can be used in the corresponding template file. These variables are provided in the context dictionary when sending notifications.

### Research Events

**Research Completed (`research_completed.jinja2`)**
- `query`: The research query string
- `research_id`: UUID of the research
- `summary`: Brief summary of research results (truncated to 200 characters)
- `url`: Full URL to view research results

Example context:
```python
{
    "query": "climate change impact on coastal cities",
    "research_id": "a1b2c3d4-e5f6-7890-g1h2-i3j4k5l6m7n8",
    "summary": "Rising sea levels threaten coastal infrastructure...",
    "url": "https://app.example.com/research/a1b2c3d4-e5f6-7890-g1h2-i3j4k5l6m7n8"
}
```

**Research Failed (`research_failed.jinja2`)**
- `query`: The research query string
- `research_id`: UUID of the research
- `error`: Sanitized error message

Example context:
```python
{
    "query": "quantum computing applications",
    "research_id": "b2c3d4e5-f6g7-8901-h2i3-j4k5l6m7n8o9",
    "error": "Research failed. Check logs for details."
}
```

**Research Queued (`research_queued.jinja2`)**
- `query`: The research query string
- `research_id`: UUID of the research
- `position`: Position in the research queue
- `wait_time`: Estimated wait time (currently "Unknown")

Example context:
```python
{
    "query": "renewable energy storage solutions",
    "research_id": "c3d4e5f6-g7h8-9012-i3j4-k5l6m7n8o9p0",
    "position": 3,
    "wait_time": "Unknown"
}
```

### Subscription Events

**Subscription Update (`subscription_update.jinja2`)**
- `subscription_name`: Name of the subscription
- `item_count`: Number of new items found
- `url`: URL to view updates

Example context:
```python
{
    "subscription_name": "AI Research Weekly",
    "item_count": 5,
    "url": "https://app.example.com/subscriptions/ai-research-weekly"
}
```

**Subscription Error (`subscription_error.jinja2`)**
- `subscription_name`: Name of the subscription
- `error`: Error message

Example context:
```python
{
    "subscription_name": "Tech News Daily",
    "error": "Failed to fetch updates"
}
```

### System Events

**API Quota Warning (`api_quota_warning.jinja2`)**
- `service`: Name of the service reaching quota limits
- `current`: Current usage count
- `limit`: Quota limit
- `reset_time`: When the quota will reset

Example context:
```python
{
    "service": "OpenAI API",
    "current": 950,
    "limit": 1000,
    "reset_time": "2024-01-15 00:00:00 UTC"
}
```

**Authentication Issue (`auth_issue.jinja2`)**
- `service`: Name of the service with authentication issues

Example context:
```python
{
    "service": "Google Scholar"
}
```

**Test Notification (`test.jinja2`)**
No context variables required.

**Section sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L180-L230)
- [queue_helpers.py](file://src/local_deep_research/notifications/queue_helpers.py#L164-L292)
- [research_completed.jinja2](file://src/local_deep_research/notifications/templates/research_completed.jinja2)
- [research_failed.jinja2](file://src/local_deep_research/notifications/templates/research_failed.jinja2)
- [research_queued.jinja2](file://src/local_deep_research/notifications/templates/research_queued.jinja2)
- [subscription_update.jinja2](file://src/local_deep_research/notifications/templates/subscription_update.jinja2)
- [subscription_error.jinja2](file://src/local_deep_research/notifications/templates/subscription_error.jinja2)
- [api_quota_warning.jinja2](file://src/local_deep_research/notifications/templates/api_quota_warning.jinja2)
- [auth_issue.jinja2](file://src/local_deep_research/notifications/templates/auth_issue.jinja2)

## Template Customization Guidelines

To customize notification templates, modify the corresponding `.jinja2` files in the `notifications/templates/` directory. Follow these formatting guidelines:

1. **Title on First Line**: The first line of the template should contain the notification title, which may include Jinja2 variables using `{{ variable_name }}` syntax.

2. **Body on Subsequent Lines**: All lines after the first line constitute the notification body. Leave a blank line between the title and body for proper formatting.

3. **Variable Usage**: Use double curly braces `{{ }}` to insert variables. Ensure variable names match those provided in the context for the specific event type.

4. **Proper Indentation**: Maintain consistent indentation for readability, but avoid excessive whitespace that might affect notification formatting.

Example template structure:
```
Title with {{ variable }}: {{ query }}

Body content starts here with {{ variables }} as needed.

Additional body content can span multiple lines.
```

When creating custom templates, ensure that all required variables for the event type are included. The system will automatically handle missing variables by falling back to the generic template format, but it's recommended to include all expected variables for consistent notification quality.

**Section sources**
- [research_completed.jinja2](file://src/local_deep_research/notifications/templates/research_completed.jinja2)
- [research_failed.jinja2](file://src/local_deep_research/notifications/templates/research_failed.jinja2)
- [research_queued.jinja2](file://src/local_deep_research/notifications/templates/research_queued.jinja2)

## Variable Detection and Missing Variables

The template system automatically detects required variables using Jinja2's meta module. The `get_required_context()` method parses the template source to identify all variables used in the template. This is accomplished by:

1. Loading the template source from the file system
2. Parsing the template with Jinja2's parser to create an abstract syntax tree (AST)
3. Using Jinja2's `meta.find_undeclared_variables()` function to extract all variable names from the AST

If Jinja2's meta module is unavailable or parsing fails, the system falls back to a regular expression approach that finds all `{{ variable }}` patterns in the template source.

When variables are missing from the context during rendering, the Jinja2 template engine will substitute empty values. If the entire rendering process fails due to missing variables, the system automatically falls back to the generic template format provided by `_get_fallback_template()`. This ensures that notifications are always delivered, even if the custom template cannot be fully rendered.

The fallback template includes the event type and all context data in a structured format, providing complete information even when the custom template fails.

**Section sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L180-L230)

## Security Considerations

When creating and modifying templates, consider the following security aspects:

1. **Input Sanitization**: All context data passed to templates should be properly sanitized to prevent injection attacks. The system automatically escapes HTML content through Jinja2's autoescape feature, which is enabled for HTML and XML templates.

2. **Error Message Handling**: Sensitive error details should not be exposed in notifications. As seen in the code, error messages are sanitized before being included in notifications to prevent information disclosure.

3. **URL Validation**: All URLs included in templates (particularly callback URLs) are validated using the security module's URL validator to prevent SSRF (Server-Side Request Forgery) and other URL-based attacks.

4. **Template Directory Security**: The templates directory should have appropriate file permissions to prevent unauthorized modifications. The system checks for the existence of the templates directory and logs warnings if it cannot be accessed.

5. **Jinja2 Security**: The Jinja2 environment is configured with secure defaults, including autoescaping and proper block trimming. Custom template modifications should not disable these security features.

6. **Context Data Validation**: Ensure that all variables used in templates are properly validated and have appropriate fallbacks to prevent rendering errors.

**Section sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L75-L80)
- [service.py](file://src/local_deep_research/notifications/service.py#L21-L23)
- [queue_helpers.py](file://src/local_deep_research/notifications/queue_helpers.py#L340-L342)

## Testing Custom Templates

To test custom templates, follow these steps:

1. **Use the Test Template**: The system includes a `test.jinja2` template that can be used to verify the template system is working correctly. Send a test notification to validate that templates are being rendered properly.

2. **Verify Variable Substitution**: Create test notifications with sample context data to ensure all variables are correctly substituted in the rendered output.

3. **Check Fallback Behavior**: Test the fallback mechanism by temporarily renaming the templates directory or introducing syntax errors in templates to ensure notifications still deliver via the fallback format.

4. **Validate Formatting**: Ensure that the title is properly extracted from the first line and the body from subsequent lines. Verify that blank lines are preserved in the body content.

5. **Test Edge Cases**: Test with empty or missing context variables to ensure the system handles these cases gracefully.

6. **Verify URL Links**: If templates include URLs, ensure they are properly formatted and validated.

The notification system includes built-in testing capabilities through the `NotificationService.test_service()` method, which can be used to verify that notifications are being delivered correctly after template modifications.

**Section sources**
- [templates.py](file://src/local_deep_research/notifications/templates.py#L110-L120)
- [service.py](file://src/local_deep_research/notifications/service.py#L236-L297)
- [test.jinja2](file://src/local_deep_research/notifications/templates/test.jinja2)