# Estimate Vehicle Total Ownership Cost

## Scope

Add an offer-by-offer total cost estimate to the vehicle market using the existing simulated purchase, energy, maintenance, condition, and resale rules. Keep it clearly labeled as a game projection.

## Decisions

- Compare 100,000 km over five game years (20,000 km/year).
- Use the asking price, current generic energy estimate, scheduled maintenance at each 10,000 km wear interval, and the existing resale formula at the end of the horizon.
- Assume maintenance restores condition to 100%; include an initial restoration for used offers below 100% condition.
- Scope the estimate to one bus. Include one preventive-maintenance kit per intervention at its catalog price; allocate the value of the two per-model starting-stock kits to that bus as resource use, even though the game buys that stock up front and shares it across same-model buses. This is an ownership-cost estimate, not future-only cash flow or a per-bus fleet total.
- Exclude financing, insurance, tires, battery replacement, and depot infrastructure; state these exclusions in the market UI.

## Steps

1. Add a reusable ownership-cost estimate model and calculation to `VehicleMarketCatalog`.
2. Show the net estimate and its cost breakdown on each purchasable offer card.
3. Record the completed slice in `docs/IMPLEMENTATION_STATUS.md` while leaving broader catalog and depot-data work open.
4. Build the macOS target to verify compilation.
