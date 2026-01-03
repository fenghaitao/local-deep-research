# Appendix

<cite>
**Referenced Files in This Document**   
- [README.md](file://README.md)
- [CONTRIBUTING.md](file://CONTRIBUTING.md)
- [pyproject.toml](file://pyproject.toml)
- [faq.md](file://docs/faq.md)
- [MIGRATION_GUIDE_v1.md](file://docs/MIGRATION_GUIDE_v1.md)
- [release_notes/0.2.0.md](file://docs/release_notes/0.2.0.md)
- [release_notes/0.4.0.md](file://docs/release_notes/0.4.0.md)
- [features.md](file://docs/features.md)
- [search-engines.md](file://docs/search-engines.md)
- [citation_handler.py](file://src/local_deep_research/citation_handler.py)
- [report_generator.py](file://src/local_deep_research/report_generator.py)
- [search_system_factory.py](file://src/local_deep_research/search_system_factory.py)
- [LICENSE](file://LICENSE)
- [SECURITY.md](file://SECURITY.md)
</cite>

## Table of Contents
1. [Glossary of Terms](#glossary-of-terms)
2. [Frequently Asked Questions (FAQ)](#frequently-asked-questions-faq)
3. [Community Resources](#community-resources)
4. [License Information](#license-information)
5. [Release Notes and Migration Guides](#release-notes-and-migration-guides)
6. [Legal and Compliance Considerations](#legal-and-compliance-considerations)
7. [External Resources and Related Projects](#external-resources-and-related-projects)

## Glossary of Terms

### RAG (Retrieval-Augmented Generation)
Retrieval-Augmented Generation (RAG) is a framework that enhances Large Language Models (LLMs) by grounding their responses in external knowledge sources. LDR implements RAG by retrieving relevant information from multiple search engines and documents, then using LLMs to generate accurate, cited responses. This approach improves factual consistency and reduces hallucinations by providing up-to-date information from verified sources.

### Iterative Research
Iterative research is a methodology where complex queries are broken down into focused sub-queries that are processed in multiple cycles. LDR uses various iterative strategies like "focused_iteration" and "IterDRAG" to refine results progressively. Each iteration builds upon previous findings, allowing for deeper exploration and validation of information across multiple sources.

### Citation Handling
Citation handling refers to LDR's system for tracking and attributing information sources. The platform supports multiple citation handler types:
- **Standard**: Balanced approach for general use
- **Forced Answer**: Optimized for benchmark performance
- **Precision Extraction**: Focuses on precise answer extraction

The citation system ensures transparency by providing proper attribution and enabling users to verify information sources.

### Research Strategies
Research strategies determine how LDR approaches information retrieval and synthesis. Available strategies include:
- **Focused Iteration**: Sequential refinement of research results
- **Parallel Search**: Simultaneous processing of multiple questions
- **IterDRAG**: Query decomposition into sub-queries
- **Iterative Refinement**: LLM-guided evaluation and follow-up
- **Academic Focus**: Prioritizes scholarly sources
- **Cross-Reference**: Validates information across multiple sources

**Section sources**
- [features.md](file://docs/features.md#search-strategies)
- [search-engines.md](file://docs/search-engines.md#search-strategies)
- [search_system_factory.py](file://src/local_deep_research/search_system_factory.py#L172-L180)

## Frequently Asked Questions (FAQ)

### General Questions
**What is Local Deep Research (LDR)?**
LDR is an open-source AI research assistant that performs systematic research by breaking down complex questions, searching multiple sources in parallel, and creating comprehensive reports with proper citations. It can run entirely locally for complete privacy.

**How is LDR different from ChatGPT or other AI assistants?**
LDR focuses specifically on research with real-time information retrieval. Key differences:
- Provides citations and sources for claims
- Searches multiple databases including academic papers
- Can run completely offline with local models
- Open source and customizable
- Searches your own documents

**Is LDR really free?**
Yes! LDR is open source (MIT license). Costs only apply if you use cloud LLM providers (OpenAI, Anthropic), premium search APIs (Tavily, SerpAPI), or need cloud hosting infrastructure. Local models (Ollama) and free search engines have no costs.

### Installation & Setup
**What are the system requirements?**
- **Python**: 3.10 or newer
- **RAM**: 8GB minimum (16GB recommended for larger models)
- **GPU VRAM** (for Ollama):
  - 7B models: 4GB VRAM minimum
  - 13B models: 8GB VRAM minimum
  - 30B models: 16GB VRAM minimum
  - 70B models: 48GB VRAM minimum
- **Disk Space**:
  - 100MB for LDR
  - 1-2GB for SearXNG
  - 5-15GB per Ollama model
- **OS**: Windows, macOS, Linux

**Do I need Docker?**
Docker is recommended but not required. You can use Docker Compose (easiest), Docker containers individually, or install via pip without Docker.

### Configuration
**How do I change the LLM model?**
1. **Via Web UI**: Settings → LLM Provider → Select model
2. **Via Environment**: Set `LDR_LLM_MODEL` and `LDR_LLM_PROVIDER`
3. **Via API**: Pass model parameters in requests

**Where should I configure settings?**
Important: The `.env` file method is deprecated. Use the web UI settings instead:
1. Run the web app: `python -m local_deep_research.web.app`
2. Navigate to Settings
3. Configure your preferences
4. Settings are saved to the database

### Common Errors
**"Error: max_workers must be greater than 0"**
This means LDR cannot connect to your LLM. Check:
1. Ollama is running: `ollama list`
2. You have models downloaded: `ollama pull llama3:8b`
3. Correct model name in settings
4. For Docker: Ensure containers can communicate

**"404 Error" when viewing results**
This issue should be resolved in versions 0.5.2 and later. If you're still experiencing it:
1. Refresh the page
2. Check if research actually completed in logs
3. Update to the latest version

**Research gets stuck or shows empty headings**
Common causes:
- "Search snippets only" disabled (must be enabled for SearXNG)
- Rate limiting from search engines
- LLM connection issues

Solutions:
1. Reset settings to defaults
2. Use fewer iterations (2-3)
3. Limit questions per iteration (3-4)

**Section sources**
- [faq.md](file://docs/faq.md)

## Community Resources

### Contribution Guidelines
Contributions to LDR are welcome and valued. The project follows a structured contribution process:

1. **Development Setup**: Follow the [Developer Guide](https://github.com/LearningCircuit/local-deep-research/wiki/Developer-Guide) for environment configuration with PDM.
2. **Pre-commit Hooks**: Install with `pre-commit install` and `pre-commit install-hooks` to ensure code quality.
3. **Branch Management**: Create a new branch for each feature or fix.
4. **Testing**: Run tests before submitting PRs with `pdm run python run_tests.py`.
5. **Pull Request Process**: 
   - Create focused PRs (one feature/fix per PR)
   - Write clear commit messages
   - Update documentation to match code changes
   - Include tests for new functionality
   - Ensure CI passes all automated checks

Security guidelines prohibit committing sensitive information like API keys or passwords. Configuration should be done through the web UI or environment variables.

**Section sources**
- [CONTRIBUTING.md](file://CONTRIBUTING.md)

### Issue Reporting Procedures
When reporting issues, include the following information:
- Error messages and logs
- Your configuration (OS, Docker/pip, models)
- Steps to reproduce
- What you've already tried

Report issues through:
- [GitHub Issues](https://github.com/LearningCircuit/local-deep-research/issues) for bug reports and feature requests
- [Discord](https://discord.gg/ttcqQeFcJ3) for support and discussions
- [Reddit](https://www.reddit.com/r/LocalDeepResearch/) for announcements and showcases

### Communication Channels
- **Discord**: [Join our community](https://discord.gg/ttcqQeFcJ3) for real-time support and discussions
- **Reddit**: [r/LocalDeepResearch](https://www.reddit.com/r/LocalDeepResearch/) for updates and user showcases
- **GitHub Issues**: For bug reports and feature requests
- **Wiki**: Contribute to the [documentation wiki](https://github.com/LearningCircuit/local-deep-research/wiki) with guides and tutorials

## License Information

### Project License
Local Deep Research is released under the MIT License, which allows for free use, modification, and distribution. The full license text is available in the [LICENSE](file://LICENSE) file.

### Third-Party Dependencies and Licenses
LDR incorporates numerous third-party libraries and tools, each with their own licensing terms. Key dependencies include:

- **LangChain**: MIT License
- **Ollama**: MIT License
- **SearXNG**: AGPL-3.0 License
- **FAISS**: MIT License
- **Flask**: BSD License
- **SQLAlchemy**: MIT License
- **Playwright**: Apache-2.0 License

The complete list of dependencies and their licenses can be found in the `pyproject.toml` file and the `pdm.lock` file. Users are responsible for complying with the licensing terms of all dependencies when using or distributing the software.

**Section sources**
- [pyproject.toml](file://pyproject.toml)
- [LICENSE](file://LICENSE)

## Release Notes and Migration Guides

### Release Notes

#### v0.2.0 Release Notes
Key enhancements in v0.2.0:
- **New Search Strategies**: Parallel Search, Iterative Deep Search, Cross-Engine Filtering
- **Improved Search Integrations**: Enhanced SearXNG support, improved GitHub integration
- **Technical Improvements**: Unified database (`ldr.db`), improved Ollama integration
- **User Experience**: Enhanced logging panel, streamlined settings UI
- **Development Improvements**: PDM support, pre-commit hooks, CodeQL integration

**Section sources**
- [docs/release_notes/0.2.0.md](file://docs/release_notes/0.2.0.md)

#### v0.4.0 Release Notes
Key enhancements in v0.4.0:
- **LLM Improvements**: Custom OpenAI endpoint support, dynamic model fetching
- **Search Enhancements**: Journal quality assessment, enhanced SearXNG integration
- **User Experience**: Search engine visibility, better API key management
- **System Improvements**: Logging system upgrade to `loguru`, memory optimization
- **New Contributor**: @JayLiu7319 contributed support for Custom OpenAI Endpoint models

**Section sources**
- [docs/release_notes/0.4.0.md](file://docs/release_notes/0.4.0.md)

### Migration Guides

#### Migration from v0.x to v1.0
LDR v1.0 introduced significant security and architectural improvements:

**Breaking Changes:**
1. **Authentication Required**: All access now requires authentication
2. **Per-User Encrypted Databases**: Each user has their own encrypted SQLCipher database
3. **Settings Snapshots**: Thread-safe settings management
4. **New API Structure**: Reorganized endpoints under blueprint prefixes

**Migration Steps:**
1. Update dependencies: `pip install --upgrade local-deep-research`
2. Create user accounts through the web interface
3. Update programmatic code to include authentication and settings snapshots
4. Update HTTP API calls to use the new endpoint structure
5. Re-enter API keys in the web interface settings

The migration guide provides detailed examples for updating both programmatic and HTTP API usage. Temporary backward compatibility is available through the `LDR_USE_SHARED_DB=1` environment variable, though this is not recommended for production use due to security implications.

**Section sources**
- [docs/MIGRATION_GUIDE_v1.md](file://docs/MIGRATION_GUIDE_v1.md)

## Legal and Compliance Considerations

### Data Usage and Privacy
LDR prioritizes user privacy and data security through several measures:
- **Signal-level encryption**: SQLCipher with AES-256 protects all user data at rest
- **Per-user isolated databases**: Each user has their own encrypted database
- **Zero-knowledge architecture**: No password recovery mechanism ensures true privacy
- **Data integrity**: HMAC-SHA512 verification prevents tampering

Users are responsible for ensuring compliance with applicable data protection regulations when using LDR. The software does not collect telemetry by default, and all processing can be performed locally without external data transmission.

### Security Considerations
LDR implements multiple security measures:
- **File Whitelist**: Repository uses a whitelist approach to prevent unintended data exposure
- **Sensitive Data Protection**: Binary files, media files, archives, and sensitive files are blocked by CI/CD pipeline
- **Secret Scanning**: GitGuardian integration scans for exposed secrets
- **Input Validation**: Comprehensive validation of user inputs and API requests
- **Rate Limiting**: Protection against abuse and denial-of-service attacks

Users should follow security best practices, including regular updates, secure API key management, and network isolation when handling sensitive information.

**Section sources**
- [README.md](file://README.md#-security--privacy)
- [SECURITY.md](file://SECURITY.md)

## External Resources and Related Projects

### Official Documentation and Guides
- [Installation Guide](https://github.com/LearningCircuit/local-deep-research/wiki/Installation)
- [Developer Guide](https://github.com/LearningCircuit/local-deep-research/wiki/Developer-Guide)
- [API Quickstart](docs/api-quickstart.md)
- [Configuration Guide](docs/env_configuration.md)
- [Docker Compose Guide](docs/docker-compose-guide.md)

### Examples and Tutorials
- [API Examples](examples/api_usage/)
- [Benchmark Examples](examples/benchmarks/)
- [Optimization Examples](examples/optimization/)
- [Elasticsearch Integration](examples/elasticsearch/)
- [Custom LLM Integration](examples/llm_integration/)

### Community Projects and Forks
- [SearXNG LDR-Academic](https://github.com/porespellar/searxng-LDR-academic): Academic-focused SearXNG fork with 12 research engines (arXiv, Google Scholar, PubMed, etc.) designed for LDR
- [BSAIL Lab: How useful is Deep Research in Academia?](https://uflbsail.net/uncategorized/how-useful-is-deep-research-in-academia/): In-depth review by contributor [@djpetti](https://github.com/djpetti)

### Featured In
- [Medium: Open-Source Deep Research AI Assistants](https://medium.com/@leucopsis/open-source-deep-research-ai-assistants-157462a59c14)
- [Hacker News](https://news.ycombinator.com/item?id=43330164): Community discussion
- [Zhihu (知乎)](https://zhuanlan.zhihu.com/p/30886269290): Chinese tech community coverage

**Note**: Third-party projects are independently maintained. These links are provided as useful resources but do not imply endorsement or guarantee of code quality or security.