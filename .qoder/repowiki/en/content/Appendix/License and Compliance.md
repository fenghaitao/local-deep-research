# License and Compliance

<cite>
**Referenced Files in This Document**   
- [LICENSE](file://LICENSE)
- [pyproject.toml](file://pyproject.toml)
- [package.json](file://package.json)
- [SECURITY_REVIEW_PROCESS.md](file://docs/SECURITY_REVIEW_PROCESS.md)
- [sqlcipher_utils.py](file://src/local_deep_research/database/sqlcipher_utils.py)
- [encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py)
- [data_sanitizer.py](file://src/local_deep_research/security/data_sanitizer.py)
- [url_validator.py](file://src/local_deep_research/security/url_validator.py)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Project License](#project-license)
3. [Third-Party Dependencies and Licenses](#third-party-dependencies-and-licenses)
4. [Data Privacy and Encryption](#data-privacy-and-encryption)
5. [Compliance with Web Scraping and API Usage](#compliance-with-web-scraping-and-api-usage)
6. [Data Retention Policies](#data-retention-policies)
7. [Security Review Process](#security-review-process)
8. [Responsible Disclosure Guidelines](#responsible-disclosure-guidelines)
9. [Attribution and Licensing for Derivative Works](#attribution-and-licensing-for-derivative-works)
10. [Conclusion](#conclusion)

## Introduction
This document provides a comprehensive overview of the legal and compliance aspects of the local-deep-research project. It covers the project's licensing, third-party dependencies, data privacy measures, compliance with web scraping and API usage terms, data retention policies, security review processes, responsible disclosure guidelines, and requirements for attribution and licensing of derivative works. The goal is to ensure that users, contributors, and organizations can use the project in a manner that respects legal and ethical standards.

## Project License
The local-deep-research project is licensed under the MIT License, a permissive open-source license that allows for broad use, modification, and distribution of the software. The full text of the license is provided below:

```
MIT License

Copyright (c) 2025 LearningCircuit

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Implications for Users and Contributors
The MIT License grants users and contributors significant freedoms, including the right to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the software. However, it also requires that the original copyright notice and permission notice be included in all copies or substantial portions of the software. This ensures that the original authors are credited and that the license terms are preserved. The license disclaims all warranties, meaning that the software is provided "as is" without any guarantees of merchantability, fitness for a particular purpose, or non-infringement. Users and contributors are advised to use the software at their own risk.

**Section sources**
- [LICENSE](file://LICENSE)
- [README.md](file://README.md#L506-L508)

## Third-Party Dependencies and Licenses
The local-deep-research project relies on a variety of third-party dependencies from both the Python and JavaScript ecosystems. These dependencies are managed through `pyproject.toml` for Python and `package.json` for JavaScript. The licenses of these dependencies are critical for ensuring compliance with open-source requirements.

### Python Dependencies
The Python dependencies are listed in `pyproject.toml` and include a wide range of libraries for AI, web development, data processing, and more. Key dependencies and their licenses include:
- **langchain**: Apache License 2.0
- **flask**: BSD License
- **sqlalchemy**: MIT License
- **requests**: Apache License 2.0
- **pydantic**: MIT License

The project uses the `pdm-backend` for dependency management, which ensures that all dependencies are properly resolved and installed. The `pyproject.toml` file specifies the exact versions of dependencies to ensure reproducibility and security.

### JavaScript Dependencies
The JavaScript dependencies are listed in `package.json` and are used for the web frontend. Key dependencies and their licenses include:
- **bootstrap**: MIT License
- **chart.js**: MIT License
- **socket.io-client**: MIT License
- **highlight.js**: BSD License
- **dompurify**: Apache License 2.0

The frontend dependencies are managed using npm, and the `package-lock.json` file ensures that the exact versions of dependencies are used.

### License Compliance
The project ensures compliance with the licenses of its dependencies by including the appropriate license texts in the repository and by providing attribution in the documentation. Users and contributors must ensure that they comply with the licenses of the dependencies when using or modifying the project.

**Section sources**
- [pyproject.toml](file://pyproject.toml)
- [package.json](file://package.json)

## Data Privacy and Encryption
The local-deep-research project places a strong emphasis on data privacy and security, particularly through the use of SQLCipher for database encryption and a zero-knowledge architecture.

### SQLCipher Encryption
The project uses SQLCipher to encrypt user databases at rest, ensuring that all data is protected with AES-256 encryption. This is the same technology used by Signal Messenger, providing a high level of security. Each user has their own encrypted database, which is isolated from other users' data. The encryption key is derived from the user's password using PBKDF2-SHA512 with 256,000 iterations, making brute-force attacks extremely difficult.

The encryption process is managed by the `sqlcipher_utils.py` and `encrypted_db.py` modules, which handle the creation and management of encrypted databases. The `sqlcipher_utils.py` module provides utility functions for setting the encryption key and applying PRAGMA settings, while `encrypted_db.py` manages the database connections and ensures that the encryption is properly initialized.

### Zero-Knowledge Architecture
The project employs a zero-knowledge architecture, meaning that no password recovery mechanism is in place. This ensures that even the developers cannot access user data, as the encryption key is derived solely from the user's password. This design choice prioritizes user privacy and security, as it prevents any potential backdoors or unauthorized access to user data.

### Data Integrity
To ensure data integrity, the project uses HMAC-SHA512 to verify that the data has not been tampered with. This is particularly important for preventing data corruption and ensuring that the integrity of the encrypted databases is maintained.

**Section sources**
- [sqlcipher_utils.py](file://src/local_deep_research/database/sqlcipher_utils.py)
- [encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py)
- [README.md](file://README.md#L57-L71)

## Compliance with Web Scraping and API Usage
The local-deep-research project interacts with various web services and APIs, and it is important to ensure compliance with the terms of service of these services.

### Web Scraping
The project uses web scraping to gather information from various sources, including academic papers, news articles, and general web content. To comply with the terms of service of these sources, the project implements rate limiting and adaptive wait times to avoid overwhelming the servers. The `BaseSearchEngine` class in `search_engine_base.py` includes mechanisms for rate limiting and retrying requests, ensuring that the project respects the rate limits of the services it interacts with.

### API Usage
The project supports integration with various APIs, including those from OpenAI, Anthropic, Google, and others. Users are responsible for obtaining the necessary API keys and ensuring that they comply with the terms of service of these providers. The project does not store API keys in plain text; instead, they are stored in encrypted databases, and the `data_sanitizer.py` module ensures that sensitive information is not accidentally leaked in logs or API responses.

### Responsible Usage
Users are encouraged to use the project responsibly and to respect the terms of service of the services they interact with. The project provides tools for monitoring and managing API usage, including rate limiting and logging, to help users stay within the limits of the services they use.

**Section sources**
- [search_engine_base.py](file://src/local_deep_research/web_search_engines/search_engine_base.py)
- [data_sanitizer.py](file://src/local_deep_research/security/data_sanitizer.py)

## Data Retention Policies
The local-deep-research project implements data retention policies to ensure that user data is not retained longer than necessary.

### Data Storage
User data is stored in encrypted databases, and each user has their own isolated database. The data is retained as long as the user account exists, and users can delete their data at any time by deleting their account. The project does not retain data from web scraping or API usage beyond the duration of the research session, unless explicitly saved by the user.

### Data Deletion
When a user deletes their account, their encrypted database is permanently deleted, and all data is irretrievable. The project does not have any mechanisms for recovering deleted data, in line with its zero-knowledge architecture.

### Logging
The project logs certain information for debugging and monitoring purposes, but sensitive information such as passwords and API keys are redacted from the logs. The `data_sanitizer.py` module ensures that sensitive data is not logged, and the logs are stored securely.

**Section sources**
- [encrypted_db.py](file://src/local_deep_research/database/encrypted_db.py)
- [data_sanitizer.py](file://src/local_deep_research/security/data_sanitizer.py)

## Security Review Process
The local-deep-research project has a robust security review process to ensure that changes to security-critical code are properly reviewed and tested.

### Automated Detection
The project uses an automated alert system to detect when pull requests modify security-critical files, such as those related to database encryption, authentication, and security utilities. When such changes are detected, the CI system posts a prominent warning comment with a security-specific review checklist, adds labels to the PR, and creates a status check indicating that a security review is required.

### Review Checklists
The review checklists are specific to the type of changes made. For example, changes to encryption code require checks for SQLCipher pragma order, hardcoded keys, backward compatibility, and migration paths. Changes to authentication code require checks for auth bypasses, secure session handling, proper password hashing, and privilege escalation. These checklists ensure that reviewers are aware of the potential risks and can thoroughly evaluate the changes.

### Developer and Reviewer Guidelines
Developers are expected to self-review their changes, document the reasons for the changes, and test thoroughly, especially with existing encrypted databases. Reviewers are expected to take the warnings seriously, go through the checklists, test locally, and ask questions if something seems off. For critical changes, a second opinion is recommended.

**Section sources**
- [SECURITY_REVIEW_PROCESS.md](file://docs/SECURITY_REVIEW_PROCESS.md)

## Responsible Disclosure Guidelines
The local-deep-research project encourages responsible disclosure of security vulnerabilities to ensure that they can be addressed promptly and effectively.

### Reporting Vulnerabilities
Users and contributors who discover security vulnerabilities are encouraged to report them to the maintainers through the GitHub Issues page. The report should include a detailed description of the vulnerability, steps to reproduce it, and any potential impact. The maintainers will acknowledge the report and work to address the vulnerability as quickly as possible.

### Coordinated Disclosure
The project follows a coordinated disclosure process, where the maintainers work with the reporter to verify the vulnerability, develop a fix, and release a patch. The maintainers will credit the reporter in the release notes and on the GitHub contributors graph, recognizing their contribution to the security of the project.

### No Exploitation
Reporters are expected to refrain from exploiting the vulnerability or disclosing it publicly until a fix has been released. This ensures that users are protected and that the vulnerability can be addressed without causing harm.

**Section sources**
- [CONTRIBUTING.md](file://CONTRIBUTING.md#L99-L104)

## Attribution and Licensing for Derivative Works
Users and contributors who create derivative works based on the local-deep-research project must comply with the terms of the MIT License and provide proper attribution.

### Attribution Requirements
Derivative works must include the original copyright notice and permission notice from the MIT License. This ensures that the original authors are credited and that the license terms are preserved. The attribution should be clear and visible, typically in the documentation or source code of the derivative work.

### Commercial Use
The MIT License allows for commercial use of the software, including in proprietary products. However, users must ensure that they comply with the license terms, including providing attribution and not holding the original authors liable for any claims or damages.

### Licensing of Derivative Works
Derivative works can be licensed under different terms, but the original MIT License terms must be preserved for the parts of the software that are derived from the local-deep-research project. This means that the derivative work can be licensed under a more restrictive license, but the original code must remain under the MIT License.

**Section sources**
- [LICENSE](file://LICENSE)
- [CONTRIBUTING.md](file://CONTRIBUTING.md#L119-L124)

## Conclusion
The local-deep-research project is designed with a strong focus on legal and compliance aspects, ensuring that users and contributors can use the software in a manner that respects open-source principles, data privacy, and security. The MIT License provides broad freedoms while requiring proper attribution, and the project's use of SQLCipher and zero-knowledge architecture ensures that user data is protected. Compliance with web scraping and API usage terms is enforced through rate limiting and responsible usage practices, and the security review process and responsible disclosure guidelines help maintain the integrity of the project. Users and contributors are encouraged to follow these guidelines to ensure that the project remains a trusted and secure tool for AI-powered research.