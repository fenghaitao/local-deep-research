# Performance Issues

<cite>
**Referenced Files in This Document**   
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py)
- [search_system.py](file://src/local_deep_research/search_system.py)
- [cost_calculator.py](file://src/local_deep_research/metrics/pricing/cost_calculator.py)
- [adaptive_tracker.py](file://src/local_deep_research/web_search_engines/rate_limiting/adaptive_tracker.py)
- [rate_limiter.py](file://src/local_deep_research/security/rate_limiter.py)
- [search_cache.py](file://src/local_deep_research/utilities/search_cache.py)
- [analytics-dashboard.md](file://docs/analytics-dashboard.md)
- [BENCHMARKING.md](file://docs/BENCHMARKING.md)
- [benchmark.html](file://src/local_deep_research/web/templates/pages/benchmark.html)
- [detail.js](file://src/local_deep_research/web/static/js/components/detail.js)
- [details.js](file://src/local_deep_research/web/static/js/components/details.js)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Performance Monitoring System](#performance-monitoring-system)
3. [Resource Utilization Tracking](#resource-utilization-tracking)
4. [Response Time Analysis](#response-time-analysis)
5. [Search Engine Performance](#search-engine-performance)
6. [LLM Call Efficiency](#llm-call-efficiency)
7. [Rate Limiting and Error Handling](#rate-limiting-and-error-handling)
8. [Analytics Dashboard](#analytics-dashboard)
9. [Benchmarking and Optimization](#benchmarking-and-optimization)
10. [Common Performance Issues and Solutions](#common-performance-issues-and-solutions)
11. [Conclusion](#conclusion)

## Introduction

The Local Deep Research system incorporates comprehensive performance monitoring to track and optimize research workflows. This documentation details the implementation of performance tracking, including resource utilization, response time analysis, and efficiency metrics. The system monitors the relationship between LLM calls, search engine queries, and overall research duration to identify bottlenecks and optimize performance. The analytics dashboard and benchmarking tools provide insights to help users identify and resolve performance issues, making the system accessible to beginners while offering technical depth for experienced developers.

## Performance Monitoring System

The performance monitoring system in Local Deep Research consists of multiple components that track different aspects of the research workflow. The system captures metrics from LLM interactions, search engine queries, and overall research sessions to provide a comprehensive view of performance.

```mermaid
graph TD
A[Research Query] --> B[Search System]
B --> C[LLM Interactions]
B --> D[Search Engine Queries]
C --> E[Token Usage Tracking]
D --> F[Search Performance Tracking]
E --> G[Cost Calculation]
F --> H[Response Time Analysis]
G --> I[Analytics Dashboard]
H --> I
I --> J[Optimization Recommendations]
```

**Diagram sources**
- [search_system.py](file://src/local_deep_research/search_system.py)
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py)

**Section sources**
- [search_system.py](file://src/local_deep_research/search_system.py)
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py)

## Resource Utilization Tracking

The system tracks resource utilization through detailed metrics collection for both LLM interactions and search engine usage. The token counter component monitors LLM token usage, while the search tracker records search engine performance.

### Token Usage Monitoring

The TokenCountingCallback class captures detailed metrics about LLM interactions, including prompt and completion tokens, response times, and success rates. This information is used to calculate costs and identify inefficient patterns.

```mermaid
classDiagram
class TokenCountingCallback {
+dict counts
+float start_time
+int response_time_ms
+str success_status
+int context_limit
+bool context_truncated
+int tokens_truncated
+str current_provider
+str current_model
+str preset_provider
+str calling_function
+dict current_call_counts
+on_llm_start(serialized, prompts)
+on_llm_new_token(token)
+on_llm_end(response)
+on_llm_error(error)
+on_chain_start(serialized, inputs)
+on_chain_end(outputs)
+on_chain_error(error)
+on_tool_start(serialized, input_str)
+on_tool_end(output)
+on_tool_error(error)
+on_text(text)
+on_agent_action(action)
+on_agent_finish(outputs)
+get_current_token_count()
+get_current_completion_token_count()
+get_total_tokens()
+get_total_completion_tokens()
+get_current_call_token_counts()
+reset_counts()
}
```

**Diagram sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py)

### Search Engine Resource Tracking

The SearchTracker class monitors search engine usage, recording metrics such as response times, success rates, and results count. This data helps identify underperforming search engines and optimize search strategies.

```mermaid
classDiagram
class SearchTracker {
+MetricsDatabase db
+record_search(engine_name, query, results_count, response_time_ms, success, error_message)
+get_search_metrics(period, research_mode, username, password)
+get_research_search_metrics(research_id)
+get_search_time_series(period, research_mode)
}
```

**Diagram sources**
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py)

**Section sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py)

## Response Time Analysis

The system analyzes response times at multiple levels, from individual LLM calls to complete research sessions. This analysis helps identify bottlenecks and optimize the research workflow.

### LLM Response Time Tracking

The token counter captures response times for each LLM call, allowing for detailed analysis of model performance. The response time is calculated from the start of the LLM call to its completion.

```mermaid
sequenceDiagram
participant User as "User"
participant System as "Research System"
participant LLM as "LLM Provider"
User->>System : Submit research query
System->>LLM : LLM request (start_time recorded)
LLM-->>System : LLM response (response_time_ms calculated)
System->>System : Update performance_stats
System->>User : Return results with timing data
```

**Diagram sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py)

### Search Engine Response Analysis

Search engine response times are tracked and analyzed to identify slow-performing engines and optimize search strategies. The system records the response time for each search query and aggregates this data for performance analysis.

```mermaid
flowchart TD
A[Start Search] --> B[Record start time]
B --> C[Execute search query]
C --> D[Record end time]
D --> E[Calculate response_time_ms]
E --> F[Store in SearchCall model]
F --> G[Aggregate for performance analysis]
```

**Diagram sources**
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py)

**Section sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py#L1446-L1455)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py#L240-L241)

## Search Engine Performance

The system monitors search engine performance through detailed metrics collection and analysis. This includes tracking success rates, response times, and results count for each search engine.

### Search Engine Metrics

The get_search_metrics method in the SearchTracker class returns comprehensive statistics about search engine performance, including call count, average response time, total results, and success rate.

```mermaid
classDiagram
class SearchTracker {
+get_search_metrics(period, research_mode, username, password)
+get_research_search_metrics(research_id)
+get_search_time_series(period, research_mode)
}
class SearchCall {
+str research_id
+str research_query
+str research_mode
+str research_phase
+int search_iteration
+str search_engine
+str query
+int results_count
+int response_time_ms
+str success_status
+str error_type
+str error_message
+datetime timestamp
}
```

**Diagram sources**
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py)
- [database/models.py](file://src/local_deep_research/database/models.py)

### Search Engine Comparison

The system allows for comparison of different search engines based on performance metrics. This helps users identify the most effective search engines for their research needs.

```mermaid
graph TD
A[Search Engine Comparison] --> B[Tavily]
A --> C[SearXNG]
A --> D[Brave]
A --> E[Wikipedia]
B --> F["Avg Response: 1.2s<br/>Success Rate: 98%"]
C --> G["Avg Response: 1.8s<br/>Success Rate: 95%"]
D --> H["Avg Response: 2.1s<br/>Success Rate: 92%"]
E --> I["Avg Response: 0.8s<br/>Success Rate: 99%"]
```

**Section sources**
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py)
- [web/templates/pages/benchmark.html](file://src/local_deep_research/web/templates/pages/benchmark.html)

## LLM Call Efficiency

The system tracks LLM call efficiency through detailed token usage analysis and cost calculation. This helps users optimize their LLM usage and reduce costs.

### Token Efficiency Analysis

The token counter tracks both prompt and completion tokens for each LLM call, allowing for analysis of token efficiency. The system calculates average token usage by model and function to identify optimization opportunities.

```mermaid
classDiagram
class TokenUsage {
+int id
+str research_id
+str research_query
+str research_mode
+str research_phase
+int llm_call_iteration
+str provider
+str model_name
+str preset_provider
+str calling_function
+int prompt_tokens
+int completion_tokens
+int total_tokens
+int response_time_ms
+str success_status
+str error_type
+str error_message
+str context_overflow_type
+int context_limit
+bool context_truncated
+int tokens_truncated
+datetime timestamp
}
```

**Diagram sources**
- [database/models.py](file://src/local_deep_research/database/models.py)

### Cost Calculation

The CostCalculator class calculates the cost of LLM usage based on token counts and provider pricing. This allows users to understand the financial implications of their research activities.

```mermaid
classDiagram
class CostCalculator {
+PricingCache cache
+PricingFetcher pricing_fetcher
+get_model_pricing(model_name, provider)
+calculate_cost(model_name, prompt_tokens, completion_tokens, provider)
+calculate_batch_costs(usage_records)
+calculate_cost_sync(model_name, prompt_tokens, completion_tokens)
+get_research_cost_summary(usage_records)
}
```

**Diagram sources**
- [cost_calculator.py](file://src/local_deep_research/metrics/pricing/cost_calculator.py)

**Section sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py)
- [cost_calculator.py](file://src/local_deep_research/metrics/pricing/cost_calculator.py)

## Rate Limiting and Error Handling

The system implements comprehensive rate limiting and error handling to ensure reliable operation and prevent abuse.

### Adaptive Rate Limiting

The adaptive rate limiter monitors search engine rate limits and adjusts wait times accordingly. The system learns from past interactions to optimize wait times and maximize success rates.

```mermaid
classDiagram
class AdaptiveRateLimitTracker {
+dict engine_states
+dict current_estimates
+float learning_rate
+float decay_per_day
+float exploration_rate
+float min_wait_time
+float max_wait_time
+update_wait_estimate(engine_type, successful_waits, failed_waits)
+get_wait_time(engine_type)
+record_attempt(engine_type, success, response_time)
+decay_estimates()
+get_engine_status(engine_type)
}
```

**Diagram sources**
- [adaptive_tracker.py](file://src/local_deep_research/web_search_engines/rate_limiting/adaptive_tracker.py)

### Error Rate Monitoring

The system tracks error rates for both LLM calls and search engine queries. This information is used to identify problematic components and optimize the research workflow.

```mermaid
flowchart TD
A[Operation Start] --> B{Success?}
B --> |Yes| C[Update success metrics]
B --> |No| D[Record error details]
D --> E[Update error_rate]
E --> F[Analyze error patterns]
F --> G[Generate optimization recommendations]
```

**Section sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py#L1546-L1565)
- [search_tracker.py](file://src/local_deep_research/metrics/search_tracker.py#L164-L171)

## Analytics Dashboard

The analytics dashboard provides a comprehensive view of system performance and resource utilization. It visualizes key metrics to help users identify trends and optimize their research workflows.

### Dashboard Components

The dashboard includes multiple components that display different aspects of system performance:

```mermaid
graph TD
A[Analytics Dashboard] --> B[System Overview Cards]
A --> C[Time-based Filtering]
A --> D[Detailed Analytics Pages]
B --> E[Total Tokens Used]
B --> F[Total Researches]
B --> G[Average Response Time]
B --> H[Success Rate]
B --> I[User Satisfaction]
B --> J[Estimated Costs]
C --> K[Last 7 days]
C --> L[Last 30 days]
C --> M[Last 3 months]
C --> N[Last year]
C --> O[All time]
D --> P[Star Reviews Analytics]
D --> Q[Cost Analytics]
D --> R[Rate Limiting Dashboard]
```

**Diagram sources**
- [analytics-dashboard.md](file://docs/analytics-dashboard.md)

### Real-time Monitoring

The dashboard provides real-time monitoring of system performance, including search engine health status and rate limiting status.

```mermaid
stateDiagram-v2
[*] --> Monitoring
Monitoring --> Healthy : success_rate > 95%
Monitoring --> Degraded : success_rate 70-95%
Monitoring --> Poor : success_rate < 70%
Healthy --> Degraded : success_rate drops
Degraded --> Healthy : success_rate improves
Degraded --> Poor : success_rate drops
Poor --> Degraded : success_rate improves
```

**Section sources**
- [analytics-dashboard.md](file://docs/analytics-dashboard.md#L76-L79)
- [detail.js](file://src/local_deep_research/web/static/js/components/detail.js)

## Benchmarking and Optimization

The system includes benchmarking tools to evaluate and optimize performance across different configurations.

### Benchmarking Framework

The benchmarking framework allows users to evaluate system performance on standardized datasets, such as SimpleQA and BrowseComp.

```mermaid
graph TD
A[Benchmarking Framework] --> B[SimpleQA Dataset]
A --> C[BrowseComp Dataset]
A --> D[Configuration Comparison]
B --> E[Fact-based questions]
C --> F[Complex browsing tasks]
D --> G[Compare search engines]
D --> H[Compare strategies]
D --> I[Compare iterations]
```

**Diagram sources**
- [BENCHMARKING.md](file://docs/BENCHMARKING.md)

### Optimization Strategies

The system supports various optimization strategies to improve performance and efficiency:

```mermaid
flowchart TD
A[Optimization] --> B[Parameter Tuning]
A --> C[Search Strategy Selection]
A --> D[Model Selection]
A --> E[Cache Utilization]
B --> F[Iterations]
B --> G[Questions per iteration]
C --> H[Focused Iteration]
C --> I[Source-Based]
D --> J[Cost vs. Quality]
E --> K[Search Results]
E --> L[LLM Responses]
```

**Section sources**
- [BENCHMARKING.md](file://docs/BENCHMARKING.md)
- [analytics-dashboard.md](file://docs/analytics-dashboard.md#L190-L205)

## Common Performance Issues and Solutions

This section addresses common performance issues and provides solutions to resolve them.

### Slow Response Times

Slow response times can be caused by various factors, including slow search engines, inefficient LLM calls, or network issues.

**Solutions:**
- Switch to faster search engines (e.g., Wikipedia for simple queries)
- Reduce the number of iterations and questions per iteration
- Use caching to avoid redundant searches
- Optimize LLM prompts to reduce token usage

**Section sources**
- [analytics-dashboard.md](file://docs/analytics-dashboard.md#L29-L30)
- [detail.js](file://src/local_deep_research/web/static/js/components/detail.js#L240-L251)

### High Memory Usage

High memory usage can occur during complex research tasks with large context windows.

**Solutions:**
- Enable context overflow detection and truncation
- Use smaller models for less complex tasks
- Implement efficient data structures for result storage
- Optimize the search strategy to reduce unnecessary data retrieval

**Section sources**
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py#L51-L57)
- [search_system.py](file://src/local_deep_research/search_system.py#L37-L40)

### Rate Limiting Issues

Rate limiting can cause search failures and slow down research workflows.

**Solutions:**
- Implement adaptive rate limiting with appropriate wait times
- Use multiple search engines to distribute load
- Monitor rate limit status and adjust search frequency
- Implement retry logic with exponential backoff

```mermaid
flowchart TD
A[Search Request] --> B{Rate Limited?}
B --> |No| C[Execute Search]
B --> |Yes| D[Wait and Retry]
D --> E[Exponential Backoff]
E --> F[Update Wait Estimate]
F --> A
```

**Section sources**
- [adaptive_tracker.py](file://src/local_deep_research/web_search_engines/rate_limiting/adaptive_tracker.py)
- [rate_limiter.py](file://src/local_deep_research/security/rate_limiter.py)

### Inefficient LLM Usage

Inefficient LLM usage can lead to high costs and slow performance.

**Solutions:**
- Monitor token usage and optimize prompts
- Use cost-effective models for appropriate tasks
- Implement caching for common queries
- Analyze cost-to-quality ratio for different models

**Section sources**
- [cost_calculator.py](file://src/local_deep_research/metrics/pricing/cost_calculator.py)
- [token_counter.py](file://src/local_deep_research/metrics/token_counter.py)

## Conclusion

The Local Deep Research system provides comprehensive performance monitoring and optimization capabilities. By tracking resource utilization, response times, and efficiency metrics, the system helps users identify and resolve performance issues. The analytics dashboard and benchmarking tools offer valuable insights for optimizing research workflows. Understanding the relationships between LLM calls, search engine queries, and overall research duration is key to improving system performance. By addressing common issues like slow response times, high memory usage, and rate limiting, users can achieve more efficient and effective research outcomes.