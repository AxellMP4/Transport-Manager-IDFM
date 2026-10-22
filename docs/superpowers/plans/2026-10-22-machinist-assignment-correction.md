# Correction d’affectation machiniste Implementation Plan

> **For agentic workers:** Implement this plan task by task. Each step is independently checkable.

**Goal:** Corriger, avec une trace d’audit, le machiniste attribué à un bloc de service déjà terminé.

**Architecture:** Un bloc soldé reste l’unité de correction, car ses courses partagent une même présence et une paie déjà enregistrée. La correction réattribue tout le bloc après validation des qualifications, du dépôt et des conflits; elle conserve les heures, le montant de paie et les mouvements de trésorerie et enregistre l’ancienne et la nouvelle attribution avec un motif.

**Tech Stack:** Swift, SwiftUI, `Codable`, moteur de simulation existant.

**Spec:** `docs/Plan_recreation_Transport_Manager_IDFM.md` et le manque documenté dans `docs/IMPLEMENTATION_STATUS.md`.

## Global Constraints

- La cible livrée est l’application macOS native SwiftUI.
- Les affectations et l’audit vivent dans la sauvegarde `SimulationSession`.
- Les règles de durée, repos et coût restent des règles de jeu, pas une validation réglementaire.
- Les sauvegardes antérieures sans historique de corrections doivent rester lisibles.
- La correction d’un bloc ne doit modifier ni les heures et montants déjà enregistrés, ni le total des écritures financières ou des règlements.

## Review Focus

- Un bloc non terminé ou non soldé ne peut pas être corrigé.
- Un machiniste d’un autre dépôt, recruté après le service ou non qualifié ne peut pas recevoir le bloc.
- Les conflits de service, repos, absence et formation bloquent la correction.
- Une correction répétée garde chaque transition et son motif dans l’historique.
- Une facture déjà émise ou réglée conserve son montant et sa date de règlement.

---

### Task 1: Correction persistée et validée

**Files:**
- Modify: `TransportManagerIDFM/Domain/VehicleMarket.swift`
- Modify: `TransportManagerIDFM/Domain/SimulationEngine.swift`

**Interfaces:**
- Add `MachinistAssignmentCorrection` with block ID, previous/corrected machinist IDs, simulation timestamp and reason.
- Add candidate lookup and `correctMachinistDutyBlock(dutyBlockID:toMachinistID:reason:)` to `SimulationEngine`.

- [x] Make the machinist ID mutable for the saved service assignment, duty block and payroll record; add the optional correction history to `SimulationSession` and initialize it for new careers.
- [x] Return correction candidates only for settled completed blocks, same-depot hires qualified for every bus in the block, and candidates whose existing work, breaks, absences and training satisfy the game scheduling rules without merging another block.
- [x] Implement the correction operation with full revalidation, a required reason, an audit record, updated block/assignment/break attribution, and payroll/invoice description updates that leave amounts and cash movements unchanged.

### Task 2: Personnel history editor and tracking

**Files:**
- Modify: `TransportManagerIDFM/Features/OperationsDashboardView.swift`
- Modify: `docs/IMPLEMENTATION_STATUS.md`

- [x] Add a recent settled-service history to Personnel with block dates, routes, recorded cost, correction history and an editor for eligible replacement machinists.
- [x] Explain in the editor that the correction changes the recorded attribution while preserving the already-settled pay and financial totals.
- [x] Mark the implemented scope and remaining limits in the status document; run `xcodebuild` for Debug macOS and `git diff --check`.
