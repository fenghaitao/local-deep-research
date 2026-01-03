# Configuration Optimization

<cite>
**Referenced Files in This Document**   
- [run_optimization.py](file://examples/optimization/run_optimization.py)
- [example_optimization.py](file://examples/optimization/example_optimization.py)
- [browsecomp_optimization.py](file://examples/optimization/browsecomp_optimization.py)
- [gemini_optimization.py](file://examples/optimization/gemini_optimization.py)
- [api.py](file://src/local_deep_research/benchmarks/optimization/api.py)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py)
- [metrics.py](file://src/local_deep_research/benchmarks/optimization/metrics.py)
- [calculation.py](file://src/local_deep_research/benchmarks/metrics/calculation.py)
- [composite.py](file://src/local_deep_research/benchmarks/evaluators/composite.py)
- [search_system.py](file://src/local_deep_research/search_system.py)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Optimization API Implementation](#optimization-api-implementation)
3. [Objective Functions and Metrics](#objective-functions-and-metrics)
4. [Search Space Configuration](#search-space-configuration)
5. [Running Optimization Studies](#running-optimization-studies)
6. [Customizing Optimization Goals](#customizing-optimization-goals)
7. [Multi-Benchmark Optimization](#multi-benchmark-optimization)
8. [Performance Considerations](#performance-considerations)
9. [Validation and Overfitting Prevention](#validation-and-overfitting-prevention)
10. [Troubleshooting Guide](#troubleshooting-guide)

## Introduction

The local-deep-research system features a sophisticated configuration optimization framework built on Optuna, enabling automated tuning of research parameters to balance quality, speed, and cost. This optimization system allows users to systematically explore different configurations of LLM selection, search strategies, and citation handling to find optimal settings for specific use cases.

The optimization framework is designed to be both powerful and accessible, providing high-level APIs for common optimization scenarios while allowing fine-grained control over the optimization process. By leveraging Optuna's advanced Bayesian optimization algorithms, the system efficiently navigates complex parameter spaces to identify configurations that maximize research effectiveness.

**Section sources**
- [run_optimization.py](file://examples/optimization/run_optimization.py#L1-L197)
- [example_optimization.py](file://examples/optimization/example_optimization.py#L1-L94)

## Optimization API Implementation

The optimization system provides a comprehensive API that abstracts the complexity of Optuna while exposing essential configuration options. The core optimization functionality is exposed through several entry points that cater to different use cases.

The primary interface is the `optimize_parameters` function, which serves as the foundation for all optimization operations. This function accepts a wide range of parameters including the research query, search tool, LLM configuration, and optimization settings. It orchestrates the entire optimization process, from study creation to result analysis.

```mermaid
classDiagram
class OptunaOptimizer {
+str base_query
+str output_dir
+str model_name
+str provider
+float temperature
+int n_trials
+int n_jobs
+Dict[str, float] metric_weights
+Dict[str, float] benchmark_weights
+optimize(param_space) Tuple[Dict, float]
+_objective(trial, param_space) float
+_run_experiment(params) Dict
+_save_results() void
+_create_visualizations() void
}
class OptunaOptimizerAPI {
+optimize_parameters(query, param_space, output_dir, model_name, provider, search_tool, temperature, n_trials, timeout, n_jobs, study_name, optimization_metrics, metric_weights, progress_callback, benchmark_weights) Tuple[Dict, float]
+optimize_for_speed(query, n_trials, output_dir, model_name, provider, search_tool, progress_callback, benchmark_weights) Tuple[Dict, float]
+optimize_for_quality(query, n_trials, output_dir, model_name, provider, search_tool, progress_callback, benchmark_weights) Tuple[Dict, float]
+optimize_for_efficiency(query, n_trials, output_dir, model_name, provider, search_tool, progress_callback, benchmark_weights) Tuple[Dict, float]
+get_default_param_space() Dict
}
OptunaOptimizerAPI --> OptunaOptimizer : "uses"
```

**Diagram sources **
- [api.py](file://src/local_deep_research/benchmarks/optimization/api.py#L15-L278)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L51-L800)

**Section sources**
- [api.py](file://src/local_deep_research/benchmarks/optimization/api.py#L15-L278)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L51-L800)

## Objective Functions and Metrics

The optimization system employs a multi-objective approach that balances research quality, speed, and resource efficiency. The objective function combines these metrics into a single score that Optuna maximizes during the optimization process.

Quality is measured using benchmark evaluations such as SimpleQA and BrowseComp, which assess the accuracy and completeness of research results. Speed is evaluated based on execution time, with faster configurations receiving higher scores. Resource efficiency considers factors like API call volume and computational complexity.

```mermaid
flowchart TD
Start([Optimization Start]) --> DefineMetrics["Define Quality, Speed, and Resource Metrics"]
DefineMetrics --> CalculateIndividual["Calculate Individual Metric Scores"]
CalculateIndividual --> NormalizeWeights["Normalize Metric Weights"]
NormalizeWeights --> CombineScores["Combine Scores Using Weighted Average"]
CombineScores --> ReturnObjective["Return Combined Score to Optuna"]
ReturnObjective --> End([Optimization Continues])
subgraph Quality Metrics
Q1["Benchmark Accuracy"]
Q2["Answer Completeness"]
Q3["Citation Accuracy"]
end
subgraph Speed Metrics
S1["Execution Time"]
S2["Query Latency"]
S3["Processing Duration"]
end
subgraph Resource Metrics
R1["API Call Count"]
R2["Token Usage"]
R3["Memory Consumption"]
end
Q1 --> CalculateIndividual
Q2 --> CalculateIndividual
Q3 --> CalculateIndividual
S1 --> CalculateIndividual
S2 --> CalculateIndividual
S3 --> CalculateIndividual
R1 --> CalculateIndividual
R2 --> CalculateIndividual
R3 --> CalculateIndividual
```

**Diagram sources **
- [calculation.py](file://src/local_deep_research/benchmarks/metrics/calculation.py#L354-L397)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L464-L468)

**Section sources**
- [calculation.py](file://src/local_deep_research/benchmarks/metrics/calculation.py#L255-L397)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L464-L468)

## Search Space Configuration

The optimization system allows users to define custom search spaces that specify the range of values for each configurable parameter. The search space determines which parameters are optimized and their possible values.

The default search space includes key parameters such as iterations, questions per iteration, search strategy, and result limits. Users can customize this space to focus on specific parameters or expand it to include additional configuration options.

```mermaid
classDiagram
class ParameterSpace {
+str param_name
+str param_type
+int low
+int high
+int step
+List[str] choices
}
class SearchStrategy {
+str rapid
+str standard
+str parallel
+str source_based
+str iterdrag
}
class OptimizationConfig {
+Dict[str, ParameterSpace] param_space
+Dict[str, float] metric_weights
+Dict[str, float] benchmark_weights
+int n_trials
+int n_jobs
}
OptimizationConfig --> ParameterSpace : "contains"
ParameterSpace --> SearchStrategy : "references"
```

**Diagram sources **
- [api.py](file://src/local_deep_research/benchmarks/optimization/api.py#L235-L278)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L254-L291)

**Section sources**
- [api.py](file://src/local_deep_research/benchmarks/optimization/api.py#L235-L278)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L254-L291)

## Running Optimization Studies

The optimization framework provides multiple approaches for running studies, from simple command-line execution to programmatic configuration. The `run_optimization.py` script offers a convenient entry point for most use cases.

To run an optimization study, users specify a research query and optimization mode (balanced, speed, quality, or efficiency). The system then executes multiple trials with different parameter combinations, evaluating each configuration and tracking the results.

```mermaid
sequenceDiagram
participant User as "User"
participant CLI as "run_optimization.py"
participant Optimizer as "OptunaOptimizer"
participant Benchmark as "CompositeBenchmarkEvaluator"
participant System as "Research System"
User->>CLI : Execute with parameters
CLI->>Optimizer : Initialize with config
loop For each trial
Optimizer->>Optimizer : Generate parameters
Optimizer->>Benchmark : Run evaluation
Benchmark->>System : Execute research
System-->>Benchmark : Return results
Benchmark-->>Optimizer : Return metrics
Optimizer->>Optimizer : Calculate score
Optimizer->>Optimizer : Update study
end
Optimizer->>CLI : Return best parameters
CLI->>User : Display results and save
```

**Diagram sources **
- [run_optimization.py](file://examples/optimization/run_optimization.py#L32-L197)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L140-L230)

**Section sources**
- [run_optimization.py](file://examples/optimization/run_optimization.py#L32-L197)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L140-L230)

## Customizing Optimization Goals

The optimization system supports customization of optimization goals through metric weights and specialized optimization functions. Users can prioritize specific objectives such as maximizing accuracy or minimizing cost by adjusting the relative weights of different metrics.

Pre-configured optimization modes provide convenient shortcuts for common scenarios:
- **Speed mode**: Focuses on minimizing execution time
- **Quality mode**: Prioritizes research accuracy and completeness  
- **Efficiency mode**: Balances quality, speed, and resource usage
- **Balanced mode**: Equal weighting of quality and speed

```mermaid
flowchart TD
Start([Customization Start]) --> SelectMode["Select Optimization Mode"]
SelectMode --> SpeedMode{"Speed Mode?"}
SpeedMode --> |Yes| SpeedConfig["Set speed_weight=0.8, quality_weight=0.2"]
SpeedMode --> |No| QualityMode{"Quality Mode?"}
QualityMode --> |Yes| QualityConfig["Set quality_weight=0.9, speed_weight=0.1"]
QualityMode --> |No| EfficiencyMode{"Efficiency Mode?"}
EfficiencyMode --> |Yes| EfficiencyConfig["Set quality_weight=0.4, speed_weight=0.3, resource_weight=0.3"]
EfficiencyMode --> |No| CustomWeights["Use custom weights from input"]
SpeedConfig --> ApplyWeights
QualityConfig --> ApplyWeights
EfficiencyConfig --> ApplyWeights
CustomWeights --> ApplyWeights
ApplyWeights --> RunOptimization["Run Optimization with Custom Weights"]
RunOptimization --> End([Optimization Complete])
```

**Diagram sources **
- [api.py](file://src/local_deep_research/benchmarks/optimization/api.py#L79-L233)
- [run_optimization.py](file://examples/optimization/run_optimization.py#L120-L168)

**Section sources**
- [api.py](file://src/local_deep_research/benchmarks/optimization/api.py#L79-L233)
- [run_optimization.py](file://examples/optimization/run_optimization.py#L120-L168)

## Multi-Benchmark Optimization

The system supports multi-benchmark optimization, allowing users to evaluate configurations across multiple benchmark types with customizable weights. This approach provides a more comprehensive assessment of research system performance.

The CompositeBenchmarkEvaluator combines results from different benchmarks such as SimpleQA and BrowseComp, weighting them according to user preferences. This enables optimization for specific domains or task types.

```mermaid
classDiagram
class CompositeBenchmarkEvaluator {
+Dict[str, float] benchmark_weights
+Dict[str, BaseBenchmarkEvaluator] evaluators
+Dict[str, float] normalized_weights
+evaluate(system_config, num_examples, output_dir) Dict
}
class BaseBenchmarkEvaluator {
<<abstract>>
+evaluate(system_config, num_examples, output_dir) Dict
}
class SimpleQAEvaluator {
+evaluate(system_config, num_examples, output_dir) Dict
}
class BrowseCompEvaluator {
+evaluate(system_config, num_examples, output_dir) Dict
}
CompositeBenchmarkEvaluator --> BaseBenchmarkEvaluator : "uses"
BaseBenchmarkEvaluator <|-- SimpleQAEvaluator
BaseBenchmarkEvaluator <|-- BrowseCompEvaluator
CompositeBenchmarkEvaluator --> SimpleQAEvaluator : "contains"
CompositeBenchmarkEvaluator --> BrowseCompEvaluator : "contains"
```

**Diagram sources **
- [composite.py](file://src/local_deep_research/benchmarks/evaluators/composite.py#L17-L109)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L113-L117)

**Section sources**
- [composite.py](file://src/local_deep_research/benchmarks/evaluators/composite.py#L17-L109)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L113-L117)

## Performance Considerations

Running optimization studies involves trade-offs between thoroughness and computational cost. The system provides several options to manage performance and accelerate convergence.

Key performance considerations include:
- **Trial count**: More trials increase confidence in results but require more time
- **Parallel execution**: Multiple jobs can run simultaneously to reduce total time
- **Benchmark examples**: Fewer examples speed up evaluation but reduce statistical significance
- **Parameter space**: Larger search spaces require more trials to explore thoroughly

The system automatically creates SQLite databases to persist study results, allowing optimization to be resumed if interrupted. Visualization files are generated periodically to monitor progress.

```mermaid
flowchart TD
A[Performance Factors] --> B["Number of Trials (n_trials)"]
A --> C["Parallel Jobs (n_jobs)"]
A --> D["Benchmark Examples"]
A --> E["Search Space Size"]
A --> F["Result Persistence"]
A --> G["Progress Visualization"]
B --> H["Higher n_trials = More thorough but slower"]
C --> I["Higher n_jobs = Faster but more resource intensive"]
D --> J["Fewer examples = Faster evaluation but less reliable"]
E --> K["Larger space = More comprehensive but needs more trials"]
F --> L["Database storage enables study resumption"]
G --> M["Visualizations help monitor optimization progress"]
```

**Diagram sources **
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L68-L72)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L156-L163)

**Section sources**
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L68-L72)
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L156-L163)

## Validation and Overfitting Prevention

To ensure optimized configurations generalize well to new queries, the system includes several mechanisms to prevent overfitting to benchmark datasets.

Best practices for validation include:
- Testing optimized configurations on unseen queries
- Using multiple benchmark types with appropriate weighting
- Employing cross-validation techniques when possible
- Monitoring for performance degradation on edge cases

The system automatically saves detailed records of all trials, enabling post-hoc analysis of optimization results and identification of potential overfitting patterns.

```mermaid
flowchart TD
A[Overfitting Prevention] --> B["Test on Unseen Queries"]
A --> C["Use Multiple Benchmarks"]
A --> D["Cross-Validation"]
A --> E["Monitor Edge Cases"]
A --> F["Analyze Trial History"]
B --> G["Validate generalization ability"]
C --> H["Ensure balanced performance across domains"]
D --> I["Assess stability of results"]
E --> J["Identify failure modes"]
F --> K["Detect optimization artifacts"]
```

**Diagram sources **
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L503-L582)
- [calculation.py](file://src/local_deep_research/benchmarks/metrics/calculation.py#L115-L170)

**Section sources**
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L503-L582)
- [calculation.py](file://src/local_deep_research/benchmarks/metrics/calculation.py#L115-L170)

## Troubleshooting Guide

Common issues when running optimization studies and their solutions:

**Issue**: Optimization takes too long
- **Solution**: Reduce n_trials, decrease benchmark examples, or limit the search space

**Issue**: Out of memory errors
- **Solution**: Reduce n_jobs to limit parallel execution

**Issue**: Poor optimization results
- **Solution**: Increase n_trials, expand the search space, or adjust metric weights

**Issue**: Benchmark failures
- **Solution**: Verify API keys and network connectivity, check LLM provider availability

**Issue**: Inconsistent results
- **Solution**: Ensure consistent environment settings, verify benchmark dataset integrity

The system logs detailed information about each trial, which can be used to diagnose issues. All results are saved to disk, allowing analysis of failed trials and identification of problematic configurations.

**Section sources**
- [optuna_optimizer.py](file://src/local_deep_research/benchmarks/optimization/optuna_optimizer.py#L386-L405)
- [run_optimization.py](file://examples/optimization/run_optimization.py#L96-L103)