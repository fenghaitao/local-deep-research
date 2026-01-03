# API Key Authentication

<cite>
**Referenced Files in This Document**   
- [settings.py](file://src/local_deep_research/database/models/settings.py)
- [routes.py](file://src/local_deep_research/web/auth/routes.py)
- [decorators.py](file://src/local_deep_research/web/auth/decorators.py)
- [api.py](file://src/local_deep_research/web/api.py)
- [rate_limiter.py](file://src/local_deep_research/web/utils/rate_limiter.py)
- [security_headers.py](file://src/local_deep_research/security/security_headers.py)
- [settings_security.json](file://src/local_deep_research/defaults/settings_security.json)
- [test_settings_models.py](file://tests/database/test_settings_models.py)
- [test_encrypted_database_orm.py](file://tests/database/test_encrypted_database_orm.py)
- [test_api_key_comprehensive.js](file://tests/ui_tests/test_api_key_comprehensive.js)
- [test_openai_api_key_usage.py](file://tests/test_openai_api_key_usage.py)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [API Key Storage and Management](#api-key-storage-and-management)
4. [Authentication Flow](#authentication-flow)
5. [Configuration and Environment Variables](#configuration-and-environment-variables)
6. [Usage Patterns](#usage-patterns)
7. [Error Handling and Troubleshooting](#error-handling-and-troubleshooting)
8. [Security Considerations](#security-considerations)
9. [Conclusion](#conclusion)

## Introduction

API Key Authentication in the local-deep-research system provides a secure mechanism for accessing both REST and WebSocket endpoints. The system implements a comprehensive authentication framework that combines API key validation with session-based authentication, rate limiting, and encrypted storage. This documentation explains the architecture, implementation details, configuration options, and usage patterns for the API key system, making it accessible to both beginners and experienced developers.

The API key system is designed to securely store sensitive credentials, validate requests, and protect against common security threats like brute force attacks and unauthorized access. It supports both web interface configuration and programmatic access, with comprehensive error handling and troubleshooting capabilities.

## Architecture Overview

The API key authentication system in local-deep-research follows a layered architecture that integrates with the application's security framework, database layer, and web interface. The system uses encrypted storage for API keys, implements rate limiting to prevent abuse, and provides both session-based and API key-based authentication methods.

```mermaid
graph TB
subgraph "Client"
A[Web Browser] --> |HTTP Requests| B
C[API Client] --> |API Requests| B
D[WebSocket Client] --> |WebSocket| B
end
subgraph "Server"
B[Web Server] --> E[Authentication Layer]
E --> F[Rate Limiting]
F --> G[API Key Validation]
G --> H[Encrypted Database]
H --> I[API Key Storage]
E --> J[Session Management]
J --> K[User Database]
B --> L[Security Headers]
end
I --> M[API Key Retrieval]
M --> G
K --> N[User Authentication]
N --> J
```

**Diagram sources**
- [routes.py](file://src/local_deep_research/web/auth/routes.py)
- [decorators.py](file://src/local_deep_research/web/auth/decorators.py)
- [settings.py](file://src/local_deep_research/database/models/settings.py)

**Section sources**
- [routes.py](file://src/local_deep_research/web/auth/routes.py#L1-L523)
- [decorators.py](file://src/local_deep_research/web/auth/decorators.py#L1-L39)

## API Key Storage and Management

The local-deep-research system stores API keys securely in an encrypted database using SQLCipher. The API key storage is implemented through the `APIKey` model, which provides encrypted storage for sensitive credentials with additional metadata for tracking and management.

```mermaid
classDiagram
class APIKey {
+int id
+string provider
+string key
+string description
+bool is_active
+datetime created_at
+datetime updated_at
+datetime last_used
+int usage_count
+__repr__()
}
class UserSettings {
+int id
+string key
+json value
+string category
+string description
+datetime created_at
+datetime updated_at
+__repr__()
}
APIKey --> "1" UserSettings : "belongs to"
UserSettings --> "1" User : "belongs to"
```

**Diagram sources**
- [settings.py](file://src/local_deep_research/database/models/settings.py#L44-L65)
- [test_settings_models.py](file://tests/database/test_settings_models.py#L212-L244)

**Section sources**
- [settings.py](file://src/local_deep_research/database/models/settings.py#L1-L91)
- [test_settings_models.py](file://tests/database/test_settings_models.py#L212-L362)

The API key system provides several key features:

1. **Encrypted Storage**: API keys are stored in an encrypted database using SQLCipher, ensuring that sensitive credentials are protected at rest.
2. **Provider Management**: Each API key is associated with a provider (e.g., "openai", "anthropic"), allowing multiple service providers to be configured.
3. **Active/Inactive Status**: API keys can be enabled or disabled without deletion, supporting key rotation and temporary deactivation.
4. **Usage Tracking**: The system tracks the last usage time and usage count for each API key, providing insights into key utilization.
5. **Key Rotation**: The system supports secure key rotation by allowing new keys to be added while deactivating old ones.

API key generation is typically handled externally by the service providers (e.g., OpenAI, Anthropic), and the generated keys are then stored in the local-deep-research system through the web interface or API. The system does not generate API keys itself but provides a secure mechanism for storing and managing keys obtained from external services.

## Authentication Flow

The authentication flow in local-deep-research combines session-based authentication with API key validation to provide secure access to both web interfaces and programmatic endpoints. The system implements a comprehensive authentication process that handles both interactive users and API clients.

```mermaid
sequenceDiagram
participant Client
participant Server
participant AuthDB
participant EncryptedDB
Client->>Server : Request (Web or API)
Server->>Server : Check Authentication
alt Web Request
Server->>Client : Redirect to Login (if not authenticated)
Client->>Server : Submit Login Form
Server->>AuthDB : Verify Credentials
AuthDB-->>Server : Authentication Result
alt Authentication Successful
Server->>EncryptedDB : Open User Database
EncryptedDB-->>Server : Database Connection
Server->>Server : Create Session
Server->>Client : Set Session Cookie
Server-->>Client : Access Granted
else Authentication Failed
Server-->>Client : Error Response
end
else API Request
Server->>Server : Check API Key/Header
alt Valid API Key
Server->>EncryptedDB : Validate Key
EncryptedDB-->>Server : Key Valid
Server-->>Client : Process Request
else Missing/Invalid Key
Server-->>Client : 401 Unauthorized
end
end
```

**Diagram sources**
- [routes.py](file://src/local_deep_research/web/auth/routes.py#L66-L140)
- [decorators.py](file://src/local_deep_research/web/auth/decorators.py#L13-L39)

**Section sources**
- [routes.py](file://src/local_deep_research/web/auth/routes.py#L66-L432)
- [decorators.py](file://src/local_deep_research/web/auth/decorators.py#L13-L39)

The authentication process follows these steps:

1. **Request Interception**: All incoming requests are intercepted by the authentication middleware.
2. **Authentication Method Detection**: The system determines whether the request is from a web browser (requiring session authentication) or an API client (requiring API key validation).
3. **Session Validation**: For web requests, the system checks for a valid session cookie and verifies the session in the session manager.
4. **API Key Validation**: For API requests, the system extracts the API key from the request headers or parameters and validates it against the stored keys.
5. **Database Connection**: Upon successful authentication, the system establishes a connection to the user's encrypted database.
6. **Access Granting**: The authenticated user is granted access to the requested resources based on their permissions.

The system also implements CSRF protection for web forms and provides a CSRF token endpoint for API clients that need to perform authenticated operations through the web interface.

## Configuration and Environment Variables

The API key system in local-deep-research can be configured through multiple methods, including the web interface, direct database settings, and environment variables. This flexibility allows for both interactive configuration and automated deployment scenarios.

### Web Interface Configuration

Users can configure API keys through the web interface by navigating to the settings page and entering their API credentials in the appropriate fields. The interface provides validation and feedback to ensure correct configuration.

### Programmatic Configuration

API keys can also be configured programmatically through the settings API or by directly updating the database. The system uses a hierarchical key structure for settings, with API keys typically stored under provider-specific paths:

- `llm.openai.api_key` - OpenAI API key
- `llm.anthropic.api_key` - Anthropic API key
- `llm.openai_endpoint.api_key` - Custom OpenAI-compatible endpoint API key

### Environment Variables

The system supports environment variable configuration as a fallback mechanism. When an API key is not set in the database, the system will check for corresponding environment variables. Environment variables are prefixed with `LDR_` to avoid conflicts with other applications:

- `LDR_LLM_OPENAI_API_KEY` - OpenAI API key
- `LDR_LLM_ANTHROPIC_API_KEY` - Anthropic API key
- `LDR_LLM_OPENAI_ENDPOINT_API_KEY` - Custom endpoint API key

The environment variable system provides a convenient way to configure API keys in containerized deployments or when using configuration management tools.

```mermaid
flowchart TD
Start([Configuration Request]) --> CheckDatabase["Check Database Settings"]
CheckDatabase --> KeyExists{"Key in Database?"}
KeyExists --> |Yes| ReturnKey["Return Database Key"]
KeyExists --> |No| CheckEnvironment["Check Environment Variables"]
CheckEnvironment --> EnvExists{"Environment Variable Set?"}
EnvExists --> |Yes| ReturnEnv["Return Environment Key"]
EnvExists --> |No| ReturnDefault["Return Default/Empty"]
ReturnKey --> End([Configuration Complete])
ReturnEnv --> End
ReturnDefault --> End
```

**Diagram sources**
- [test_openai_api_key_usage.py](file://tests/test_openai_api_key_usage.py#L86-L109)
- [update_llm_config.py](file://examples/optimization/update_llm_config.py#L111-L125)

**Section sources**
- [test_openai_api_key_usage.py](file://tests/test_openai_api_key_usage.py#L61-L122)
- [update_llm_config.py](file://examples/optimization/update_llm_config.py#L82-L154)

## Usage Patterns

The API key authentication system supports various usage patterns for both REST and WebSocket endpoints, accommodating different client types and integration scenarios.

### REST API Usage

For REST API endpoints, clients can authenticate using API keys in several ways:

1. **Authorization Header**: The preferred method is to include the API key in the Authorization header:
   ```
   Authorization: Bearer sk-api-key-123456789
   ```

2. **Query Parameter**: As an alternative, the API key can be included as a query parameter:
   ```
   GET /api/v1/research?api_key=sk-api-key-123456789
   ```

3. **Request Body**: For POST requests, the API key can be included in the JSON body:
   ```json
   {
     "api_key": "sk-api-key-123456789",
     "query": "research topic"
   }
   ```

### WebSocket Authentication

WebSocket connections require authentication to establish a secure session. The system supports WebSocket authentication through:

1. **Initial Handshake**: Including the API key in the initial WebSocket handshake request as a query parameter or header.
2. **Authentication Message**: Sending an authentication message immediately after connection with the API key.
3. **Session-Based**: Using a session cookie obtained through web authentication to establish the WebSocket connection.

### Programmatic Access Examples

The following examples demonstrate how to use API keys programmatically:

**Python Example:**
```python
import requests

# Using Authorization header
headers = {
    "Authorization": "Bearer sk-api-key-123456789",
    "Content-Type": "application/json"
}

response = requests.post(
    "http://localhost:5000/api/v1/research",
    json={"query": "machine learning trends"},
    headers=headers
)
```

**JavaScript Example:**
```javascript
// Using fetch with Authorization header
fetch('http://localhost:5000/api/v1/research', {
    method: 'POST',
    headers: {
        'Authorization': 'Bearer sk-api-key-123456789',
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({ query: 'machine learning trends' })
})
.then(response => response.json())
.then(data => console.log(data));
```

**WebSocket Example:**
```javascript
// WebSocket with API key in URL
const socket = new WebSocket(
    'ws://localhost:5000/ws/research?api_key=sk-api-key-123456789'
);

socket.onopen = function(event) {
    console.log('WebSocket connection established');
};
```

## Error Handling and Troubleshooting

The API key authentication system provides comprehensive error handling and troubleshooting capabilities to help users resolve common issues.

### Common Error Responses

The system returns standardized error responses for authentication failures:

- **401 Unauthorized**: Returned when no authentication credentials are provided or when the provided credentials are invalid.
- **403 Forbidden**: Returned when the authenticated user does not have permission to access the requested resource.
- **429 Too Many Requests**: Returned when rate limiting is triggered due to excessive requests.

### Common Issues and Solutions

**Invalid API Key:**
- **Symptom**: 401 Unauthorized response
- **Solution**: Verify the API key is correctly entered in the settings. Check for typos or extra whitespace.

**Missing API Key:**
- **Symptom**: 401 Unauthorized response with message "API key is required"
- **Solution**: Ensure the API key is included in the request headers, query parameters, or request body.

**Key Permission Errors:**
- **Symptom**: 403 Forbidden response
- **Solution**: Verify the API key has the necessary permissions for the requested operation. Check if the key is associated with the correct provider and has sufficient privileges.

**Rate Limiting Issues:**
- **Symptom**: 429 Too Many Requests response
- **Solution**: Implement request throttling in your client application. Check the rate limit headers in the response to understand the current limits.

### Troubleshooting Steps

1. **Verify API Key Format**: Ensure the API key follows the expected format (typically starting with "sk-").
2. **Check Key Status**: Verify the API key is active in the settings interface.
3. **Test Authentication Method**: Try different authentication methods (header, query parameter, etc.) to isolate the issue.
4. **Review Server Logs**: Check the application logs for detailed error messages and authentication attempts.
5. **Test with Different Endpoints**: Verify if the issue affects all endpoints or is specific to certain ones.
6. **Clear Browser Cache**: For web interface issues, clear the browser cache and cookies.
7. **Restart Server**: In some cases, restarting the server can resolve authentication issues.

```mermaid
flowchart TD
Start([Authentication Issue]) --> IdentifyError["Identify Error Type"]
IdentifyError --> InvalidKey{"Invalid Key?"}
InvalidKey --> |Yes| VerifyKey["Verify Key in Settings"]
InvalidKey --> |No| MissingKey{"Missing Key?"}
MissingKey --> |Yes| CheckHeaders["Check Request Headers/Parameters"]
MissingKey --> |No| PermissionError{"Permission Error?"}
PermissionError --> |Yes| CheckPermissions["Verify Key Permissions"]
PermissionError --> |No| RateLimit{"Rate Limit?"}
RateLimit --> |Yes| ImplementThrottling["Implement Request Throttling"]
RateLimit --> |No| CheckLogs["Check Server Logs"]
VerifyKey --> End([Resolved])
CheckHeaders --> End
CheckPermissions --> End
ImplementThrottling --> End
CheckLogs --> End
```

**Diagram sources**
- [test_api_key_comprehensive.js](file://tests/ui_tests/test_api_key_comprehensive.js#L30-L36)
- [test_openai_api_key_usage.py](file://tests/test_openai_api_key_usage.py#L74-L77)

**Section sources**
- [test_api_key_comprehensive.js](file://tests/ui_tests/test_api_key_comprehensive.js#L1-L507)
- [test_openai_api_key_usage.py](file://tests/test_openai_api_key_usage.py#L61-L122)

## Security Considerations

The API key authentication system implements multiple security measures to protect against common threats and ensure the confidentiality of sensitive credentials.

### Encryption and Storage Security

API keys are stored in an encrypted database using SQLCipher, providing protection at rest. The encryption ensures that even if the database file is compromised, the API keys cannot be easily extracted.

### Rate Limiting

The system implements rate limiting to prevent brute force attacks and abuse:
- **Default Rate Limit**: 5000 requests per hour, 50,000 per day
- **Login Rate Limit**: 5 attempts per 15 minutes
- **Registration Rate Limit**: 3 attempts per hour

These limits can be configured through the security settings in the application.

```mermaid
flowchart TD
A[Incoming Request] --> B{Rate Limit Check}
B --> |Within Limits| C[Process Request]
B --> |Exceeded Limits| D[Reject Request]
D --> E[Return 429 Too Many Requests]
C --> F[Update Rate Limit Counter]
F --> G[Store Request Timestamp]
G --> H[Return Response]
```

**Diagram sources**
- [rate_limiter.py](file://src/local_deep_research/web/utils/rate_limiter.py#L57-L76)
- [settings_security.json](file://src/local_deep_research/defaults/settings_security.json#L2-L38)

**Section sources**
- [rate_limiter.py](file://src/local_deep_research/web/utils/rate_limiter.py#L33-L76)
- [settings_security.json](file://src/local_deep_research/defaults/settings_security.json#L1-L39)

### Secure Transmission

The system enforces secure transmission of API keys:
- **HTTPS**: API keys should only be transmitted over HTTPS connections
- **Header Usage**: API keys in headers are less likely to be logged than in URLs
- **Short-Lived Tokens**: For enhanced security, consider using short-lived tokens instead of long-term API keys

### Key Rotation and Management

The system supports secure key rotation practices:
- **Deactivate Old Keys**: Old keys can be deactivated without deletion, maintaining audit trails
- **Usage Monitoring**: Track key usage to identify compromised keys
- **Regular Rotation**: Implement regular key rotation as a security best practice

## Conclusion

The API Key Authentication system in local-deep-research provides a robust and secure mechanism for protecting access to both web interfaces and programmatic endpoints. By combining encrypted storage, comprehensive authentication flows, and flexible configuration options, the system ensures that sensitive credentials are protected while providing convenient access for authorized users and applications.

Key takeaways:
- API keys are securely stored in an encrypted database with usage tracking
- Multiple authentication methods are supported for different client types
- Comprehensive error handling and troubleshooting guidance is provided
- Security measures including rate limiting and secure transmission are implemented
- Flexible configuration options support both interactive and automated setups

The system strikes a balance between security and usability, making it accessible to beginners while providing the depth and flexibility needed by experienced developers. By following the best practices outlined in this documentation, users can effectively configure and manage API keys to secure their local-deep-research deployments.