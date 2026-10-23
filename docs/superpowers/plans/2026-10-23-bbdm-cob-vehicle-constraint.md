# Bords de Marne COB Vehicle Constraint Plan

> **For agentic workers:** Implement this plan task by task. Each step is independently checkable.

**Goal:** Record and display IDFM’s published vehicle and capacity constraint for the planned Bus Bords de Marne COB without inventing named-site capacities or future line assignments.

**Architecture:** Extend the existing planned-site evidence note and source links in `DepotLineRoster`; update the project tracker with the new evidence and its limits. The existing depot roster UI already renders these notes and links.

**Tech Stack:** Swift value types, SwiftUI, Xcode macOS target.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md`, sections 6.1–6.3; `docs/IMPLEMENTATION_STATUS.md`, items 266 and 353.

## Global Constraints

- Do not infer named depot capacities, energy equipment, or a post-transfer line roster.
- Keep the Neuilly-sur-Marne COB marked as planned and other future shared lines undefined.
- Build the Debug macOS target and update `docs/IMPLEMENTATION_STATUS.md`.

## Review Focus

- Keep the Bords de Marne project’s approximate 150-passenger figure separate from the TZen 4 HESS model’s 140-passenger specification.
- State that IDFM’s public Q&A does not provide capacities or name each existing COB.
- Preserve the existing localization source while adding the vehicle and facility source.

---

### Task 1: Add the sourced infrastructure constraint

**Files:**
- Modify: `TransportManagerIDFM/Domain/DepotLineRoster.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`
- Create: `docs/superpowers/plans/2026-10-23-bbdm-cob-vehicle-constraint.md`
- Verify: Debug macOS build and `git diff --check`

**Interfaces:**
- Produces: source-linked technical context on the planned Neuilly-sur-Marne COB through the existing site detail UI.

- [x] Link IDFM’s 22 February 2024 Q&A and record the 24 m electric bi-articulated vehicle, approximate passenger capacity, maintenance/cleaning/parking role, and existing-center limitation with stated scope.
- [x] Build Debug macOS and check the patch; no automated tests are added or run.
