# Regional Bluebus Market Entry Implementation Plan

> **For agentic workers:** Use the existing project execution workflow and complete this plan task by task. Steps use checkbox syntax for tracking.

**Goal:** Expand the Île-de-France vehicle market with a sourced Bluebus 12 m electric reference while keeping regional fleet evidence separate from Bords de Marne sightings.

**Architecture:** Add optional, Codable-compatible regional evidence and range fields to the existing model catalog. Add the Bluebus reference and one clearly simulated used offer, then expose only the sourced facts in the market card; keep unknown capacity, battery, door and accessibility details unfilled.

**Tech Stack:** Swift 6, SwiftUI, Codable simulation market models.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md` — sections 6.1–6.3; `docs/IMPLEMENTATION_STATUS.md` — regional model catalogue.

## Global Constraints

- Preserve existing career saves by making any newly added model fields optional and compatible with synthesized Codable decoding.
- Distinguish official fleet evidence from simulated market stock and estimated game prices.
- Do not invent battery capacity, passenger capacity, door count, PMR layout, or depot charging compatibility when the sources do not provide them.
- Use the RATP 2016 activity report for the 12 m Bluebus order and first-service evidence, the IDFM 2015 note for its stated range, and CATP's 2024 12 m electric-bus average only as a generic price basis, not a Bluebus quotation.
- Do not add or run tests unless the user asks; verify compilation with the macOS build.

## Review Focus

- A regional-only model must not be described as observed in the Bords de Marne fleet.
- Old saves without the optional regional evidence and range keys must remain decodable.
- The simulated used offer must not look like a real classified listing.
- Bluebus capacity, battery size, doors, accessibility layout, and depot compatibility remain unknown unless sourced.
- Its stated range must retain the source's qualification: up to 180 km without intermediate charging, with terminal charging potentially extending it.

---

### Task 1: Extend model evidence without losing save compatibility

**Files:**
- Modify `TransportManagerIDFM/Domain/VehicleMarket.swift`.

**Interfaces:**
- Change `VehicleMarketModel.firstObservedInScenarioYear` to `Int?`, preserving existing saved integer values.
- Add optional `regionalEvidenceYear: Int?`, `rangeKilometers: Int?`, and `rangeEvidenceNote: String?` properties; update the catalog factory to populate them.

- [x] Add the optional properties and keep existing Bords de Marne entries' current year and technical values unchanged.
- [x] Compile the macOS target to verify the Codable model and existing model initializers still build.

### Task 2: Add a sourced Bluebus reference and simulated stock

**Files:**
- Modify `TransportManagerIDFM/Domain/VehicleMarket.swift`.

**Interfaces:**
- Add catalog model ID `bluebus-12m-electric`, standard class, electric energy, length 12 m, regional evidence year 2016, and range 180 km with the qualification note.
- Link fleet evidence to RATP's 2016 activity report, which records an order for 23 Bluebus 12 m for line 341 and first service in spring 2016; retain IDFM's 2015 advance announcement as the contemporary range source, and keep unsupported capacity, battery, and accessibility fields nil.
- Add one generated used offer, explicitly within the existing simulated market mechanism, with a generic 2024 CATP electric 12 m price reference rather than a model-specific quote.

- [x] Add the regional Bluebus catalog entry with RATP fleet evidence and IDFM range evidence.
- [x] Add the generated used offer without adding a new or real-world inventory claim.

### Task 3: Show provenance and update the active project status

**Files:**
- Modify `TransportManagerIDFM/Features/OperationsDashboardView.swift`.
- Modify `README.md` and `docs/IMPLEMENTATION_STATUS.md`.

- [x] Show the regional evidence year and qualified range in the offer card; keep undocumented specifications visibly undocumented.
- [x] Update the market summary to say it now includes a regionally documented Bluebus reference while the full regional catalogue remains incomplete.
- [x] Run the macOS Debug build and resolve compilation errors.

**Ruling:** Treat this Bluebus entry as one regionally attested model family from the 2016 line-341 deployment. Do not infer it was present at Bords de Marne or carry over the manufacturer's current specification as though it were the 2016 vehicle. Use the contemporary IDFM statement of up to 180 km without intermediate charging; note that terminal charging could extend it.

**Verification:** Build with `xcodebuild -quiet -project TransportManagerIDFM.xcodeproj -scheme TransportManagerIDFM -configuration Debug -destination 'generic/platform=macOS' -derivedDataPath /tmp/transport-manager-idfm-bluebus CODE_SIGNING_ALLOWED=NO build`. Do not run tests under the global constraint above. Source evidence: RATP's 2016 activity report records an order for 23 Bluebus 12 m for line 341 and the first service in spring 2016; IDFM's `STIF en ligne n°8` (2015) is the contemporary announcement that describes standard 12 m buses with up to 180 km range without intermediate charging; CATP's generic 2024 electric 12 m acquisition average is not a Bluebus quote.
