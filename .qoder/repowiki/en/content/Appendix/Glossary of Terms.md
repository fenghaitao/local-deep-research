# Glossary of Terms

<cite>
**Referenced Files in This Document**   
- [adaptive_query_generator.py](file://src/local_deep_research/advanced_search_system/query_generation/adaptive_query_generator.py)
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py)
- [search_engine_base.py](file://src/local_deep_research/web_search_engines/search_engine_base.py)
- [cross_engine_filter.py](file://src/local_deep_research/advanced_search_system/filters/cross_engine_filter.py)
- [followup_context_manager.py](file://src/local_deep_research/advanced_search_system/knowledge/followup_context_manager.py)
- [adaptive_explorer.py](file://src/local_deep_research/advanced_search_system/candidate_exploration/adaptive_explorer.py)
- [parallel_explorer.py](file://src/local_deep_research/advanced_search_system/candidate_exploration/parallel_explorer.py)
- [dual_confidence_with_rejection.py](file://src/local_deep_research/advanced_search_system/strategies/dual_confidence_with_rejection.py)
- [citation_handler.py](file://src/local_deep_research/citation_handler.py)
- [standard_citation_handler.py](file://src/local_deep_research/citation_handlers/standard_citation_handler.py)
- [forced_answer_citation_handler.py](file://src/local_deep_research/citation_handlers/forced_answer_citation_handler.py)
- [precision_extraction_handler.py](file://src/local_deep_research/citation_handlers/precision_extraction_handler.py)
</cite>

## Table of Contents
1. [RAG (Retrieval-Augmented Generation)](#rag-retrieval-augmented-generation)
2. [Iterative Research](#iterative-research)
3. [Constrained Search](#constrained-search)
4. [Dual Confidence Verification](#dual-confidence-verification)
5. [Citation Handling](#citation-handling)
6. [Research Strategies](#research-strategies)
7. [Query Decomposition](#query-decomposition)
8. [LLM-driven Modular Strategy](#llm-driven-modular-strategy)
9. [Follow-up Contextual Reasoning](#follow-up-contextual-reasoning)
10. [Cross-engine Filtering](#cross-engine-filtering)
11. [System Components](#system-components)

## RAG (Retrieval-Augmented Generation)

Retrieval-Augmented Generation (RAG) is a framework that combines information retrieval with language generation to produce more accurate and factually grounded responses. In the local-deep-research project, RAG is implemented through a multi-step process where relevant information is first retrieved from various sources, then synthesized by a language model to generate comprehensive answers with proper citations.

The system enhances traditional RAG by incorporating advanced evaluation metrics, constraint-based verification, and multiple research strategies to improve the quality and trustworthiness of generated content. This approach addresses limitations of standard RAG systems by ensuring factual consistency, source attribution validity, and robustness against misleading retrievals.

**Section sources**
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py#L1-L800)
- [detailed_report_how_to_improve_retrieval_augmented_generation_in_p.md](file://examples/detailed_report_how_to_improve_retrieval_augmented_generation_in_p.md#L471-L834)

## Iterative Research

Iterative research refers to the process of conducting research in multiple cycles, where each iteration builds upon the findings of previous ones. In the local-deep-research system, this approach is implemented through strategies that progressively refine search queries, gather additional evidence, and verify candidate solutions until a sufficiently confident answer is reached.

The iterative process typically involves decomposing complex queries into constraints, finding potential candidates, gathering evidence for each candidate-constraint pair, scoring candidates based on evidence quality, and refining the search based on results. This allows the system to handle complex queries that cannot be resolved in a single search operation.

**Section sources**
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py#L132-L189)
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py#L592-L646)

## Constrained Search

Constrained search is a research methodology that decomposes queries into verifiable constraints and systematically searches for candidates that satisfy these constraints. The system extracts constraints from the original query, such as name patterns, locations, properties, or temporal requirements, and uses them to guide the search process.

This approach enables more precise and targeted research by focusing on specific criteria that potential answers must satisfy. The system evaluates candidates against these constraints, gathering evidence for each constraint and calculating an overall confidence score based on the quality and quantity of supporting evidence.

**Section sources**
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py#L29-L34)
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py#L97-L108)

## Dual Confidence Verification

Dual confidence verification is an advanced validation strategy that assesses both positive and negative evidence for candidate solutions. The system evaluates how well a candidate satisfies relevant constraints (positive evidence) while also checking for evidence that contradicts the candidate (negative evidence).

This approach helps prevent false positives by rejecting candidates that have strong negative evidence for any critical constraint, even if they have some positive evidence. The dual confidence mechanism can be enhanced with early rejection capabilities, allowing the system to discard unpromising candidates quickly and focus resources on more promising options.

**Section sources**
- [dual_confidence_with_rejection.py](file://src/local_deep_research/advanced_search_system/strategies/dual_confidence_with_rejection.py#L1-L35)
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py#L567-L590)

## Citation Handling

Citation handling refers to the system's approach to managing and presenting sources for generated content. The local-deep-research project implements multiple citation handling strategies through specialized handlers that process search results and format them appropriately for different use cases.

The system supports various citation handler types, including standard citation handling for general research, forced answer citation handling for benchmark performance, and precision extraction handling for simple question-answering tasks. Each handler processes retrieved documents and formats sources according to specific requirements.

**Section sources**
- [citation_handler.py](file://src/local_deep_research/citation_handler.py#L40-L70)
- [standard_citation_handler.py](file://src/local_deep_research/citation_handlers/standard_citation_handler.py)
- [forced_answer_citation_handler.py](file://src/local_deep_research/citation_handlers/forced_answer_citation_handler.py)
- [precision_extraction_handler.py](file://src/local_deep_research/citation_handlers/precision_extraction_handler.py)

## Research Strategies

Research strategies are specialized approaches for conducting research based on the nature of the query and desired outcomes. The system implements multiple strategies, each optimized for different types of research problems.

### Adaptive Decomposition Strategy
This strategy dynamically adjusts its approach based on the success of different search methods. It tracks the performance of various query generation techniques and adapts future searches to focus on the most productive approaches, learning from past results to improve efficiency.

### Evidence-Based Strategy
An approach that decomposes queries into constraints, finds candidates, and systematically gathers evidence to score each candidate. This strategy emphasizes verifiable evidence and progressive refinement of search results until a confident answer is reached.

### Parallel Strategy
A breadth-first approach that runs multiple search queries in parallel to quickly discover a wide range of candidates. This strategy generates multiple query variations and executes searches concurrently for speed, focusing on comprehensive exploration.

**Section sources**
- [adaptive_explorer.py](file://src/local_deep_research/advanced_search_system/candidate_exploration/adaptive_explorer.py#L1-L330)
- [parallel_explorer.py](file://src/local_deep_research/advanced_search_system/candidate_exploration/parallel_explorer.py#L1-L253)
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py#L24-L34)

## Query Decomposition

Query decomposition is the process of breaking down complex research questions into smaller, more manageable components or constraints. The system analyzes queries to identify key elements such as entities, properties, relationships, temporal aspects, and other constraints that can be addressed individually.

This approach enables more effective searching by transforming broad, ambiguous questions into specific, targeted queries that can be processed more efficiently. The decomposed constraints are then used to guide the search process, verify candidate solutions, and ensure comprehensive coverage of all aspects of the original question.

**Section sources**
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py#L97-L108)
- [adaptive_query_generator.py](file://src/local_deep_research/advanced_search_system/query_generation/adaptive_query_generator.py#L88-L103)

## LLM-driven Modular Strategy

LLM-driven modular strategy refers to the system's architecture where specialized components handle different aspects of the research process, with language models driving key decision points. The system is organized into modular components for constraint analysis, candidate exploration, evidence evaluation, and result synthesis, with LLMs orchestrating the workflow between these modules.

This approach allows for flexible composition of research workflows, where different modules can be combined or replaced based on the specific requirements of a research task. The LLM acts as an intelligent controller, making decisions about which modules to invoke, how to interpret their outputs, and when to terminate the research process.

**Section sources**
- [evidence_based_strategy.py](file://src/local_deep_research/advanced_search_system/strategies/evidence_based_strategy.py#L36-L69)
- [adaptive_query_generator.py](file://src/local_deep_research/advanced_search_system/query_generation/adaptive_query_generator.py#L37-L48)

## Follow-up Contextual Reasoning

Follow-up contextual reasoning is the system's ability to conduct research that builds upon previous findings by incorporating context from prior research sessions. When handling follow-up questions, the system retrieves and processes information from previous research, including findings, sources, and metadata, to provide contextually relevant answers.

The follow-up context manager extracts key entities, summarizes past findings, and identifies information gaps to guide the new research. This enables coherent, context-aware research that maintains continuity across multiple related queries, avoiding redundant searches and building upon established knowledge.

**Section sources**
- [followup_context_manager.py](file://src/local_deep_research/advanced_search_system/knowledge/followup_context_manager.py#L1-L416)
- [base_followup_question.py](file://src/local_deep_research/advanced_search_system/questions/followup/base_followup_question.py#L46-L65)

## Cross-engine Filtering

Cross-engine filtering is a technique for combining and ranking results from multiple search engines to improve overall search quality. The system aggregates results from various search engines and applies a filtering process to rank them by relevance to the query.

The cross-engine filter uses language models to evaluate the relevance of results from different sources, considering factors such as direct relevance to the query, source quality, and recency. It then produces a unified, ranked list of results, eliminating duplicates and prioritizing the most relevant information across all search engines.

**Section sources**
- [cross_engine_filter.py](file://src/local_deep_research/advanced_search_system/filters/cross_engine_filter.py#L1-L227)
- [search_engine_base.py](file://src/local_deep_research/web_search_engines/search_engine_base.py#L259-L394)

## System Components

### Search Engines
Search engines are components responsible for retrieving information from various sources. The system supports multiple search engine types, including web search engines, academic databases, news sources, and local knowledge bases. Each engine implements a standardized interface while providing access to its specific data source.

### Retrievers
Retrievers are components that fetch relevant documents or information based on queries. They can be integrated with external systems like LangChain or operate as custom implementations. Retrievers work in conjunction with search engines to provide targeted information retrieval capabilities.

### Citation Handlers
Citation handlers process retrieved documents and format them for citation in research results. Different handler types implement specialized approaches for handling citations based on the research context and requirements, ensuring proper attribution and source formatting.

### Knowledge Bases
Knowledge bases are structured repositories of information that the system can query during research. These may include local document collections, databases, or external knowledge graphs. The system can integrate with knowledge bases through custom retrievers, combining internal knowledge with external search results.

**Section sources**
- [search_engine_base.py](file://src/local_deep_research/web_search_engines/search_engine_base.py#L35-L657)
- [citation_handler.py](file://src/local_deep_research/citation_handler.py#L37-L70)
- [retriever_registry.py](file://src/local_deep_research/web_search_engines/retriever_registry.py)
- [knowledge](file://src/local_deep_research/advanced_search_system/knowledge/)