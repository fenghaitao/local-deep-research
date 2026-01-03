# News Sources

<cite>
**Referenced Files in This Document**   
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py)
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py)
- [search_subscription.py](file://src/local_deep_research/news/subscription_manager/search_subscription.py)
- [topic_subscription.py](file://src/local_deep_research/news/subscription_manager/topic_subscription.py)
- [base_preference.py](file://src/local_deep_research/news/preference_manager/base_preference.py)
- [folder_manager.py](file://src/local_deep_research/news/folder_manager.py)
- [api.py](file://src/local_deep_research/news/api.py)
- [news.js](file://src/local_deep_research/web/static/js/pages/news.js)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [News Source Integration](#news-source-integration)
3. [Real-time News Indexing and Metadata Extraction](#real-time-news-indexing-and-metadata-extraction)
4. [Publication Date Filtering and Query Construction](#publication-date-filtering-and-query-construction)
5. [API Authentication and Result Sorting](#api-authentication-and-result-sorting)
6. [News Subscription System Integration](#news-subscription-system-integration)
7. [Breaking News Detection and Source Prioritization](#breaking-news-detection-and-source-prioritization)
8. [Language Filtering and Credibility Assessment](#language-filtering-and-credibility-assessment)
9. [Rate Limiting and Paywalled Content Handling](#rate-limiting-and-paywalled-content-handling)
10. [Configuration Options](#configuration-options)

## Introduction
This document provides comprehensive documentation for the news search sources integration in the local deep research system, focusing on The Guardian and Wikinews. The system enables real-time news indexing, sophisticated metadata extraction, and advanced filtering capabilities. It supports API authentication, intelligent query construction, and result sorting by relevance or date. The documentation covers integration with the news subscription system, breaking news detection, and configuration options for source prioritization, language filtering, and credibility assessment. Special attention is given to rate limiting for high-frequency monitoring and handling of paywalled content from commercial news providers.

## News Source Integration

The system integrates with major news sources through specialized search engine implementations that handle API interactions, authentication, and data retrieval. The Guardian and Wikinews are implemented as dedicated search engines with optimized query processing and result handling.

```mermaid
classDiagram
class GuardianSearchEngine {
+str api_key
+str from_date
+str to_date
+str section
+str order_by
+bool optimize_queries
+bool adaptive_search
+__init__(max_results, api_key, from_date, to_date, section, order_by, llm, max_filtered_results, optimize_queries, adaptive_search)
+_optimize_query_for_guardian(query) str
+_adapt_dates_for_query_type(query) void
+_adaptive_search(query) List[Dict]
+_get_all_data(query) List[Dict]
+_get_previews(query) List[Dict]
+_get_full_content(relevant_items) List[Dict]
+run(query, research_context) List[Dict]
+search_by_section(section, max_results) List[Dict]
+get_recent_articles(days, max_results) List[Dict]
}
class WikinewsSearchEngine {
+str lang_code
+datetime from_date
+datetime to_date
+bool adaptive_search
+__init__(search_language, adaptive_search, time_period, llm, max_filtered_results, max_results, search_snippets_only)
+_optimize_query_for_wikinews(query) str
+_adapt_date_range_for_query(query) void
+_fetch_search_results(query, sroffset) List[Dict]
+_process_search_result(result, query) Dict or None
+_fetch_full_content_and_pubdate(page_id, fallback_date) Tuple[str, datetime]
+_get_previews(query) List[Dict]
+_get_full_content(relevant_items) List[Dict]
+run(query, research_context) List[Dict]
}
GuardianSearchEngine --|> BaseSearchEngine
WikinewsSearchEngine --|> BaseSearchEngine
```

**Diagram sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L1-L677)
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L1-L535)

**Section sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L1-L677)
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L1-L535)

## Real-time News Indexing and Metadata Extraction

The system implements real-time news indexing capabilities for both The Guardian and Wikinews, extracting comprehensive metadata from articles to support advanced search and analysis. The Guardian integration extracts headline, trail text, byline, body content, publication information, and keywords, while the Wikinews integration extracts title, snippet, full content, publication date, and URL information.

```mermaid
sequenceDiagram
participant User as "User Interface"
participant NewsAPI as "News API"
participant Guardian as "The Guardian"
participant Wikinews as "Wikinews"
User->>NewsAPI : Request news articles
NewsAPI->>Guardian : API request with parameters
Guardian-->>NewsAPI : Return article data
NewsAPI->>Wikinews : API request with parameters
Wikinews-->>NewsAPI : Return article data
NewsAPI->>NewsAPI : Extract metadata from responses
NewsAPI->>NewsAPI : Process and format results
NewsAPI-->>User : Return indexed articles with metadata
Note over NewsAPI,User : Real-time indexing with comprehensive metadata extraction
```

**Diagram sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L384-L414)
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L376-L386)

**Section sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L384-L414)
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L376-L386)

## Publication Date Filtering and Query Construction

The system provides sophisticated publication date filtering capabilities with configurable date ranges and automatic adaptation based on query type. For The Guardian, users can specify from_date and to_date parameters in YYYY-MM-DD format, with defaults of one month ago to today. The Wikinews integration uses datetime objects with configurable time periods (all, year, month, week, day).

```mermaid
flowchart TD
Start([Query Received]) --> AnalyzeQuery["Analyze Query Type"]
AnalyzeQuery --> QueryType{"Query Type?"}
QueryType --> |Historical| SetHistoricalDates["Set from_date to 10 years ago"]
QueryType --> |Current| SetRecentDates["Set from_date to 60 days ago"]
QueryType --> |Unclear| UseDefaultDates["Use default date range"]
SetHistoricalDates --> ApplyFilter["Apply Date Filter"]
SetRecentDates --> ApplyFilter
UseDefaultDates --> ApplyFilter
ApplyFilter --> ExecuteSearch["Execute Search with Date Filter"]
ExecuteSearch --> ReturnResults["Return Filtered Results"]
style Start fill:#f9f,stroke:#333
style ReturnResults fill:#f9f,stroke:#333
```

Query construction is enhanced with LLM-based optimization that transforms natural language queries into effective search queries. The system automatically optimizes queries by removing filler words, focusing on essential keywords, and structuring queries for optimal results.

**Diagram sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L173-L237)
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L202-L266)

**Section sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L173-L237)
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L202-L266)

## API Authentication and Result Sorting

API authentication is required for The Guardian integration, with the API key provided either as a parameter or retrieved from the system settings. The Wikinews integration does not require authentication but includes a user agent header for identification.

```mermaid
classDiagram
class GuardianSearchEngine {
-str api_key
+__init__(api_key, ...)
+_get_all_data(query) List[Dict]
}
class AuthenticationFlow {
+validate_api_key(key) bool
+get_api_key_from_settings() str
+apply_authentication_headers() Dict
}
GuardianSearchEngine --> AuthenticationFlow : "uses"
class ResultSorting {
+sort_by_relevance(results) List[Dict]
+sort_by_date_newest(results) List[Dict]
+sort_by_date_oldest(results) List[Dict]
}
GuardianSearchEngine --> ResultSorting : "uses"
WikinewsSearchEngine --> ResultSorting : "uses"
```

Results can be sorted by relevance, newest, or oldest based on the order_by parameter. The default sorting is by relevance, but users can specify alternative sorting methods to prioritize recent or chronological results.

**Diagram sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L56-L69)
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L17-L18)

**Section sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L56-L69)
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L17-L18)

## News Subscription System Integration

The system integrates with a comprehensive news subscription system that allows users to subscribe to specific search queries or topics for ongoing news updates. Subscriptions are managed through a subscription manager that handles creation, updating, and deletion of subscriptions.

```mermaid
classDiagram
class SearchSubscription {
+str original_query
+str current_query
+bool transform_to_news_query
+List[str] query_history
+__init__(user_id, query, source, refresh_interval_minutes, transform_to_news_query, subscription_id)
+generate_search_query() str
+_transform_to_news_query(query) str
+evolve_query(new_terms) void
+get_statistics() Dict
+to_dict() Dict
}
class TopicSubscription {
+str topic
+List[str] related_topics
+List[str] topic_history
+datetime last_significant_activity
+__init__(topic, user_id, refresh_interval_minutes, source, related_topics, subscription_id)
+generate_search_query() str
+update_activity(news_count, significant_news) void
+evolve_topic(new_form, reason) void
+add_related_topic(topic) void
+merge_with(other_subscription) void
+should_auto_expire() bool
+get_statistics() Dict
+to_dict() Dict
}
class BaseSubscription {
+str user_id
+CardSource source
+str query_or_topic
+int refresh_interval_minutes
+int refresh_count
+int error_count
+str status
+datetime created_at
+datetime updated_at
+datetime last_refresh
+datetime next_refresh
+Dict metadata
+__init__(user_id, source, query_or_topic, refresh_interval_minutes, subscription_id)
+get_subscription_type() str
+generate_search_query() str
+to_dict() Dict
}
SearchSubscription --|> BaseSubscription
TopicSubscription --|> BaseSubscription
```

**Diagram sources**
- [search_subscription.py](file://src/local_deep_research/news/subscription_manager/search_subscription.py#L13-L255)
- [topic_subscription.py](file://src/local_deep_research/news/subscription_manager/topic_subscription.py#L14-L314)

**Section sources**
- [search_subscription.py](file://src/local_deep_research/news/subscription_manager/search_subscription.py#L13-L255)
- [topic_subscription.py](file://src/local_deep_research/news/subscription_manager/topic_subscription.py#L14-L314)

## Breaking News Detection and Source Prioritization

The system includes breaking news detection capabilities through specialized query templates and monitoring. The JavaScript frontend implements a breaking news table query that searches for important breaking news stories from the current day only, with strict requirements for verifiable sources.

```mermaid
sequenceDiagram
participant Frontend as "Frontend UI"
participant Backend as "Backend System"
participant SearchEngines as "Search Engines"
Frontend->>Backend : Request breaking news
Backend->>SearchEngines : Execute breaking news query
SearchEngines-->>Backend : Return breaking news results
Backend->>Backend : Filter and prioritize results
Backend->>Backend : Apply credibility assessment
Backend-->>Frontend : Return breaking news table
Frontend->>Frontend : Display breaking news in table format
Note over Backend,Frontend : Real-time breaking news detection with credibility filtering
```

Source prioritization is configurable through user preferences, allowing users to boost specific news sources. The system also implements automatic source credibility assessment based on domain characteristics, content analysis, and HTTPS usage.

**Diagram sources**
- [news.js](file://src/local_deep_research/web/static/js/pages/news.js#L68-L77)
- [base_preference.py](file://src/local_deep_research/news/preference_manager/base_preference.py#L114-L137)

**Section sources**
- [news.js](file://src/local_deep_research/web/static/js/pages/news.js#L68-L77)
- [base_preference.py](file://src/local_deep_research/news/preference_manager/base_preference.py#L114-L137)

## Language Filtering and Credibility Assessment

The system supports language filtering for Wikinews, with support for multiple languages including English, Spanish, French, German, Chinese, and others. Users can specify the search language, which is mapped to the appropriate language code for the Wikinews API.

```mermaid
classDiagram
class WikinewsSearchEngine {
+str lang_code
+List[str] supported_languages
+__init__(search_language, ...)
+_validate_language(search_language) str
}
class CredibilityAssessment {
+float base_score
+Dict[str, float] type_priorities
+_calculate_credibility(url, domain, source_type, content) float
+_analyze_content_type(content) str
}
WikinewsSearchEngine --> CredibilityAssessment : "uses"
```

Credibility assessment is performed using a multi-factor approach that considers source type, domain characteristics (such as .edu or .gov), HTTPS usage, and content analysis. The system assigns credibility scores to sources to help prioritize more reliable information.

**Diagram sources**
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L19-L35)
- [base_preference.py](file://src/local_deep_research/news/preference_manager/base_preference.py#L196-L211)

**Section sources**
- [search_engine_wikinews.py](file://src/local_deep_research/web_search_engines/engines/search_engine_wikinews.py#L19-L35)
- [base_preference.py](file://src/local_deep_research/news/preference_manager/base_preference.py#L196-L211)

## Rate Limiting and Paywalled Content Handling

The system implements comprehensive rate limiting to prevent excessive API requests and ensure compliance with API usage policies. Rate limiting metrics are tracked and displayed in the system's analytics dashboard, including rate limit success rate, rate limit events, average wait time, and engines tracked.

```mermaid
flowchart TD
Start([API Request]) --> CheckRateLimit["Check Rate Limit Status"]
CheckRateLimit --> IsLimited{"Rate Limited?"}
IsLimited --> |Yes| Wait["Wait Required Time"]
Wait --> ExecuteRequest["Execute API Request"]
IsLimited --> |No| ExecuteRequest
ExecuteRequest --> UpdateTracker["Update Rate Limit Tracker"]
UpdateTracker --> ReturnResponse["Return API Response"]
style Start fill:#f9f,stroke:#333
style ReturnResponse fill:#f9f,stroke:#333
```

Paywalled content from commercial news providers is handled by focusing on metadata and snippets that are typically available without subscription. The system prioritizes extracting accessible information while acknowledging the limitations of paywalled content.

**Diagram sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L367-L371)
- [metrics.html](file://src/local_deep_research/web/templates/pages/metrics.html#L700-L723)

**Section sources**
- [search_engine_guardian.py](file://src/local_deep_research/web_search_engines/engines/search_engine_guardian.py#L367-L371)
- [metrics.html](file://src/local_deep_research/web/templates/pages/metrics.html#L700-L723)

## Configuration Options

The system provides extensive configuration options for news source management, including source prioritization, language filtering, and credibility assessment. Users can configure refresh intervals, date ranges, sorting preferences, and query optimization settings.

```mermaid
classDiagram
class NewsConfiguration {
+Dict[str, Any] default_settings
+int impact_threshold
+Dict[str, bool] focus_preferences
+str search_strategy
+str custom_search_terms
+Dict[str, float] source_weights
+List[str] liked_categories
+List[str] disliked_categories
+Dict[str, float] interests
+List[str] disliked_topics
+__init__()
+get_default_preferences() Dict
+update_preferences(user_id, preferences) Dict
+add_interest(user_id, interest, weight) void
+remove_interest(user_id, interest) void
+ignore_topic(user_id, topic) void
+boost_source(user_id, source, weight) void
}
class FolderManager {
+Session session
+get_user_folders(user_id) List[SubscriptionFolder]
+create_folder(name, description) SubscriptionFolder
+update_folder(folder_id, **kwargs) SubscriptionFolder or None
+delete_folder(folder_id, move_to) bool
+get_subscriptions_by_folder(user_id) Dict
+update_subscription(subscription_id, **kwargs) BaseSubscription or None
+delete_subscription(subscription_id) bool
+get_subscription_stats(user_id) Dict
+_sub_to_dict(sub) Dict
}
NewsConfiguration --> BasePreferenceManager
FolderManager --> SubscriptionFolder
FolderManager --> BaseSubscription
```

These configuration options are accessible through the user interface and can be managed programmatically through the API, allowing for flexible customization of the news search experience.

**Diagram sources**
- [base_preference.py](file://src/local_deep_research/news/preference_manager/base_preference.py#L14-L164)
- [folder_manager.py](file://src/local_deep_research/news/folder_manager.py#L15-L226)

**Section sources**
- [base_preference.py](file://src/local_deep_research/news/preference_manager/base_preference.py#L14-L164)
- [folder_manager.py](file://src/local_deep_research/news/folder_manager.py#L15-L226)