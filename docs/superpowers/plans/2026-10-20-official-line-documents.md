# Official Line Plans and Timetables Implementation Plan

> **For agentic workers:** Execute this plan task by task in the current workspace.

**Goal:** Import and version IDFM's official line-plan and timetable link catalogue, then expose matching documents from the selected bus line.

**Architecture:** Parse the official `fiches-horaires-et-plans` CSV into an archived, hash-addressed dataset version. Match document `ID_Line` values through the already imported line-reference catalogue, preserve every URL and source field, and show external links without copying the PDFs.

**Tech Stack:** Swift 6, Foundation, SwiftUI, existing `CSVTableReader`, URLSession and `NetworkVersionStore` storage conventions.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 4.3, 4.4 and 14 Phase B.

## Global Constraints

- Keep the GTFS route ID distinct from IDFM `ID_Line` and use the existing exact identifier matcher.
- Archive the imported CSV, its SHA-256, source URL, import date, license and attribution; archive each rejected row with its 1-based data-record number, reason and original fields.
- Preserve original document names, URLs, types and unrecognized CSV fields.
- Do not copy linked PDFs into the application; retain links because PDF reuse terms are separate.
- Keep missing document links visible and non-blocking.
- Do not infer a contract or depot assignment from a plan or timetable.

## Review Focus

- Duplicate or malformed `ID_Line` rows: retain rows and never create a false route match.
- Non-HTTP document URLs: keep the source row as invalid/skipped metadata, never make it clickable.
- Multiple plans or timetables for one line: present all imported links, not an arbitrary single document.
- A missing line-reference match: show no route documents and explain the missing prerequisite.
- An imported catalogue without a document for a line: state that absence without implying the line has no service.

---

### Task 1: Versioned document catalogue

**Files:**
- Modify: `TransportManagerIDFM/Domain/NetworkCatalog.swift`
- Create: `TransportManagerIDFM/Domain/LineDocumentStore.swift`
- Modify: `TransportManagerIDFM/Domain/NetworkLibrary.swift`

**Interfaces:**
- `NetworkLineDocument` stores source ID, document name, URL, type, commercial line name and raw CSV attributes.
- `NetworkLineDocumentVersion` stores dataset metadata, archive path, checksum, record count, skipped-record count and the issues archive path.
- `LineDocumentStore.importCSV(data:originalFilename:)` archives and indexes one version; `loadDocuments(for:)` reads its index.
- `NetworkLibrary` exposes the active documents, local import, current public download and loading APIs.

- [x] Add backward-compatible catalogue fields and source state for document versions.
- [x] Parse `ID_Line`, `Document_Name`, `URL`, `Type` and `Name_Line` with normalized column names; preserve extra columns.
- [x] Archive original CSV and a JSON index by SHA-256 with the Open Licence v2.0 metadata.
- [x] Archive row-level issue metadata for rejected records, including source record number, reason and raw fields; allow a structurally valid CSV with no usable links to remain inspectable.
- [x] Add asynchronous current-download and local-import paths for the official dataset.

### Task 2: Selected-line document access

**Files:**
- Modify: `TransportManagerIDFM/Domain/NetworkLibrary.swift`
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`

**Interfaces:**
- `NetworkLibrary.documents(for route: GTFSRouteSummary) -> [NetworkLineDocument]` matches through the unique imported IDFM line reference.

- [x] Add download and CSV import controls to the source panel, with import status and errors.
- [x] Show all official plan and timetable links for the selected route, grouped by their source type.
- [x] Show distinct messages for missing dataset, missing IDFM line match and no document rows.
- [x] Keep the links optional so missing documents do not block a career.

### Task 3: Documentation and verification

**Files:**
- Modify: `README.md`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Document the official document-link dataset, its license, versioning and URL-only handling of PDFs.
- [x] Run the macOS Xcode build and inspect its exit status.

### Review corrections

- [x] Migrate decoded catalogs by restoring any missing current source definitions while retaining saved import states and unknown source entries.
- [x] Persist invalid document rows as a versioned JSON issue archive rather than only retaining a skipped-row count.
