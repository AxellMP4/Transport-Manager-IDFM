# Workshop Parts Inventory

**Goal:** Make workshop consumables part of maintenance and repair planning, with a saved depot stock and visible purchase costs.

**Architecture:** Store generic maintenance and severity-based repair kits in the career session. Deduct one kit when an intervention is scheduled. The active stock panel can immediately replenish a selected kit, debiting the existing financial ledger. New careers receive a small funded starter stock; older careers decode with zero stock and can replenish it.

**Scope:** Prices and immediate delivery are explicitly game rules. Real part numbers by vehicle model, purchase lead times, stock transfers and supplier selection remain open.

## Tasks

- [x] Add Codable stock types and starting inventory with an explicit initial cost.
- [x] Add ledger-backed restocking and refuse repair or preventive maintenance without the required kit.
- [x] Show stock in the vehicle market and allow restocking during an incident response.
- [x] Document the starter stock, purchase rule and remaining supply-chain gaps.
- [x] Build the macOS target; no tests were added or run.
