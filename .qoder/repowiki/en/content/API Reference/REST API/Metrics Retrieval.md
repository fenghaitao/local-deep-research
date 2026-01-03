# Metrics Retrieval

<cite>
**Referenced Files in This Document**   
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py)
- [database.py](file://src/local_deep_research/metrics/database.py)
- [query_utils.py](file://src/local_deep_research/metrics/query_utils.py)
- [cost_calculator.py](file://src/local_deep_research/metrics/pricing/cost_calculator.py)
- [pricing_fetcher.py](file://src/local_deep_research/metrics/pricing/pricing_fetcher.py)
- [pricing_cache.py](file://src/local_deep_research/metrics/pricing/pricing_cache.py)
- [metrics.py](file://src/local_deep_research/database/models/metrics.py)
- [thread_metrics.py](file://src/local_deep_research/database/thread_metrics.py)
- [metrics_routes.py](file://src/local_deep_research/web/routes/metrics_routes.py)
- [test_metrics_api.py](file://tests/api_tests/test_metrics_api.py)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Metrics Data Model](#metrics-data-model)
3. [API Endpoints](#api-endpoints)
4. [Cost Calculation System](#cost-calculation-system)
5. [Aggregation Methods](#aggregation-methods)
6. [Time-Series Data](#time-series-data)
7. [Error Handling](#error-handling)
8. [Authentication Requirements](#authentication-requirements)
9. [Relationship to Tracking System](#relationship-to-tracking-system)
10. [Examples](#examples)

## Introduction

The metrics and analytics system provides comprehensive tracking and retrieval capabilities for research costs, API usage, performance data, and system analytics. This documentation details the endpoints and data models used to monitor and analyze the system's operations, with a focus on cost analytics, token usage, and performance metrics.

The system collects detailed information during research execution, including token usage across different LLM providers, search engine performance, and cost calculations based on provider pricing. The metrics are stored in encrypted user databases and can be retrieved through various API endpoints for analysis and visualization.

**Section sources**
- [metrics_routes.py](file://src/local_deep_research/web/routes/metrics_routes.py#L1-L50)
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py#L1-L50)

## Metrics Data Model

The metrics system uses a comprehensive data model to track various aspects of research operations. The primary data structures include token usage, search call tracking, and model usage statistics.

### Token Usage Model

The `TokenUsage` model tracks detailed information about each LLM call, including token counts, costs, and performance metrics:

```mermaid
erDiagram
TOKEN_USAGE {
integer id PK
string research_id FK
timestamp timestamp
string model_provider
string model_name
integer prompt_tokens
integer completion_tokens
integer total_tokens
float prompt_cost
float completion_cost
float total_cost
string operation_type
json operation_details
string research_mode
integer response_time_ms
string success_status
string error_type
text research_query
string research_phase
integer search_iteration
json search_engines_planned
string search_engine_selected
string calling_file
string calling_function
json call_stack
integer context_limit
boolean context_truncated
integer tokens_truncated
float truncation_ratio
integer ollama_prompt_eval_count
integer ollama_eval_count
integer ollama_total_duration
integer ollama_load_duration
integer ollama_prompt_eval_duration
integer ollama_eval_duration
}
RESEARCH_HISTORY ||--o{ TOKEN_USAGE : "has"
```

### Search Call Model

The `SearchCall` model tracks individual search engine operations with performance and success metrics:

```mermaid
erDiagram
SEARCH_CALL {
integer id PK
string research_id FK
timestamp timestamp
string search_engine
text query
integer num_results_requested
integer num_results_returned
float response_time_ms
integer success
text error_message
integer rate_limited
float wait_time_ms
string research_mode
text research_query
string research_phase
integer search_iteration
string success_status
string error_type
integer results_count
}
RESEARCH_HISTORY ||--o{ SEARCH_CALL : "has"
```

### Model Usage Model

The `ModelUsage` model provides aggregate statistics for each LLM model:

```mermaid
erDiagram
MODEL_USAGE {
integer id PK
string model_provider
string model_name
integer total_calls
integer total_tokens
float total_cost
float avg_response_time_ms
integer error_count
float success_rate
timestamp first_used_at
timestamp last_used_at
}
```

**Diagram sources**
- [metrics.py](file://src/local_deep_research/database/models/metrics.py#L20-L133)

**Section sources**
- [metrics.py](file://src/local_deep_research/database/models/metrics.py#L1-L210)

## API Endpoints

The metrics system provides several REST API endpoints for retrieving different types of analytics data. All endpoints require authentication and return JSON responses.

### Core Metrics Endpoints

```mermaid
graph TD
A[GET /metrics/api/metrics] --> B[Overall metrics summary]
C[GET /metrics/api/metrics/research/{research_id}] --> D[Specific research metrics]
E[GET /metrics/api/metrics/research/{research_id}/timeline] --> F[Timeline metrics]
G[GET /metrics/api/metrics/research/{research_id}/search] --> H[Search metrics]
I[GET /metrics/api/cost-analytics] --> J[Cost analytics]
K[GET /metrics/api/pricing] --> L[Pricing information]
M[GET /metrics/api/rate-limiting] --> N[Rate limiting metrics]
O[GET /metrics/api/rate-limiting/current] --> P[Current rate limits]
```

**Diagram sources**
- [metrics_routes.py](file://src/local_deep_research/web/routes/metrics_routes.py#L860-L1037)
- [route_registry.py](file://src/local_deep_research/web/routes/route_registry.py#L236-L276)

### Endpoint Details

#### Overall Metrics Summary
- **Endpoint**: `GET /metrics/api/metrics`
- **Parameters**: 
  - `period`: Time period filter ('7d', '30d', '3m', '1y', 'all')
  - `mode`: Research mode filter ('quick', 'detailed', 'all')
- **Response**: Comprehensive metrics including token usage, search statistics, strategy analytics, and rate limiting data

#### Research-Specific Metrics
- **Endpoint**: `GET /metrics/api/metrics/research/{research_id}`
- **Parameters**: None
- **Response**: Token usage metrics for a specific research session, including total tokens, calls, and model breakdown

#### Cost Analytics
- **Endpoint**: `GET /metrics/api/cost-analytics`
- **Parameters**: None
- **Response**: Cost breakdown by model, provider, and research session, including total costs and cost per token

#### Pricing Information
- **Endpoint**: `GET /metrics/api/pricing`
- **Parameters**: None
- **Response**: Current pricing data for all supported LLM providers and models

#### Rate Limiting Metrics
- **Endpoint**: `GET /metrics/api/rate-limiting`
- **Parameters**: 
  - `period`: Time period filter ('7d', '30d', '3m', '1y', 'all')
- **Response**: Rate limiting statistics including success rates, wait times, and engine status

**Section sources**
- [metrics_routes.py](file://src/local_deep_research/web/routes/metrics_routes.py#L860-L1037)

## Cost Calculation System

The cost calculation system determines the financial cost of LLM usage based on token counts and provider pricing. The system uses a three-tiered approach: real-time pricing fetchers, in-memory caching, and static fallback pricing.

### Cost Calculator Architecture

```mermaid
classDiagram
class CostCalculator {
+cache : PricingCache
+pricing_fetcher : PricingFetcher
+get_model_pricing(model_name, provider) Dict[str, float]
+calculate_cost(model_name, prompt_tokens, completion_tokens, provider) Dict[str, float]
+calculate_batch_costs(usage_records) List[Dict[str, Any]]
+calculate_cost_sync(model_name, prompt_tokens, completion_tokens) Dict[str, float]
+get_research_cost_summary(usage_records) Dict[str, Any]
}
class PricingFetcher {
+session : aiohttp.ClientSession
+static_pricing : Dict[str, Dict[str, float]]
+fetch_openai_pricing() Optional[Dict[str, Any]]
+fetch_anthropic_pricing() Optional[Dict[str, Any]]
+fetch_google_pricing() Optional[Dict[str, Any]]
+fetch_huggingface_pricing() Optional[Dict[str, Any]]
+get_model_pricing(model_name, provider) Optional[Dict[str, float]]
+get_all_pricing() Dict[str, Dict[str, float]]
+get_provider_from_model(model_name) str
}
class PricingCache {
+cache_ttl : int
+_cache : Dict[str, Dict[str, Any]]
+get(key) Optional[Any]
+set(key, data)
+get_model_pricing(model_name) Optional[Dict[str, float]]
+set_model_pricing(model_name, pricing)
+get_all_pricing() Optional[Dict[str, Dict[str, float]]]
+set_all_pricing(pricing)
+clear()
+clear_expired()
+get_cache_stats() Dict[str, Any]
}
CostCalculator --> PricingCache : "uses"
CostCalculator --> PricingFetcher : "uses"
```

**Diagram sources**
- [cost_calculator.py](file://src/local_deep_research/metrics/pricing/cost_calculator.py#L16-L237)
- [pricing_fetcher.py](file://src/local_deep_research/metrics/pricing/pricing_fetcher.py#L14-L241)
- [pricing_cache.py](file://src/local_deep_research/metrics/pricing/pricing_cache.py#L14-L109)

### Pricing Data Flow

```mermaid
sequenceDiagram
participant Client as "API Client"
participant CostCalc as "CostCalculator"
participant Cache as "PricingCache"
participant Fetcher as "PricingFetcher"
Client->>CostCalc : calculate_cost(model, tokens)
CostCalc->>Cache : get_model_pricing(model)
alt Cache hit
Cache-->>CostCalc : Pricing data
CostCalc->>CostCalc : Calculate cost
CostCalc-->>Client : Cost breakdown
else Cache miss
Cache-->>CostCalc : No data
CostCalc->>Fetcher : get_model_pricing(model)
alt Live pricing available
Fetcher-->>CostCalc : Pricing data
CostCalc->>Cache : set_model_pricing(model, pricing)
else No live pricing
Fetcher-->>CostCalc : None
CostCalc->>Fetcher : static_pricing.get(model)
Fetcher-->>CostCalc : Static pricing
end
CostCalc->>CostCalc : Calculate cost
CostCalc-->>Client : Cost breakdown
end
```

**Diagram sources**
- [cost_calculator.py](file://src/local_deep_research/metrics/pricing/cost_calculator.py#L32-L94)
- [pricing_fetcher.py](file://src/local_deep_research/metrics/pricing/pricing_fetcher.py#L117-L181)

### Static Pricing Database

The system includes a comprehensive static pricing database for major LLM providers:

```mermaid
erDiagram
PRICING_DATA {
string model_name PK
float prompt_price_per_1k_tokens
float completion_price_per_1k_tokens
string provider
}
PRICING_DATA {
"gpt-4" : 0.03 : 0.06 : "openai"
"gpt-4-turbo" : 0.01 : 0.03 : "openai"
"gpt-4o" : 0.005 : 0.015 : "openai"
"gpt-4o-mini" : 0.00015 : 0.0006 : "openai"
"gpt-3.5-turbo" : 0.001 : 0.002 : "openai"
"claude-3-opus" : 0.015 : 0.075 : "anthropic"
"claude-3-sonnet" : 0.003 : 0.015 : "anthropic"
"claude-3-haiku" : 0.00025 : 0.00125 : "anthropic"
"claude-3-5-sonnet" : 0.003 : 0.015 : "anthropic"
"gemini-pro" : 0.0005 : 0.0015 : "google"
"gemini-pro-vision" : 0.0005 : 0.0015 : "google"
"gemini-1.5-pro" : 0.0035 : 0.0105 : "google"
"gemini-1.5-flash" : 0.00035 : 0.00105 : "google"
"ollama" : 0.0 : 0.0 : "local"
"llama" : 0.0 : 0.0 : "local"
"mistral" : 0.0 : 0.0 : "local"
"gemma" : 0.0 : 0.0 : "local"
"qwen" : 0.0 : 0.0 : "local"
"codellama" : 0.0 : 0.0 : "local"
"vicuna" : 0.0 : 0.0 : "local"
"alpaca" : 0.0 : 0.0 : "local"
"vllm" : 0.0 : 0.0 : "local"
"lmstudio" : 0.0 : 0.0 : "local"
"llamacpp" : 0.0 : 0.0 : "local"
}
```

**Diagram sources**
- [pricing_fetcher.py](file://src/local_deep_research/metrics/pricing/pricing_fetcher.py#L29-L60)

**Section sources**
- [pricing_fetcher.py](file://src/local_deep_research/metrics/pricing/pricing_fetcher.py#L1-L241)

## Aggregation Methods

The metrics system employs various aggregation methods to provide summarized data across different dimensions and time periods.

### Time-Based Aggregation

The system supports multiple time periods for metric queries, with corresponding cutoff times:

```mermaid
flowchart TD
A[Time Period] --> B[7d]
A --> C[30d]
A --> D[3m]
A --> E[1y]
A --> F[all]
B --> G[Cutoff: now - 7 days]
C --> H[Cutoff: now - 30 days]
D --> I[Cutoff: now - 90 days]
E --> J[Cutoff: now - 365 days]
F --> K[No cutoff]
L[Query Execution] --> M[Apply time filter]
M --> N[Aggregate results]
N --> O[Return summarized data]
```

**Diagram sources**
- [query_utils.py](file://src/local_deep_research/metrics/query_utils.py#L9-L33)

### Research Mode Aggregation

Metrics can be filtered and aggregated by research mode:

```mermaid
flowchart TD
A[Research Mode Filter] --> B[quick]
A --> C[detailed]
A --> D[all]
B --> E[Filter by research_mode = 'quick']
C --> F[Filter by research_mode = 'detailed']
D --> G[No mode filter]
H[Query Execution] --> I[Apply mode filter]
I --> J[Aggregate results]
J --> K[Return mode-specific data]
```

**Diagram sources**
- [query_utils.py](file://src/local_deep_research/metrics/query_utils.py#L36-L51)

### Database Aggregation Queries

The system uses SQLAlchemy to perform efficient database aggregations:

```mermaid
sequenceDiagram
participant App as "Application"
participant TokenCounter as "TokenCounter"
participant DB as "Database"
App->>TokenCounter : get_overall_metrics(period, research_mode)
TokenCounter->>DB : Query TokenUsage with filters
DB-->>TokenCounter : Raw token usage records
TokenCounter->>TokenCounter : Aggregate by model
TokenCounter->>TokenCounter : Calculate totals
TokenCounter-->>App : Aggregated metrics
App->>TokenCounter : get_research_metrics(research_id)
TokenCounter->>DB : Query TokenUsage by research_id
DB-->>TokenCounter : Token usage for research
TokenCounter->>TokenCounter : Group by model
TokenCounter->>TokenCounter : Calculate research totals
TokenCounter-->>App : Research-specific metrics
```

**Diagram sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py#L633-L702)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py#L122-L241)

**Section sources**
- [query_utils.py](file://src/local_deep_research/metrics/query_utils.py#L1-L52)
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py#L595-L702)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py#L17-L241)

## Time-Series Data

The system provides time-series data for visualizing metrics over time, particularly for search activity and usage patterns.

### Search Time Series Endpoint

```mermaid
sequenceDiagram
participant Client as "API Client"
participant SearchTracker as "SearchTracker"
participant DB as "Database"
Client->>SearchTracker : get_search_time_series(period, research_mode)
SearchTracker->>DB : Query SearchCall with time and mode filters
DB-->>SearchTracker : Search call records
SearchTracker->>SearchTracker : Format as time series
SearchTracker-->>Client : Array of time series data points
```

**Diagram sources**
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py#L343-L404)

### Time Series Data Structure

The time-series data includes the following fields for each data point:

| Field | Type | Description |
|-------|------|-------------|
| timestamp | string | ISO format timestamp of the search call |
| search_engine | string | Name of the search engine used |
| results_count | integer | Number of results returned by the search |
| response_time_ms | integer | Response time in milliseconds |
| success_status | string | "success" or "error" status of the search |
| query | string | Truncated search query (first 50 characters) |

This structure enables visualization of search activity patterns, performance trends, and engine usage over time.

**Section sources**
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py#L343-L404)

## Error Handling

The metrics system implements comprehensive error handling for invalid requests and system errors.

### Invalid Time Range Handling

When an invalid time period is provided, the system defaults to 30 days:

```python
def get_time_filter_condition(period: str, timestamp_column: Column) -> Any:
    """Get SQLAlchemy condition for time filtering."""
    if period == "all":
        return None
    elif period == "7d":
        cutoff = datetime.now(UTC) - timedelta(days=7)
    elif period == "30d":
        cutoff = datetime.now(UTC) - timedelta(days=30)
    elif period == "3m":
        cutoff = datetime.now(UTC) - timedelta(days=90)
    elif period == "1y":
        cutoff = datetime.now(UTC) - timedelta(days=365)
    else:
        # Default to 30 days for unknown periods
        cutoff = datetime.now(UTC) - timedelta(days=30)
    
    return timestamp_column >= cutoff
```

### API Error Responses

All API endpoints return standardized error responses:

```json
{
  "status": "error",
  "message": "An internal error occurred. Please try again later."
}
```

Or for specific validation errors:

```json
{
  "status": "error",
  "message": "No user session found"
}
```

### Exception Handling in Metrics Collection

The system gracefully handles exceptions during metrics collection:

```mermaid
flowchart TD
A[Record Metrics] --> B{Success?}
B --> |Yes| C[Store in database]
B --> |No| D[Log error]
D --> E[Continue execution]
E --> F[Metrics collection failed silently]
```

This ensures that metrics collection failures do not disrupt the primary research operations.

**Section sources**
- [query_utils.py](file://src/local_deep_research/metrics/query_utils.py#L9-L33)
- [metrics_routes.py](file://src/local_deep_research/web/routes/metrics_routes.py#L860-L958)

## Authentication Requirements

All metrics API endpoints require user authentication to ensure data privacy and security.

### Authentication Mechanism

```mermaid
sequenceDiagram
participant Client as "API Client"
participant Flask as "Flask Session"
participant Metrics as "Metrics Endpoint"
Client->>Metrics : Request with session cookie
Metrics->>Flask : Get username from session
alt User authenticated
Flask-->>Metrics : Username
Metrics->>Metrics : Process request
Metrics-->>Client : Return metrics data
else User not authenticated
Flask-->>Metrics : None
Metrics-->>Client : 401 Unauthorized
end
```

### Session-Based Authentication

The system uses Flask sessions to authenticate users:

1. Users must be logged in to access metrics endpoints
2. The username is retrieved from the Flask session
3. Database queries are scoped to the authenticated user's data
4. Thread-safe metrics writing uses session passwords for encrypted database access

This approach ensures that users can only access their own metrics data, maintaining privacy and security.

**Section sources**
- [metrics_routes.py](file://src/local_deep_research/web/routes/metrics_routes.py#L846-L872)
- [thread_metrics.py](file://src/local_deep_research/database/thread_metrics.py#L53-L65)

## Relationship to Tracking System

The metrics endpoints are closely integrated with the underlying tracking system that collects data during research execution.

### Data Flow Architecture

```mermaid
graph TD
A[Research Execution] --> B[TokenCountingCallback]
A --> C[SearchTracker]
B --> D[In-memory tracking]
C --> E[In-memory tracking]
D --> F{Thread type?}
E --> F
F --> |MainThread| G[Direct database write]
F --> |Background thread| H[Thread-safe metrics writer]
G --> I[Encrypted user database]
H --> J[Thread-safe session]
J --> I
I --> K[Metrics API endpoints]
K --> L[Dashboard and analytics]
```

### Token Tracking Lifecycle

```mermaid
sequenceDiagram
participant Research as "Research Process"
participant Callback as "TokenCountingCallback"
participant Memory as "In-memory counts"
participant DB as "Database"
Research->>Callback : LLM call starts
Callback->>Memory : Start timing, capture context
Research->>Callback : LLM call ends
Callback->>Memory : Extract token usage
Callback->>Memory : Calculate response time
Callback->>Callback : Determine thread context
alt MainThread
Callback->>DB : Direct session write
else Background thread
Callback->>DB : Thread-safe write with credentials
end
DB-->>Callback : Confirmation
```

### Search Tracking Lifecycle

```mermaid
sequenceDiagram
participant Research as "Research Process"
participant Tracker as "SearchTracker"
participant Context as "Research Context"
participant DB as "Database"
Research->>Context : Set research parameters
Research->>Tracker : record_search(engine, query, results, time, success)
Tracker->>Context : Extract research_id, username, password
Tracker->>Tracker : Validate context
Tracker->>DB : Write search call with thread-safe access
DB-->>Tracker : Confirmation
```

The tracking system captures metrics at the point of execution and stores them in the user's encrypted database. The metrics API endpoints then query this stored data to provide analytics and reporting capabilities.

**Diagram sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py#L19-L589)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py#L24-L121)
- [thread_metrics.py](file://src/local_deep_research/database/thread_metrics.py#L19-L159)

**Section sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py#L1-L800)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py#L1-L443)
- [thread_metrics.py](file://src/local_deep_research/database/thread_metrics.py#L1-L160)

## Examples

### Querying Daily Usage Metrics

To retrieve metrics for the last 7 days:

```bash
curl -X GET "http://localhost:5000/metrics/api/metrics?period=7d&mode=all" \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "status": "success",
  "metrics": {
    "total_tokens": 154230,
    "total_calls": 234,
    "by_model": [
      {
        "model": "gpt-4o",
        "provider": "openai",
        "tokens": 89450,
        "calls": 120,
        "prompt_tokens": 45230,
        "completion_tokens": 44220
      },
      {
        "model": "claude-3-sonnet",
        "provider": "anthropic",
        "tokens": 64780,
        "calls": 114,
        "prompt_tokens": 32560,
        "completion_tokens": 32220
      }
    ],
    "search_engine_stats": [
      {
        "engine": "google_pse",
        "call_count": 45,
        "avg_response_time": 1250,
        "total_results": 450,
        "avg_results_per_call": 10,
        "success_rate": 95.6,
        "error_count": 2
      }
    ]
  },
  "period": "7d",
  "research_mode": "all"
}
```

### Retrieving Cost Breakdown by LLM Provider

To get cost analytics by provider:

```bash
curl -X GET "http://localhost:5000/metrics/api/cost-analytics" \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "status": "success",
  "metrics": {
    "total_cost": 4.23,
    "prompt_cost": 1.87,
    "completion_cost": 2.36,
    "total_tokens": 154230,
    "prompt_tokens": 77790,
    "completion_tokens": 76440,
    "total_calls": 234,
    "model_breakdown": {
      "gpt-4o": {
        "total_cost": 2.67,
        "prompt_tokens": 45230,
        "completion_tokens": 44220,
        "calls": 120
      },
      "claude-3-sonnet": {
        "total_cost": 1.56,
        "prompt_tokens": 32560,
        "completion_tokens": 32220,
        "calls": 114
      }
    },
    "avg_cost_per_call": 0.018,
    "cost_per_token": 0.0000274
  }
}
```

### Obtaining Performance Statistics

To retrieve search performance metrics:

```bash
curl -X GET "http://localhost:5000/metrics/api/rate-limiting?period=30d" \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "status": "success",
  "data": {
    "rate_limiting": {
      "total_attempts": 189,
      "successful_attempts": 176,
      "failed_attempts": 13,
      "success_rate": 93.1,
      "rate_limit_events": 8,
      "avg_wait_time": 1.25,
      "avg_successful_wait": 0.8,
      "tracked_engines": 3,
      "engine_stats": [
        {
          "engine": "google_pse",
          "base_wait_seconds": 1.0,
          "min_wait_seconds": 0.5,
          "max_wait_seconds": 3.0,
          "success_rate": 95.0,
          "total_attempts": 120,
          "recent_attempts": 120,
          "recent_success_rate": 95.0,
          "attempts": 120,
          "status": "healthy",
          "last_updated": "2025-01-15T10:30:45+00:00"
        }
      ],
      "total_engines_tracked": 3,
      "healthy_engines": 2,
      "degraded_engines": 1,
      "poor_engines": 0
    }
  },
  "period": "30d"
}
```

### Getting Research-Specific Metrics

To retrieve metrics for a specific research session:

```bash
curl -X GET "http://localhost:5000/metrics/api/metrics/research/abc123-def456" \
  -H "Content-Type: application/json"
```

Response:
```json
{
  "status": "success",
  "metrics": {
    "research_id": "abc123-def456",
    "total_tokens": 4560,
    "total_calls": 8,
    "model_usage": [
      {
        "model": "gpt-4o",
        "provider": "openai",
        "tokens": 4560,
        "calls": 8,
        "prompt_tokens": 2340,
        "completion_tokens": 2220
      }
    ]
  }
}
```

**Section sources**
- [test_metrics_api.py](file://tests/api_tests/test_metrics_api.py#L1-L149)
- [metrics_routes.py](file://src/local_deep_research/web/routes/metrics_routes.py#L860-L1037)