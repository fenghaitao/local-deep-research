# Examples and Tutorials

<cite>
**Referenced Files in This Document**   
- [README.md](file://README.md)
- [examples/api_usage/README.md](file://examples/api_usage/README.md)
- [examples/api_usage/programmatic/simple_programmatic_example.py](file://examples/api_usage/programmatic/simple_programmatic_example.py)
- [examples/api_usage/http/simple_working_example.py](file://examples/api_usage/http/simple_working_example.py)
- [examples/benchmarks/README.md](file://examples/benchmarks/README.md)
- [examples/benchmarks/run_simpleqa.py](file://examples/benchmarks/run_simpleqa.py)
- [examples/optimization/README.md](file://examples/optimization/README.md)
- [examples/optimization/example_optimization.py](file://examples/optimization/example_optimization.py)
- [examples/llm_integration/basic_custom_llm.py](file://examples/llm_integration/basic_custom_llm.py)
- [examples/llm_integration/advanced_custom_llm.py](file://examples/llm_integration/advanced_custom_llm.py)
- [docs/BENCHMARKING.md](file://docs/BENCHMARKING.md)
- [docs/analytics-dashboard.md](file://docs/analytics-dashboard.md)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Basic Research Examples](#basic-research-examples)
3. [Advanced Research Scenarios](#advanced-research-scenarios)
4. [Integration Examples](#integration-examples)
5. [Optimization Techniques](#optimization-techniques)
6. [Benchmarking Methodologies](#benchmarking-methodologies)
7. [Analytics Dashboard Usage](#analytics-dashboard-usage)
8. [Common Patterns and Anti-patterns](#common-patterns-and-anti-patterns)
9. [Conclusion](#conclusion)

## Introduction

The Local Deep Research (LDR) system is an AI-powered research assistant designed for deep, iterative research using multiple language models and search engines with proper citations. This document provides comprehensive examples and tutorials to help users understand and effectively utilize the system's capabilities.

LDR enables users to perform systematic research by breaking down complex questions into focused sub-queries, searching multiple sources in parallel, verifying information across sources for accuracy, and creating comprehensive reports with proper citations. The system supports various research modes from quick summaries to detailed reports and offers extensive integration options with external tools and platforms.

This tutorial covers practical usage scenarios for both beginners and experienced users, including basic research examples, advanced research scenarios, integration examples, optimization techniques, benchmarking methodologies, and analytics dashboard usage.

**Section sources**
- [README.md](file://README.md#L1-L513)

## Basic Research Examples

This section demonstrates simple queries and result interpretation using the Local Deep Research system. The examples show how to get started with basic research tasks and understand the output.

### Simple Programmatic Example

The simplest way to use LDR programmatically is through the Python API. The following example demonstrates how to perform quick summaries, detailed research, and generate reports:

```python
from local_deep_research.api import (
    detailed_research,
    quick_summary,
    generate_report,
)
from local_deep_research.api.settings_utils import create_settings_snapshot

# Create settings with Wikipedia as search tool
settings_snapshot = create_settings_snapshot(
    overrides={
        "search.tool": "wikipedia",
        "api.allow_file_output": True,
    }
)

# Example 1: Quick Summary
result = quick_summary(
    "What is machine learning?",
    settings_snapshot=settings_snapshot,
    programmatic_mode=True,
)

# Example 2: Detailed Research
result = detailed_research(
    query="Impact of climate change on agriculture",
    iterations=2,
    search_tool="wikipedia",
    search_strategy="source_based",
    settings_snapshot=settings_snapshot,
    programmatic_mode=True,
)

# Example 3: Generate and Save a Report
report = generate_report(
    query="Future of artificial intelligence",
    output_file="ai_future_report.md",
    searches_per_section=2,
    iterations=1,
    settings_snapshot=settings_snapshot,
)
```

This example shows the core functionality of LDR with minimal configuration. The `create_settings_snapshot` function provides sensible defaults, and specific settings can be overridden as needed.

**Section sources**
- [examples/api_usage/programmatic/simple_programmatic_example.py](file://examples/api_usage/programmatic/simple_programmatic_example.py#L1-L87)

### HTTP API Example

For users who prefer to interact with LDR through HTTP requests, the system provides a REST API. The following example demonstrates how to use the HTTP API to perform research:

```python
import requests
from bs4 import BeautifulSoup

# Create session for cookie persistence
session = requests.Session()

# Login - get CSRF token first
login_page = session.get("http://localhost:5000/auth/login")
soup = BeautifulSoup(login_page.text, 'html.parser')
csrf_input = soup.find('input', {'name': 'csrf_token'})
login_csrf = csrf_input.get('value')

# Login with form data
session.post(
    "http://localhost:5000/auth/login",
    data={
        "username": "your_username",
        "password": "your_password",
        "csrf_token": login_csrf
    }
)

# Get CSRF token for API
csrf_token = session.get("http://localhost:5000/auth/csrf-token").json()["csrf_token"]

# Make API request
response = session.post(
    "http://localhost:5000/api/start_research",
    json={"query": "What is quantum computing?"},
    headers={"X-CSRF-Token": csrf_token, "Content-Type": "application/json"}
)
```

The HTTP API requires proper authentication and CSRF token handling. The example shows the complete workflow from authentication to making a research request.

**Section sources**
- [examples/api_usage/README.md](file://examples/api_usage/README.md#L1-L200)
- [examples/api_usage/http/simple_working_example.py](file://examples/api_usage/http/simple_working_example.py#L1-L266)

## Advanced Research Scenarios

This section covers complex topics, multi-step investigations, and specialized research modes that demonstrate the full capabilities of the Local Deep Research system.

### Multi-Stage Research Pipeline

LDR supports complex research workflows that involve multiple stages with different configurations. The following example demonstrates a multi-stage research pipeline:

```python
# Stage 1: Quick exploration with simple LLM
simple_llm = ConfigurableLLM(response_style="simple", max_length=200)
initial = quick_summary(
    query="Climate change impacts on agriculture",
    llms={"simple": simple_llm},
    provider="simple",
    iterations=1,
)

# Stage 2: Detailed research with expert LLM
expert_llm = DomainExpertLLM(domain="technical", expertise_level=0.95)
detailed = detailed_research(
    query="Climate change impacts on agriculture: focus on technology solutions",
    llms={"expert": expert_llm},
    provider="expert",
    iterations=2,
)
```

This approach allows researchers to start with a broad overview and then focus on specific aspects with more specialized models and configurations.

### Custom LLM Integration

LDR supports integration with custom LangChain LLMs, enabling users to leverage specialized models for specific research domains:

```python
class DomainExpertLLM(BaseChatModel):
    """LLM that specializes in specific domains."""
    
    def __init__(self, domain: str = "general", expertise_level: float = 0.8):
        super().__init__()
        self.domain = domain
        self.expertise_level = expertise_level
        self.domain_knowledge = {
            "medical": ["diagnosis", "treatment", "symptoms", "medications"],
            "legal": ["contracts", "liability", "regulations", "compliance"],
            "technical": [
                "algorithms",
                "architecture",
                "performance",
                "scalability",
            ],
            "finance": ["investments", "risk", "portfolio", "markets"],
        }

    def _generate(self, messages: List[BaseMessage], **kwargs) -> ChatResult:
        """Generate domain-specific response."""
        query = messages[-1].content if messages else ""
        
        # Check if query matches domain
        domain_terms = self.domain_knowledge.get(self.domain, [])
        relevance = sum(1 for term in domain_terms if term.lower() in query.lower())
        
        if relevance > 0:
            response = f"[{self.domain.upper()} EXPERT - High Relevance]: "
        else:
            response = f"[{self.domain.upper()} EXPERT - General]: "
            
        response += f"Based on my {self.domain} expertise (level: {self.expertise_level}), "
        response += f"regarding '{query[:100]}...': This requires specialized knowledge."
        
        message = AIMessage(content=response)
        generation = ChatGeneration(message=message)
        
        return ChatResult(generations=[generation])
```

This custom LLM can be used for domain-specific research, providing more relevant and accurate results for specialized topics.

**Section sources**
- [examples/llm_integration/advanced_custom_llm.py](file://examples/llm_integration/advanced_custom_llm.py#L1-L351)

## Integration Examples

This section demonstrates how to combine the Local Deep Research system with external tools and platforms.

### LangChain Retriever Integration

LDR can integrate with LangChain retrievers to search custom knowledge bases:

```python
from local_deep_research.api import quick_summary

# Use your existing LangChain retriever
result = quick_summary(
    query="What are our deployment procedures?",
    retrievers={"company_kb": your_retriever},
    search_tool="company_kb"
)
```

This integration works with various LangChain-compatible retrievers including FAISS, Chroma, Pinecone, Weaviate, Elasticsearch, and others.

### Command Line Tools

LDR provides command line tools for automation and integration with other systems:

```bash
# Run benchmarks from CLI
python -m local_deep_research.benchmarks --dataset simpleqa --examples 50

# Manage rate limiting
python -m local_deep_research.web_search_engines.rate_limiting status
python -m local_deep_research.web_search_engines.rate_limiting reset
```

These tools enable integration with CI/CD pipelines, monitoring systems, and other automation frameworks.

**Section sources**
- [README.md](file://README.md#L403-L421)
- [examples/api_usage/README.md](file://examples/api_usage/README.md#L1-L200)

## Optimization Techniques

This section covers techniques for improving research quality and efficiency in the Local Deep Research system.

### Parameter Optimization

LDR includes optimization tools to find the best settings for different use cases:

```python
from local_deep_research.benchmarks.optimization import optimize_parameters

# Define parameter space to explore
param_space = {
    "iterations": {
        "type": "int",
        "low": 1,
        "high": 3,
        "step": 1,
    },
    "questions_per_iteration": {
        "type": "int",
        "low": 1,
        "high": 5,
        "step": 1,
    },
    "search_strategy": {
        "type": "categorical",
        "choices": ["rapid", "iterdrag", "source_based"],
    },
}

# Run optimization
balanced_params, balanced_score = optimize_parameters(
    query="SimpleQA quick demo",
    search_tool="searxng",
    n_trials=20,
    output_dir="optimization_results",
    param_space=param_space,
    metric_weights={"quality": 0.5, "speed": 0.5},
)
```

The optimization process uses Optuna to efficiently search for the best parameters based on quality, speed, and other metrics.

### Custom LLM Wrappers

Advanced optimization can be achieved by creating custom LLM wrappers with specific behaviors:

```python
class RetryLLM(BaseChatModel):
    """LLM wrapper that adds retry logic to any base LLM."""
    
    def __init__(self, base_llm: BaseChatModel, max_retries: int = 3, retry_delay: float = 1.0):
        super().__init__()
        self.base_llm = base_llm
        self.max_retries = max_retries
        self.retry_delay = retry_delay

    def _generate(self, messages: List[BaseMessage], **kwargs) -> ChatResult:
        """Generate with retry logic."""
        last_error = None
        
        for attempt in range(self.max_retries):
            try:
                return self.base_llm._generate(messages, **kwargs)
            except Exception as e:
                last_error = e
                if attempt < self.max_retries - 1:
                    time.sleep(self.retry_delay)
                    self.retry_delay *= 2  # Exponential backoff
                    
        raise last_error
```

These wrappers can add features like retry logic, rate limiting, logging, and preprocessing to improve reliability and performance.

**Section sources**
- [examples/optimization/README.md](file://examples/optimization/README.md#L1-L125)
- [examples/optimization/example_optimization.py](file://examples/optimization/example_optimization.py#L1-L94)

## Benchmarking Methodologies

This section covers benchmarking methodologies and performance measurement using the provided tools.

### SimpleQA Benchmark

The SimpleQA benchmark evaluates factual question answering capabilities:

```python
from local_deep_research.benchmarks.benchmark_functions import evaluate_simpleqa

# Run the benchmark
results = evaluate_simpleqa(
    num_examples=10,
    search_iterations=3,
    questions_per_iteration=3,
    search_tool="searxng",
    human_evaluation=False,
    evaluation_model="gpt-4",
    evaluation_provider="openai",
    output_dir="simpleqa_results",
)

# Print summary
print(f"Accuracy: {results.get('accuracy', 0):.3f}")
print(f"Total examples: {results.get('total_examples', 0)}")
print(f"Report saved to: {results.get('report_path', '')}")
```

The SimpleQA benchmark is recommended for testing general knowledge retrieval and provides a good baseline for comparing configurations.

### Benchmark Configuration

The benchmarking system supports various configuration options:

```bash
# Run SimpleQA with custom parameters
python run_simpleqa.py --examples 50 --iterations 3 --questions 3 --search-tool searxng

# Run BrowseComp benchmark
python run_browsecomp.py --examples 5 --iterations 3 --questions 3
```

Key configuration options include:
- Number of examples to run
- Number of search iterations
- Questions per iteration
- Search tool to use
- Output directory for results
- Evaluation method (automatic or human)

The benchmarking system helps users find optimal configurations for their specific research needs.

**Section sources**
- [docs/BENCHMARKING.md](file://docs/BENCHMARKING.md#L1-L92)
- [examples/benchmarks/README.md](file://examples/benchmarks/README.md#L1-L63)
- [examples/benchmarks/run_simpleqa.py](file://examples/benchmarks/run_simpleqa.py#L1-L117)

## Analytics Dashboard Usage

This section documents analytics dashboard usage and interpretation of metrics.

### Dashboard Components

The metrics dashboard provides insights into research activities, costs, and system performance:

- **System Overview Cards**: Display key metrics including total tokens used, total researches, average response time, success rate, user satisfaction, and estimated costs
- **Time-based Filtering**: Allows filtering analytics by time period (last 7 days, 30 days, 3 months, year, all time)
- **Star Reviews Analytics**: Shows 5-star rating distribution, average ratings by time period, and rating trends
- **Cost Analytics**: Tracks cost breakdown by provider, token usage details, and cost trends over time
- **Rate Limiting Dashboard**: Monitors search engine rate limit status, success/failure rates, and wait time tracking

### Data Export

Analytics data can be accessed via API endpoints:

```bash
# Get overall metrics
curl http://localhost:5000/api/metrics

# Get specific research metrics
curl http://localhost:5000/api/metrics/research/<research_id>

# Get cost analytics
curl http://localhost:5000/api/cost-analytics

# Get rate limiting status
curl http://localhost:5000/api/rate-limiting
```

The dashboard uses Chart.js to visualize data with line charts, bar charts, pie charts, and progress indicators.

### Using Analytics for Optimization

The analytics dashboard can be used to identify areas for improvement:

1. **Identify Cost Drivers**: Review high-token queries in cost analytics and compare model costs vs. quality ratings
2. **Improve Search Performance**: Monitor search engine health status and identify frequently rate-limited engines
3. **Enhance Research Quality**: Analyze user ratings by research type and review low-rated sessions for patterns

The analytics data helps users make informed decisions about configuration changes and optimization strategies.

**Section sources**
- [docs/analytics-dashboard.md](file://docs/analytics-dashboard.md#L1-L246)

## Common Patterns and Anti-patterns

This section addresses common patterns and anti-patterns in research formulation and system usage.

### Best Practices

**Recommended Patterns:**
- Start with small benchmark tests to verify configuration
- Use moderate example counts for shared resources
- Monitor API usage in the Metrics page
- Respect rate limits and shared infrastructure
- Use the web interface for initial configuration and testing
- Implement proper error handling in programmatic integrations
- Regularly review analytics to identify optimization opportunities

**Effective Research Strategies:**
- Break down complex questions into focused sub-queries
- Use appropriate search strategies for different research goals
- Verify information across multiple sources
- Document research assumptions and limitations
- Save and organize research results for future reference

### Common Anti-patterns

**Avoid These Practices:**
- Running large benchmarks without verifying configuration first
- Ignoring rate limits and making excessive API calls
- Using inappropriate search engines for the research topic
- Relying on a single source for critical information
- Not monitoring token usage and costs
- Using default settings without optimization for specific use cases
- Performing research without proper authentication and security measures

**Troubleshooting Common Issues:**
- **Low accuracy**: Verify API keys and search engine connectivity
- **No search results**: Check API credentials and rate limiting
- **Very fast processing**: Usually indicates configuration issues
- **High token usage**: Review query complexity and optimization settings
- **Authentication failures**: Ensure proper CSRF token handling and user creation

Following these guidelines helps ensure effective and efficient use of the Local Deep Research system.

**Section sources**
- [docs/BENCHMARKING.md](file://docs/BENCHMARKING.md#L1-L92)
- [docs/analytics-dashboard.md](file://docs/analytics-dashboard.md#L1-L246)
- [README.md](file://README.md#L1-L513)

## Conclusion

The Local Deep Research system provides a comprehensive platform for AI-powered research with extensive capabilities for basic and advanced research scenarios. This tutorial has demonstrated practical usage examples covering simple queries, complex multi-step investigations, integration with external tools, optimization techniques, benchmarking methodologies, and analytics dashboard usage.

Key takeaways include:
- The system supports both programmatic and HTTP API access for flexible integration
- Advanced research scenarios can be implemented using custom LLMs and multi-stage pipelines
- Integration with LangChain retrievers enables searching custom knowledge bases
- Optimization tools help find the best configurations for specific research needs
- Benchmarking methodologies provide objective performance measurement
- The analytics dashboard offers valuable insights into research activities and costs

By following the examples and best practices outlined in this tutorial, users can effectively leverage the Local Deep Research system to conduct thorough, accurate, and well-documented research.