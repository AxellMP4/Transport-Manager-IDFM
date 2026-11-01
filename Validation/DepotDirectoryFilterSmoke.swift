import Foundation

@main
enum DepotDirectoryFilterSmoke {
    static func main() {
        let evidenceURL = URL(string: "https://example.com/depot")!
        let observedFleet = DepotFleetObservation(
            totalVehicleCount: 12,
            energyCounts: [DepotFleetEnergyCount(energyTitle: "Électrique", vehicleCount: 12)],
            averageFleetAgeYears: nil,
            airConditionedVehicleSharePercent: nil,
            reviewedOnLabel: "2026",
            sourceFreshnessNote: "Observation datée",
            limitationNote: "Ne prouve pas la capacité maximale",
            sourceTitle: "Source de test",
            sourceURL: evidenceURL
        )
        let sites = [
            DepotLineRosterSite(
                id: "neuilly-plaisance",
                name: "Neuilly-Plaisance",
                locality: "Seine-Saint-Denis",
                status: "COB nommé pour DSP 45 · RATP Cap",
                availability: .operational,
                evidenceNote: "Adresse publiée",
                sourceURL: evidenceURL,
                documentedAddress: "26 boulevard Gallieni, Neuilly-Plaisance",
                idfmBusContractID: "45",
                operatorName: "RATP Cap"
            ),
            DepotLineRosterSite(
                id: "freres-lumiere",
                name: "Frères-Lumière",
                locality: "Neuilly-sur-Marne",
                status: "Site listé · statut à vérifier",
                availability: .currentStatusUnverified,
                evidenceNote: "Adresse absente",
                sourceURL: evidenceURL,
                idfmBusContractID: "45",
                operatorName: "RATP Cap"
            ),
            DepotLineRosterSite(
                id: "lagny",
                name: "Lagny-sur-Marne",
                locality: "Seine-et-Marne",
                status: "COB nommé pour DSP 10 · Transdev",
                availability: .operational,
                evidenceNote: "Parc observé",
                sourceURL: evidenceURL,
                idfmBusContractID: "10",
                operatorName: "Transdev",
                fleetObservation: observedFleet
            )
        ]

        let exactDepotMatch = DepotDirectorySiteFilter(
            availability: .operational,
            operatorName: "RATP Cap",
            contractID: "45",
            quality: .documentedAddress
        ).applying(to: sites)
        precondition(exactDepotMatch.map(\.id) == ["neuilly-plaisance"])

        let fleetEvidenceMatch = DepotDirectorySiteFilter(
            operatorName: "Transdev",
            quality: .observedFleet
        ).applying(to: sites)
        precondition(fleetEvidenceMatch.map(\.id) == ["lagny"])

        let documentedAddresses = DepotDirectorySiteFilter(quality: .documentedAddress).applying(to: sites)
        precondition(documentedAddresses.map(\.id) == ["neuilly-plaisance"])

        print("PASS: depot directory filters combine operator, contract, status, and data quality without hiding unfiltered records")
    }
}
