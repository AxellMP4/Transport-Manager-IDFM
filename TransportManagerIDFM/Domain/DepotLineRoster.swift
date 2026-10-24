import Foundation

enum DepotLineEvidenceStatus: String, Hashable, Sendable {
    case confirmed = "Rattachement documenté"
    case shared = "Partagée"
    case partial = "Remisage partiel"
    case observedPool = "Parc de ligne observé"
    case candidate = "Affectation candidate"
    case unresolved = "Non attribuée"
    case conflict = "Sources contradictoires"
    case planned = "Projet"

    var systemImage: String {
        switch self {
        case .confirmed: "checkmark.seal.fill"
        case .shared: "arrow.triangle.branch"
        case .partial: "bus.fill"
        case .observedPool: "eye"
        case .candidate: "questionmark.circle"
        case .unresolved: "minus.circle"
        case .conflict: "exclamationmark.triangle.fill"
        case .planned: "hammer"
        }
    }
}

enum DepotSiteAvailability: Hashable, Sendable {
    case operational
    case planned
    case currentStatusUnverified

    var label: String {
        switch self {
        case .operational: "En activité · preuve publique"
        case .planned: "Projet · non opérationnel"
        case .currentStatusUnverified: "Site référencé · statut actuel à vérifier"
        }
    }

    var shortLabel: String {
        switch self {
        case .operational: "En activité"
        case .planned: "Projet"
        case .currentStatusUnverified: "À vérifier"
        }
    }

    var systemImage: String {
        switch self {
        case .operational: "building.2.fill"
        case .planned: "hammer"
        case .currentStatusUnverified: "questionmark.circle"
        }
    }

    var isOperational: Bool { self == .operational }
}

struct DepotLineRosterSite: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let locality: String
    let status: String
    let availability: DepotSiteAvailability
    let evidenceNote: String
    let sourceURL: URL?
    let documentedAddress: String?
    let evidenceTitle: String?
    let idfmBusContractID: String?
    let additionalEvidenceTitle: String?
    let additionalEvidenceURL: URL?
    let supportingEvidence: [DepotSiteEvidenceLink]
    let fleetObservation: DepotFleetObservation?
    let facilityObservations: [DepotFacilityObservation]
    let chargingInfrastructureObservation: DepotChargingInfrastructureObservation?

    var evidenceLinks: [DepotSiteEvidenceLink] {
        var links: [DepotSiteEvidenceLink] = []
        if let evidenceTitle, let sourceURL {
            links.append(DepotSiteEvidenceLink(title: evidenceTitle, url: sourceURL))
        }
        if let additionalEvidenceTitle, let additionalEvidenceURL {
            links.append(DepotSiteEvidenceLink(title: additionalEvidenceTitle, url: additionalEvidenceURL))
        }
        links.append(contentsOf: supportingEvidence)
        var seenURLs = Set<String>()
        return links.filter { seenURLs.insert($0.url.absoluteString).inserted }
    }

    var isOperational: Bool { availability.isOperational }

    /// The public contract defines a real line roster for this site. An unverified
    /// operating status stays visible but does not prevent a career on that contract.
    var hasPlayableContractScope: Bool {
        availability != .planned && idfmBusContractID != nil
    }

    init(
        id: String,
        name: String,
        locality: String,
        status: String,
        availability: DepotSiteAvailability,
        evidenceNote: String,
        sourceURL: URL?,
        documentedAddress: String? = nil,
        evidenceTitle: String? = nil,
        idfmBusContractID: String? = nil,
        additionalEvidenceTitle: String? = nil,
        additionalEvidenceURL: URL? = nil,
        supportingEvidence: [DepotSiteEvidenceLink] = [],
        fleetObservation: DepotFleetObservation? = nil,
        facilityObservations: [DepotFacilityObservation] = [],
        chargingInfrastructureObservation: DepotChargingInfrastructureObservation? = nil
    ) {
        self.id = id
        self.name = name
        self.locality = locality
        self.status = status
        self.availability = availability
        self.evidenceNote = evidenceNote
        self.sourceURL = sourceURL
        self.documentedAddress = documentedAddress
        self.evidenceTitle = evidenceTitle
        self.idfmBusContractID = idfmBusContractID
        self.additionalEvidenceTitle = additionalEvidenceTitle
        self.additionalEvidenceURL = additionalEvidenceURL
        self.supportingEvidence = supportingEvidence
        self.fleetObservation = fleetObservation
        self.facilityObservations = facilityObservations
        self.chargingInfrastructureObservation = chargingInfrastructureObservation
    }
}

struct DepotSiteEvidenceLink: Hashable, Identifiable, Sendable {
    let title: String
    let url: URL

    var id: String { url.absoluteString }
}

struct DepotFleetEnergyCount: Hashable, Identifiable, Sendable {
    let energyTitle: String
    let vehicleCount: Int

    var id: String { energyTitle 