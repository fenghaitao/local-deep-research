# Local LLM Providers

<cite>
**Referenced Files in This Document**   
- [ollama.py](file://src/local_deep_research/llm/providers/implementations/ollama.py)
- [lmstudio.py](file://src/local_deep_research/llm/providers/implementations/lmstudio.py)
- [llm_registry.py](file://src/local_deep_research/llm/llm_registry.py)
- [thread_settings.py](file://src/local_deep_research/config/thread_settings.py)
- [llm_config.py](file://src/local_deep_research/config/llm_config.py)
- [research.html](file://src/local_deep_research/web/templates/pages/research.html)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json)
- [settings_ollama_embeddings.json](file://src/local_deep_research/defaults/settings_ollama_embeddings.json)
- [llm_utils.py](file://src/local_deep_research/utilities/llm_utils.py)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Ollama Configuration](#ollama-configuration)
3. [LM Studio Configuration](#lm-studio-configuration)
4. [Model Management](#model-management)
5. [Inference Parameters](#inference-parameters)
6. [Advanced Settings](#advanced-settings)
7. [Implementation Details](#implementation-details)
8. [Troubleshooting](#troubleshooting)
9. [Performance Optimization](#performance-optimization)

## Introduction

This document provides comprehensive guidance for configuring local LLM providers, specifically focusing on Ollama and LM Studio integration within the Local Deep Research system. The documentation covers setup procedures, configuration options, implementation specifics, and troubleshooting guidance for connecting to locally running LLM servers.

Local LLM providers offer enhanced privacy, reduced latency, and offline capabilities compared to cloud-based alternatives. Ollama and LM Studio are two popular local inference frameworks that enable users to run large language models directly on their hardware. This document details the configuration process for both providers, including host, port, and protocol settings, model specification, inference parameter configuration, and advanced settings for optimal performance.

The implementation leverages a modular provider architecture that allows seamless integration of different LLM backends while maintaining consistent interfaces for model listing, completion requests, and error handling. Understanding these configuration options and implementation details is essential for maximizing the effectiveness of local LLM deployment in research workflows.

## Ollama Configuration

Configuring Ollama as a local LLM provider requires setting up the connection parameters and authentication details. The primary configuration setting is `llm.ollama.url`, which specifies the endpoint for the Ollama server. By default, Ollama runs on `http://localhost:11434`, but this can be customized based on deployment requirements. The URL setting is used for both model listing and inference requests, ensuring consistent communication with the Ollama API.

Authentication for Ollama is optional and configured through the `llm.ollama.api_key` setting. When configured, the API key is transmitted using Bearer token authentication in the Authorization header, enabling secure access to authenticated Ollama instances. This is particularly useful when Ollama is deployed behind a reverse proxy or when running in a multi-user environment requiring access control.

The Ollama provider implementation includes comprehensive availability checking by querying the `/api/tags` endpoint to verify server responsiveness and model availability. This health check is performed before any inference requests to prevent failed operations due to server unavailability. The provider also supports both older and newer Ollama API formats, ensuring compatibility across different Ollama versions.

In the web interface, the Ollama endpoint configuration is dynamically displayed when the Ollama provider is selected, with the input field labeled "Ollama Endpoint" and a placeholder showing the default URL format. This user-friendly interface simplifies configuration for non-technical users while maintaining the flexibility needed for advanced deployments.

**Section sources**
- [ollama.py](file://src/local_deep_research/llm/providers/implementations/ollama.py#L36-L37)
- [research.html](file://src/local_deep_research/web/templates/pages/research.html#L98-L103)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L366-L371)

## LM Studio Configuration

LM Studio configuration follows a similar pattern to other OpenAI-compatible providers but with specific adaptations for its local deployment model. The provider uses the `llm.lmstudio.url` setting to specify the connection endpoint, with a default value of `http://localhost:1234`. Unlike cloud providers, LM Studio does not require a genuine API key for authentication, as it operates as a local service. Instead, the implementation uses a placeholder key value of "not-required" to satisfy the OpenAI client requirements while indicating that no actual authentication is needed.

The LM Studio provider inherits from the `OpenAICompatibleProvider` base class, which provides shared functionality for OpenAI-compatible endpoints. This inheritance allows the LM Studio implementation to leverage existing OpenAI client functionality while overriding specific behaviors to accommodate LM Studio's unique characteristics. The provider automatically appends the `/v1` path to the base URL, as LM Studio exposes its API at this endpoint.

Availability checking for LM Studio is implemented by querying the `/v1/models` endpoint with a short timeout of 1.0 seconds. This quick health check verifies that the LM Studio server is running and responsive before attempting inference operations. The check is designed to be lightweight to minimize impact on application performance while providing reliable availability detection.

The web interface includes a dedicated container for the LM Studio URL configuration that appears when LM Studio is selected as the provider. This dynamic form element ensures that users only see relevant configuration options based on their provider selection, reducing interface complexity and potential configuration errors.

**Section sources**
- [lmstudio.py](file://src/local_deep_research/llm/providers/implementations/lmstudio.py#L17-L18)
- [research.html](file://src/local_deep_research/web/templates/pages/research.html#L105-L107)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L366-L371)

## Model Management

Model management for local LLM providers involves discovering available models, validating model availability, and handling model selection. The Ollama provider implements a robust model listing mechanism through the `list_models_for_api` method, which queries the Ollama server's `/api/tags` endpoint to retrieve the complete list of installed models. This method normalizes the response format to ensure consistency across different Ollama API versions, extracting model names and creating user-friendly display labels.

When creating an LLM instance, both Ollama and LM Studio providers perform model availability validation before initialization. For Ollama, this involves checking the requested model against the list of available models retrieved from the server. If the specified model is not found, a `ValueError` is raised with descriptive information about available models, helping users correct configuration errors. This validation prevents failed inference attempts due to missing models.

The model selection process supports both explicit model specification and default model usage. The Ollama provider uses "gemma:latest" as its default model, while LM Studio uses "local-model" as a placeholder, encouraging users to specify their loaded model. This design ensures that the system can operate with reasonable defaults while allowing customization for specific use cases.

Model names are handled in a case-insensitive manner throughout the system, with normalization to lowercase for consistent storage and retrieval. This approach prevents issues related to case variations in model names and ensures reliable model matching across different components of the application.

**Section sources**
- [ollama.py](file://src/local_deep_research/llm/providers/implementations/ollama.py#L74-L116)
- [lmstudio.py](file://src/local_deep_research/llm/providers/implementations/lmstudio.py#L30-L50)
- [llm_utils.py](file://src/local_deep_research/utilities/llm_utils.py#L104-L159)

## Inference Parameters

Inference parameters control the behavior and output characteristics of LLM responses. The system supports configuration of key parameters including temperature, top_p, and max_tokens through both provider-specific implementations and global settings. Temperature controls the randomness of predictions, with lower values producing more deterministic outputs and higher values increasing creativity. The default temperature is set to 0.7, balancing coherence and diversity in generated text.

The max_tokens parameter determines the maximum length of generated responses. For local providers, this value is calculated as 80% of the context window size to ensure sufficient space for input prompts and system messages. This calculation prevents context overflow errors while maximizing response length. The context window size is configurable through the `llm.local_context_window_size` setting, with a default value that balances performance and memory usage.

Top_p (nucleus sampling) is supported through the underlying LangChain implementations, allowing for dynamic adjustment of the probability mass considered during token generation. This parameter works in conjunction with temperature to control output diversity and quality. Both Ollama and LM Studio providers pass these parameters directly to their respective client libraries, ensuring consistent behavior with the underlying models.

These inference parameters can be configured globally or overridden on a per-request basis, providing flexibility for different research scenarios. The web interface exposes these parameters in the research configuration section, allowing users to adjust them based on their specific requirements without requiring code changes.

**Section sources**
- [ollama.py](file://src/local_deep_research/llm/providers/implementations/ollama.py#L208-L243)
- [lmstudio.py](file://src/local_deep_research/llm/providers/implementations/lmstudio.py#L30-L50)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L338-L371)

## Advanced Settings

Advanced settings for local LLM providers include GPU layer allocation, context window configuration, and streaming response options. The context window size is a critical parameter that affects both performance and memory usage. For local providers, this is controlled by the `llm.local_context_window_size` setting, which defaults to a value that balances capability and resource constraints. This setting directly influences the `num_ctx` parameter passed to the Ollama client, determining the maximum sequence length the model can process.

GPU layer allocation is managed by the underlying inference engines (Ollama and LM Studio) rather than the application itself. However, the application provides the necessary configuration hooks to support GPU acceleration when available. This includes proper header configuration and protocol handling to ensure optimal performance when GPU resources are utilized.

Streaming responses are supported through the underlying LangChain implementations, allowing for real-time display of generated content. This feature improves user experience by providing immediate feedback during long-running inference operations. The streaming configuration is handled automatically by the provider implementations, with appropriate callbacks and event handling to process partial responses.

The system also supports separate configuration for embedding models through the `embeddings.ollama.url` setting, allowing users to direct embedding operations to a different Ollama server than LLM operations. This separation enables specialized hardware configurations where embedding and inference workloads are distributed across different systems for optimal performance.

**Section sources**
- [ollama.py](file://src/local_deep_research/llm/providers/implementations/ollama.py#L218-L243)
- [settings_ollama_embeddings.json](file://src/local_deep_research/defaults/settings_ollama_embeddings.json#L1-L16)
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L366-L371)

## Implementation Details

The implementation of local LLM providers follows a modular architecture with clear separation of concerns. Both Ollama and LM Studio providers are registered in the global LLM registry through the `llm_registry.py` module, which provides thread-safe storage and retrieval of LLM instances and factory functions. This registry pattern enables dynamic provider loading and ensures consistent access to LLM instances across different parts of the application.

The Ollama provider implementation uses the `langchain_ollama.ChatOllama` client, which provides a comprehensive interface for Ollama interactions. The provider class handles authentication header generation, URL normalization, and error handling, abstracting these complexities from higher-level components. The `create_llm` method constructs the client with appropriate parameters, including model name, temperature, and context window size, while the `is_available` method performs health checks to verify server availability.

The LM Studio provider leverages inheritance from the `OpenAICompatibleProvider` base class, demonstrating the system's extensibility for OpenAI-compatible endpoints. This design allows LM Studio to reuse existing OpenAI client functionality while customizing specific behaviors such as authentication (using a placeholder key) and URL construction (appending the `/v1` path). The provider overrides the `create_llm` method to inject LM Studio-specific configuration while maintaining the same interface as other providers.

Both providers implement the factory pattern through standalone functions (`create_ollama_llm` and `create_lmstudio_llm`) that serve as entry points for LLM creation. These functions are registered with the LLM registry and can be called directly when needed, providing flexibility in how LLM instances are obtained. The implementation also includes comprehensive logging throughout the provider lifecycle, aiding in debugging and monitoring.

**Section sources**
- [ollama.py](file://src/local_deep_research/llm/providers/implementations/ollama.py#L27-L345)
- [lmstudio.py](file://src/local_deep_research/llm/providers/implementations/lmstudio.py#L9-L115)
- [llm_registry.py](file://src/local_deep_research/llm/llm_registry.py#L1-L162)

## Troubleshooting

Troubleshooting local LLM provider issues involves addressing connectivity problems, model loading errors, and configuration inconsistencies. Common connectivity issues include incorrect URL configuration, firewall restrictions, and server unavailability. The system provides diagnostic logging that records connection attempts, response codes, and error messages, helping identify the root cause of connectivity problems.

Model loading errors typically occur when the requested model is not installed on the local server or when there are permission issues accessing the model files. The Ollama provider includes explicit model validation that checks for model existence before attempting inference, providing clear error messages when models are missing. Users should verify model installation through the Ollama command line interface or LM Studio interface before configuring them in the application.

Configuration inconsistencies can arise from mismatched settings between the application and the local LLM server. For example, using HTTPS when the server only supports HTTP, or specifying an incorrect port number. The system's health check mechanisms help identify these issues by testing connectivity before processing requests. Users should ensure that the configured URL matches the actual server address and port.

Resource-related issues, such as insufficient memory or GPU resources, may cause inference operations to fail or perform poorly. Monitoring system resources and adjusting the context window size or model complexity can help mitigate these issues. The application's logging includes information about resource usage and performance metrics that can aid in diagnosing resource constraints.

**Section sources**
- [ollama.py](file://src/local_deep_research/llm/providers/implementations/ollama.py#L254-L308)
- [lmstudio.py](file://src/local_deep_research/llm/providers/implementations/lmstudio.py#L53-L73)
- [llm_utils.py](file://src/local_deep_research/utilities/llm_utils.py#L126-L158)

## Performance Optimization

Performance optimization for local LLM inference involves configuring parameters to balance speed, quality, and resource utilization. The context window size should be set appropriately for the available hardware, with smaller values reducing memory usage and improving response times. For systems with limited RAM, reducing the `llm.local_context_window_size` setting can prevent out-of-memory errors and improve stability.

Model selection significantly impacts performance, with smaller models generally providing faster inference times at the cost of reduced capability. Users should select models that match their hardware capabilities and research requirements. The system's model listing functionality helps identify available models and their characteristics, enabling informed selection.

Caching strategies can improve performance by reducing redundant computations. While the core LLM providers do not implement caching directly, the application framework supports caching at higher levels for repeated queries or similar research tasks. This reduces the load on the LLM server and improves overall system responsiveness.

Resource monitoring and load balancing are essential for maintaining optimal performance, especially when running multiple research tasks concurrently. The system's configuration allows limiting concurrent research processes through the `app.max_concurrent_researches` setting, preventing resource exhaustion and ensuring consistent performance across tasks.

**Section sources**
- [default_settings.json](file://src/local_deep_research/defaults/default_settings.json#L118-L131)
- [ollama.py](file://src/local_deep_research/llm/providers/implementations/ollama.py#L218-L243)
- [llm_config.py](file://src/local_deep_research/config/llm_config.py#L482-L516)