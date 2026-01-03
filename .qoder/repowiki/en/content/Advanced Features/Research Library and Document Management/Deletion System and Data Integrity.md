# Deletion System and Data Integrity

<cite>
**Referenced Files in This Document**   
- [cascade_helper.py](file://src/local_deep_research/research_library/deletion/utils/cascade_helper.py)
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py)
- [collection_deletion.py](file://src/local_deep_research/research_library/deletion/services/collection_deletion.py)
- [bulk_deletion.py](file://src/local_deep_research/research_library/deletion/services/bulk_deletion.py)
- [delete_routes.py](file://src/local_deep_research/research_library/deletion/routes/delete_routes.py)
- [test_document_deletion.py](file://tests/deletion/test_document_deletion.py)
- [test_collection_deletion.py](file://tests/deletion/test_collection_deletion.py)
- [test_cascade_integration.py](file://tests/deletion/test_cascade_integration.py)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Cascade Deletion Pattern](#cascade-deletion-pattern)
3. [Three-Level Deletion Service Architecture](#three-level-deletion-service-architecture)
4. [Safety Mechanisms and Deletion Previews](#safety-mechanisms-and-deletion-previews)
5. [Resource Cleanup During Deletion](#resource-cleanup-during-deletion)
6. [Deletion Scenarios and Data Impact](#deletion-scenarios-and-data-impact)
7. [API Endpoints for Deletion Operations](#api-endpoints-for-deletion-operations)
8. [Conclusion](#conclusion)

## Introduction

The deletion system in the Local Deep Research application is designed to ensure data integrity while providing flexible document and collection management capabilities. This system implements a comprehensive cascade deletion pattern to maintain referential integrity across multiple data stores, including databases, filesystems, and search indexes. The architecture supports three distinct levels of deletion operations—document, collection, and bulk—each with specific behaviors and safety mechanisms. The system also includes features for previewing deletion impacts, recovering recently deleted items, and cleaning up associated resources such as PDF files, database records, and index entries. This documentation provides a detailed analysis of the deletion system's implementation, focusing on its architecture, safety mechanisms, and integration points.

## Cascade Deletion Pattern

The cascade deletion pattern implemented in the Local Deep Research application ensures referential integrity by systematically cleaning up related records that would otherwise become orphaned. This pattern is primarily facilitated through the `CascadeHelper` utility class, which addresses the absence of foreign key constraints in certain database relationships.

The `CascadeHelper` class provides static methods for cleaning up various types of related records during deletion operations. Key methods include `delete_document_chunks()` for removing DocumentChunks associated with a document, `delete_document_blob()` for handling document binary data, and `delete_faiss_index_files()` for removing FAISS index files. The helper also manages the update of DownloadTracker records when documents are deleted, ensuring that download status is properly maintained.

A critical aspect of the cascade pattern is the manual cleanup of DocumentChunks, which lack foreign key constraints. When a document is deleted, the system must explicitly remove all associated chunks to prevent orphaned records. This is accomplished by first retrieving all collection IDs associated with the document and then deleting chunks for each collection. The `delete_document_completely()` method in `CascadeHelper` implements a specific deletion order to avoid database constraint violations, first deleting the DocumentBlob (which has the document ID as a primary key), then the DocumentCollection links, and finally the Document itself.

```mermaid
classDiagram
class CascadeHelper {
+delete_document_chunks(session, document_id, collection_name) int
+delete_collection_chunks(session, collection_name) int
+delete_document_blob(session, document_id) int
+delete_filesystem_file(file_path) bool
+delete_faiss_index_files(index_path) bool
+delete_rag_indices_for_collection(session, collection_name) Dict[str, Any]
+update_download_tracker(session, document) bool
+count_document_in_collections(session, document_id) int
+get_document_collections(session, document_id) List[str]
+remove_from_faiss_index(username, collection_name, chunk_ids) bool
+delete_document_completely(session, document_id) bool
}
class DocumentDeletionService {
-username : str
-cascade_helper : CascadeHelper
+delete_document(document_id) Dict[str, Any]
+delete_blob_only(document_id) Dict[str, Any]
+remove_from_collection(document_id, collection_id) Dict[str, Any]
+get_deletion_preview(document_id) Dict[str, Any]
}
class CollectionDeletionService {
-username : str
-cascade_helper : CascadeHelper
+delete_collection(collection_id, delete_orphaned_documents) Dict[str, Any]
+delete_collection_index_only(collection_id) Dict[str, Any]
+get_deletion_preview(collection_id) Dict[str, Any]
}
CascadeHelper --> DocumentDeletionService : "used by"
CascadeHelper --> CollectionDeletionService : "used by"
```

**Diagram sources**
- [cascade_helper.py](file://src/local_deep_research/research_library/deletion/utils/cascade_helper.py#L26-L418)
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L23-L436)
- [collection_deletion.py](file://src/local_deep_research/research_library/deletion/services/collection_deletion.py#L26-L328)

**Section sources**
- [cascade_helper.py](file://src/local_deep_research/research_library/deletion/utils/cascade_helper.py#L26-L418)

## Three-Level Deletion Service Architecture

The deletion system implements a three-level service architecture consisting of document, collection, and bulk deletion services. Each level provides specific functionality while maintaining data integrity through the cascade deletion pattern.

The **Document Deletion Service** handles individual document operations, including complete document deletion, blob-only deletion (removing the PDF while preserving text content), and removing documents from collections. When a document is removed from a collection, the service checks if the document exists in any other collections. If not, the document is completely deleted to prevent orphaned records. The service returns detailed results including the number of chunks deleted, blob size freed, and whether the document was unlinked or deleted.

The **Collection Deletion Service** manages collection-level operations, including full collection deletion and index-only deletion. When a collection is deleted, all associated DocumentChunks, RAG indices, and FAISS index files are removed. Documents are preserved but unlinked from the collection unless they are no longer referenced by any other collection, in which case they are also deleted. The service supports an option to preserve all documents regardless of their collection membership.

The **Bulk Deletion Service** provides operations for handling multiple documents simultaneously. It leverages the Document Deletion Service to perform bulk operations such as deleting multiple documents, removing multiple documents from a collection, or deleting blobs for multiple documents. The service aggregates results from individual operations, providing summary statistics on the number of successful and failed deletions, total chunks deleted, and bytes freed.

```mermaid
flowchart TD
A["Deletion Request"] --> B{Operation Type}
B --> |Single Document| C[DocumentDeletionService]
B --> |Single Collection| D[CollectionDeletionService]
B --> |Multiple Items| E[BulkDeletionService]
C --> F[CascadeHelper]
D --> F
E --> C
E --> D
F --> G[Database Cleanup]
F --> H[Filesystem Cleanup]
F --> I[Index Cleanup]
G --> J[Transaction Commit]
H --> J
I --> J
J --> K[Return Results]
style C fill:#f9f,stroke:#333
style D fill:#f9f,stroke:#333
style E fill:#f9f,stroke:#333
style F fill:#bbf,stroke:#333
```

**Diagram sources**
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L23-L436)
- [collection_deletion.py](file://src/local_deep_research/research_library/deletion/services/collection_deletion.py#L26-L328)
- [bulk_deletion.py](file://src/local_deep_research/research_library/deletion/services/bulk_deletion.py#L17-L298)

**Section sources**
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L23-L436)
- [collection_deletion.py](file://src/local_deep_research/research_library/deletion/services/collection_deletion.py#L26-L328)
- [bulk_deletion.py](file://src/local_deep_research/research_library/deletion/services/bulk_deletion.py#L17-L298)

## Safety Mechanisms and Deletion Previews

The deletion system incorporates several safety mechanisms to prevent accidental data loss and provide users with clear information about the impact of deletion operations. The primary safety feature is the deletion preview functionality, which allows users to see exactly what will be affected before confirming a deletion.

The preview system is implemented through `get_deletion_preview()` methods in both the DocumentDeletionService and CollectionDeletionService. For document deletion, the preview shows information such as the document title, file type, storage mode, whether a blob exists and its size, the number of collections the document belongs to, and the number of text chunks that will be deleted. For collection deletion, the preview displays the collection name, description, number of documents, number of chunks, number of folders, and whether a RAG index exists.

These preview methods are exposed through dedicated API endpoints that return detailed information about the impending deletion. The frontend can use this information to display confirmation dialogs with specific details about the operation, helping users make informed decisions. The preview functionality is also available for bulk operations through the `get_bulk_preview()` method in the BulkDeletionService, which provides aggregate statistics on the total number of documents, documents with blobs, total blob size, and total chunks affected.

The system also implements transactional integrity through database sessions, ensuring that deletion operations are atomic. If any part of the deletion process fails, the entire transaction is rolled back, preventing partial deletions that could compromise data integrity. Error handling is comprehensive, with detailed error messages returned to the client to help diagnose issues.

```mermaid
sequenceDiagram
participant User as "User Interface"
participant API as "Delete API"
participant Service as "Deletion Service"
participant Helper as "CascadeHelper"
participant DB as "Database"
User->>API : GET /document/{id}/preview
API->>Service : get_deletion_preview(id)
Service->>DB : Query document metadata
Service->>Helper : get_document_collections(id)
Helper->>DB : Query DocumentCollection
DB-->>Helper : Collection IDs
Helper-->>Service : Collection count
Service->>DB : Count DocumentChunks
DB-->>Service : Chunk count
Service->>Helper : get_document_blob_size(id)
Helper->>DB : Query DocumentBlob
DB-->>Helper : Blob size
Helper-->>Service : Blob size
Service-->>API : Preview data
API-->>User : JSON response with deletion impact
User->>API : DELETE /document/{id}
API->>Service : delete_document(id)
Service->>Helper : get_document_collections(id)
Helper->>DB : Query collections
DB-->>Helper : Collection IDs
Helper-->>Service : Collection IDs
Service->>Helper : delete_document_chunks() for each collection
Helper->>DB : Delete chunks
DB-->>Helper : Count
Service->>Helper : get_document_blob_size(id)
Helper->>DB : Query blob
DB-->>Helper : Size
Service->>Helper : delete_filesystem_file() if applicable
Service->>Helper : update_download_tracker()
Service->>Helper : delete_document_completely(id)
Helper->>DB : Delete blob, links, document
DB-->>Helper : Success
Helper-->>Service : Result
Service-->>API : Deletion summary
API-->>User : Success/failure response
```

**Diagram sources**
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L389-L436)
- [delete_routes.py](file://src/local_deep_research/research_library/deletion/routes/delete_routes.py#L87-L109)

**Section sources**
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L389-L436)
- [delete_routes.py](file://src/local_deep_research/research_library/deletion/routes/delete_routes.py#L87-L109)

## Resource Cleanup During Deletion

The deletion system comprehensively cleans up all associated resources when documents or collections are removed, ensuring no orphaned data remains in the system. This cleanup process targets three main resource types: database records, filesystem files, and search index entries.

For **database records**, the system removes multiple related entities when a document is deleted. The DocumentBlob record is deleted either through CASCADE operations or explicitly via the `delete_document_blob()` method. DocumentCollection links are removed to disconnect the document from collections, and RagDocumentStatus records are cleaned up as part of the CASCADE deletion. The system handles the special case of DocumentChunks, which lack foreign key constraints, by explicitly deleting them through query-based operations before removing the parent document.

For **filesystem files**, the system identifies and removes PDF files when appropriate. The `delete_filesystem_file()` method in CascadeHelper handles this cleanup, checking the document's storage mode and file path before attempting deletion. The method includes safeguards to prevent deletion of special path markers like "metadata_only" or "text_only_not_stored". When a document is stored in the filesystem (storage_mode="filesystem"), the absolute path is resolved using `get_absolute_path_from_settings()` before deletion.

For **search index entries**, the system removes both the FAISS index files (.faiss and .pkl) and the corresponding RAGIndex database records. The `delete_faiss_index_files()` method deletes the physical index files from storage, while `delete_rag_indices_for_collection()` removes the database records and returns statistics on the cleanup. When removing specific chunks from a collection, the `remove_from_faiss_index()` method interacts with the LibraryRAGService to update the FAISS index directly.

The cleanup process is designed to be idempotent and resilient, with error handling that logs failures but continues with other cleanup operations. This ensures that even if one resource type cannot be cleaned up (e.g., a filesystem file is locked), other cleanup operations still proceed, minimizing the risk of data inconsistency.

```mermaid
flowchart TD
A[Deletion Operation] --> B[Database Cleanup]
A --> C[Filesystem Cleanup]
A --> D[Index Cleanup]
B --> B1[Delete DocumentChunks]
B --> B2[Delete DocumentBlob]
B --> B3[Delete DocumentCollection links]
B --> B4[Delete RagDocumentStatus]
B --> B5[Delete Document]
C --> C1[Check storage mode]
C1 --> |filesystem| C2[Resolve absolute path]
C2 --> C3[Delete file]
C1 --> |database| C4[No action needed]
D --> D1[Delete FAISS .faiss file]
D --> D2[Delete FAISS .pkl file]
D --> D3[Delete RAGIndex record]
B --> E[Transaction Commit]
C --> E
D --> E
E --> F[Return Results]
style B fill:#f96,stroke:#333
style C fill:#f96,stroke:#333
style D fill:#f96,stroke:#333
```

**Diagram sources**
- [cascade_helper.py](file://src/local_deep_research/research_library/deletion/utils/cascade_helper.py#L140-L208)
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L109-L119)
- [collection_deletion.py](file://src/local_deep_research/research_library/deletion/services/collection_deletion.py#L114-L119)

**Section sources**
- [cascade_helper.py](file://src/local_deep_research/research_library/deletion/utils/cascade_helper.py#L140-L208)
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L109-L119)
- [collection_deletion.py](file://src/local_deep_research/research_library/deletion/services/collection_deletion.py#L114-L119)

## Deletion Scenarios and Data Impact

The deletion system handles various scenarios with specific behaviors to maintain data integrity and user expectations. These scenarios include single document deletion, document removal from collections, collection deletion, and bulk operations.

In the **single document deletion** scenario, the system removes the document and all its associated data, including text chunks, PDF blob, and collection links. If the document is stored in the filesystem, the physical file is also deleted. The DownloadTracker record is updated to reflect that the document is no longer downloaded. This operation is comprehensive and irreversible, freeing all resources associated with the document.

When **removing a document from a collection**, the system's behavior depends on whether the document exists in other collections. If the document is only in the specified collection, it is completely deleted after being unlinked (an "orphan" deletion). If the document exists in other collections, it is only unlinked from the specified collection, preserving the document and its data. This behavior ensures that documents are only deleted when they are no longer referenced anywhere in the system.

For **collection deletion**, the system preserves documents but removes all collection-specific data. This includes deleting all DocumentChunks associated with the collection, removing the RAG index and FAISS files, and deleting CollectionFolder records. Documents are unlinked from the collection but remain in the library unless they are no longer referenced by any other collection, in which case they are also deleted. This allows users to reorganize their collections without losing document content.

**Bulk operations** apply the same logic to multiple items simultaneously. The BulkDeletionService processes each item individually, aggregating the results to provide a comprehensive summary of the operation's success and impact. This includes tracking the number of successful deletions, failures, total chunks deleted, and bytes freed.

The system's behavior is validated through comprehensive integration tests that verify the complete cleanup of all related records and the absence of orphaned data. These tests confirm that the cascade deletion pattern works correctly across all scenarios, maintaining referential integrity throughout the application.

```mermaid
stateDiagram-v2
[*] --> DocumentState
state DocumentState {
[*] --> InCollection
[*] --> NotInCollection
InCollection --> RemovedFromCollection : remove_from_collection()
RemovedFromCollection --> CheckOtherCollections : count_document_in_collections()
state CheckOtherCollections {
[*] --> HasOtherCollections
[*] --> NoOtherCollections
HasOtherCollections --> Unlinked : update DownloadTracker
NoOtherCollections --> DeleteDocument : delete_document_completely()
Unlinked --> DocumentState
DeleteDocument --> [*]
}
NotInCollection --> DeleteDocument : delete_document()
DeleteDocument --> [*]
}
[*] --> CollectionState
state CollectionState {
[*] --> Active
Active --> DeleteCollection : delete_collection()
DeleteCollection --> RemoveChunks : delete_collection_chunks()
RemoveChunks --> RemoveIndex : delete_rag_indices_for_collection()
RemoveIndex --> RemoveLinks : delete DocumentCollection links
RemoveLinks --> DeleteCollectionRecord : delete Collection
DeleteCollectionRecord --> CheckDocuments : for each document in collection
CheckDocuments --> DocumentState
DeleteCollectionRecord --> [*]
}
```

**Diagram sources**
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L246-L377)
- [collection_deletion.py](file://src/local_deep_research/research_library/deletion/services/collection_deletion.py#L38-L178)
- [test_document_deletion.py](file://tests/deletion/test_document_deletion.py#L190-L222)
- [test_collection_deletion.py](file://tests/deletion/test_collection_deletion.py#L373-L426)

**Section sources**
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L246-L377)
- [collection_deletion.py](file://src/local_deep_research/research_library/deletion/services/collection_deletion.py#L38-L178)

## API Endpoints for Deletion Operations

The deletion system exposes a comprehensive set of REST API endpoints through the delete_routes module, providing programmatic access to all deletion functionality. These endpoints follow consistent patterns for request handling, error reporting, and response formatting.

The **document deletion endpoints** include:
- `DELETE /library/api/document/{document_id}`: Permanently deletes a document and all associated data
- `DELETE /library/api/document/{document_id}/blob`: Deletes only the PDF blob, preserving text content
- `GET /library/api/document/{document_id}/preview`: Returns a preview of what will be deleted
- `DELETE /library/api/collection/{collection_id}/document/{document_id}`: Removes a document from a specific collection

The **collection deletion endpoints** include:
- `DELETE /library/api/collections/{collection_id}`: Deletes a collection and cleans up related data
- `DELETE /library/api/collections/{collection_id}/index`: Deletes only the RAG index for a collection
- `GET /library/api/collections/{collection_id}/preview`: Returns a preview of collection deletion impact

The **bulk deletion endpoints** include:
- `DELETE /library/api/documents/bulk`: Deletes multiple documents at once
- `DELETE /library/api/documents/blobs`: Deletes PDF blobs for multiple documents
- `DELETE /library/api/collection/{collection_id}/documents/bulk`: Removes multiple documents from a collection
- `POST /library/api/documents/preview`: Gets a preview of bulk deletion impact

All endpoints require authentication via the `@login_required` decorator and return JSON responses with a consistent structure. Successful operations return a 200 status code with a response body containing `"success": true` and operation-specific details. Failed operations return appropriate HTTP status codes (404 for not found, 400 for bad requests) with `"success": false` and an error message. The endpoints handle request validation, including checking for required parameters and proper data types, providing clear error messages when validation fails.

```mermaid
erDiagram
DOCUMENT ||--o{ DOCUMENT_CHUNK : "contains"
DOCUMENT ||--|| DOCUMENT_BLOB : "has"
DOCUMENT ||--o{ DOCUMENT_COLLECTION : "in"
COLLECTION ||--o{ DOCUMENT_COLLECTION : "contains"
COLLECTION ||--o{ COLLECTION_FOLDER : "has"
COLLECTION ||--o{ RAG_INDEX : "has"
DOCUMENT_COLLECTION }|--|| DOCUMENT : "references"
DOCUMENT_COLLECTION }|--|| COLLECTION : "references"
RAG_INDEX }|--|| COLLECTION : "for"
DOCUMENT {
string id PK
string source_type_id FK
string document_hash
int file_size
string file_type
string title
string filename
string storage_mode
string file_path
text text_content
timestamp created_at
timestamp updated_at
}
DOCUMENT_BLOB {
string document_id PK,FK
bytea pdf_binary
string blob_hash
}
DOCUMENT_CHUNK {
string chunk_hash PK
string source_type
string source_id
string collection_name
text chunk_text
int chunk_index
int start_char
int end_char
int word_count
string embedding_id
string embedding_model
string embedding_model_type
}
DOCUMENT_COLLECTION {
string document_id PK,FK
string collection_id PK,FK
boolean indexed
int chunk_count
}
COLLECTION {
string id PK
string name
string description
boolean is_default
string embedding_model
string embedding_model_type
int embedding_dimension
int chunk_size
int chunk_overlap
timestamp created_at
timestamp updated_at
}
COLLECTION_FOLDER {
string collection_id PK,FK
string folder_path PK
boolean recursive
int file_count
timestamp last_scanned
}
RAG_INDEX {
string collection_name PK,FK
string embedding_model
string embedding_model_type
int embedding_dimension
string index_path
string index_hash
int chunk_size
int chunk_overlap
int chunk_count
int total_documents
timestamp created_at
timestamp updated_at
}
```

**Diagram sources**
- [delete_routes.py](file://src/local_deep_research/research_library/deletion/routes/delete_routes.py#L32-L414)
- [document_deletion.py](file://src/local_deep_research/research_library/deletion/services/document_deletion.py#L35-L436)
- [collection_deletion.py](file://src/local_deep_research/research_library/deletion/services/collection_deletion.py#L38-L328)

**Section sources**
- [delete_routes.py](file://src/local_deep_research/research_library/deletion/routes/delete_routes.py#L32-L414)

## Conclusion

The deletion system in the Local Deep Research application provides a robust and comprehensive solution for managing document and collection removal while ensuring data integrity. Through the implementation of a cascade deletion pattern via the CascadeHelper utility, the system maintains referential integrity across multiple data stores, including databases, filesystems, and search indexes. The three-level service architecture—document, collection, and bulk—offers flexible deletion capabilities that meet various user needs while incorporating safety mechanisms like deletion previews and confirmation dialogs.

The system thoroughly cleans up all associated resources during deletion operations, including database records, filesystem files, and index entries, preventing orphaned data and ensuring efficient resource utilization. Various deletion scenarios are handled appropriately, with intelligent behavior for orphaned documents and collections. The comprehensive API endpoints provide programmatic access to all deletion functionality with consistent error handling and response formats.

While the current implementation does not show direct integration with the notification system to inform users of deletion results, such integration could be added to enhance user experience by providing real-time feedback on deletion operations and any errors encountered. Overall, the deletion system demonstrates a well-designed approach to data management that prioritizes integrity, safety, and usability.