# IONOS Configuration

<cite>
**Referenced Files in This Document**   
- [ionos.py](file://src/local_deep_research/llm/providers/implementations/ionos.py)
- [ionos_settings.json](file://src/local_deep_research/defaults/llm_providers/ionos_settings.json)
- [openai_base.py](file://src/local_deep_research/llm/providers/openai_base.py)
- [llm_registry.py](file://src/local_deep_research/llm/llm_registry.py)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Configuration Parameters](#configuration-parameters)
3. [Authentication Setup](#authentication-setup)
4. [IONOS Provider Implementation](#ionos-provider-implementation)
5. [Provider-Specific Features](#provider-specific-features)
6. [Advanced Configuration](#advanced-configuration)
7. [Security Considerations](#security-considerations)

## Introduction
IONOS AI Model Hub provides a GDPR-compliant cloud LLM service with data processing in Germany. The service offers OpenAI-compatible API endpoints and is currently free until September 30, 2025. This document details the configuration and integration of IONOS as a cloud LLM provider within the Local Deep Research system, covering authentication methods, configuration parameters, implementation details, and security considerations.

**Section sources**
- [ionos.py](file://src/local_deep_research/llm/providers/implementations/ionos.py#L1-L70)

## Configuration Parameters
The IONOS provider requires specific configuration parameters to establish connectivity and authentication. The primary configuration parameter is the API key, which is used for authenticating requests to the IONOS AI Model Hub. Additional parameters include the base URL endpoint and model identifiers.

The required configuration parameters are:
- **API Key**: Authentication credential for accessing IONOS services
- **Base URL**: Endpoint for the IONOS AI Model Hub API
- **Model Identifier**: Specifies which LLM model to use for inference
- **Default Model**: The fallback model used when no specific model is requested

The default base URL is set to `https://openai.inference.de-txl.ionos.com/v1`, which corresponds to the German data center. The default model is configured as `meta-llama/llama-3.2-3b-instruct`, an open model available through the IONOS platform.

**Section sources**
- [ionos.py](file://src/local_deep_research/llm/providers/implementations/ionos.py#L17-L20)
- [ionos_settings.json](file://src/local_deep_research/defaults/llm_providers/ionos_settings.json#L1-L16)

## Authentication Setup
Authentication for IONOS can be configured through environment variables or JSON configuration files. The system supports both methods to accommodate different deployment scenarios and security requirements.

### Environment Variable Configuration
The recommended method for authentication is through the environment variable `IONOS_API_KEY`. This approach keeps sensitive credentials out of configuration files and allows for easy rotation without modifying application code.

To configure authentication via environment variables:
1. Set the `IONOS_API_KEY` environment variable with your API key
2. Ensure the application has access to read environment variables
3. The system automatically detects and uses the API key during initialization

### JSON Configuration File Setup
For environments where environment variables are not preferred, authentication can be configured through JSON settings files. The IONOS API key is stored in the configuration under the key `llm.ionos.api_key`.

The configuration structure in JSON format:
```json
{
    "llm.ionos.api_key": {
        "category": "llm_general",
        "description": "API key to use for the IONOS AI Model Hub provider (GDPR-compliant, data processed in Germany).",
        "editable": true,
        "name": "IONOS API Key",
        "type": "SEARCH",
        "ui_element": "password",
        "value": null,
        "visible": true
    }
}
```

**Section sources**
- [ionos.py](file://src/local_deep_research/llm/providers/implementations/ionos.py#L18)
- [ionos_settings.json](file://src/local_deep_research/defaults/llm_providers/ionos_settings.json#L1-L16)

## IONOS Provider Implementation
The IONOS provider is implemented as a specialized class that extends the base `OpenAICompatibleProvider` class, enabling compatibility with OpenAI's API structure while incorporating IONOS-specific requirements.

### Class Structure and Inheritance
The `IONOSProvider` class inherits from `OpenAICompatibleProvider`, which provides the foundational functionality for OpenAI-compatible services. This inheritance pattern allows the IONOS provider to leverage existing OpenAI client functionality while customizing specific behaviors.

```mermaid
classDiagram
class OpenAICompatibleProvider {
+provider_name : str
+api_key_setting : str
+default_base_url : str
+default_model : str
+create_llm(model_name, temperature, **kwargs) BaseChatModel
+is_available(settings_snapshot) bool
+requires_auth_for_models() bool
+list_models(settings_snapshot) List[Dict]
}
class IONOSProvider {
+provider_name : str
+api_key_setting : str
+default_base_url : str
+default_model : str
+provider_key : str
+company_name : str
+region : str
+country : str
+gdpr_compliant : bool
+data_location : str
+is_cloud : bool
+requires_auth_for_models() bool
}
IONOSProvider --|> OpenAICompatibleProvider : extends
note right of IONOSProvider
IONOS-specific configuration and metadata
Inherits core functionality from base class
end note
```

**Diagram sources**
- [ionos.py](file://src/local_deep_research/llm/providers/implementations/ionos.py#L9-L35)
- [openai_base.py](file://src/local_deep_research/llm/providers/openai_base.py#L25-L38)

### Authentication Requirements
The IONOS provider requires authentication for all API operations, including listing available models. This is implemented through the `requires_auth_for_models()` class method, which returns `True` to indicate that authentication is mandatory.

The authentication process follows these steps:
1. Retrieve the API key from settings or environment variables
2. Validate that the API key is present and not empty
3. Include the API key in all requests to the IONOS endpoint
4. Handle authentication failures with appropriate error messages

The system automatically checks for the presence of the API key and raises a `ValueError` if authentication is not properly configured, ensuring that misconfigurations are caught early in the process.

**Section sources**
- [ionos.py](file://src/local_deep_research/llm/providers/implementations/ionos.py#L31-L35)
- [openai_base.py](file://src/local_deep_research/llm/providers/openai_base.py#L54-L71)

## Provider-Specific Features
The IONOS provider includes several features specific to its service offering and compliance requirements.

### Regional Endpoints
IONOS provides regional endpoints to ensure data residency and compliance with local regulations. The default configuration uses the German data center endpoint, which processes all data within Germany. This is particularly important for GDPR compliance, as it ensures that personal data remains within the European Union.

The regional endpoint configuration includes:
- Data processing location: Germany
- Region identifier: EU
- Country: Germany
- GDPR compliance: True

These metadata attributes are used by the system's provider discovery mechanism to present IONOS as a GDPR-compliant option in user interfaces and selection menus.

### Service-Specific Headers
While the IONOS API is OpenAI-compatible and uses standard authentication headers, the implementation includes provider-specific metadata that is used internally by the system. This metadata helps with logging, monitoring, and provider selection in multi-provider environments.

The provider metadata includes:
- `provider_key`: "IONOS" - used for internal identification
- `company_name`: "IONOS" - displayed in provider lists
- `region`: "EU" - indicates the geographic region
- `country`: "Germany" - specific country of operation
- `gdpr_compliant`: True - indicates GDPR compliance status
- `data_location`: "Germany" - where data is processed
- `is_cloud`: True - indicates this is a cloud service

**Section sources**
- [ionos.py](file://src/local_deep_research/llm/providers/implementations/ionos.py#L22-L30)

## Advanced Configuration
The IONOS provider supports advanced configuration options beyond the basic setup, allowing for fine-tuned control over the integration.

### Custom Base URLs for Different Regions
Although the default configuration points to the German data center, the system supports custom base URLs for different IONOS regions. This flexibility allows users to select alternative endpoints based on performance, latency, or specific compliance requirements.

To configure a custom base URL:
1. Override the `base_url` parameter when creating the LLM instance
2. Or set a custom URL in the configuration settings
3. The system will use the specified URL instead of the default

The configuration system normalizes URLs to ensure proper formatting and prevent common configuration errors.

### Request Timeout Settings
The IONOS provider inherits request timeout capabilities from the base `OpenAICompatibleProvider` class. Timeout settings can be configured globally or on a per-request basis to handle network conditions and performance requirements.

Timeout configuration options:
- Global timeout setting via `llm.request_timeout` in settings
- Per-request timeout override through the `request_timeout` parameter
- Default timeout inherited from the system's safe request configuration

The timeout mechanism helps prevent hanging requests and ensures that the application remains responsive even when the IONOS service experiences delays.

**Section sources**
- [ionos.py](file://src/local_deep_research/llm/providers/implementations/ionos.py#L19)
- [openai_base.py](file://src/local_deep_research/llm/providers/openai_base.py#L128-L138)

## Security Considerations
Integrating with IONOS AI services requires careful attention to security practices, particularly regarding API key management and data transmission.

### API Key Storage Security
The security of API keys is paramount when integrating with cloud LLM providers. The system implements several measures to protect API keys:

1. **Environment Variables**: Storing API keys in environment variables prevents them from being exposed in configuration files or version control systems.

2. **Secure UI Elements**: In user interfaces, the API key field is configured with `ui_element: "password"`, ensuring that the key is masked when displayed.

3. **Configuration File Protection**: When using JSON configuration files, the system should ensure these files have appropriate file permissions to prevent unauthorized access.

4. **Memory Management**: The system follows secure coding practices to minimize the time API keys spend in memory and to prevent them from being logged or exposed in error messages.

### Transmission Security
All communication with the IONOS AI Model Hub uses HTTPS to encrypt data in transit. The default base URL uses the HTTPS protocol, ensuring that all API requests and responses are encrypted.

Additional transmission security considerations:
- **SSRF Protection**: The system's `safe_requests` module includes protection against Server-Side Request Forgery attacks, validating URLs before making requests.
- **Connection Validation**: The system verifies the security of connections and can be configured to reject insecure connections.
- **Data Minimization**: Only necessary data is transmitted to the IONOS service, reducing the potential impact of any security incidents.

The GDPR-compliant nature of the IONOS service, with data processing in Germany, provides an additional layer of regulatory protection for personal data, making it a suitable choice for applications with strict data privacy requirements.

**Section sources**
- [ionos_settings.json](file://src/local_deep_research/defaults/llm_providers/ionos_settings.json#L12)
- [ionos.py](file://src/local_deep_research/llm/providers/implementations/ionos.py#L27-L28)
- [safe_requests.py](file://src/local_deep_research/security/safe_requests.py#L11)