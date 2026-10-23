# Heuliez GX 437 Elec Catalogue Reference Plan

> **For agentic workers:** Implement this plan task by task. Each step is independently checkable.

**Goal:** Add a CATP-source-backed Heuliez GX 437 Elec reference without implying current IDFM fleet use, a Bords de Marne assignment, or an unsupported purchase price.

**Architecture:** Add a separate electric model beside the GX 437 Hybrid in the existing vehicle catalogue. Preserve CATP's dated slow-charge configuration as a technical variant, and leave the purchase offer absent because the consulted sources do not publish a model-specific price or 2026 availability.

**Tech Stack:** Swift value types, SwiftUI catalogue data, Xcode macOS target.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 6.1–6.3; `docs/IMPLEMENTATION_STATUS.md`, item 265.

## Global Constraints

- The catalogue target is a macOS SwiftUI app.
- A CATP market reference does not prove use in Île-de-France or at Bords de Marne.
- The 2024-02 specification distinguishes default battery capacity from options and continuous power from peak power.
- Do not create an offer without a supported price and availability basis.
- Build the Debug macOS target and update `docs/IMPLEMENTATION_STATUS.md`.

## Review Focus

- Do not label the 155 passenger capacity as including the driver; the sheet says “155 + conducteur”.
- Do not treat the 2024-02 pack configuration as a GX 437 Hybrid specification.
- Do not infer a price, current CATP validity, fleet presence, or depot charging compatibility.

---

### Task 1: Add the CATP model reference

**Files:**
- Modify: `TransportManagerIDFM/Domain/VehicleMarket.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Verify: Debug macOS build and `git diff --check`

**Interfaces:**
- Produces: model ID `heuliez-gx437-electric` with one CATP AC 2024-02 slow-charge technical variant.

- [x] Add the model and source-linked variant; keep purchase price, current stock, and regional fleet dates unset.
- [x] Record the source limits and external GTFS mirror discovery in the project status and GTFS notes.
- [x] Build Debug macOS and check the patch; no automated tests are added or run.
