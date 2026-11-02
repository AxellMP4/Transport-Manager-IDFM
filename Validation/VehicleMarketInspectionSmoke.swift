import Foundation

@main
struct VehicleMarketInspectionSmoke {
    @MainActor
    static func main() {
        negotiationResponsesAreDeterministicAndDoNotBuyBeforeConfirmation()
        counteroffersExpireAndRejectedOffersDoNotPurchase()
        unresolvedNegotiationsNeedAnExplicitDecision()
        negotiatedPurchasesRecheckCapitalAndStock()
        legacyCareerWithoutNegotiationsStillDecodes()

        let unknownDepotEnergy = DepotEnergyEvidence(
            status: .unknown,
            note: "L’installation réelle de ce dépôt n’est pas documentée.",
            dateLabel: nil,
            sources: []
        )
        let legacyReadiness = DepotEnergyReadiness.legacyUnverified(unknownDepotEnergy)
        let legacyCompatibility = VehicleMarketDepotCompatibilityRules.presentation(for: legacyReadiness)
        precondition(legacyReadiness.isReady, "Une sauvegarde ancienne conserve le comportement d’achat compatible avec son schéma.")
        precondition(legacyCompatibility.status.contains("Achat autorisé"))
        precondition(legacyCompatibility.status.contains("non vérifié"))
        precondition(legacyCompatibility.detail == unknownDepotEnergy.note)

        guard let hydrogenReference = VehicleMarketCatalog.model(id: "solaris-new-urbino-12-hydrogen-idfm") else {
            fatalError("Le modèle Solaris de référence doit rester consultable.")
        }
        precondition(VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "SOLARIS"))
        precondition(VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "hydrogene"))
        precondition(VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "12"))
        precondition(VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "  Solaris  "))
        precondition(!VehicleMarketCatalog.matchesCatalogSearch(hydrogenReference, query: "articulé"))

        let requiredInstallation = DepotEnergyReadiness.requiresInstallation(unknownDepotEnergy)
        let blockedCompatibility = VehicleMarketDepotCompatibilityRules.presentation(for: requiredInstallation)
        precondition(!requiredInstallation.isReady, "Une carrière récente doit installer l’équipement requis avant l’achat.")
        precondition(blockedCompatibility.status == requiredInstallation.statusTitle, "Les autres états de compatibilité gardent leur libellé existant.")

        guard let usedOffer = VehicleMarketCatalog.offers(for: 2026).first(where: {
            $0.id == "irisbus-citelis-12-diesel-used-2012-2026"
        }) else {
            fatalError("L’offre d’occasion témoin doit exister pour la carrière 2026.")
        }

        let originalAskingPrice = usedOffer.askingPrice
        let firstReport = VehicleMarketInspectionRules.estimate(for: usedOffer, gameYear: 2026)
        guard let firstReport else {
            fatalError("Une offre d’occasion doit permettre une inspection estimée avant achat.")
        }

        precondition(firstReport.offerID == usedOffer.id)
        precondition(firstReport.estimatedConditionPercent == usedOffer.conditionPercent)
        precondition(firstReport.findings.contains { $0.id == "condition-remediation" })
        precondition(firstReport.findings.contains { $0.id == "high-mileage-wear" })
        precondition(firstReport.findings.contains { $0.id == "age-related-check" })
        precondition(firstReport.estimatedRemediationCostEuro > 0)
        precondition(
            firstReport.estimatedRemediationCostEuro == firstReport.findings.reduce(0) { $0 + $1.estimatedCostEuro },
            "Le devis estimé doit correspondre à la somme des interventions estimées."
        )
        precondition(
            VehicleMarketInspectionRules.estimate(for: usedOffer, gameYear: 2026) == firstReport,
            "L’estimation doit être reproductible pour une même offre et une même année."
        )
        precondition(
            usedOffer.askingPrice == originalAskingPrice,
            "L’inspection ne doit ni acheter le bus ni modifier son prix d’offre."
        )

        let cleanUsedOffer = VehicleMarketOffer(
            id: "clean-used-bus",
            modelID: usedOffer.modelID,
            condition: .used,
            vehicleYear: 2020,
            odometerKilometers: 80_000,
            conditionPercent: 100,
            estimatedPriceLow: 100_000,
            estimatedPriceHigh: 120_000,
            askingPrice: 110_000,
            estimateConfidence: .low,
            deliveryDays: 2,
            initialStock: 1,
            priceBasis: "Estimation de jeu"
        )
        guard let cleanReport = VehicleMarketInspectionRules.estimate(for: cleanUsedOffer, gameYear: 2026) else {
            fatalError("L’offre propre d’occasion doit rester inspectable.")
        }
        precondition(cleanReport.estimatedConditionPercent == 100)
        precondition(cleanReport.findings.isEmpty)
        precondition(cleanReport.estimatedRemediationCostEuro == 0)

        guard let newOffer = VehicleMarketCatalog.offers(for: 2026).first(where: { $0.condition == .new }) else {
            fatalError("Le marché doit contenir une offre neuve témoin.")
        }
        precondition(
            VehicleMarketInspectionRules.estimate(for: newOffer, gameYear: 2026) == nil,
            "L’inspection de remise en état concerne les offres d’occasion uniquement."
        )

        print("Vehicle market inspection and negotiation smoke passed.")
    }

    @MainActor
    private static func negotiationResponsesAreDeterministicAndDoNotBuyBeforeConfirmation() {
        let offer = negotiationOffer()
        let initialDate = Date(timeIntervalSince1970: 1_800_000_000)
        let engine = SimulationEngine(initialSession: negotiationSession(
            at: initialDate,
            offer: offer,
            cash: 200_000
        ))

        let negotiation = try! engine.proposeVehicleNegotiation(offerID: offer.id, proposedPriceEuro: 92_000)
        precondition(negotiation.response == .accepted(priceEuro: 92_000))
        precondition(engine.session?.vehicleNegotiations?.first == negotiation)
        precondition(engine.session?.cashBalance == 200_000)
        precondition(engine.session?.ownedBuses?.isEmpty == true)
        precondition(engine.session?.ledgerEntries?.isEmpty == true)

        try! engine.acceptVehicleNegotiation(offerID: offer.id)
        let purchased = engine.session!
        precondition(purchased.cashBalance == 108_000)
        precondition(purchased.ownedBuses?.first?.purchasePrice == 92_000)
        precondition(purchased.ledgerEntries?.last?.amount == -92_000)
        precondition(purchased.vehicleNegotiations?.first?.response == .purchased(priceEuro: 92_000))

        let negotiatedOwnershipCost = VehicleMarketCatalog.ownershipCostEstimate(
            for: offer,
            model: VehicleMarketCatalog.model(id: offer.modelID)!,
            startingAt: initialDate,
            acquisitionPriceEuro: 92_000
        )
        precondition(negotiatedOwnershipCost.acquisitionCostEuro == 92_000)
    }

    @MainActor
    private static func counteroffersExpireAndRejectedOffersDoNotPurchase() {
        let offer = negotiationOffer()
        precondition(
            VehicleMarketNegotiationRules.response(for: offer, proposedPriceEuro: 80_000) == .counterOffered(priceEuro: 90_000)
        )
        precondition(
            VehicleMarketNegotiationRules.response(for: offer, proposedPriceEuro: 60_000) == .refused
        )

        let proposedAt = Date(timeIntervalSince1970: 1_800_000_000)
        let negotiation = VehicleNegotiationRecord(
            offerID: offer.id,
            proposedPriceEuro: 80_000,
            response: .counterOffered(priceEuro: 90_000),
            createdAt: proposedAt,
            expiresAt: proposedAt.addingTimeInterval(VehicleMarketNegotiationRules.responseValidity)
        )
        precondition(negotiation.response(at: proposedAt) == .counterOffered(priceEuro: 90_000))
        precondition(negotiation.response(at: negotiation.expiresAt!) == .expired)

        let engine = SimulationEngine(initialSession: negotiationSession(at: proposedAt, offer: offer, cash: 200_000))
        let refused = try! engine.proposeVehicleNegotiation(offerID: offer.id, proposedPriceEuro: 60_000)
        precondition(refused.response == .refused)
        precondition(engine.session?.ownedBuses?.isEmpty == true)
        precondition(engine.session?.ledgerEntries?.isEmpty == true)
        precondition(engine.session?.cashBalance == 200_000)
    }

    @MainActor
    private static func unresolvedNegotiationsNeedAnExplicitDecision() {
        let offer = negotiationOffer()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let counterofferEngine = SimulationEngine(initialSession: negotiationSession(at: now, offer: offer, cash: 200_000))
        let counteroffer = try! counterofferEngine.proposeVehicleNegotiation(offerID: offer.id, proposedPriceEuro: 80_000)
        precondition(counteroffer.response == .counterOffered(priceEuro: 90_000))
        try! counterofferEngine.acceptVehicleNegotiation(offerID: offer.id)
        precondition(counterofferEngine.session?.cashBalance == 110_000)
        precondition(counterofferEngine.session?.ownedBuses?.first?.purchasePrice == 90_000)
        precondition(counterofferEngine.session?.ledgerEntries?.last?.amount == -90_000)

        let awaitingDecisionEngine = SimulationEngine(initialSession: negotiationSession(at: now, offer: offer, cash: 200_000))
        try! awaitingDecisionEngine.proposeVehicleNegotiation(offerID: offer.id, proposedPriceEuro: 92_000)
        do {
            try awaitingDecisionEngine.purchaseVehicle(offerID: offer.id)
            preconditionFailure("A direct purchase must wait for a pending seller response to be accepted or declined.")
        } catch SimulationEngineError.vehicleNegotiationAwaitingResponse {
            precondition(awaitingDecisionEngine.session?.ownedBuses?.isEmpty == true)
            precondition(awaitingDecisionEngine.session?.ledgerEntries?.isEmpty == true)
            precondition(awaitingDecisionEngine.session?.cashBalance == 200_000)
        } catch {
            preconditionFailure("Unexpected pending negotiation error: \(error)")
        }

        try! awaitingDecisionEngine.declineVehicleNegotiation(offerID: offer.id)
        try! awaitingDecisionEngine.purchaseVehicle(offerID: offer.id)
        precondition(awaitingDecisionEngine.session?.cashBalance == 100_000)
        precondition(awaitingDecisionEngine.session?.ownedBuses?.first?.purchasePrice == offer.askingPrice)
        precondition(awaitingDecisionEngine.session?.vehicleNegotiations?.first?.response == .declined)
    }

    @MainActor
    private static func negotiatedPurchasesRecheckCapitalAndStock() {
        let offer = negotiationOffer()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let lowCapitalEngine = SimulationEngine(initialSession: negotiationSession(at: now, offer: offer, cash: 85_000))
        try! lowCapitalEngine.proposeVehicleNegotiation(offerID: offer.id, proposedPriceEuro: 92_000)
        do {
            try lowCapitalEngine.acceptVehicleNegotiation(offerID: offer.id)
            preconditionFailure("Accepting the seller's price must recheck the current cash balance.")
        } catch SimulationEngineError.insufficientCapital(required: 92_000, available: 85_000) {
            precondition(lowCapitalEngine.session?.ownedBuses?.isEmpty == true)
            precondition(lowCapitalEngine.session?.ledgerEntries?.isEmpty == true)
            precondition(lowCapitalEngine.session?.cashBalance == 85_000)
        } catch {
            preconditionFailure("Unexpected low-capital error: \(error)")
        }

        var soldOutSession = negotiationSession(at: now, offer: offer, cash: 200_000)
        soldOutSession.purchasedOfferQuantities = [offer.id: offer.initialStock]
        let soldOutEngine = SimulationEngine(initialSession: soldOutSession)
        try! soldOutEngine.proposeVehicleNegotiation(offerID: offer.id, proposedPriceEuro: 92_000)
        do {
            try soldOutEngine.acceptVehicleNegotiation(offerID: offer.id)
            preconditionFailure("Accepting a negotiated amount must recheck remaining stock.")
        } catch SimulationEngineError.exhaustedMarketOffer {
            precondition(soldOutEngine.session?.ownedBuses?.isEmpty == true)
            precondition(soldOutEngine.session?.ledgerEntries?.isEmpty == true)
            precondition(soldOutEngine.session?.cashBalance == 200_000)
        } catch {
            preconditionFailure("Unexpected stock error: \(error)")
        }
    }

    private static func legacyCareerWithoutNegotiationsStillDecodes() {
        let offer = negotiationOffer()
        let session = negotiationSession(at: Date(timeIntervalSince1970: 1_800_000_000), offer: offer, cash: 100_000)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try! encoder.encode(session)
        var legacyObject = try! JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        legacyObject.removeValue(forKey: "vehicleNegotiations")
        let legacyData = try! JSONSerialization.data(withJSONObject: legacyObject)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try! decoder.decode(SimulationSession.self, from: legacyData)
        precondition(decoded.vehicleNegotiations == nil)
    }

    private static func negotiationOffer(stock: Int = 1) -> VehicleMarketOffer {
        VehicleMarketOffer(
            id: "negotiation-smoke-offer",
            modelID: "irisbus-citelis-12-diesel",
            condition: .used,
            vehicleYear: 2020,
            odometerKilometers: 80_000,
            conditionPercent: 95,
            estimatedPriceLow: 80_000,
            estimatedPriceHigh: 120_000,
            askingPrice: 100_000,
            estimateConfidence: .low,
            deliveryDays: 2,
            initialStock: stock,
            priceBasis: "Estimation de jeu"
        )
    }

    private static func negotiationSession(at date: Date, offer: VehicleMarketOffer, cash: Int) -> SimulationSession {
        SimulationSession(
            id: "vehicle-negotiation-smoke-session",
            scenarioID: "vehicle-negotiation-smoke",
            depotID: "vehicle-negotiation-smoke-depot",
            networkVersions: SimulationDataVersions(
                gtfsID: "negotiation-gtfs",
                routeGeometryID: "negotiation-geometry",
                contractID: "negotiation-contract",
                lineReferenceID: "negotiation-lines"
            ),
            randomSeed: 9,
            createdAt: date,
            updatedAt: date,
            simulatedAt: date,
            speed: .paused,
            resumeSpeed: .x1,
            nextEventSequence: 0,
            pendingEvents: [],
            eventHistory: [],
            cashBalance: cash,
            ownedBuses: [],
            marketOffers: [offer],
            purchasedOfferQuantities: [:],
            ledgerEntries: []
        )
    }
}
