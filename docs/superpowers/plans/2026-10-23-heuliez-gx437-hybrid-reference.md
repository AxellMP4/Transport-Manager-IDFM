# Heuliez GX 437 Hybrid Reference Implementation Plan

> **For agentic workers:** Implement this plan task by task. Steps use checkbox syntax for tracking.

**Goal:** Add a source-backed regional Heuliez GX 437 Hybrid entry without assigning its specifications or availability to Bords de Marne.

**Architecture:** Add one `VehicleMarketModel` and dated `VehicleTechnicalVariant` entries to the existing catalog. Keep manufacturer seating layouts separate from the documented RATP vehicle and leave market pricing/offers absent until a suitable 18 m hybrid price basis is documented.

**Tech Stack:** Swift value types, SwiftUI catalog data, Xcode macOS target.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 4.2, 6.1–6.3; `docs/IMPLEMENTATION_STATUS.md`, regional vehicle catalog item.

## Global Constraints

- Catalog models attested in Île-de-France and retain the source and observation date.
- A contract area, manufacturer range, or single vehicle record does not prove assignment to either Bords de Marne COB.
- Leave unverified dimensions, capacities, prices, and market availability unset; do not create an offer without a documented price basis.
- Verify the macOS Debug target after changes and record the result in `docs/IMPLEMENTATION_STATUS.md`.

## Review Focus

- Do not turn manufacturer seating layouts into a maximum passenger capacity.
- Do not generalize vehicle 924417's configuration to every GX 437 Hybrid.
- Do not imply availability for sale or add a Bords de Marne market offer.
- Do not apply GX 437 Hybrid data to GX 437 diesel or electric variants.

---

### Task 1: Add the regional model and document the validation

**Files:**
- Modify: `TransportManagerIDFM/Domain/VehicleMarket.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Verify: `TransportManagerIDFM` Debug macOS target

**Interfaces:**
- Produces: model ID `heuliez-gx437-hybrid`; source-dated variants for the June 2020 manufacturer seating layouts and the individual RATP vehicle 924417.

- [x] Add the articulated diesel-hybrid reference, preserving the 2020 manufacturer dimensions and the separate 38-seat, 40-seat, and 924417 configurations; keep maximum capacity and CATP price unset.
- [x] Record the primary Heuliez technical sheet and the dated secondary fleet evidence; explicitly note that neither proves Bords de Marne assignment or current sale availability.
- [x] Run `swiftc -frontend -parse TransportManagerIDFM/Domain/VehicleMarket.swift TransportManagerIDFM/Features/OperationsDashboardView.swift` and `git diff --check`.
- [x] Build Debug macOS with `xcodebuild -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -configuration Debug -sdk macosx -destination 'generic/platform=macOS' -derivedDataPath /private/tmp/TransitCityGX437DerivedData CODE_SIGNING_ALLOWED=NO build`; record the result and architectures in the status document.
