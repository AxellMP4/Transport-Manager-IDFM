# DSP 45 source ledger and line crosswalk

## Objective

Make the official IDFM line-to-contract crosswalk available in the Bords de Marne network audit, independent of whether GTFS has been imported. Preserve the source date and identifier semantics, and do not infer depot or COB assignments from the contract contour.

## Evidence model

- Match line-reference `ID_Bus_Contrat` to contract-contour `id_contrat` (both identify the bus contract).
- Never use GeoJSON `objectid` as the contract key; contract 45 currently has `objectid=3`.
- Keep the line-reference and contour versions independently dated and hashed; their snapshots are not cotemporal.
- For the 20 October 2026 line-reference snapshot: contract 45 has 29 active lines and one upcoming line, 314, effective 2 November 2026. The upcoming 314 is not active on 1 November unless the official validity dates say so.
- IDFM's award announcement reports 29 lines, 2 COB plus a third planned site, 315 vehicles, 13.9 million contractual commercial kilometres, a six-year base term through 31 October 2031, and an optional two-year extension.
- The RATP 2025 annual report instead describes Boucles de Marne as 31 lines, 3 COB, 320 vehicles, and 18.6 million contractual commercial kilometres over eight years. Preserve this as a separately sourced operator-report snapshot; the discrepancy with IDFM is unresolved and neither source should overwrite the other.
- IDFM's 2026 budget lists €28,473,705 under an engagement schedule. Its period/financial semantics are unclear, so it must not be treated as annual revenue or seeded cash.
- The PRIM dataset page and the catalog API returned different processing times for the 20 October line-reference dataset. Store/display the catalog API's `data_processed` as metadata and keep it distinct from the downloaded CSV's hash/import time; do not claim that both exports were produced at precisely that timestamp.
- Keep COB assignment unresolved unless supported by its own dated evidence.

## Implementation steps

1. Add the contract identifier and optional source processing date to the line-reference model/version, with backward-compatible decoding for existing local catalogs.
2. Capture IDFM dataset metadata when downloading the line-reference CSV, while allowing metadata lookup to fail without blocking the CSV import. Label the API processing time separately from CSV import time/hash.
3. Load contract contours for the audit and show a collapsible DSP 45 roster sourced from `ID_Bus_Contrat`, including line ID/name, operator/network, exact status, and validity range.
4. Join the contract feature by `id_contrat`, show its display name and independently sourced version metadata, and explicitly describe `objectid` as an unrelated feature identifier.
5. Add source-separated contract facts for the IDFM award announcement, the differing 2025 RATP operational snapshot, and the IDFM budget commitment, keeping the budget figure out of the simulated cash-flow model.
6. Update implementation status and the full project plan's outstanding-data notes after the UI is integrated.
7. Build the macOS target to catch compiler errors. Do not run tests unless the user asks.

## Acceptance criteria

- The 30 official IDFM records for contract 45 are visible without GTFS; statuses and validity dates distinguish 29 active from upcoming 314.
- Contract geometry joins using the value `45` in `id_contrat`, never `objectid=3`.
- Line references, contract contours, and RATP/IDFM contract facts show separate dates and provenance.
- No depot/COB allocation, annual DSP45 revenue, or budget cash flow is invented from these sources.
- Existing older local line-reference manifests remain readable.
- The macOS app target builds successfully.

## Progress — 20 October 2026

- Implemented the crosswalk roster, contract-contour join, separate source snapshots, budget label, and line-reference processing metadata.
- Added the regional Scania Citywide articulated CNG reference in a separate catalog-only change.
- macOS Debug build succeeded with Xcode using an isolated DerivedData folder. No tests were run.
- Bundled the official line-reference, line-document, and contract-contour exports with Xcode resources and added a sequential first-launch import into Application Support only when no active version exists; existing user-selected versions are preserved. The roster now has its local source data available offline.
- Rebuilt the macOS Debug target after wiring the bootstrap; the three built `.app` resource files match the documented SHA-256 values. No tests were run.
- Further work remains in the full recreation objective, including real PRIM archive validation, complete regional depot/line coverage, and remaining game-system requirements.
